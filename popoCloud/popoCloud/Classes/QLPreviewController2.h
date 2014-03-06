//
//  QLPreviewController2.h
//  popoCloud
//
//  Created by Kortide on 13-4-22.
//
//

#import <QuickLook/QuickLook.h>
#import "FileCache.h"
#import "PCShareUrl.h"
#import "PCOpenFile.h"
#import "PCProgressingViewController.h"
#import "FileCacheController.h"
#import "PCFileInfo.h"
#import "PCRestClient.h"
#import "KTURLRequest.h"
@interface QLPreviewController2 : QLPreviewController <QLPreviewControllerDataSource,QLPreviewControllerDelegate,PCRestClientDelegate>
{
    UIToolbar *toolbar_;
    UIStatusBarStyle statusBarStyle_;
    
    BOOL statusbarHidden_; // Determines if statusbar is hidden at initial load. In other words, statusbar remains hidden when toggling chrome.
    BOOL isChromeHidden_;
    BOOL rotationInProgress_;
    
    BOOL viewDidAppearOnce_;
    BOOL navbarWasTranslucent_;
    
    NSTimer *chromeHideTimer_;
    
    UIBarButtonItem *nextButton_;
    UIBarButtonItem *previousButton_;
    UIBarButtonItem *btnDelete;
    PCFileInfo     *currentFileInfo;
    NSString            *backBtnTitle;
    BOOL needDeleteBoxFile;
    PCRestClient *restClient;
    BOOL clickDelete;
}
@property(nonatomic,readwrite) BOOL bShowCollectBtn;
@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;
@property (nonatomic, assign, getter=isStatusbarHidden) BOOL statusbarHidden;
@property (retain, nonatomic)    PCShareUrl *shareUrl;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *dicatorView;
@property (retain, nonatomic)  PCFileInfo     *currentFileInfo;
@property (retain, nonatomic)  NSString            *backBtnTitle;
//声音或视频文件，有播放栏，不显示我们的bar，免得遮住系统的功能。
@property (readwrite, nonatomic) BOOL bHideToolbarForMusicFile;
@property (retain, nonatomic) KTURLRequest *currentRequest;
@property (copy, nonatomic) NSString *localPath;
@end
