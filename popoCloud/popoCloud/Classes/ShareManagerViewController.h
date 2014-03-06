//
//  ShareManagerViewController.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-26.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "EGORefreshTableHeaderView.h"
#import "PCLogout.h"
#import "PCFileCell.h"
#import "PCFileExpansionCell.h"
#import "PCShareUrl.h"
#import <QuickLook/QuickLook.h>
#import "MBProgressHUD.h"
#import "PCFileInfo.h"
#import "PCShareServices.h"
@interface ShareManagerViewController : UIViewController <PCShareServicesDelegate,
PCFileCellDelegate,QLPreviewControllerDataSource, QLPreviewControllerDelegate,PCFileExpansionCellDelegate> {
    NSMutableData* data;
    NSMutableArray *tableData;
    
    BOOL isDeleteShare;
    
    NSInteger mStatus;
    NSInteger deleteIndex;
    
    //    EGORefreshTableHeaderView *_refreshHeaderView;
	BOOL _reloading;
    BOOL _isGetShare;
    PCFileInfo *currentFileInfo;
    
    BOOL isOpen;
    NSIndexPath *selectIndexPath;
    
    PCShareUrl *shareUrl;
    FileCache* fileCache;
    BOOL isProcessing;
    NSURLConnection *urlConnection;
    
    MBProgressHUD *hud;
    UIDeviceOrientation oldOrientation;
}

@property (nonatomic, retain) IBOutlet UITableView* tableView;
@property (nonatomic, retain) IBOutlet UILabel* lblText;
@property (nonatomic, retain) IBOutlet UILabel* lblDes;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *dicatorView;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) NSURLConnection *urlConnection;
@property (nonatomic, assign) BOOL isOpen;
@property (nonatomic, retain) NSIndexPath *selectIndexPath;
@property (nonatomic, copy) NSString *localPath;

@property (nonatomic, retain) PCFileInfo *currentFileInfo;
@property (nonatomic, retain) MBProgressHUD *hud;

- (void) cancelProcess;
- (void)doneLoadingTableViewData;
- (void) getShareList;
- (void) deleteShare:(NSString*)shareID;

@end
