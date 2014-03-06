//
//  Asset.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAsset.h"
#import "ELCAssetTablePicker.h"
#import "NetPenetrate.h"
#import "PCAppDelegate.h"
#import "FileListViewController.h"
#import "FileUploadManager.h"
#import "PCLogin.h"
#import "FileUploadInfo.h"
#import "PCUtilityUiOperate.h"

#define VIEWTAG_THUMBNAIL   100
#define VIEWTAG_OVERLAY     101

@implementation ELCAsset

@synthesize asset;
@synthesize parent;

-(id)initWithAsset:(ALAsset*)_asset
{
	if (self = [super initWithFrame:CGRectZero])
    {
		self.asset = _asset;
		
		UIImageView *assetImageView = [[UIImageView alloc] initWithFrame:
                                       CGRectMake(0, 0, 75, 75)];
		[assetImageView setContentMode:UIViewContentModeScaleToFill];
        [assetImageView setTag:VIEWTAG_THUMBNAIL];
		//[assetImageView setImage:[UIImage imageWithCGImage:[self.asset thumbnail]]];
		[self addSubview:assetImageView];
		[assetImageView release];
    }
    
	return self;
}

- (void)showPic
{
    UIImageView *thumbImgView = (UIImageView *)[self viewWithTag:VIEWTAG_THUMBNAIL];
    [(UIImageView*)thumbImgView  setImage:[UIImage imageWithCGImage:[self.asset thumbnail]]];
}

-(void)toggleSelection
{
    //    UINavigationController *rootController = ((PCAppDelegate *)[UIApplication sharedApplication].delegate).viewController;
    UITabBarController *tabController = ((PCAppDelegate *)[UIApplication sharedApplication].delegate).tabbarContent;
    UINavigationController *fileRootController = (UINavigationController *)tabController.selectedViewController;
    FileListViewController *fileList = (FileListViewController *)fileRootController.topViewController;
    DLogNotice(@"fileList=%@",fileList);
    NSString *fileName = asset.defaultRepresentation.filename;
    NSString *path = [fileList.dirPath stringByAppendingPathComponent:fileName];
    DLogNotice(@"upload path=%@,size=%lld",path,asset.defaultRepresentation.size);
    
    if (path.length >= FILE_PATH_MAX_LENGTH)
    {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"CannotUpload", nil) delegate:nil];
        return;
    }
    
    if (![NetPenetrate sharedInstance].isPenetrate &&
        asset.defaultRepresentation.size >= SIZE_2M * 15)
    {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"FileSizeMoreThan30MB", nil) delegate:nil];
        return;
    }
    
    FileUploadManager *uploadMgr = [FileUploadManager sharedManager];
    NSNumber *arrayIndex = uploadMgr.deviceDic[[PCLogin getResource]];
    
    if (arrayIndex)
    {
        NSString *assetUrl = [[[asset valueForProperty:ALAssetPropertyURLs] valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys] objectAtIndex:0]] absoluteString];
        __block BOOL alreadyInUpload = NO;
        
        [uploadMgr.uploadFileArr[arrayIndex.integerValue] enumerateObjectsUsingBlock:
         ^(id obj, NSUInteger idx, BOOL *stop) {
             FileUploadInfo *info = obj;
             if ([info.hostPath isEqualToString:path] &&
                 [info.assetUrl isEqualToString:assetUrl])
             {
                 alreadyInUpload = YES;
                 *stop = YES;
             }
         }];
        
        if (alreadyInUpload)
        {
            [PCUtilityUiOperate showErrorAlert:[fileName stringByAppendingString:NSLocalizedString(@"FileAlreadyUpload", nil)]
                                      delegate:nil];
            return;
        }
    }
    
    if (_selected)
    {
        UIView *overlayView = [self viewWithTag:VIEWTAG_OVERLAY];
        [overlayView removeFromSuperview];
    }
    else
    {
        UIImageView *overlayView = [[UIImageView alloc] initWithFrame:
                                    CGRectMake(0, 0, 75, 75)];
        [overlayView setTag:VIEWTAG_OVERLAY];
        [overlayView setImage:[UIImage imageNamed:@"overlay.png"]];
        [self addSubview:overlayView];
        [overlayView release];
    }
    
    _selected = !_selected;
    [(ELCAssetTablePicker *)parent notifyClickImage:_selected];
}

- (void)dealloc
{
    self.asset = nil;
    [super dealloc];
}

@end

