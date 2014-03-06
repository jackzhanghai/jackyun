//
//  QLPreviewController2.m
//  popoCloud
//
//  Created by Kortide on 13-4-22.
//
//

#import "QLPreviewController2.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "ModalAlert.h"
#import "PCAppDelegate.h"
#import "FileCacheController.h"
#import <QuartzCore/QuartzCore.h>
#import "FileListViewController.h"
#define COLLECT_TAG   7
#define   DELETE_FOLDER_TAG            55
#define     DELETE_LOCAL_FILE          56
const CGFloat ktkDefaultPortraitToolbarHeight2   = 44;
const CGFloat ktkDefaultLandscapeToolbarHeight2  = 33;
const CGFloat ktkDefaultToolbarHeight2 = 44;

@implementation QLPreviewController2
@synthesize statusBarStyle = statusBarStyle_;
@synthesize statusbarHidden = statusbarHidden_;
@synthesize currentFileInfo;
@synthesize backBtnTitle;
@synthesize localPath;

#pragma mark -
#pragma mark Frame calculations
#define PADDING  20

- (CGRect)frameForPagingScrollView
{
    CGRect frame = [[UIScreen mainScreen] bounds];
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return frame;
}

- (void)dealloc
{
    if (restClient) {
        if (self.currentRequest) {
            [restClient cancelRequest:self.currentRequest];
        }
        self.currentRequest = nil;
        [restClient release];
        restClient = nil;
    }
    if (clickDelete)
    {
        NSString *path = [[[NSString alloc] initWithString:self.currentFileInfo.path] autorelease];
        [[NSNotificationCenter defaultCenter] postNotificationName:DeleteLocalFile object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path,@"path", nil]];
    }
    self.localPath = nil;
    self.currentFileInfo = nil;
    [nextButton_ release], nextButton_ = nil;
    self.backBtnTitle = nil;
    [previousButton_ release], previousButton_ = nil;
    [btnDelete release];
    btnDelete = nil;
    [toolbar_ removeFromSuperview];
    [toolbar_ release], toolbar_ = nil;
    self.shareUrl = nil;
    self.dicatorView = nil;

    [super dealloc];
}

//- (id)init
//{
//    if (self = [super init]) {
//        //[self setWantsFullScreenLayout:YES];
//        //self.hidesBottomBarWhenPushed = YES;
//    }
//    return self;
//}

- (void)loadView
{
    [super loadView];
    
    // CGRect scrollFrame = [self frameForPagingScrollView];
    nextButton_ = [[UIBarButtonItem alloc]
                   initWithTitle:@"收藏"
                   style:UIBarButtonItemStyleBordered
                   target:self
                   action:@selector(collectButtonClick:)];
    
    previousButton_ = [[UIBarButtonItem alloc]
                       initWithTitle:@"分享"
                       style:UIBarButtonItemStyleBordered
                       target:self
                       action:@selector(sharePhoto)];
    
    btnDelete = [[UIBarButtonItem alloc]
                  initWithTitle:NSLocalizedString(@"Delete", nil)
                  style:UIBarButtonItemStyleBordered
                  target:self
                  action:@selector(clickDelete)];
    
    
    UIBarItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                     target:nil
                                                                     action:nil];
    
    NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithCapacity:7];
    
    [toolbarItems addObject:space];
    [toolbarItems addObject:previousButton_];
    [toolbarItems addObject:space];
    [toolbarItems addObject:nextButton_];
    [toolbarItems addObject:space];
    [toolbarItems addObject:btnDelete];
    [toolbarItems addObject:space];
    
    CGRect screenFrame = [self.view bounds];
    CGRect toolbarFrame = CGRectMake(0,
                                     screenFrame.size.height - ktkDefaultToolbarHeight2,
                                     screenFrame.size.width,
                                     ktkDefaultToolbarHeight2);
    toolbar_ = [[UIToolbar alloc] initWithFrame:toolbarFrame];//| UIViewAutoresizingFlexibleTopMargin |UIViewAutoresizingFlexibleHeight
    [toolbar_ setAutoresizingMask:UIViewAutoresizingFlexibleWidth |  UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin];
    [toolbar_ setBarStyle:UIBarStyleBlack];
    toolbar_.translucent = YES;
    if (((PCAppDelegate *)[UIApplication sharedApplication].delegate).bNetOffline) {
        [toolbar_ setItems:[NSArray arrayWithObjects:space,btnDelete,space, nil]];
    }
    else
        [toolbar_ setItems:toolbarItems];
    [[self view] addSubview:toolbar_];
    
    
    [toolbarItems release];
    [space release];
}

//- (void)setTitleWithCurrentPhotoIndex
//{
//    NSString *title = @"文档";
//    [self setTitle:title];
//}
-(void)needDeleteBoxFile
{
    needDeleteBoxFile = NO;
    for (UIViewController *view in self.navigationController.viewControllers)
    {
        if ([view isKindOfClass:[FileListViewController class]])
        {
            needDeleteBoxFile = YES;
            break;
        }
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dicatorView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
    self.dicatorView.color = [UIColor grayColor];
    [self.view addSubview:self.dicatorView];
    self.dicatorView.center = self.view.center;
    self.dicatorView.autoresizingMask =    UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin|
    UIViewAutoresizingFlexibleBottomMargin;
    [self needDeleteBoxFile];
    clickDelete = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"QLPreview"];
    [self setCollectBtnStatus];
    [self.view bringSubviewToFront:toolbar_];
    if (self.bHideToolbarForMusicFile)
    {
        toolbar_.hidden = YES;
    }
    else
    {
        toolbar_.hidden = NO;
    }
    
     self.navigationController.toolbarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Reset nav bar translucency and status bar style to whatever it was before.
    if (self.shareUrl)
        [self.shareUrl cancelConnection];
    
    self.navigationController.navigationBar.translucent = NO;
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"QLPreview"];
}
-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.view bringSubviewToFront:toolbar_];
}
- (void)viewDidDisappear:(BOOL)animated
{
    //[self cancelChromeDisplayTimer];
    [super viewDidDisappear:animated];
}


- (void)toggleNavButtons
{
    //   [previousButton_ setEnabled:(currentIndex_ > 0)];
    //   [nextButton_ setEnabled:(currentIndex_ < photoCount_ - 1)];
}



#pragma mark -
#pragma mark Rotation Magic

- (void)updateToolbarWithOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    CGRect toolbarFrame = toolbar_.frame;
    if ((interfaceOrientation) == UIInterfaceOrientationPortrait || (interfaceOrientation) == UIInterfaceOrientationPortraitUpsideDown) {
        toolbarFrame.size.height = ktkDefaultPortraitToolbarHeight2;
    } else {
        toolbarFrame.size.height = ktkDefaultLandscapeToolbarHeight2+1;
    }
    
    toolbarFrame.size.width = self.view.frame.size.width;
    toolbarFrame.origin.y =  self.view.frame.size.height - toolbarFrame.size.height;
    toolbar_.frame = toolbarFrame;
}


- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return  IS_IPAD ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (IS_IPAD || (interfaceOrientation == UIInterfaceOrientationPortrait));
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    // Rotate the toolbar.
    [self updateToolbarWithOrientation:toInterfaceOrientation];
    
    // Adjust navigation bar if needed.
    if (isChromeHidden_ && statusbarHidden_ == NO) {
        UINavigationBar *navbar = [[self navigationController] navigationBar];
        CGRect frame = [navbar frame];
        frame.origin.y = 20;
        [navbar setFrame:frame];
    }
}

//- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
//{
//    [self startChromeDisplayTimer];
//}

- (UIView *)rotatingFooterView
{
    return toolbar_;
}


#pragma mark -
#pragma mark - callback methods
- (void) shareUrlFail:(NSString*)errorDescription {
    [self.dicatorView stopAnimating];
    [PCUtilityUiOperate showErrorAlert:errorDescription delegate:self];
}

- (void) shareUrlStart {
    [self.dicatorView startAnimating];
}

- (void) shareUrlFinish {
    [self.dicatorView stopAnimating];
}

#pragma mark -
#pragma mark Toolbar Actions
-(void)lockUI
{
    [self.dicatorView startAnimating];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
}
-(void)unlockUI
{
    [self.dicatorView stopAnimating];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}
-(void)clickDelete //删除本地文件
{
    if (needDeleteBoxFile)
    {
        UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"确定删除云盘文件?\n(此操作会删除帐号下云盘中的相应文件)"
                                                              message:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                    otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        deleteAlert.tag = DELETE_FOLDER_TAG;
        [deleteAlert show];
        [deleteAlert release];
    }
    else
    {
        DLogNotice(@"删除本地文件");
        UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConfirmDel", nil)
                                                              message:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                    otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        deleteAlert.tag = DELETE_LOCAL_FILE;
        [deleteAlert show];
        [deleteAlert release];
    }
}
- (void)sharePhoto
{
    if (currentFileInfo)
    {
        self.shareUrl = [[[PCShareUrl alloc] init] autorelease];
        [self.shareUrl shareFileWithInfo:currentFileInfo andDelegate:self];
        
    }
}


-(void)doDownloadFile
{
    NSString *hostPath = self.currentFileInfo.path;
    FileDownloadManager *downloadMgr = [PCUtilityFileOperate downloadManager];
    FileCache * fileCache = [[FileCache alloc] init];
    fileCache.currentDeviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
    
    long long size = [self.currentFileInfo.size longLongValue];
    
    if (size == 0)
    {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"CollectEmptyFile", nil)
                                     title:NSLocalizedString(@"Prompt", nil)
                                  delegate:nil];
    }
    //若文件先缓存了，则收藏时判断是否在Caches文件夹里，在的话把该文件从Caches文件夹移到Download文件夹，并更新数据库
    else if([fileCache GetFuLLSizeFileFromCacheWithFileInfo:self.currentFileInfo withType:TYPE_CACHE_FILE] &&
            [PCUtilityFileOperate moveCacheFileToDownload:hostPath
                                                 fileSize:size
                                                fileCache:fileCache
                                                 fileType:TYPE_CACHE_FILE])
    {
        self.localPath = [fileCache getCacheFilePath:hostPath withType:TYPE_DOWNLOAD_FILE];
        [PCUtilityUiOperate showHasCollectTip:self.currentFileInfo.name];
        [self setCollectBtnTitle:NO];
    }
    else if ([downloadMgr addItem:hostPath
                         fileSize:size
                    modifyGTMTime:[self.currentFileInfo.modifyTime longLongValue]])
    {
        [self setCollectBtnTitle:NO];
    } 
    
    [fileCache release];

}
- (void)collectButtonClick:(id)sender
{
    if (![PCUtility isNetworkReachable:nil])
    {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"OpenNetwork", nil) delegate:nil];
        return;
    }
    UIBarButtonItem *btn = sender;
    if (btn.tag)//没有收藏过，点击的是收藏按钮
    {
        [self doDownloadFile];
    }
    else
    {
        UIAlertView *Alert = [[UIAlertView alloc] initWithTitle:@"该文件已经下载过了，需要重新下载吗?"
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        Alert.tag = COLLECT_TAG;
        [Alert show];
        [Alert release];
    }
}

#pragma mark -

- (void)setCollectBtnTitle:(BOOL)isNoCollect
{
    nextButton_.title = NSLocalizedString(@"Collect", nil);
    nextButton_.tag = isNoCollect;
}

- (void)setCollectBtnStatus
{
    if (currentFileInfo)
    {
        NSString *hostPath = currentFileInfo.path;
        NSString *modifyTime = currentFileInfo.modifyTime;
        BOOL isNoCollect = [[PCUtilityFileOperate downloadManager] getFileStatus:hostPath
                                                        andModifyTime:modifyTime] == kStatusNoDownload;
        [self setCollectBtnTitle:isNoCollect];
    }
}

#pragma mark -
#pragma mark QLPreviewControllerDataSource

// Returns the number of items that the preview controller should preview
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)previewController
{
    return 1;
}

// returns the item that the preview controller should preview
- (id)previewController:(QLPreviewController *)previewController previewItemAtIndex:(NSInteger)idx
{
    return [NSURL fileURLWithPath:self.localPath];
}

- (void)previewControllerWillDismiss:(QLPreviewController *)controller
{
    if (self.navigationController) {
        [self.navigationController setToolbarHidden:YES animated:NO];
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView firstOtherButtonIndex])
    {
        if (alertView.tag == DELETE_LOCAL_FILE)
        {
            clickDelete = YES;
            UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"成功删除本地文件"
                                                                  message:nil
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                        otherButtonTitles:nil];
            [deleteAlert show];
            [deleteAlert release];
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }
        if (alertView.tag == DELETE_FOLDER_TAG) {
            [self lockUI];
            if (!restClient)
            {
                restClient = [[PCRestClient alloc]  init];
                restClient.delegate = self;
            }
            self.currentRequest = [restClient deletePath:self.currentFileInfo.path];
            return;
        }
        if (alertView.tag == COLLECT_TAG) {
            [self doDownloadFile];
//            [self setCollectBtnTitle:YES];
//            NSString *hostPath = self.currentFileInfo.path;
//            self.localPath = [PCUtilityFileOperate moveDownloadFileToCache:hostPath downPath:self.localPath];
        }
    }
}
#pragma mark - PCRestClientDelegate
- (void)restClient:(PCRestClient*)client deletedPath:(NSDictionary *)resultInfo
{
    clickDelete = YES;
    [self unlockUI];
    self.currentRequest = nil;
    
    NSArray *controllers = self.navigationController.viewControllers;
    UIViewController *listController = controllers[controllers.count - 2];
    if ([listController respondsToSelector:@selector(refreshFileList:)]) {
        [listController performSelector:@selector(refreshFileList:) withObject:self.currentFileInfo];
    }
    
    [PCUtilityUiOperate showErrorAlert:@"文件删除成功" delegate:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)restClient:(PCRestClient*)client deletePathFailedWithError:(NSError*)error
{
    [self unlockUI];
    [ErrorHandler showErrorAlert:error];
    self.currentRequest = nil;
}
@end
