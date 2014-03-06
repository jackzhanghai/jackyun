//
//  FileCacheController.h
//  popoCloud
//
//  Created by leijun on 13-3-4.
//
//

#import <UIKit/UIKit.h>
#import "FileCache.h"
#import "KTPhotoScrollViewController.h"
#import "SDWebImageDataSource.h"
#import "KTPhotoBrowserDataSource.h"
#import "PCShareUrl.h"
#import <QuickLook/QuickLook.h>
#import "PCFileInfo.h"
#import "PCRestClient.h"
#import "KTURLRequest.h"
typedef enum {
	KT_FILE_MEDIA,
	KT_FILE_IMAGE,
	KT_FILE_OTHER
} KTFILEType;

@class MPMoviePlayerController;
@interface FileCacheController : UIViewController <PCFileCacheDelegate,KTPhotoBrowserDataSource,PCRestClientDelegate
//QLPreviewControllerDataSource,
//QLPreviewControllerDelegate
>
{
    PCRestClient *restClient;
}
@property (readwrite, nonatomic) KTFILEType m_fileType;
@property (copy, nonatomic) NSString *m_filePath;
@property (retain, nonatomic) IBOutlet UIImageView *imgView;
@property (retain, nonatomic) IBOutlet UIButton *BtnTitle;
@property (retain, nonatomic) IBOutlet UIProgressView *progressView;
@property (retain, nonatomic) IBOutlet UILabel *labelProgress;
@property (retain, nonatomic)  UIBarButtonItem *btnShare;
@property (retain, nonatomic)  UIBarButtonItem *btnCollect;
@property (retain, nonatomic)  UIBarButtonItem *btnDelete;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *dicatorView;
@property (nonatomic, readwrite) BOOL  bHasDownloaded;
@property (retain, nonatomic)    NSMutableArray *images_;
@property (retain, nonatomic)    PCFileInfo *currentFileInfo;
@property (nonatomic, readwrite) int startWithIndex_;
@property (retain, nonatomic)    PCShareUrl *shareUrl;
@property (nonatomic, readwrite) BOOL  bViewDidAppear;
@property (retain, nonatomic) UIToolbar *toolbar_;
@property (retain, nonatomic)  NSString            *backBtnTitle;
//为了 让 点击按钮的 响应 区域 变大。
@property (retain, nonatomic) IBOutlet UIButton *BtnTitleCover;
@property (readwrite, nonatomic) BOOL   bOriginalImage;//查看图片是否用原图（收藏是）
@property (retain, nonatomic) KTURLRequest *currentRequest;
- (IBAction)clickShare:(id)sender;
- (IBAction)clickOpen:(id)sender;
- (IBAction)clickCollect:(id)sender;

- (id)initWithPath:(NSString*)filePath andFinishLoadingState:(BOOL)finished andDataSource: (NSArray*)dataArray  andCurrentPCFileInfo:(PCFileInfo*)currentFileInfo andLastViewControllerName:(NSString *)title;
- (void) openFiles;
- (void)downloadProgress:(NSNotification *)note;
- (void)downloadFinish:(NSNotification *)note;

@end
