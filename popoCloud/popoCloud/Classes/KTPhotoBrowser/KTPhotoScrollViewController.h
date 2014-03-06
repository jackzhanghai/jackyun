//
//  KTPhotoScrollViewController.h
//  KTPhotoBrowser
//
//  Created by Kirby Turner on 2/4/10.
//  Copyright 2010 White Peak Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PCShareUrl.h"
#import "PCRestClient.h"
#import "PCRestClient.h"

@class KTPhotoViewController;
@class FileCache;
@protocol KTPhotoBrowserDataSource;

@interface KTPhotoScrollViewController : UIViewController<UIScrollViewDelegate, UIActionSheetDelegate,PCRestClientDelegate,UITableViewDataSource,UITableViewDelegate>
{
   id <KTPhotoBrowserDataSource> dataSource_;
   UIScrollView *scrollView_;
   UIToolbar *toolbar_;
   NSUInteger startWithIndex_;
   NSInteger currentIndex_;
   NSInteger photoCount_;
   
   NSMutableArray *photoViews_;

   // these values are stored off before we start rotation so we adjust our content offset appropriately during rotation
   int firstVisiblePageIndexBeforeRotation_;
   CGFloat percentScrolledIntoFirstVisiblePage_;
   
   UIStatusBarStyle statusBarStyle_;

   BOOL statusbarHidden_; // Determines if statusbar is hidden at initial load. In other words, statusbar remains hidden when toggling chrome.
   BOOL isChromeHidden_;
   BOOL rotationInProgress_;
  
   BOOL viewDidAppearOnce_;
   BOOL navbarWasTranslucent_;
   NSTimer *chromeHideTimer_;
   
   UIBarButtonItem *collectBtn;
   UIBarButtonItem *shareBtn;
   UIBarButtonItem *deleteBtn;
   UIBarButtonItem *woXiHuanBtn;
   BOOL     bDeletepPhoneContent;//收藏页面删除是删除手机端文件
   PCRestClient *restClient;
   UIView         *mFavoriteBG;
   UITableView *mTable;//弹出框(我喜欢）
   PCRestClient *pcClient;
}

@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;
@property (nonatomic, assign, getter=isStatusbarHidden) BOOL statusbarHidden;
@property (retain, nonatomic) PCShareUrl *shareUrl;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *dicatorView;
@property (nonatomic, assign) BOOL bDeletepPhoneContent;
@property (nonatomic, assign) BOOL bShowToolBar;
@property (nonatomic, retain) KTURLRequest *currentRequest;
@property (nonatomic, retain) FileCache *m_fileCache;//下载原图用（收藏到系统相册）
@property (nonatomic, retain)  NSString *mGroupType;
@property (nonatomic, retain)  NSString  *currentFavoriteFileName;
@property(nonatomic,retain)   NSMutableArray *mFavoriteList;//我喜欢 文件夹 列表
@property (nonatomic, retain)  NSString  *groupName;

- (id)initWithDataSource:(id <KTPhotoBrowserDataSource>)dataSource andStartWithPhotoAtIndex:(NSUInteger)index;
- (void)toggleChromeDisplay;
- (void)showPicScrollView:(BOOL)bShow;
@end
