//
//  FileCacheController.m
//  popoCloud
//
//  Created by leijun on 13-3-4.
//
//
#import "UIImage+Compress.h"
#import "FileCacheController.h"
#import "FileListViewController.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "KTPhotoView+SDWebImage.h"
#import "KTPhotoScrollViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

const CGFloat ktkDefaultPortraitToolbarHeight3   = 44;
const CGFloat ktkDefaultLandscapeToolbarHeight3  = 33;
const CGFloat ktkDefaultToolbarHeight3 = 44;

#define COLLECT_ALERT_TAG   4
#define   DELETE_FOLDER_TAG            55
@implementation FileCacheController
@synthesize m_fileType;
@synthesize m_filePath;
@synthesize bOriginalImage;

#pragma mark - methods from super class
- (id)initWithPath:(NSString*)filePath andFinishLoadingState:(BOOL)finished andDataSource: (NSArray*)dataArray  andCurrentPCFileInfo:(PCFileInfo*)currentFileInfo andLastViewControllerName:(NSString *)title
{
    if (self = [super init]) {
        //避免null值 无  pathextention方法导致 crash
        if (![filePath isKindOfClass:[NSString class]]) {
            filePath =   @"";
        }
        self.backBtnTitle = title;
        self.m_filePath = filePath;
        self.images_ = [NSMutableArray array];
        self.currentFileInfo = currentFileInfo;
        self.bOriginalImage = NO;
        [dataArray retain];
        int index = 0;
        // for (PCFileInfo *fileInfo in dataArray)
        for (id  fileData in dataArray)
        {
            // 过滤掉特殊信息，文件列表可能传入 NSString 对象（新建文件夹）
            if ([fileData isKindOfClass:[PCFileInfo class]]) {
                PCFileInfo *fileInfo = (PCFileInfo*)fileData;
                NSString *tmpPath = fileInfo.path;
                if ([tmpPath isKindOfClass:[NSString class]] && (fileInfo.mFileType == PC_FILE_IMAGE) ) {
                    //NSLog(@"文件名比对  %@,   %@",tmpPath ,m_filePath);
                    [self.images_  addObject:fileInfo];
                    if ([tmpPath    isEqualToString:currentFileInfo.path]){
                        self.startWithIndex_= index;
                    }
                    index++;
                }
            }
        }
        
        [dataArray release];
        
        self.hidesBottomBarWhenPushed = YES;
        
        if (currentFileInfo.mFileType == PC_FILE_IMAGE) {
            m_fileType =  KT_FILE_IMAGE;
        }
        else if ( (currentFileInfo.mFileType == PC_FILE_VEDIO) ||
                 (currentFileInfo.mFileType == PC_FILE_AUDIO))
        {
            m_fileType =  KT_FILE_MEDIA;
        }
        else
        {
            m_fileType =  KT_FILE_OTHER;
        }
        self.bHasDownloaded = finished;
    }
    return self;
}

- (BOOL)isImageWithPath:(NSString*)path
{
    //避免null值 无  pathextention方法导致 crash
    if (![path isKindOfClass:[NSString class]]) {
        path =   @"";
    }
    
    if ([[path pathExtension] isEqualToString:@"file_pic.png"]) {
        return YES;
    }
    return NO;
}

- (void)PushPhotoViewController
{
    KTPhotoScrollViewController *newController = [[KTPhotoScrollViewController alloc]
                                                  initWithDataSource:self
                                                  andStartWithPhotoAtIndex:self.startWithIndex_];
    
    //             [[self navigationController] pushViewController:newController animated:YES];
    NSMutableArray *array =  [NSMutableArray arrayWithArray: [self.navigationController viewControllers]];
    int count = [array count];
    [array replaceObjectAtIndex:count-1 withObject:newController];
    [self.navigationController setViewControllers:array];
    [newController release];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(self.bHasDownloaded)
    {
        self.btnCollect.enabled = YES;
        self.btnShare.enabled = YES;
        self.BtnTitle.enabled = YES;
        self.BtnTitleCover.enabled = YES;
        self.btnDelete.enabled = YES;
        
        if (self.m_filePath)
        {
            [self openFiles];
        }
    }
    
    self.bViewDidAppear = YES;
}

- (void)createToolBar
{
    self.btnCollect = [[[UIBarButtonItem alloc]
                        initWithTitle:nil
                        style:UIBarButtonItemStyleBordered
                        target:self
                        action:@selector(clickCollect:)] autorelease];
    
    self.btnShare = [[[UIBarButtonItem alloc]
                      initWithTitle:NSLocalizedString(@"Share", nil)
                      style:UIBarButtonItemStyleBordered
                      target:self
                      action:@selector(clickShare:)] autorelease];
    
    self.btnDelete = [[[UIBarButtonItem alloc]
                       initWithTitle:NSLocalizedString(@"Delete", nil)
                       style:UIBarButtonItemStyleBordered
                       target:self
                       action:@selector(clickDelete:)] autorelease];
    
    self.btnDelete.enabled = NO;
    self.btnCollect.enabled = NO;
    self.btnShare.enabled = NO;
    
    UIBarItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                     target:nil
                                                                     action:nil];
    
    NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithCapacity:7];
    
    [toolbarItems addObject:space];
    [toolbarItems addObject:self.btnShare];
    [toolbarItems addObject:space];
    [toolbarItems addObject:self.btnCollect];
    [toolbarItems addObject:space];
    [toolbarItems addObject:self.btnDelete];
    [toolbarItems addObject:space];
    
    
    CGRect ViewFrame = [self.view bounds];
    CGRect toolbarFrame = CGRectMake(0,
                                     ViewFrame.size.height - ktkDefaultToolbarHeight3,
                                     ViewFrame.size.width,
                                     ktkDefaultToolbarHeight3);
    self.toolbar_ = [[[UIToolbar alloc] initWithFrame:toolbarFrame] autorelease];
    [self.toolbar_ setAutoresizingMask:UIViewAutoresizingFlexibleWidth
     // |UIViewAutoresizingFlexibleHeight
     | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin];
    [self.toolbar_ setBarStyle:UIBarStyleBlack];
    //self.toolbar_.translucent = YES;
    [self.toolbar_ setItems:toolbarItems];
    [self.view addSubview:self.toolbar_];
    
    [toolbarItems release];
    [space release];
}

#pragma mark -
#pragma mark Rotation Magic

- (void)updateToolbarWithOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    CGRect toolbarFrame = self.toolbar_.frame;
    if ((interfaceOrientation) == UIInterfaceOrientationPortrait || (interfaceOrientation) == UIInterfaceOrientationPortraitUpsideDown) {
        toolbarFrame.size.height = ktkDefaultPortraitToolbarHeight3;
    } else {
        toolbarFrame.size.height = ktkDefaultLandscapeToolbarHeight3+1;
    }
    
    toolbarFrame.size.width = self.view.frame.size.width;
    toolbarFrame.origin.y =  self.view.frame.size.height - toolbarFrame.size.height;
    self.toolbar_.frame = toolbarFrame;
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
    [self layoutSubviews];
    // Rotate the toolbar.
    [self updateToolbarWithOrientation:toInterfaceOrientation];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    [self  createToolBar];
    NSString *tmpImgName = [PCUtilityFileOperate getImgByExt:self.title.pathExtension];
    NSMutableString *imgName = [NSMutableString stringWithString:tmpImgName];
    NSUInteger index = [tmpImgName rangeOfString:@"." options:NSBackwardsSearch].location;
    [imgName insertString:@"_big" atIndex:index];
    
    UIImage *img = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:imgName
                                                                                    ofType:nil]];
    //    DLogNotice(@"img.size=%@,scale=%f",NSStringFromCGSize(img.size),img.scale);
    
    self.imgView.image = img;
    
    self.btnShare.title = NSLocalizedString(@"Share", nil);
    self.btnCollect.title = NSLocalizedString(@"Collect", nil);
    self.BtnTitle.enabled = NO;
    self.BtnTitleCover.enabled = NO;
    CGRect rect = self.progressView.frame;
    rect.size.height = 9;
    self.progressView.frame = rect;
    self.progressView.hidden = self.bHasDownloaded;
    
    NSString *title = self.bHasDownloaded && m_fileType == KT_FILE_MEDIA ?
    NSLocalizedString(@"ClickToOpen", nil) : self.title;
    [self.BtnTitle setTitle:title forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    [self setImgView:nil];
    self.dicatorView = nil;
    [self setBtnTitle:nil];
    self.BtnTitleCover = nil;
    [self setProgressView:nil];
    [self setBtnShare:nil];
    [self setBtnCollect:nil];
    [self setBtnDelete:nil];
    [self setLabelProgress:nil];
    [super viewDidUnload];
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
    [self removeNotifications];
    self.backBtnTitle = nil;
    self.BtnTitleCover = nil;
    self.shareUrl = nil;
    self.dicatorView = nil;
    self.toolbar_ = nil;
    self.imgView = nil;
    self.BtnTitle = nil;
    self.progressView = nil;
    self.labelProgress = nil;
    self.btnShare = nil;
    self.btnCollect = nil;
    self.btnDelete = nil;
    self.m_filePath = nil;
    self.images_ = nil;
    self.currentFileInfo = nil;
    
    [super dealloc];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.shareUrl)
        [self.shareUrl cancelConnection];
    
    NSArray *controllers = ((UINavigationController *)self.parentViewController).viewControllers;
    UIViewController *listController = (controllers.lastObject==self)?(controllers[controllers.count - 2]):controllers.lastObject;
    
    if ([listController respondsToSelector:@selector(cancelProcess)]) {
        [listController performSelector:@selector(cancelProcess)];
    }
    
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"FileCacheView"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self setCollectBtnStatus];
    [self layoutSubviews];
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"FileCacheView"];
}


#pragma mark - private methods

- (void)layoutSubviews
{
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
        self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        if (IS_IPAD)
        {
            NSInteger centerY = self.view.center.y;
            [self setImgCoord:centerY - 120 titleCoord:centerY progressCoord:centerY + 60];
        }
        else
        {
            [self setImgCoord:90 titleCoord:190 progressCoord:210];
        }
    }
    else
    {
        if (IS_IPAD)
        {
            [self setImgCoord:360 titleCoord:480 progressCoord:540];
        }
        else
        {
            [self setImgCoord:140 titleCoord:250 progressCoord:286];
        }
    }
}

- (void)setImgCoord:(NSInteger)imgY titleCoord:(NSInteger)titleY progressCoord:(NSInteger)progY
{
    NSInteger centerX = self.view.center.x;
    
    self.imgView.center = CGPointMake(centerX, imgY);
    self.BtnTitleCover.center = self.imgView.center;
    self.BtnTitle.center = CGPointMake(centerX, titleY);
    self.progressView.center = CGPointMake(centerX, progY);
    self.labelProgress.center = self.progressView.center;
}

- (void)removeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RefreshProgress" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RefreshTableView" object:nil];
}

- (void)setCollectBtnStatus
{
    NSString *hostPath = self.currentFileInfo.path;
    NSString *modifyTime = self.currentFileInfo.modifyTime;
    BOOL isNoCollect = [[PCUtilityFileOperate downloadManager] getFileStatus:hostPath
                                                               andModifyTime:modifyTime] == kStatusNoDownload;
    [self setCollectBtnTitle:isNoCollect];
}

- (void)setCollectBtnTitle:(BOOL)isNoCollect
{
    self.btnCollect.title = NSLocalizedString(@"Collect", nil);
    self.btnCollect.tag = isNoCollect;
}

#pragma mark- PCFileCacheDelegate methods

- (void)cacheFileFinish:(FileCache *)fileCache
{
    self.btnCollect.enabled = YES;
    self.btnShare.enabled = YES;
    self.BtnTitle.enabled = YES;
    self.btnDelete.enabled = YES;
    self.BtnTitleCover.enabled = YES;
    NSArray *controllers = ((UINavigationController *)self.parentViewController).viewControllers;
    UIViewController *listController = controllers[controllers.count - 2];
    
    if ([listController respondsToSelector:@selector(endProcess)]) {
        [listController performSelector:@selector(endProcess)];
    }
    
    self.bHasDownloaded = YES;
    self.progressView.hidden = YES;
    [self.BtnTitle setTitle:NSLocalizedString(@"ClickToOpen", nil) forState:UIControlStateNormal];
    NSString *filePath =nil;
    filePath = fileCache.localPath;
    if (filePath)
        self.m_filePath = filePath;
    
    if (self.bViewDidAppear)
    {
        [self openFiles];
    }
    
    [fileCache release];
    fileCache=nil;
}

- (void)cacheFileFail:(FileCache *)fileCache hostPath:(NSString *)hostPath error:(NSString *)error
{
    NSArray *controllers = ((UINavigationController *)self.parentViewController).viewControllers;
    UIViewController *listController = controllers[controllers.count - 2];
    
    if ([listController respondsToSelector:@selector(endProcess)]) {
        [listController performSelector:@selector(endProcess)];
    }
    
    if (fileCache.localPath) {
        [PCUtilityFileOperate deleteFile:fileCache.localPath];
        [FileCache deleteDownloadFile:fileCache.localPath];
    }
    [PCUtilityUiOperate showErrorAlert:error delegate:self];
    [fileCache release];
    fileCache=nil;
}

- (void)cacheFileProgress:(float)progress hostPath:(NSString *)hostPath
{
    self.progressView.progress = progress;
    self.labelProgress.text = [NSString stringWithFormat:@"%.1f%%",  progress * 100];
}

#pragma mark - PCShareUrlDelegate methods

- (void) shareUrlFail:(NSString*)errorDescription {
    [self.dicatorView stopAnimating];
    [PCUtilityUiOperate showErrorAlert:errorDescription delegate:self];
    self.shareUrl = nil;
}

- (void) shareUrlStart {
    [self.dicatorView startAnimating];
}

- (void) shareUrlFinish {
    [self.dicatorView stopAnimating];
}

- (void)shareUrlComplete
{
    self.shareUrl = nil;
}
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
#pragma mark - callback methods

- (IBAction)clickShare:(id)sender
{
    self.shareUrl = [[[PCShareUrl alloc] init] autorelease];
    [self.shareUrl shareFileWithInfo:self.currentFileInfo andDelegate:self];
    
}
-(void)clickDelete:(id)sender
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
    else if([fileCache GetFuLLSizeFileFromCacheWithFileInfo:self.currentFileInfo withType:TYPE_CACHE_FILE] &&(self.currentFileInfo.mFileType != PC_FILE_IMAGE)
            &&  [PCUtilityFileOperate moveCacheFileToDownload:hostPath
                                                     fileSize:size
                                                    fileCache:fileCache
                                                     fileType:TYPE_CACHE_FILE])
    {
        self.m_filePath = [fileCache getCacheFilePath:hostPath withType:TYPE_DOWNLOAD_FILE];
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
- (void)clickCollect:(id)sender
{
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
        Alert.tag = COLLECT_ALERT_TAG;
        [Alert show];
        [Alert release];
    }
}

- (void)clickOpen:(id)sender
{
    if (self.m_fileType != KT_FILE_MEDIA ) {
        return;
    }
    if (self.m_filePath)
    {
        [self openFileWithFileInfo:self.currentFileInfo];
    }
    else
    {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"FileCannotOpen", nil) delegate:nil];
    }
}

- (void)openFileWithFileInfo:(PCFileInfo*)fileInfo{
    //add by libing 2013-6-26 fix bug bug54838  bug 55854
    //    BOOL result = [QLPreviewController2 canPreviewItem:(id<QLPreviewItem>)fileURL];
    BOOL result = [PCUtilityFileOperate itemCanOpenWithPath:self.m_filePath];
    
    if (!result) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"NoSuitableProgram", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        [alert release];
        //        [self release];
    }
    else{
        //避免null值 无  pathextention方法导致 crash
        id curPath = fileInfo.path;
        if (![curPath isKindOfClass:[NSString class]]) {
            curPath =   @"";
        }
        
        QLPreviewController2 *previewController = [[QLPreviewController2 alloc] init];
        previewController.currentFileInfo = fileInfo;
        
        //////
        if ([[PCUtilityFileOperate getImgByExt:[curPath pathExtension]] isEqualToString:@"file_video.png"]
            )
        {
            NSURL *url = [NSURL  fileURLWithPath:self.m_filePath];
            
            MPMoviePlayerViewController *playerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
            [self presentMoviePlayerViewControllerAnimated:playerViewController];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
            
            MPMoviePlayerController *player = [playerViewController moviePlayer];
            [player play];
            [playerViewController release];
            [previewController release];
            return;
        }
        else if ([[PCUtilityFileOperate getImgByExt:[curPath pathExtension]] isEqualToString:@"file_music.png"])
        {
            NSURL *url = [NSURL  fileURLWithPath:self.m_filePath];
            
            MPMoviePlayerViewController *playerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
            [self presentMoviePlayerViewControllerAnimated:playerViewController];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
            
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [[AVAudioSession sharedInstance] setActive: YES error:nil];
            
            MPMoviePlayerController *player = [playerViewController moviePlayer];
            [player play];
            [playerViewController release];
            [previewController release];
            return;
        }
        
        previewController.localPath = self.m_filePath;
        previewController.dataSource = previewController;
        previewController.delegate = previewController;
        //previewController.backBtnTitle = self.backBtnTitle;
        // start previewing the document at the current section index
        previewController.currentPreviewItemIndex = 0;
        previewController.hidesBottomBarWhenPushed = YES;
        //[self.navigationController pushViewController:previewController animated:YES];
        
        
        
        NSMutableArray *array =  [NSMutableArray arrayWithArray: [self.navigationController viewControllers]];
        int count = [array count];
        [array replaceObjectAtIndex:count-1 withObject:previewController];
        UINavigationController *navControl =  self.navigationController;
        [navControl setViewControllers:array];
        
        
        [previewController release];
    }
}

- (void)downloadProgress:(NSNotification *)note
{
    float progress = [note.userInfo[@"progress"] floatValue];
    [self cacheFileProgress:progress hostPath:nil];
}

- (void)downloadFinish:(NSNotification *)note
{
    BOOL success = [note.userInfo[@"success"] boolValue];
    if (success)
    {
        [self cacheFileFinish:nil];
    }
    else
    {
        NSString *error = note.userInfo[@"error"];
        [self cacheFileFail:nil hostPath:nil error:error];
    }
    
    [self removeNotifications];
}

#pragma mark -
#pragma mark KTPhotoBrowserDataSource

- (NSInteger)numberOfPhotos {
    NSInteger count = [self.images_ count];
    return count;
}

- (void)deleteImageAtIndex:(NSInteger)index
{
    [self.images_ removeObjectAtIndex:index];
}

- (void)imageAtIndex:(NSInteger)index photoView:(KTPhotoView *)photoView {
    PCFileInfo *fileInfo = [self.images_ objectAtIndex:index];
    
    FileCache *fileCache = [[FileCache alloc] init];
    fileCache.currentDeviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
    [fileCache setProgressView:nil progressScale:1.0];
    NSString *filePath = nil;
    
    //图片的modify  time 问题 导致 图片可能下多次，弱化modify time为条件之一,通过比对大小一致也通过。
    int  type = bOriginalImage?TYPE_DOWNLOAD_FILE:TYPE_CACHE_SLIDEIMAGE;
    if ([fileCache readFileFromCacheWithFileInfo:fileInfo  withType:type])
    {
        filePath =  [fileCache getCacheFilePath:fileInfo.path
                                       withType:type];
    }
    [fileCache release];
    if (filePath)
    {
        UIImage * original = [UIImage imageWithContentsOfFile:filePath];
        if(original)
        {
            if ( [fileInfo.size longLongValue] >= K_MAX_IMAGE_SIZE)
            {
                [photoView setImage:[UIImage imageNamed:@"load_fail_img.png"]];
                photoView.labelProgress.hidden = NO;
                photoView.labelProgress.text = NSLocalizedString(@"CachePictureFail", nil);
                return;
            }
            if (original.size.width>MAX_IMAGEPIX_X || original.size.height>MAX_IMAGEPIX_Y)
            {
                if ((original.size.width)*(original.size.height) >= K_MAX_IMAGE_POINTS)
                {
                    [photoView setImage:[UIImage imageNamed:@"load_fail_img.png"]];
                    photoView.labelProgress.hidden = NO;
                    photoView.labelProgress.text = NSLocalizedString(@"CachePictureFail", nil);;
                    return;
                }
                //[photoView changeContentMode:UIViewContentModeScaleAspectFit];
                //
                NSMutableDictionary *dic =  [NSMutableDictionary dictionaryWithDictionary:[PCUtility compressingImgDic]];
                //已经在对图片做处理了
                //                NSLog(@"最近的 压缩完的窗口信息是:%@   对应的路径:%@ , 字典： %@",photoView,filePath,dic);
                if ([dic objectForKey:filePath]) {
                    [dic setObject:photoView forKey:filePath];
                    if (!photoView.imageView_.image)
                    {
                        [photoView.indicator startAnimating];
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^        {
                            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                            UIImage * original = [UIImage imageWithContentsOfFile:filePath];
                            if(original)
                            {
                                UIImage *compressedImgae = [original   compressedImage];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [photoView.indicator stopAnimating];
                                    photoView.labelProgress.hidden = YES;
                                    [photoView setImage:compressedImgae];
                                    [[PCUtility compressingImgDic] removeObjectForKey:filePath];
                                    [PCUtility setCompressImgDic:dic];
                                });
                            }
                            [pool release];
                        });
                        
                    }
                    return;
                }
                else
                {
                    [dic setObject:photoView forKey:filePath];
                    [PCUtility setCompressImgDic:dic];
                }
                [photoView.indicator startAnimating];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^        {
                    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                    UIImage * original = [UIImage imageWithContentsOfFile:filePath];
                    if(original)
                    {
                        UIImage *compressedImgae = [original   compressedImage];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //[photoView setImage:compressedImgae];
                            //                            NSLog(@"当前的 压缩完的图片信息是:%@   对应的路径:%@",dic,filePath);
                            //                            KTPhotoView *photo = (KTPhotoView*)[[PCUtility compressingImgDic] objectForKey:filePath];
                            photoView.labelProgress.hidden = YES;
                            [photoView.indicator stopAnimating];
                            [photoView setImage:compressedImgae];
                            [[PCUtility compressingImgDic] removeObjectForKey:filePath];
                            //[PCUtility setCompressImgDic:dic];
                        });
                    }
                    [pool release];
                });
                //
            }
            else
            {
                [photoView setImage:original];
            }
        }
    }
    else  if ([photoView StartLoadFileWithPCFileInfo:fileInfo  andImageType:type])
    {
        //[photoView setImage:[UIImage imageNamed:@"picture.png"]];
        [photoView setImage:nil];
        photoView.labelProgress.hidden = NO;
        photoView.labelProgress.text = @"下载中：0%";
        [photoView.indicator startAnimating];
    }
    else
    {
        [photoView setImage:[UIImage imageNamed:@"load_fail_img.png"]];
        self.labelProgress.hidden = NO;
        if ([fileInfo.size  longLongValue]>= K_MAX_IMAGE_SIZE)
        {
            self.labelProgress.text = NSLocalizedString(@"CachePictureFail", nil);
        }
        else{
            photoView.labelProgress.text = NSLocalizedString(@"CachePictureFail", nil);
        }
    }
}

- (PCFileInfo*)getFileInfoNodeAtIndex:(NSInteger)index
{
    return [self.images_  objectAtIndex:index];
}

- (void) playerPlaybackDidFinish:(NSNotification*) aNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:nil];
    
    NSNumber *reason = [aNotification.userInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    if ([reason intValue] == MPMovieFinishReasonPlaybackError)
    {
        //NSError *error = [aNotification.userInfo objectForKey:@"error"];
        //NSString *errorInfo = error ? error.localizedDescription : NSLocalizedString(@"NoSuitableProgram", nil);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                        message:@"播放失败"//errorInfo
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        alert.tag = NoSuitableProgramAlertTag;
        [alert show];
        [alert release];
    }
    else
    {
        [self dismissMoviePlayerViewControllerAnimated];
    }
}

- (void) openFiles
{
    if (m_fileType == KT_FILE_IMAGE)
    {
        [self PushPhotoViewController];
    }
    else if(m_fileType == KT_FILE_MEDIA)
    {
        
    }
    else if(m_fileType == KT_FILE_OTHER)
    {
        [self openFileWithFileInfo:self.currentFileInfo];
    }
    
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == DELETE_FOLDER_TAG)
    {
        if (buttonIndex == 1)
        {
            [self lockUI];
            if (!restClient) {
                restClient = [[PCRestClient alloc] init];
                restClient.delegate = self;
            }
            self.currentRequest = [restClient deletePath:self.currentFileInfo.path];
        }
        return;
    }
    if (alertView.tag == COLLECT_ALERT_TAG) {
        if (buttonIndex == [alertView firstOtherButtonIndex])
        {
            [self doDownloadFile];
            //            NSString *hostPath = self.currentFileInfo.path;
            //            FileDownloadManager *downloadMgr = [PCUtilityFileOperate downloadManager];
            //            [self setCollectBtnTitle:YES];
            //            //如果本来就是缓存文件，则只删除收藏那端的记录；modified by ray,bug ID:54647
            //            //        if ([self.m_filePath hasPrefix:NSTemporaryDirectory()]
            //            if ([self.m_filePath hasPrefix:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"]]
            //                || (self.currentFileInfo.mFileType == PC_FILE_IMAGE))
            //            {
            //                DownloadStatus status = [downloadMgr getFileStatus:hostPath
            //                                                     andModifyTime:self.currentFileInfo.modifyTime];
            //                [downloadMgr deleteDownloadItem:hostPath fileStatus:status];
            //            }
            //            else//若是收藏文件，则要把收藏文件移到缓存目录去，并更新数据库记录,图片例外
            //            {
            //                self.m_filePath = [PCUtilityFileOperate moveDownloadFileToCache:hostPath downPath:self.m_filePath];
            //            }
        }
    }
    else if(alertView.tag == NoSuitableProgramAlertTag)
    {
        [self dismissMoviePlayerViewControllerAnimated];
    }
}
#pragma mark - PCRestClientDelegate
- (void)restClient:(PCRestClient*)client deletedPath:(NSDictionary *)resultInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshFileList" object:self.currentFileInfo];
    [self unlockUI];
    self.currentRequest = nil;
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
