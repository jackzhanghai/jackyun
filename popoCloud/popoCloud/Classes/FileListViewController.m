
//
//  FilesViewController.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-10.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "FileListViewController.h"
#import "PCUtility.h"
#import "FileCache.h"
#import "FileUpload.h"
#import "FileSearch.h"
#import "PCShareUrl.h"
#import "PCOpenFile.h"
#import "PCLogin.h"
#import "ModalAlert.h"
#import "PCAppDelegate.h"
#import "FileFolderViewController.h"
#import "PCFileCell.h"
#import "PCFileExpansionCell.h"
#import "FileCacheController.h"
#import "SettingPhotosPermissionViewController.h"
#import "ELCAlbumPickerController.h"
#import "ActivateBoxViewController.h"
#import "FileUploadController.h"
#import "FileUploadManager.h"
#import "ZipArchive.h"
#import "PCFileInfo.h"
#import "FileUploadInfo.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "PCUtilityStringOperate.h"
#import "PCUtilityDataManagement.h"
#import "PCRestClient.h"
#import "NetPenetrate.h"
#import "ScreenLockViewController.h"
#import "customAVPlayerViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>

#define NOCONTERNVIEWTAG 1989
#define  STATUS_FILE_LIST 1
#define  STATUS_REGET_SHARE_LIST 2
#define LIMIT (IS_IPAD ? ([UIApplication sharedApplication].statusBarOrientation > UIDeviceOrientationPortraitUpsideDown ? @"40" : @"50") : (IS_IPHONE5 ? @"25" : @"20"))
#define   CREATE_FOLDER_STR               @"新建文件夹"

#define   NEW_FOLDER_TAG                1
#define   DELETE_FOLDER_TAG            2
#define   RENAME_FOLDER_TAG          3
#define   RENAME_FOLDER_TEXTFIELD_TAG          4
#define   TOOLVIEWTAG 2013
#define   CANCEL_COLLECT_TAG  9
#define   XIAZAITAG 10
#define   CACHE_FILE_TAG 11
#define   PROCESSVIEWTAG 33333
#define   EDITTAG 44444

@implementation FileListViewController
@synthesize tableView;
@synthesize searchBar;
@synthesize historyfilteredListContent;
@synthesize dirPath;
@synthesize keyWord;
@synthesize lblResult;
@synthesize dicatorView;
@synthesize lblProgress;
@synthesize popover;
@synthesize localPath;
@synthesize isOpen;
@synthesize selectIndexPath;
@synthesize filteredListContent, savedSearchTerm, searchWasActive;
@synthesize dirName;
@synthesize thumbImgFileCache;
@synthesize currentRequest;
@synthesize tempNewName;

#pragma mark - methods from super class
- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {
    
    self = [super initWithNibName:nibName bundle:nibBundle];
    
    if (self)
    {
        self.hidesBottomBarWhenPushed = YES;
        tableData = [[NSMutableArray alloc] initWithObjects:CREATE_FOLDER_STR, nil];
        isFinish = NO;
        isNetworkError = NO;
        isProcessing = NO;
        fileCache = nil;
        isSearchDisplay = NO;
        progressingViewController = nil;
        self.isOpen = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableView:) name:@"RefreshTableView" object:nil];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"FileListViewController dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.tempNewName = nil;
    self.searchBar = nil;
    self.lblResult = nil;
    self.lblProgress = nil;//unused
    self.popover = nil;
    
    [self.tableView removeObserver:self forKeyPath:@"contentSize" context:NULL];
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    self.keyWord = nil;
    self.historyfilteredListContent = nil;
    self.searchDisplayController.delegate = nil;
    self.searchDisplayController.searchResultsDelegate = nil;
    self.searchDisplayController.searchResultsDataSource = nil;
    [filteredListContent release];
    self.savedSearchTerm = nil;
    
    
    self.dirPath = nil;
    self.dirName = nil;
    [tableData release];
    [dicatorView release];
    self.localPath = nil;
    [currentFileInfo release];
    [self cancelProcess];
    if (_refreshHeaderView) {
        [_refreshHeaderView release];
        _refreshHeaderView=nil;
    }
    self.selectIndexPath = nil;
    
    if (shareUrl && shareUrl.actionSheet)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:shareUrl selector:@selector(showActionSheet) object:nil];
    }
    
    if (shareUrl)
        [shareUrl release];
    if (fileSearchCancel)
        [fileSearchCancel release];
    
    self.thumbImgFileCache = nil;
    [needLoadThumbImageArray removeAllObjects];
    [needLoadThumbImageArray release];
    [thumbImageCache removeAllObjects];
    [thumbImageCache release];
    
    [downloadOrDeleteArray release];
    [downLoadArray release];
    [deleteArray release];
    
    if (self.currentRequest) {
        [restClient cancelRequest:self.currentRequest];
        self.currentRequest = nil;
    }
    [restClient release];
    
    [super dealloc];
}

#pragma mark - View lifecycle
-(void)enableToolViewBtn:(BOOL)enable
{
    if ([self.view viewWithTag:TOOLVIEWTAG])
    {
        ToolView *view = (ToolView *)[self.view viewWithTag:TOOLVIEWTAG];
        if (!view.hidden)
        {
            [view enableBtnDownloadAndDelete:enable];
        }
    }
}
- (void)hideToolView
{
    if ([self.view viewWithTag:TOOLVIEWTAG])
    {
        ToolView *view = (ToolView *)[self.view viewWithTag:TOOLVIEWTAG];
        [view resetTitleAndStatus];
        view.hidden = YES;
    }
}

- (void)showToolView
{
    if (![self.view viewWithTag:TOOLVIEWTAG]) {
        ToolView *toolView = [[[NSBundle mainBundle] loadNibNamed:@"ToolView" owner:nil options:nil] objectAtIndex:0];
        toolView.tag = TOOLVIEWTAG;
        toolView.toolViewDelegate = self;
        [self.view addSubview:toolView];
    }
    else
    {
        [self.view viewWithTag:TOOLVIEWTAG].hidden = NO;
        [self.view bringSubviewToFront:[self.view viewWithTag:TOOLVIEWTAG]];
    }

    [self toolViewFrame];
    [self enableToolViewBtn:NO];
}
-(void)resetNoContentViewFrame
{
    if ([self.view viewWithTag:NOCONTERNVIEWTAG ]) {
        UIView *view = [self.view viewWithTag:NOCONTERNVIEWTAG];
        CGRect rect = view.frame;
        rect.origin.y = self.tableView.frame.origin.y + TABLE_CELL_HEIGHT;
        view.frame = rect;
    }
}
-(void)resetTableViewFrame
{
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    if (IS_IPAD && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
    {
        height = [UIScreen mainScreen].bounds.size.width;
    }
    BOOL searchBarHidden = searchBar.hidden;
    BOOL toolViewHidden = NO;
    if ([self.view viewWithTag:TOOLVIEWTAG])
    {
        toolViewHidden = [self.view viewWithTag:TOOLVIEWTAG].hidden;
    }
    else
    {
        toolViewHidden = YES;
    }
    CGFloat offSet = self.navigationController.navigationBar.frame.size.height + 20;
    height-=offSet;
    if (!searchBarHidden) {
        height-=searchBar.frame.size.height;
    }
    if (!toolViewHidden)
    {
        if ([self.view viewWithTag:TOOLVIEWTAG])
        {
            height-=[self.view viewWithTag:TOOLVIEWTAG].frame.size.height;
        }
    }
    [UIView animateWithDuration:0.2
                          animations:^{
        if (searchBarHidden)
        {
            self.tableView.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, height);
            [self resetNoContentViewFrame];
        }
        else
        {
            self.tableView.frame = CGRectMake(0,searchBar.frame.size.height, self.tableView.bounds.size.width, height);
            [self resetNoContentViewFrame];
        }
     }];
    [self.view layoutSubviews];
}
-(void)cancelAction
{
    if (!self.searchDisplayController.isActive)
    {
        self.navigationItem.hidesBackButton = NO;
        [self addRefreshBtnAddEditBtn];
        if (downloadOrDeleteArray)
        {
            [downloadOrDeleteArray removeAllObjects];
        }
        if ([deleteArray count]) {
            [deleteArray removeAllObjects];
        }
        self.tableView.editing = NO;
        [tableData insertObject:CREATE_FOLDER_STR atIndex:0];
        searchBar.hidden = NO;
        [self.tableView reloadData];
    }
    if ([tableData count] > [LIMIT integerValue])
    {
        _refreshHeaderView.hidden = NO;
    }
    if ([tableData count] <= 1) {
        [self enableEidtBtn:NO];
    }
    [self hideToolView];
    [self resetTableViewFrame];
    [self resetEGOFrame];
    [self performSelector:@selector(loadNewestThumbImage) withObject:nil];
}
-(void)addCancelNavBtn
{
    [self.navigationItem setRightBarButtonItems:nil];
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)];
    self.navigationItem.rightBarButtonItem = cancel;
    [cancel release];
}
-(void)toolViewFrame
{
    if ([self.view viewWithTag:TOOLVIEWTAG])
    {
        ToolView *toolView = (ToolView *)[self.view viewWithTag:TOOLVIEWTAG];
        CGRect rect = toolView.bounds;
        BOOL isLandScape = [UIApplication sharedApplication].statusBarOrientation > UIInterfaceOrientationPortraitUpsideDown ? YES : NO;
        rect.size.width = (isLandScape ? [UIScreen mainScreen].bounds.size.height : [UIScreen mainScreen].bounds.size.width);
        rect.origin.x = 0;
        rect.origin.y = (isLandScape ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height) - 49 - ([UIApplication sharedApplication].statusBarHidden ? 0 : 20) - (self.navigationController.navigationBarHidden ? 0 : 44) ;
        toolView.frame = rect;
    }

}
-(void)editAction
{
    if (self.popover)
    {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadNewestThumbImage) object:nil];
    [self cancelThumbImageCache];
    if (!self.searchDisplayController.isActive)
    {
        self.navigationItem.hidesBackButton = YES;
        if (self.isOpen) {
            [self didSelectCellRow:NO otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];  //关自己
            self.selectIndexPath = nil;
        }
        if (downloadOrDeleteArray)
        {
            [downloadOrDeleteArray removeAllObjects];
        }
        
        [self addCancelNavBtn];
        self.tableView.editing = YES;
        _refreshHeaderView.hidden = YES;
        if (![[tableData objectAtIndex:0] isKindOfClass:[PCFileInfo class]]) {
            [tableData removeObjectAtIndex:0];
        }
        [self.tableView reloadData];
        [self showToolView];
        if (!searchBar.hidden) {
            searchBar.hidden = YES;
            [self resetTableViewFrame];
        }
        [self resetEGOFrame];
    }
}
-(void)enableEidtBtn:(BOOL)enable
{
    for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems)
    {
        if (item.tag == EDITTAG)
        {
            item.enabled = enable;
            break;
        }
    }
}
-(void)addRefreshBtnAddEditBtn
{
    //增加刷新按钮 add by xy
    UIButton *edit = [[UIButton alloc] init];
    [edit setImage:[UIImage imageNamed:[PCUtilityFileOperate getImgName:@"file_edit"]] forState:UIControlStateNormal];
    [edit addTarget:self action:@selector(editAction) forControlEvents:UIControlEventTouchUpInside];
    
    edit.frame = CGRectMake(5, 5, 23, 23);
    UIBarButtonItem *editBtn = [[UIBarButtonItem alloc] initWithCustomView:edit];
    editBtn.tag = EDITTAG;
    [edit release];
    
    UIButton *refreshButton = [[UIButton alloc] init];
    [refreshButton setImage:[UIImage imageNamed:[PCUtilityFileOperate getImgName:@"navigate_refresh"]] forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(setNavigationItemByRefresh:) forControlEvents:UIControlEventTouchUpInside];
    
    refreshButton.frame = CGRectMake(5, 5, 23, 23);
    
    UIBarButtonItem *refreshButtonItem = [[UIBarButtonItem alloc] initWithCustomView:refreshButton];
    [refreshButton release];
    
    //增加间距
    UIButton* spaceButton = [[UIButton alloc] init];
    
    spaceButton.frame = CGRectMake(0, 0, 5, 5);
    
    UIBarButtonItem* spaceButtonButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spaceButton];
    [spaceButton release];
    
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects: refreshButtonItem,spaceButtonButtonItem,editBtn,nil]];
    
    [spaceButtonButtonItem release];
    
    [refreshButtonItem release];
    
    [editBtn release];
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentSize"])
    {
        [self resetEGOFrame];
    }
}
-(void)refreshFileListData:(NSNotification *)notification
{
    if ([tableData containsObject:[notification object]]) {
        [tableData removeObject:[notification object]];
        [tableView reloadData];
    }
    if ([self.filteredListContent containsObject:[notification object]] && self.searchDisplayController.isActive) {
        [self.filteredListContent removeObject:[notification object]];
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFileListData:) name:@"RefreshFileList" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restorePopover) name:@"ScreenLockCorrect" object:nil];
    self.tableView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    [self.tableView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:NULL];
    
    isRefresh = NO;
    isNoMoreData = YES;
    _refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0, self.tableView.bounds.size.height, self.tableView.bounds.size.width,EGOHEIGHT)];
    _refreshHeaderView.delegate = self;
    [self.tableView addSubview:_refreshHeaderView];
    needLoadThumbImageArray = [[NSMutableArray alloc] init];
    //多选下载，删除array
    downloadOrDeleteArray = [[NSMutableArray alloc] initWithCapacity:1];
    downLoadArray = [[NSMutableArray alloc] init];
    deleteArray = [[NSMutableArray alloc] init];
    
    thumbImageCache = [[NSCache alloc] init];
    shareUrl = nil;
    
    self.searchBar.placeholder = NSLocalizedString(@"SearchBarPlaceHolder", nil);
    if (!IS_IPAD) {
        // Change search bar text font
        UITextField *searchField = [self.searchBar valueForKey:@"_searchField"];
        searchField.font = [UIFont systemFontOfSize:13.0f];
    }
    
    dicatorView.activityIndicatorViewStyle =  UIActivityIndicatorViewStyleWhiteLarge;
    dicatorView.color = [UIColor grayColor];
    dicatorView.center = self.view.center;
    
    if (self.searchDisplayController.isActive)
    {
        self.navigationItem.title = NSLocalizedString(@"SearchResult", nil);
        [searchBar setHidden:YES];
        tableView.frame = self.view.frame;
    }
    else
    {
        [self addRefreshBtnAddEditBtn];
    }
    
    //lblResult.text = NSLocalizedString(@"NoResultForSearch", nil);
    
    if (!isFinish) {
        [dicatorView startAnimating];
        [self getList];
    }
    
    self.filteredListContent = [NSMutableArray array];
    
    if (self.savedSearchTerm)
    {
        [self.searchDisplayController setActive:self.searchWasActive];
        [self.searchDisplayController.searchBar setText:savedSearchTerm];
        
        self.savedSearchTerm = nil;
    }
    [self.searchDisplayController.searchResultsTableView reloadData];
    
    oldOrientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
    oldOrientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]){
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.filteredListContent = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([tableData count] > [LIMIT integerValue])
    {
        _refreshHeaderView.hidden = NO;
    }
    else
    {
        _refreshHeaderView.hidden = YES;
    }
    isScrolling = NO;
    isCoveredByPushing = NO;
    if (self.searchDisplayController.isActive) {
        [self.searchDisplayController.searchResultsTableView reloadData];
        [self.searchBar becomeFirstResponder];
    }
    
    if (isNetworkError) {
        isNetworkError = NO;
        isFinish = NO;
        [dicatorView startAnimating];
        
        [self getList];
    }
    if (!isFinish)
    {
        [dicatorView startAnimating];
        UIButton *refreshImg = (UIButton *)self.navigationItem.rightBarButtonItem.customView;
        refreshImg.enabled = NO;
        [PCUtilityUiOperate animateRefreshBtn:refreshImg];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    dicatorView.center = self.view.center;
    
    if (_refreshHeaderView) {
        [self resetEGOFrame];
    }
    [MobClick beginLogPageView:@"FileListView"];
    [self setNoContentViewCenter];
}

- (void)viewWillDisappear:(BOOL)animated
{
    isCoveredByPushing = YES;
    if (self.thumbImgFileCache) {
        self.thumbImgFileCache.delegate = nil;
        [self.thumbImgFileCache cancel];
        
    }
    [needLoadThumbImageArray removeAllObjects];
    if (shareUrl)
    {
        [shareUrl cancelConnection];
        [self shareUrlFinish];
    }
    
    if (self.isMovingFromParentViewController) {
        [self cancelProcess];
    }
    
    if (fileSearch) {
        //没退出应用
        if ([fileSearch currentSearchID]) {
            fileSearchCancel =    [[FileSearch alloc] init];
            [fileSearchCancel searchCancelWithdelegate:self  andSerchID:[fileSearch currentSearchID]];
            [PCUtilityUiOperate showOKAlert: NSLocalizedString(@"SearchBeCancel", nil) delegate:self];
        }
        
        [fileSearch cancel];
        [fileSearch release];
        fileSearch = nil;
    }
    if ([self.view viewWithTag:SEARCH_DICTATOR_TAG]) {
        [[self.view viewWithTag:SEARCH_DICTATOR_TAG] removeFromSuperview];
    }
    //[dicatorView stopAnimating];
    if (self.selectIndexPath)
    {
        self.isOpen = NO;
        [self didSelectCellRow:NO otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];
        self.selectIndexPath = nil;
    }
    [self deletePopover];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    //[self.searchDisplayController setActive:NO animated:NO];
    if (self.searchDisplayController.isActive) {
        if(([self.filteredListContent count] ==2)
           &&[[self.filteredListContent objectAtIndex:1] isKindOfClass:[NSString class]]
           )
        {
            self.filteredListContent = [NSMutableArray arrayWithObjects: @"",@"点击搜索按钮进行搜索", nil];
        }
        
    }
    
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"FileListView"];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.searchWasActive = [self.searchDisplayController isActive];
    self.savedSearchTerm = [self.searchDisplayController.searchBar text];
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

-(void)setNoContentViewCenter
{
    UIView *header = [self.view viewWithTag:NOCONTERNVIEWTAG];
    if (header)
    {
        UIImageView *image = (UIImageView *)[header viewWithTag:ImageTag];
        CGFloat offset = 0.0;
        if (IS_IPAD)
        {
            if (image)
            {
                if ((image.center.y == 300 - TABLE_CELL_HEIGHT || image.center.y == 300) && UIDeviceOrientationIsLandscape((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation))
                {
                    offset =-100;
                }
                if ((image.center.y == 200 - TABLE_CELL_HEIGHT || image.center.y == 200)&& UIDeviceOrientationIsPortrait((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation))
                {
                    offset =100;
                }
            }
        }
        if (image)
        {
            image.center = CGPointMake(self.view.center.x, image.center.y+offset);
        }
        
        
        UILabel *title = (UILabel *)[header viewWithTag:LabelTitleTag];
        if (title)
        {
            title.center = CGPointMake(self.view.center.x, title.center.y+offset);
        }
        
        UIView *des = [header viewWithTag:LabelDesTag];
        if (des)
        {
            if (offset>0)
            {
                des.frame = CGRectMake(des.frame.origin.x, des.frame.origin.y, self.view.frame.size.width-40, des.frame.size.height);
            }
            else
            {
                des.frame = CGRectMake(des.frame.origin.x, des.frame.origin.y, self.view.frame.size.width-40, des.frame.size.height);
            }
            des.center = CGPointMake(self.view.center.x, des.center.y+offset);
        }
    }
}

-(void)resetEGOFrame
{
    CGFloat y =  self.tableView.contentSize.height > self.tableView.bounds.size.height ? self.tableView.contentSize.height : self.tableView.bounds.size.height;
    if (y<self.tableView.bounds.size.height)
    {
        y = self.tableView.bounds.size.height;
    }
    //ios 7 插入一行之后tableview的contentSize没有增加，导致最后一行展开之后被下拉刷新组件遮住了
//    if (IS_IOS7)
//    {
//        if (y == self.tableView.contentSize.height && self.isOpen)
//        {
//            y+=TABLE_CELL_HEIGHT;
//        }
//        
//    }
    _refreshHeaderView.frame = CGRectMake(0,y, self.tableView.bounds.size.width, EGOHEIGHT);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    dicatorView.center = self.view.center;
    
    [self resetEGOFrame];
    
    if ([self.view viewWithTag:SEARCH_DICTATOR_TAG]) {
        ((UIView*)[self.view viewWithTag:SEARCH_DICTATOR_TAG]).center = self.view.center;
    }
    if ([self.view viewWithTag:NOCONTERNVIEWTAG]) {
        [self setNoContentViewCenter];
    }
    if ([self.view viewWithTag:PROCESSVIEWTAG]) {
        ((UIView*)[self.view viewWithTag:PROCESSVIEWTAG]).center = self.view.center;
        [self resetActivityFrame];
    }
    if (self.popover && IS_IPAD) {
        [self.popover dismissPopoverAnimated:NO];
        if ([[PCSettings sharedSettings] screenLock])
        {
            if (![[ScreenLockViewController sharedLock] isOnScreen])
            {
                [self.popover presentPopoverFromRect:[self popoverShowRect] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
        }
        else
        {
            [self.popover presentPopoverFromRect:[self popoverShowRect] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }


    }
}
-(CGRect)popoverShowRect
{
    CGRect rect = CGRectZero;
    NewFolderAndUploadCell *cell = (NewFolderAndUploadCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if (cell)
    {
        rect = cell.uploadBtn.frame;
        CGFloat x = cell.frame.size.width;
        x = x/2;
        rect.origin.x = x;
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            rect.origin.x+=x/2.0f - 50;
        }
        rect.origin.y = cell.uploadBtn.frame.size.height-10;
        if (searchBar.hidden) {
            rect.origin.y-=searchBar.bounds.size.height;
        }
    }
    return rect;
}
- (void)showPopover:(UIViewController *)controller
{
    self.popover = [[[UIPopoverController alloc] initWithContentViewController:controller] autorelease];
    self.popover.delegate = self;
    [self.popover presentPopoverFromRect:[self popoverShowRect] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
}

- (void)deletePopover
{
    if (self.popover)
    {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
}

- (DownloadStatus)getDownloadFileStatus:(NSString *)hostPath
{
    DownloadStatus status = kStatusNoDownload;
    
    FileDownloadManager *downloadMgr = [PCUtilityFileOperate downloadManager];
    
    for (PCFileDownloadingInfo *info in downloadMgr.tableDownloading) {
        if ([info.hostPath isEqualToString:hostPath]) {
            return info.status.shortValue + 1;
        }
    }
    
    for (PCFileDownloadingInfo *info in downloadMgr.tableDownloadingStoped) {
        if ([info.hostPath isEqualToString:hostPath]) {
            return kStatusDownloadStop;
        }
    }
    
    for (PCFileDownloadedInfo *info in downloadMgr.tableDownloaded) {
        if ([info.hostPath isEqualToString:hostPath]) {
            return kStatusDownloaded;
        }
    }
    
    return status;
}

#pragma mark - callback methods

- (void)orientationDidChange:(NSNotification *)note
{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    
    if (orientation < UIDeviceOrientationPortrait ||
        orientation > UIDeviceOrientationLandscapeRight ||
        (orientation == UIDeviceOrientationPortraitUpsideDown && !IS_IPAD) ||
        oldOrientation == orientation)
        return;
    
    oldOrientation = orientation;
    
    
    dicatorView.center = self.view.center;
    
    if (shareUrl && shareUrl.actionSheet)
    {
        [shareUrl.actionSheet dismissWithClickedButtonIndex:shareUrl.actionSheet.cancelButtonIndex
                                                   animated:NO];
        [shareUrl performSelector:@selector(showActionSheet) withObject:nil afterDelay:0.1];
    }
    UIView *sheet = [self.view.window viewWithTag:SHEETVIEWTAG];
    if ([sheet isKindOfClass:[UIActionSheet class]]) {
        
        [(UIActionSheet*)sheet dismissWithClickedButtonIndex:1 animated:NO];
        [self performSelector:@selector(deleteButtonClick:) withObject:nil afterDelay:0.1];
    }
}

//-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
////    cell.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
//}
//显示文字类提示信息的cell，例如 “搜索中”
- (UITableViewCell*)  createNormalCellForTable:(UITableView*)currentTable
{
    static NSString *CellIdentifierNormal = @"NormalCell";
    UITableViewCell *cellNormal = [currentTable dequeueReusableCellWithIdentifier:CellIdentifierNormal];
    
    if (cellNormal == nil)
    {
        cellNormal = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault
                                             reuseIdentifier: CellIdentifierNormal] autorelease];
        cellNormal.backgroundColor = [UIColor clearColor];
        cellNormal.selectionStyle = UITableViewCellSelectionStyleNone;
        cellNormal.accessoryType = UITableViewCellAccessoryNone;
        cellNormal.textLabel.font = [UIFont systemFontOfSize:16];
    }
    cellNormal.imageView.image = nil;
    cellNormal.textLabel.textColor = [UIColor darkGrayColor];
    cellNormal.textLabel.textAlignment = UITextAlignmentCenter;
    return cellNormal;
}

//显示文件信息的cell
- (UITableViewCell*)  createFileInfoCellForTable:(UITableView*)currentTable   andPath:(NSIndexPath*)indexPath
{
    PCFileInfo *fileInfo = nil;
    if (currentTable == self.tableView)
    {
        fileInfo = [tableData objectAtIndex:indexPath.section];
    }
    else
    {
        if (([self.filteredListContent count] ==2
             &&[[self.filteredListContent objectAtIndex:0] isKindOfClass:[NSString class]]
             && [[self.filteredListContent objectAtIndex:0] isEqualToString:@""]))
        {
            return [self createCellForSearchTableAtIndexPath:indexPath];
        }
        else if ([self.filteredListContent count] == 0)
        {
            self.filteredListContent = [NSMutableArray arrayWithObjects: @"",@"点击搜索按钮进行搜索", nil];
            return [self createCellForSearchTableAtIndexPath:indexPath];
        }
        else
        {
            fileInfo =[self.filteredListContent objectAtIndex:indexPath.section];
        }
    }
    
    BOOL bSelected = (self.isOpen&&(self.selectIndexPath.section == indexPath.section));
    static NSString *CellIdentifierFileInfoCell = @"FileInfoCell";
    PCFileCell *cell = [currentTable dequeueReusableCellWithIdentifier:CellIdentifierFileInfoCell];
    if (cell == nil)
    {
        cell = [[[PCFileCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifierFileInfoCell] autorelease];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    //修改重用引起的问题
    if (bSelected)
    {
        [cell changeArrowImageWithExpansion:YES];
    }
    else
    {
        [cell changeArrowImageWithExpansion:NO];
    }
    
    cell.delegate = self;
    cell.indexRow = indexPath.row;
    cell.indexSection = indexPath.section;
    if (fileInfo.bFileFoldType)
    {
        [cell changeStatusImageWithFileStatus:kStatusNoDownload];
        cell.imageView.image = [UIImage imageNamed:@"file_folder.png"];
        cell.detailTextLabel.text = nil;
    }
    else
    {
        NSString *imageName = [PCUtilityFileOperate getImgByExt:fileInfo.ext];
        if(fileInfo.mFileType == PC_FILE_IMAGE)
        {
            NSString *path =[[self getLocalThumbImageRootPath] stringByAppendingPathComponent:fileInfo.path];
            id obj = [thumbImageCache objectForKey:path];
            if (obj)
            {
                cell.imageView.image = (UIImage *)obj;
            }
            else
            {
                cell.imageView.image = [UIImage imageNamed:imageName];
                if ([[NSFileManager defaultManager] fileExistsAtPath:path])
                {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
                                   {
                                       NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                                       UIImage *image = [UIImage imageWithContentsOfFile:path];
                                       BOOL isEmpty = YES;
                                       if (image.size.width!=0)
                                       {
                                           isEmpty = NO;
                                           UIGraphicsBeginImageContextWithOptions(cell.imageView.bounds.size,YES,[UIScreen mainScreen].scale);
                                           [image drawInRect:cell.imageView.bounds];
                                           image = UIGraphicsGetImageFromCurrentImageContext();
                                           UIGraphicsEndImageContext();
                                       }
                                       
                                       if (image && !isEmpty)
                                       {
                                           [thumbImageCache setObject:image forKey:path];
                                       }
                                       else
                                       {
                                           dispatch_async(dispatch_get_main_queue(), ^(void)
                                                          {
                                                              cell.imageView.image = [UIImage imageNamed:imageName];
                                                          });
                                       }
                                       if (image && !isScrolling) {
                                           dispatch_async(dispatch_get_main_queue(), ^(void)
                                                          {
                                                              cell.imageView.image = image;
                                                          });
                                       }
                                       [pool release];
                                   });
                }
            }
        }
        else
            cell.imageView.image = [UIImage imageNamed:imageName];
        
        cell.detailTextLabel.text = [PCUtilityFileOperate formatFileSize:[fileInfo.size longLongValue] isNeedBlank:YES];
        
        [cell changeStatusImageWithFileStatus:[self getDownloadFileStatus:fileInfo.path]];
    }
    
    cell.textLabel.text = fileInfo.name;
    [self changeCellSelectedIamge:indexPath cell:cell isSelected:NO];
    return cell;
}

//展开后的cell,带分享 收藏 重命名等 功能 按钮。
- (UITableViewCell*)  createFunctionCellForTable:(UITableView*)currentTable  andPath:(NSIndexPath*)indexPath
{
    PCFileInfo *fileInfo = (currentTable == self.tableView)?[tableData objectAtIndex:indexPath.section]:[self.filteredListContent objectAtIndex:indexPath.section];
    if (self.selectIndexPath.section == indexPath.section&&indexPath.row!=0)
    {
        static NSString *CellIdentifier = @"Cell2";
        PCFileExpansionCell *cell2 = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell2 == nil)
        {
            cell2 = [[[PCFileExpansionCell alloc] initWithStyle: UITableViewCellStyleSubtitle
                                                reuseIdentifier: CellIdentifier] autorelease];
            cell2.selectionStyle = UITableViewCellSelectionStyleNone;
            cell2.accessoryType = UITableViewCellAccessoryNone;
            cell2.textLabel.font = [UIFont systemFontOfSize:16];
        }
        cell2.delegate = self;
        cell2.indexPath = indexPath;
        
        if (fileInfo.bFileFoldType)
        {
            [cell2 initActionContent:FILELIST_FOLDER];
        }
        else
        {
            [cell2 initActionContent:[self getDownloadFileStatus:fileInfo.path] == kStatusNoDownload
             ? FILELIST_FILE_NO_FAVORITE : FILELIST_FILE_FAVORITE];
        }
        
        return cell2;
    }
    return nil;
}

//文件列表的tableview
- (UITableViewCell*)  createCellForFileListTableAtIndexPath:(NSIndexPath*)path
{
    if (path.section == 0 && !self.tableView.editing)
    {
        NewFolderAndUploadCell *cellNormal  = [self.tableView dequeueReusableCellWithIdentifier:@"NewFolderAndUploadCell"];
        if (!cellNormal)
        {
                cellNormal = (NewFolderAndUploadCell *)[[[NSBundle mainBundle] loadNibNamed:@"NewFolderAndUploadCell" owner:self options:nil] objectAtIndex:0];
                cellNormal.delegate = self;
        
        }

        return cellNormal ;
    }
    else{
        if (path.row == 0) {
            return  [self createFileInfoCellForTable:self.tableView   andPath:path];
        }
        else{
            return [self createFunctionCellForTable:self.tableView  andPath:path];
        }
    }
}

//搜索结果的tableview
- (UITableViewCell*)  createCellForSearchTableAtIndexPath:(NSIndexPath*)path
{
    if ([self.filteredListContent count] ==2
        &&[[self.filteredListContent objectAtIndex:0] isKindOfClass:[NSString class]]
        && [[self.filteredListContent objectAtIndex:0] isEqualToString:@""]) {
        UITableViewCell  *cellNormal = [self createNormalCellForTable:self.searchDisplayController.searchResultsTableView];
        if (path.section < [self.filteredListContent count]) {
            cellNormal.textLabel.text = [self.filteredListContent objectAtIndex:path.section];
        }
        
        return cellNormal;
    }
    else{
        if (path.row == 0) {
            return  [self createFileInfoCellForTable:self.searchDisplayController.searchResultsTableView   andPath:path];
        }
        else{
            return [self createFunctionCellForTable:self.searchDisplayController.searchResultsTableView  andPath:path];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)t_tableView
{
    // Return the number of sections.
    if (t_tableView == self.searchDisplayController.searchResultsTableView)
	{
        return [self.filteredListContent count];
    }
	else
	{
        return tableData.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.isOpen)
    {
        if (self.selectIndexPath.section == section)
        {
            return 2;
        }
    }
    return 1;
    
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == 0  &&  !self.searchDisplayController.isActive) {
        return 50;//新建文件夹
    }
    else if (self.isOpen&&self.selectIndexPath.section == indexPath.section&&indexPath.row!=0)
    {
        return 55;
    }
    else
    {
        return TABLE_CELL_HEIGHT;
    }
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_tableView == self.searchDisplayController.searchResultsTableView)
    {
        return [self createCellForSearchTableAtIndexPath:indexPath];
    }
    else{
        return [self createCellForFileListTableAtIndexPath:indexPath];
    }
    return nil;
}

- (void) stopCheckAndOpenFileWithError:(NSString*)errMsg
{
    [self endProcess];
    [fileCache release];
    fileCache = nil;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:errMsg delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void) checkAndOpenFileWithFileInfo:(PCFileInfo*)fileInfo andTotalData:(NSArray*)currentData
{
    [MobClick event:UM_FILE_VIEW label:fileInfo.ext];
    // add by xy  bugID:54134
    if (![PCUtility isNetworkReachable:self]) {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"OpenNetwork", nil) delegate:nil];
        return;
    }
    //            [self showProgressView];
    fileCache = [[FileCache alloc] init];
    fileCache.currentDeviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
    [fileCache setProgressView:progressingViewController.progressView progressScale:1.0];
    
    DownloadStatus status = [[PCUtilityFileOperate downloadManager] getFileStatus:fileInfo.path
                                                                    andModifyTime:fileInfo.modifyTime];
    BOOL bImageCache = NO;
    
    if ([fileInfo.size longLongValue] == 0)
    {
        [self stopCheckAndOpenFileWithError:NSLocalizedString(@"ConfirmEmptyFile", nil)];
    }
    //add by libing 2013-6-26 fix bug bug54838  bug 55854
    else if(!(fileInfo.path&&[PCUtilityFileOperate itemCanOpenWithPath:fileInfo.path]))
    {
        [self stopCheckAndOpenFileWithError:NSLocalizedString(@"NoSuitableProgram", nil)];
    }
    //非图片文件并有cache缓存 或 图片有缓存在 slideimage
    else if (([fileCache  readFileFromCacheWithFileInfo:fileInfo withType:TYPE_CACHE_SLIDEIMAGE]
              && (bImageCache = !bImageCache))
             ||
             ((fileInfo.mFileType != PC_FILE_IMAGE)
              &&
              [fileCache GetFuLLSizeFileFromCacheWithFileInfo:fileInfo  withType:TYPE_CACHE_FILE]))
        
    {
        [self endProcess];
        id filePath =fileInfo.path;
        if (![filePath isKindOfClass:[NSString class]]) {
            filePath =   @"";
        }
        int fileSaveType = bImageCache? TYPE_CACHE_SLIDEIMAGE:TYPE_CACHE_FILE;
        if (fileInfo.mFileType != PC_FILE_OTHER)
        {
            FileCacheController *cacheController = [[FileCacheController alloc] initWithPath:[fileCache getCacheFilePath:filePath
                                                                                                                withType:fileSaveType]  andFinishLoadingState:YES
                                                                               andDataSource:currentData
                                                                        andCurrentPCFileInfo:fileInfo
                                                                   andLastViewControllerName:self.navigationItem.title];
            cacheController.title = fileInfo.name;
            if (fileInfo.mFileType == PC_FILE_IMAGE)
            {
                KTPhotoScrollViewController *newController = [[KTPhotoScrollViewController alloc]
                                                              initWithDataSource:cacheController
                                                              andStartWithPhotoAtIndex:cacheController.startWithIndex_];
                [self.navigationController pushViewController:newController animated:YES];                            [newController release];
            }
            else
            {
                [self.navigationController pushViewController:cacheController animated:YES];
            }
            [cacheController release];
        }
        else
        {
            [self openFileWithFileInfo:fileInfo andFileType:TYPE_CACHE_FILE];
        }
        [fileCache release];
        fileCache = nil;
    }
    //若文件先下载（收藏）了，则点击该文件还会判断其是否在Download文件夹里，added by ray
    else if ([fileCache readFileFromCacheWithFileInfo:fileInfo withType:TYPE_DOWNLOAD_FILE] &&
             (status == kStatusDownloaded || status == kStatusDownloading)&&
             (fileInfo.mFileType != PC_FILE_IMAGE))
    {
        [self endProcess];
        if (status == kStatusDownloaded)
        {
            NSString *filePath = fileInfo.path;
            //避免null值 无  pathextention方法导致 crash
            if (![filePath isKindOfClass:[NSString class]])
                filePath = @"";
            
            if (fileInfo.mFileType != PC_FILE_OTHER)
            {
                FileCacheController *cacheController = [[FileCacheController alloc] initWithPath:[fileCache getCacheFilePath:filePath
                                                                                                                    withType:TYPE_DOWNLOAD_FILE]  andFinishLoadingState:YES
                                                                                   andDataSource:currentData
                                                                            andCurrentPCFileInfo:fileInfo
                                                                       andLastViewControllerName:self.navigationItem.title];
                cacheController.title = fileInfo.name;
                if (fileInfo.mFileType == PC_FILE_IMAGE)
                {
                    KTPhotoScrollViewController *newController = [[KTPhotoScrollViewController alloc]
                                                                  initWithDataSource:cacheController
                                                                  andStartWithPhotoAtIndex:cacheController.startWithIndex_];
                    
                    [self.navigationController pushViewController:newController animated:YES];                            [newController release];
                }
                else
                {
                    [self.navigationController pushViewController:cacheController animated:YES];
                }
                [cacheController release];
            }
            else
            {
                [self openFileWithFileInfo:fileInfo andFileType:TYPE_DOWNLOAD_FILE];
            }
        }
        else//若是正在收藏下载的文件，则不再单独缓存下载，直接显示收藏那边的下载进度
        {
            FileCacheController *cacheController = [[FileCacheController alloc] initWithPath:[fileCache getCacheFilePath:fileInfo.path
                                                                                                                withType:TYPE_DOWNLOAD_FILE]  andFinishLoadingState:NO
                                                                               andDataSource:currentData
                                                                        andCurrentPCFileInfo:fileInfo
                                                                   andLastViewControllerName:self.navigationItem.title];
            
            [[NSNotificationCenter defaultCenter] addObserver:cacheController selector:@selector(downloadProgress:) name:@"RefreshProgress" object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:cacheController selector:@selector(downloadFinish:) name:@"RefreshTableView" object:nil];
            
            cacheController.title = fileInfo.name;
            [self.navigationController pushViewController:cacheController animated:YES];
            
            PCFileDownloadingInfo *downloadingInfo = [[PCUtilityFileOperate downloadManager]
                                                      fetchObject:@"FileDownloadingInfo"
                                                      hostPath:fileInfo.path
                                                      modifyTime:nil];
            if (downloadingInfo)
                [cacheController cacheFileProgress:downloadingInfo.progress.floatValue
                                          hostPath:nil];
            [cacheController release];
        }
        [fileCache release];
        fileCache = nil;
    }
    else
    {
        if (fileInfo.mFileType != PC_FILE_AUDIO && fileInfo.mFileType != PC_FILE_VEDIO)
        {
            NSInteger cacheType = fileInfo.mFileType == PC_FILE_IMAGE ? TYPE_CACHE_SLIDEIMAGE : TYPE_CACHE_FILE;
            NSString *filePath = [fileCache getCacheFilePath:fileInfo.path withType:cacheType];
            FileCacheController *cacheController = [[FileCacheController alloc] initWithPath:filePath
                                                                       andFinishLoadingState:NO
                                                                               andDataSource:fileInfo.mFileType == PC_FILE_IMAGE ? currentData : nil
                                                                        andCurrentPCFileInfo:fileInfo
                                                                   andLastViewControllerName:self.navigationItem.title];
            if (fileInfo.mFileType == PC_FILE_IMAGE)
            {
                KTPhotoScrollViewController *newController = [[KTPhotoScrollViewController alloc]
                                                              initWithDataSource:cacheController
                                                              andStartWithPhotoAtIndex:cacheController.startWithIndex_];
                [self.navigationController pushViewController:newController animated:YES];
                [newController release];
                if (fileCache) {
                    [fileCache release];
                    fileCache = nil;
                }
            }
            else
            {
                if ([fileCache cacheFile:fileInfo.path
                                viewType:cacheType
                          viewController:cacheController
                                fileSize:[fileInfo.size longLongValue]
                           modifyGTMTime:[fileInfo.modifyTime longLongValue]
                               showAlert:YES])
                {
                    cacheController.hidesBottomBarWhenPushed = YES;
                    cacheController.title = fileInfo.name;
                    [self.navigationController pushViewController:cacheController animated:YES];
                    [self startProcess];
                }
            }
            [cacheController release];
        }
        else
        {
            if ([NetPenetrate sharedInstance].gCurrentNetworkState == CURRENT_NETWORK_STATE_DEFAULT)
            {
                [currentFileInfo release];
                currentFileInfo = [fileInfo retain];
                
                if (self.selectIndexPath)
                {
                    [self didSelectCellRow:NO otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];
                    self.selectIndexPath = nil;
                }
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"网络状况不佳，需要缓冲一段时间后播放"
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                      otherButtonTitles:NSLocalizedString(@"Continue", nil), nil];
                alert.tag = CACHE_FILE_TAG;
                [alert show];
                [alert release];
            }
            else if ([PCUtilityFileOperate livingMediaSupport:fileInfo.ext])
            {
                NSString *url = [NSString stringWithFormat:@"mediaPlay?path=%@", fileInfo.path];
                NSMutableString *urlStr = [NSMutableString stringWithString:url];
                if ([PCSettings sharedSettings].bSessionSupported ) {
                    [urlStr appendString:@"&"];
                    [urlStr appendFormat:@"%@=%@", @"token_id",[PCLogin getToken]];
                    [urlStr appendString:@"&"];
                    [urlStr appendFormat:@"%@=%@", @"client_id",[[UIDevice currentDevice] uniqueDeviceIdentifier]];
                }
                
                NSString  *temp = [[NSString stringWithString:urlStr] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                NSURL *nsUrl = [PCUtility getNSURL:temp];
                if (fileInfo.mFileType == PC_FILE_AUDIO) {
                    [self playOnlineMusicWithContentUrl:nsUrl];
                }
                else if (fileInfo.mFileType == PC_FILE_VEDIO) {
                    [self playOnlineVedioWithContentUrl:nsUrl];
                }
                
                if (fileCache) {
                    [fileCache release];
                    fileCache = nil;
                }
            }
            else
            {
                NSString *filePath = [fileCache getCacheFilePath:fileInfo.path withType:TYPE_CACHE_FILE];
                FileCacheController *cacheController = [[FileCacheController alloc] initWithPath:filePath
                                                                           andFinishLoadingState:NO
                                                                                   andDataSource:nil
                                                                            andCurrentPCFileInfo:fileInfo
                                                                       andLastViewControllerName:self.navigationItem.title];
                if ([fileCache cacheFile:fileInfo.path
                                viewType:TYPE_CACHE_FILE
                          viewController:cacheController
                                fileSize:[fileInfo.size longLongValue]
                           modifyGTMTime:[fileInfo.modifyTime longLongValue]
                               showAlert:YES])
                {
                    cacheController.hidesBottomBarWhenPushed = YES;
                    cacheController.title = fileInfo.name;
                    [self.navigationController pushViewController:cacheController animated:YES];
                    [self startProcess];
                }
                [cacheController release];
            }
        }
    }
}

#pragma mark - Table view delegate
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)cur_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}
-(NSString *)loadDeletePath:(NSMutableArray *)array
{
    NSArray *realArray;
    if ([array count] > MAXDELETEFILE)
    {
        realArray = [[array subarrayWithRange:NSMakeRange(0, MAXDELETEFILE)] retain];
    }
    else
    {
        realArray = [array copy];
    }
    NSMutableString *pathStr = [[NSMutableString alloc] initWithString:@"["];
    for (PCFileInfo *info in realArray)
    {
        [pathStr appendFormat:@"\"%@\",",info.path];
    }
    [pathStr deleteCharactersInRange:NSMakeRange(pathStr.length-1, 1)];
    [pathStr appendString:@"]"];
    [realArray release];
    
    return [pathStr autorelease];
}
#pragma mark - ToolView delegate and file operate
//删除文件
-(void)resetActivityFrame
{
    if ([self.view viewWithTag:PROCESSVIEWTAG])
    {
        UIView *view = (UIView *)[self.view viewWithTag:PROCESSVIEWTAG];
        UILabel *processLabel = (UILabel *)[view viewWithTag:2090];
        UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[view viewWithTag:2091];
        CGRect rect = activity.frame;
        rect.origin.x = (processLabel.bounds.size.width - [processLabel.text sizeWithFont:processLabel.font].width)/2.0f - rect.size.width - 5.0f;
        rect.origin.y = (view.bounds.size.height - rect.size.height)/2.0f;
        activity.frame = rect;
    }
}
-(void)removeDeleteProcessView
{
    if ([self.view viewWithTag:PROCESSVIEWTAG])
    {
        [[self.view viewWithTag:PROCESSVIEWTAG] removeFromSuperview];
    }
}
-(void)createDeleteProcessView
{
    if (![self.view viewWithTag:PROCESSVIEWTAG])
    {
        dicatorView.hidden = YES;
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
        view.backgroundColor = [UIColor grayColor];
        view.alpha = 0.85;
        view.layer.cornerRadius = 5.0f;
        view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        view.center = self.view.center;
        view.tag = PROCESSVIEWTAG;
        [self.view addSubview:view];
        [view release];
        
        UILabel *processLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
        processLabel.backgroundColor = [UIColor clearColor];
        processLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        processLabel.tag = 2090;
        processLabel.text = @"正在删除文件，请稍后...";
        processLabel.textColor = [UIColor whiteColor];
        processLabel.textAlignment = NSTextAlignmentCenter;
        [view addSubview:processLabel];
        [processLabel release];
        
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [view addSubview:activity];
        activity.tag = 2091;
        CGRect rect = activity.frame;
        rect.origin.x = (processLabel.bounds.size.width - [processLabel.text sizeWithFont:processLabel.font].width)/2.0f - rect.size.width - 5.0f;
        rect.origin.y = (view.bounds.size.height - rect.size.height)/2.0f;
        activity.frame = rect;
        [activity startAnimating];
        [activity release];
    }

}
-(void)deleteFile
{
    [self lockUI];
    for (PCFileInfo *info in downloadOrDeleteArray)
    {
        if (![deleteArray containsObject:info])
        {
            [deleteArray addObject:info];
        }
    }
    [downloadOrDeleteArray removeAllObjects];
    if ([deleteArray count] == 0)
    {
        return;
    }
    [self createDeleteProcessView];
    FileOperate *fileOperate = [[FileOperate alloc] init];
    [fileOperate fileOperateWithPath:[self loadDeletePath:deleteArray] method:@"remove" delegateOwner:self];
    fileOperate.totalFileCount = [deleteArray count] > MAXDELETEFILE ? MAXDELETEFILE : [deleteArray count];

}

-(void)realDownload//加入下载队列
{
    PCFileInfo *fileInfo = [downLoadArray objectAtIndex:0];
    fileCache = [[FileCache alloc] init];
    fileCache.currentDeviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
    [MobClick event:UM_FAVOURITE label:fileInfo.ext];
    if ([fileInfo.size longLongValue] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"CollectEmptyFile", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    //若文件先缓存了，则收藏时判断是否在Caches文件夹里，在的话把该文件从Caches文件夹移到Download文件夹，并更新数据库
    else if([fileCache GetFuLLSizeFileFromCacheWithFileInfo:fileInfo withType:TYPE_CACHE_FILE] && [PCUtilityFileOperate moveCacheFileToDownload:fileInfo.path
                                                                                                                                       fileSize:[fileInfo.size longLongValue]
                                                                                                                                      fileCache:fileCache
                                                                                                                                       fileType:TYPE_CACHE_FILE])
    {
        [PCUtilityUiOperate showHasCollectTip:fileInfo.name];
    }
    else
    {
        [[PCUtilityFileOperate downloadManager] addItem:fileInfo.path fileSize:[fileInfo.size longLongValue] modifyGTMTime:[fileInfo. modifyTime longLongValue]];
        if (isSearchDisplay) {
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
        else{
            [self.tableView reloadData];
        }
    }
    
    [fileCache release];
    fileCache = nil;
    [downLoadArray removeObjectAtIndex:0];
}

-(void)downloadFile
{
    if (![PCUtility isNetworkReachable:self]) {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"OpenNetwork", nil) delegate:nil];
        return;
    }
    [downLoadArray addObjectsFromArray:downloadOrDeleteArray];
    [downloadOrDeleteArray removeAllObjects];
    if(![downLoadArray count])
    {
        [self cancelAction];
        return;
    }
    
    PCFileInfo *fileInfo = [downLoadArray objectAtIndex:0];
    DownloadStatus fileDownLoadStatus = [[PCUtilityFileOperate downloadManager] getFileStatus:fileInfo.path andModifyTime:nil];
    if (fileDownLoadStatus > kStatusNoDownload)
    {
        if (ignoreDownloaded)
        {
            [downLoadArray removeObject:fileInfo];
            [self downloadFile];
            return;
        }
        [[PCUtilityFileOperate downloadManager] deleteDownloadItem:fileInfo.path fileStatus:fileDownLoadStatus];
    }
    
    [self realDownload];//真正的去加入下载队列
    [self downloadFile];
}
-(void)didSelectBtn:(NSInteger)tag
{
    if (tag == QuanXuanTag)//全选  全不选
    {
            for (id info in tableData)
            {
                if ([info isKindOfClass:[PCFileInfo class]])
                {
                    if (![downloadOrDeleteArray containsObject:info])
                    {
                        [downloadOrDeleteArray addObject:info];
                        [self enableToolViewBtn:YES];
                    }
                }
            }
            [tableView reloadData];
    }
    else if (tag == QuanBuXuanTag)//全不选
    {
        
        [downloadOrDeleteArray removeAllObjects];
        [tableView reloadData];
        [self enableToolViewBtn:NO];
        
    }
    else if (tag == ShanChuTag)//删除
    {
        if ([downloadOrDeleteArray count] > 0 || [deleteArray count] > 0 )
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

    }
    else if (tag == XiaZaiTag)//下载
    {
        if ([downloadOrDeleteArray count])
        {
            for (PCFileInfo *info in downloadOrDeleteArray)
            {
                if (info.bFileFoldType)
                {
                    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"不支持文件夹下载"
                                                                          message:nil
                                                                         delegate:nil
                                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                                otherButtonTitles:nil];
                    [deleteAlert show];
                    [deleteAlert release];
                    return;
                }
            }
            
            for (PCFileInfo *fileInfo in downloadOrDeleteArray)
            {
                DownloadStatus fileDownLoadStatus = [[PCUtilityFileOperate downloadManager] getFileStatus:fileInfo.path andModifyTime:nil];
                if (fileDownLoadStatus > kStatusNoDownload)
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                    message:@"部分文件已经下载过了，请确认是否再下一次，还是忽略已下载的文件继续下载？"
                                                                   delegate:self
                                                          cancelButtonTitle:@"忽略"
                                                          otherButtonTitles:@"再下一次", nil];
                    [alert show];
                    alert.tag = XIAZAITAG;
                    [alert release];
                    return;
                }
            }
            
            [self downloadFile];
        }
        
    }
    else if (tag == WoXiHuanTag)//我喜欢
    {
    
    }
}
#pragma mark - PCFileCell delegate
- (void)didSelectCell:(NSIndexPath *)indexPath
{
    NSMutableArray *currentData = isSearchDisplay?filteredListContent:tableData;
    UITableView *currentTable = isSearchDisplay?self.searchDisplayController.searchResultsTableView:tableView;
    if (isProcessing) return;
    
    if (indexPath.section < currentData.count)
    {
        PCFileInfo *fileInfo = [currentData objectAtIndex:indexPath.section];
        if (fileInfo.bFileFoldType)
        {
            if ([fileInfo.path isKindOfClass:[NSNull class]])
            {
                [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"NotExist", nil) delegate:nil];
                return;
            }
            FileListViewController *fileListView = [[FileListViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"FileListView"] bundle:nil];
            fileListView.navigationItem.title = fileInfo.name;
            fileListView.dirPath = fileInfo.path;
            fileListView.dirName = [dirName stringByAppendingPathComponent:fileInfo.name];
            [self.navigationController pushViewController:fileListView animated:YES];
            [fileListView release];
        }
        else
        {
            [self checkAndOpenFileWithFileInfo:fileInfo andTotalData:currentData];
        }
    }
    [currentTable deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)expansionView:(NSIndexPath *)indexPath
{
    DLogNotice(@"文件集：expansionView index = %d",indexPath.section);
    if (nil == indexPath)
    {
        return;
    }
    //fix bug 56398
    NSMutableArray *dataArray = tableData;
    if (isSearchDisplay)
    {
        dataArray = filteredListContent;
    }
    //
    if (indexPath.section < dataArray.count && indexPath.row == 0 && _reloading == NO)
    {
        if ([indexPath isEqual:self.selectIndexPath])
        {
            self.isOpen = NO;
            // 有一个是开的 allCellsIsClose = no 当前操作的是开的 selectedCellIsClose = no
            [self didSelectCellRow:NO otherCellIsOpen:NO currentIndexPath:indexPath];  //关自己
            self.selectIndexPath = nil;
        }
        else
        {
            if (!self.selectIndexPath)
            {
                self.selectIndexPath = [indexPath retain];
                [indexPath release];
                [self didSelectCellRow:YES otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];
            }
            else
            {
                NSLog(@"indexPath : %d", indexPath.section);
                [self didSelectCellRow:NO otherCellIsOpen:YES currentIndexPath:indexPath];
            }
        }
        
    }
}
//在编辑状态下选中了cell
-(void)changeCellSelectedIamge:(NSIndexPath *)indexPath cell:(PCFileCell *)cell isSelected:(BOOL)selected
{
    if (!self.tableView.editing) {
        return;
    }
    if (indexPath.section > [tableData count])
    {
        return;
    }
    PCFileInfo *info = [tableData objectAtIndex:indexPath.section];
    if (info)
    {
        if (!selected)
        {
            if ([downloadOrDeleteArray containsObject:info])
            {
                [cell changeSelectImage:YES];
            }
            else
            {
                [cell changeSelectImage:NO];
            }
            return;
        }
        
        if ([downloadOrDeleteArray containsObject:info])
        {
            BOOL selectAll = [downloadOrDeleteArray count]==[tableData count] ? YES : NO;
            [downloadOrDeleteArray removeObject:info];
            if (selectAll)
            {
                [(ToolView*)[self.view viewWithTag:TOOLVIEWTAG] changeTitleOfSelectAll];
            }
            [cell changeSelectImage:NO];
        }
        else
        {
            [downloadOrDeleteArray addObject:info];
            [cell changeSelectImage:YES];
            BOOL selectAll = [downloadOrDeleteArray count]==[tableData count] ? YES : NO;
            if (selectAll)
            {
                [(ToolView*)[self.view viewWithTag:TOOLVIEWTAG] changeTitleOfSelectAll];
            }
        }
    }
    if ([downloadOrDeleteArray count])
    {
        [self enableToolViewBtn:YES];
    }
    else
    {
        [self enableToolViewBtn:NO];
    }

}
- (void)eidtStatusSelected:(NSIndexPath *)token andCell:(PCFileCell *)cell
{
    [self changeCellSelectedIamge:token cell:cell isSelected:YES];
}
/**
 * 打开工具cell
 * @param  allCellsIsClose  所有的cell是否都是关闭的
 * @param  otherCellIsOpen  操作的cell以外的cell是否有打开的
 */
- (void)didSelectCellRow:(BOOL)allCellsIsClose otherCellIsOpen:(BOOL)selectedCellIsClose currentIndexPath:(NSIndexPath *) currentIndexPath;
{
    @synchronized(self.selectIndexPath)
    {
//        NSMutableArray *currentData = isSearchDisplay?filteredListContent:tableData;
//        if (selectIndexPath.section < currentData.count)
//        {
//            if (currentFileInfo) {
//                [currentFileInfo release];
//            }
//            currentFileInfo = [[currentData objectAtIndex:selectIndexPath.section] retain];
//        }
        
        self.isOpen = allCellsIsClose;
        UITableView *currentTable = isSearchDisplay?self.searchDisplayController.searchResultsTableView:tableView;
        
        //PCFileCell *cell = (PCFileCell *)[currentTable cellForRowAtIndexPath:self.selectIndexPath];
        UITableViewCell *cell = (UITableViewCell *)[currentTable cellForRowAtIndexPath:self.selectIndexPath];
        if (cell  && [cell isKindOfClass:[PCFileCell class]]) {
            [(PCFileCell*)cell changeArrowImageWithExpansion:allCellsIsClose];
        }
        
        
        [currentTable beginUpdates];
        
        int section = self.selectIndexPath.section;
        NSMutableArray* rowToInsert = [[NSMutableArray alloc] init];
        NSIndexPath* indexPathToInsert = [NSIndexPath indexPathForRow:1 inSection:section];
        [rowToInsert addObject:indexPathToInsert];
        if (allCellsIsClose)
        {
            [currentTable insertRowsAtIndexPaths:rowToInsert withRowAnimation:UITableViewRowAnimationTop];
        }
        else
        {
            [currentTable deleteRowsAtIndexPaths:rowToInsert withRowAnimation:UITableViewRowAnimationNone];
            currentTable.contentSize = CGSizeMake(currentTable.contentSize.width, currentTable.contentSize.height-TABLE_CELL_HEIGHT);
        }
        
        [rowToInsert release];
        
        [currentTable endUpdates];
        
//        [self resetEGOFrame];
//        UITableViewCell *cell1 = [currentTable cellForRowAtIndexPath:indexPathToInsert];
//        if (cell1)
//        {
//            if (cell1.frame.origin.y+cell1.frame.size.height > _refreshHeaderView.frame.origin.y)
//            {
//                _refreshHeaderView.frame = CGRectMake(_refreshHeaderView.frame.origin.x, cell1.frame.origin.y+cell1.frame.size.height, _refreshHeaderView.frame.size.width, _refreshHeaderView.frame.size.height);
//            }
//        }
        if (selectedCellIsClose)
        {
            self.isOpen = YES;
            self.selectIndexPath = [currentIndexPath retain];
            [currentIndexPath release];
            [self didSelectCellRow:YES otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];
        }
        
        if (self.isOpen)
        {
            UITableViewCell *cell = [currentTable cellForRowAtIndexPath:selectIndexPath];
            
            //当前滚动到的位置
            CGFloat deltaY = currentTable.contentOffset.y;
            //cell的位置
            CGPoint position = CGPointMake(0, cell.frame.origin.y + cell.frame.size.height*2 - 5 );
            //tableview的高度
            CGFloat height = currentTable.frame.size.height;
            
            //偏移量
            CGFloat offsetY;
            
            if (position.y - deltaY >= height)
            {
                offsetY = position.y - height - deltaY ;
                
            }
            else
            {
                offsetY = 0;
            }
            
            [currentTable setContentOffset:CGPointMake(0, offsetY + deltaY) animated:YES];
        }
    }
}


#pragma mark - PCFileExpansionCell delegate
- (void)shareButtonClick
{
    NSMutableArray *currentData = isSearchDisplay?filteredListContent:tableData;
    
    PCFileInfo *fileInfo = [currentData objectAtIndex:self.selectIndexPath.section];
    
    if ([fileInfo.path isKindOfClass:[NSNull class]])
    {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"NotExist", nil) delegate:nil];
        
        return;
    }
    if (!(fileInfo.bFileFoldType) && [fileInfo.size longLongValue] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"ShareEmptyFile", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    if (!shareUrl)
        shareUrl = [[PCShareUrl alloc] init];
    
    [shareUrl shareFileWithInfo:fileInfo andDelegate:self];
    
}

- (void)collectButtonClick
{
    //xy add 收藏时没有网络弹出提示框
    if (![PCUtility isNetworkReachable:self]) {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"OpenNetwork", nil) delegate:nil];
        return;
    }
    
    NSMutableArray *currentData = isSearchDisplay?filteredListContent:tableData;
    PCFileInfo *fileInfo = [currentData objectAtIndex:self.selectIndexPath.section];
    fileCache = [[FileCache alloc] init];
    fileCache.currentDeviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
    [MobClick event:UM_FAVOURITE label:fileInfo.ext];
    if ([fileInfo.size longLongValue] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"CollectEmptyFile", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    //若文件先缓存了，则收藏时判断是否在Caches文件夹里，在的话把该文件从Caches文件夹移到Download文件夹，并更新数据库
    else if([fileCache GetFuLLSizeFileFromCacheWithFileInfo:fileInfo withType:TYPE_CACHE_FILE] && [PCUtilityFileOperate moveCacheFileToDownload:fileInfo.path
                                                                                                                                       fileSize:[fileInfo.size longLongValue]
                                                                                                                                      fileCache:fileCache
                                                                                                                                       fileType:TYPE_CACHE_FILE])
    {
        [PCUtilityUiOperate showHasCollectTip:fileInfo.name];
    }
    else
    {
        [[PCUtilityFileOperate downloadManager] addItem:fileInfo.path fileSize:[fileInfo.size longLongValue] modifyGTMTime:[fileInfo. modifyTime longLongValue]];
        if (isSearchDisplay) {
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
        else{
            [self.tableView reloadData];
        }
    }
    
    [fileCache release];
    fileCache = nil;
}

- (void)cancelCollectButtonClick
{
    UIAlertView *Alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"isCancelCollect", nil)
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    Alert.tag = CANCEL_COLLECT_TAG;
    [Alert show];
    [Alert release];
}

- (void)deleteButtonClick:(PCFileExpansionCell *)cell
{
    //    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"确定删除云盘文件?\n(此操作会删除帐号下云盘中的相应文件)"
    //                                                             delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    //	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    //    actionSheet.tag =SHEETVIEWTAG;
    //    [actionSheet showFromTabBar:self.tabBarController.tabBar];
    //
    //	[actionSheet release];
    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"确定删除云盘文件?\n(此操作会删除帐号下云盘中的相应文件)"
                                                          message:nil
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    deleteAlert.tag = DELETE_FOLDER_TAG;
    [deleteAlert show];
    [deleteAlert release];
}

- (void)reNameButtonClick:(PCFileExpansionCell *)cell
{
    PCFileInfo *fileInfo = (self.searchDisplayController.isActive)?[self.filteredListContent objectAtIndex:self.selectIndexPath.section]:[tableData objectAtIndex:self.selectIndexPath.section];
    UIAlertView * inputAnswerAlert = [[UIAlertView alloc] initWithTitle:fileInfo.bFileFoldType ? @"重命名文件夹" : @"重命名文件"
                                                                message:fileInfo.bFileFoldType ? @"请输入新的文件夹名称" : @"请输入新的文件名"
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                      otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    inputAnswerAlert.tag = RENAME_FOLDER_TAG;
    inputAnswerAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [inputAnswerAlert textFieldAtIndex:0];
    textField.text= fileInfo.name;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.tag = RENAME_FOLDER_TEXTFIELD_TAG;
    [inputAnswerAlert show];
    [inputAnswerAlert release];
}

#pragma mark - Notification key:RefreshTableView
- (void)refreshTableView:(NSNotification*)notification
{
    [isSearchDisplay ? self.searchDisplayController.searchResultsTableView : tableView reloadData];
    //    [self reloadTableViewDataSource];
}

#pragma mark - public methods

- (void) getList {
    if (restClient == nil) {
        restClient = [[PCRestClient alloc] init];
        restClient.delegate = self;
    }
    
    _reloading = YES;//加载阶段    禁止点开cell.
    isFirstResult = YES;
    isNetworkError = NO;
    
    [lblResult setHidden:YES];
    
    UIBarButtonItem *tmp = [self.navigationItem.rightBarButtonItems objectAtIndex:0];
    UIButton *refreshImg = (UIButton *)tmp.customView;
    
    if (self.searchDisplayController.isActive)
    {
        [self getSearchList];
    }
    else {
        [PCUtilityUiOperate animateRefreshBtn:refreshImg];
        refreshImg.enabled = NO;
        [self getFileList];
    }
}

- (void) getFileList
{
    isFinish = NO;
    NSInteger count = 0;
    if ([tableData count]>=1 && [[tableData objectAtIndex:0] isKindOfClass:[NSString class]])
    {
        count = [tableData count] - 1;
    }
    
    NSString *start = [NSString stringWithFormat:@"%d",isRefresh ? 0 : count];
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:dirPath,@"parentDir",start,@"start",LIMIT,@"limit", nil];
    self.currentRequest = [restClient getFileListInfoByPage:dic];
}

- (void) getSearchList {
    if (!fileSearch)
        fileSearch = [[FileSearch alloc] init];
    [fileSearch searchFile:dirPath key:keyWord delegate:self];
}

- (void) startProcess {
    isProcessing = YES;
}

- (void) endProcess {
    isProcessing = NO;
}

- (void) cancelProcess {
    if (isProcessing) {
        if (fileCache) {
            if (fileCache.localPath) {
                [PCUtilityFileOperate deleteFile:fileCache.localPath];
                [FileCache deleteDownloadFile:fileCache.localPath];
            }
            [fileCache cancel];
            [fileCache release];
            fileCache = nil;
        }
        [self endProcess];
    }
    
    if (self.currentRequest) {
        [self doneLoadingTableViewData];
        isRefresh = NO;
        [restClient cancelRequest:self.currentRequest];
        self.currentRequest = nil;
        isFinish = YES;
    }
}

- (void) showProgressView {
    //    [self progressingViewRelease];
    progressingViewController = [[PCProgressingViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"PCProgressingView"] bundle:nil];
    [self.view.window addSubview:progressingViewController.view];
}

#pragma mark - UISearchDisplayDelegate Mehtods
- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    if (self.selectIndexPath)
    {
        self.isOpen = NO;
        [self didSelectCellRow:NO otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];
        self.selectIndexPath = nil;
    }
    if (self.thumbImgFileCache) {
        self.thumbImgFileCache.delegate = nil;
        [self.thumbImgFileCache cancel];
    }
}

- (void) searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    [self.tableView reloadData];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadNewestThumbImage) object:nil];
    [self performSelector:@selector(loadNewestThumbImage)];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView
{
    isSearchDisplay = YES;
    self.searchDisplayController.searchResultsTableView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    
    self.filteredListContent = [NSMutableArray arrayWithObjects: @"",@"", nil];
    [self.searchDisplayController.searchResultsTableView reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:nil];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView;
{
    if (self.thumbImgFileCache) {
        self.thumbImgFileCache.delegate = nil;
        [self.thumbImgFileCache cancel];
    }
    if (self.selectIndexPath)
    {
        self.isOpen = NO;
        //[self didSelectCellRow:NO otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];
        self.selectIndexPath = nil;
    }
    [self.tableView reloadData];

}
- (void) keyboardWillHide {
    
    UITableView *table = [[self searchDisplayController] searchResultsTableView];

    [table setContentInset:UIEdgeInsetsZero];
    
    [table setScrollIndicatorInsets:UIEdgeInsetsZero];
    
}
- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    isSearchDisplay = NO;
    
    if (fileSearch) {
        fileSearchCancel =    [[FileSearch alloc] init];
        [fileSearchCancel searchCancelWithdelegate:self  andSerchID:[fileSearch currentSearchID]];
        [PCUtilityUiOperate showOKAlert: NSLocalizedString(@"SearchBeCancel", nil) delegate:self];
        [fileSearch cancel];
        [fileSearch release];
        fileSearch = nil;
    }
    if ([self.view viewWithTag:SEARCH_DICTATOR_TAG]) {
        [[self.view viewWithTag:SEARCH_DICTATOR_TAG] removeFromSuperview];
    }
    
    [self.filteredListContent removeAllObjects];
    [self.historyfilteredListContent removeAllObjects];
    [dicatorView stopAnimating];
    
    if (tableData && (tableData.count>0)) {
        [lblResult setHidden:YES];
        
        if ([tableData count]==1)//表示没有数据
        {
            
            if (!controller.isActive)
            {
                self.tableView.frame = CGRectMake(0, self.tableView.frame.origin.y-searchBar.frame.size.height, self.tableView.bounds.size.width, self.tableView.bounds.size.height);
                UIView *view = [self noContentView];
                [self.view addSubview:view];
                self.tableView.scrollEnabled = NO;
            }

        }
    }
    else
    {
        //[lblResult setHidden:NO];
    }
}

#pragma mark - ELCImagePickerControllerDelegate methods

- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    NSMutableArray *addFileArr = [NSMutableArray arrayWithCapacity:info.count];
    
    [info enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop){
        
        NSString *imageName = dict[@"imageName"];
        NSString *url = [dict[UIImagePickerControllerReferenceURL] absoluteString];
        NSString *path = [dirPath stringByAppendingPathComponent:imageName];
        NSNumber *size = dict[@"imageSize"];
        NSString *diskName = [dirName stringByAppendingPathComponent:imageName];
        NSString *deviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
        NSString *deviceName = [[PCSettings sharedSettings] currentDeviceName];
        NSNumber *status = @(waitUploadStatus);
        NSDate *uploadTime = [NSDate date];
        NSString *userID = [[PCSettings sharedSettings] userId];
        
        //上传数据结构
        NSManagedObjectContext *context = [PCUtilityDataManagement managedObjectContext];
        FileUploadInfo *fileUploadInfo = [NSEntityDescription insertNewObjectForEntityForName:@"FileUploadInfo"
                                                                       inManagedObjectContext:context];
        [fileUploadInfo setDeviceID:deviceID];
        [fileUploadInfo setDeviceName:deviceName];
        [fileUploadInfo setDiskName:diskName];
        [fileUploadInfo setFileSize:size];
        [fileUploadInfo setUploadTime:uploadTime];
        [fileUploadInfo setAssetUrl:url];
        [fileUploadInfo setHostPath:path];
        [fileUploadInfo setStatus:status];
        [fileUploadInfo setUser:userID];
        
        [PCUtilityDataManagement saveInfos];
        
        [addFileArr addObject:fileUploadInfo];
    }];
    
    [[FileUploadManager sharedManager] addNewFileUploadInfos:addFileArr];
    
    if (IS_IPAD)
    {
        [self deletePopover];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UISearchBarDelegate Mehtods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText  // called when text changes (including clear)
{
    //有搜索结果数据，并且当前搜索框内容包含上次搜索关键字
    BOOL hasResults = ([historyfilteredListContent count]>0)&&[[self.historyfilteredListContent objectAtIndex:0] isKindOfClass:[PCFileInfo class]];
    BOOL hasResults2 = ([filteredListContent count]>0)&&[[self.filteredListContent objectAtIndex:0] isKindOfClass:[PCFileInfo class]];
    
    if ((self.keyWord  && searchText)
        &&(hasResults2||hasResults)
        &&([searchText  rangeOfString:self.keyWord options:NSCaseInsensitiveSearch].length == [self.keyWord length]))
    {
        NSMutableArray *newArray =[NSMutableArray array];
        if (!historyfilteredListContent || ([historyfilteredListContent count]==0)) {
            self.historyfilteredListContent = [NSMutableArray array];
            for (PCFileInfo *fileInfo in self.filteredListContent)
            {
                [historyfilteredListContent addObject:fileInfo];
            }
        }
        for (PCFileInfo *fileInfo in self.historyfilteredListContent)
        {
            NSString *name = fileInfo.name;
            if ([name  rangeOfString:searchText options:NSCaseInsensitiveSearch].length == [searchText length]) {
                [newArray addObject:fileInfo];
            }
        }
        self.filteredListContent = newArray;
        [self.searchDisplayController.searchResultsTableView reloadData];
        return;
    }
    if(!([self.filteredListContent count] ==2
         &&[[self.filteredListContent objectAtIndex:1] isKindOfClass:[NSString class]]
         && [[self.filteredListContent objectAtIndex:1] isEqualToString:@"点击搜索按钮进行搜索"]))
    {
        self.filteredListContent = [NSMutableArray arrayWithObjects: @"",@"点击搜索按钮进行搜索", nil];
    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)_searchBar
{
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *searchText = [_searchBar.text stringByTrimmingCharactersInSet:set];
    
    if (!searchText || searchText.length < 2) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"InvalidSearchLength", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    //搜索前停止上一个搜索。
    if (fileSearch) {
        fileSearchCancel =    [[FileSearch alloc] init];
        [fileSearchCancel searchCancelWithdelegate:self  andSerchID:[fileSearch currentSearchID]];
        [fileSearch cancel];
        [fileSearch release];
        fileSearch = nil;
    }
    if ([self.view viewWithTag:SEARCH_DICTATOR_TAG]) {
        [[self.view viewWithTag:SEARCH_DICTATOR_TAG] removeFromSuperview];
    }
    //fix bug 56988
    self.selectIndexPath = nil;
    self.isOpen = NO;
    [self.historyfilteredListContent removeAllObjects];
    self.filteredListContent = [NSMutableArray arrayWithObjects:@"",@"搜索中",nil];
    [self.searchDisplayController.searchResultsTableView reloadData];
    
    
    self.dirPath = dirPath;
    self.keyWord = searchText;
    
    UIActivityIndicatorView *searchDictator = [[UIActivityIndicatorView alloc]
                                               initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    searchDictator.tag = SEARCH_DICTATOR_TAG;
    searchDictator.color = [UIColor grayColor];
    
    //[self.searchDisplayController.searchResultsTableView addSubview:searchDictator];
    [self.view addSubview:searchDictator];
    [self.view bringSubviewToFront:searchDictator];
    [searchDictator startAnimating];
    [searchDictator release];
    searchDictator.center = self.view.center;
    //[self.view bringSubviewToFront:dicatorView];
    
    [self getList];
    //[self.navigationController pushViewController:fileListView animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)_searchBar
{
    //修改ios7下 取消搜索crash的问题，这里设置searchbar的文本在ios7下引发了tableview的reload过程，过程中 tableview的数据源又有过清理，所以crash。现在去掉这行。
    //searchBar.text = @"";
    [searchBar resignFirstResponder];
    if ([tableData count]==1)//表示没有数据
    {
        [tableView reloadData];
        UIView *view = [self noContentView];
        [self.view addSubview:view];
        [self resetTableViewFrame];
        self.tableView.scrollEnabled = NO;

    }

}

- (void)setNavigationItemByRefresh:(id)sender
{
    UIBarButtonItem *tmp = [self.navigationItem.rightBarButtonItems objectAtIndex:0];
    UIButton *refreshImg = (UIButton *)tmp.customView;
    refreshImg.enabled = NO;
    CAKeyframeAnimation *theAnimation = [CAKeyframeAnimation animation];
    
    theAnimation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeRotation(0,0,0,1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeRotation(3.13,0,0,1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeRotation(6.26,0,0,1)]];
    theAnimation.cumulative =YES;
    theAnimation.removedOnCompletion =YES;
    theAnimation.repeatCount =HUGE_VALF;
    theAnimation.speed = 0.3f;
    
    [refreshImg.layer addAnimation:theAnimation forKey:@"transform"];
    
    //modify by xy bug：54013
    isRefresh = YES;
    isNoMoreData = NO;
    [self cancelThumbImageCache];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadNewestThumbImage) object:nil];
    [self reloadTableViewDataSource];
}

- (void)addPhoto:(id)sender
{
    if (self.popover)
    {
        return;
    }
    
    BOOL bHasPrivacy = [PCUtilityFileOperate checkPrivacyForAlbum];
    
    if (bHasPrivacy)
    {
        ELCAlbumPickerController *albumController = [[ELCAlbumPickerController alloc] init];
        ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] initWithRootViewController:albumController];
        
        albumController.parent = elcPicker;
        elcPicker.delegate = self;
        
        if (IS_IPAD)
        {
            [self showPopover:elcPicker];
        }
        else
        {
            [self.navigationController presentViewController:elcPicker animated:YES completion:NULL];
        }
        
        [elcPicker release];
        [albumController release];
    }
    else
    {
        NSString *nibName = [PCUtilityFileOperate getXibName:@"SettingPhotosPermissionViewController"];
        SettingPhotosPermissionViewController *setPhotoPermission = [[SettingPhotosPermissionViewController alloc] initWithNibName:nibName bundle:nil];
        
        if (IS_IPAD)
        {
            setPhotoPermission.showType = kShowInPopover;
            
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:setPhotoPermission];
            [self showPopover:navController];
            [navController release];
        }
        else
        {
            setPhotoPermission.showType = kShowWhenUpload;
            
            UINavigationController *navController = [[UINavigationController2 alloc] initWithRootViewController:setPhotoPermission];
            [self.navigationController presentViewController:navController animated:YES completion:NULL];
            [navController release];
        }
        
        [setPhotoPermission release];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.popover = nil;
}

#pragma mark
- (void)openFileWithFileInfo:(PCFileInfo*)fileInfo andFileType:(CacheFileType) fileType{
    [dicatorView stopAnimating];
    FileCache *localFileCache = [[[FileCache alloc] init] autorelease];
    localFileCache.currentDeviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
    self.localPath = [localFileCache getCacheFilePath:fileInfo.path
                                             withType:fileType];
    
    [PCUtilityFileOperate openFileAtPath:self.localPath WithBackTitle:self.navigationItem.title andFileInfo:fileInfo andNavigationViewControllerDelegate:self];
}

- (void) shareUrlFail:(NSString*)errorDescription {
    [dicatorView stopAnimating];
    [PCUtilityUiOperate showErrorAlert:errorDescription delegate:nil];
}

- (void) shareUrlStart {
    [self.view  bringSubviewToFront:dicatorView];
    [dicatorView startAnimating];
}

- (void) shareUrlFinish {
    [dicatorView stopAnimating];
}

//----------------------------------------------------------
- (void) searchFileAddObjects:(FileSearch*)fileSearch objects:(NSArray*)objects {
    if ([self.filteredListContent count] ==2
        &&[[self.filteredListContent objectAtIndex:1] isKindOfClass:[NSString class]]
        ) {
        [self.filteredListContent removeAllObjects];
    }
    [filteredListContent addObjectsFromArray:objects];
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void) searchFileFinish:(FileSearch*)_fileSearch {
    _reloading = NO;
    //||后面表示 是开始搜索前的 提示信息数据，并没有搜索到结果数据
    if ((!filteredListContent.count)||([self.filteredListContent count] ==2
                                       &&[[self.filteredListContent objectAtIndex:0] isKindOfClass:[NSString class]]
                                       && [[self.filteredListContent objectAtIndex:0] isEqualToString:@""])) {
        
        self.filteredListContent = [NSMutableArray arrayWithObjects:@"", @"没有找到相关文件。",nil];
    }
    [fileSearch release];
    fileSearch = nil;
    
    [self.searchDisplayController.searchResultsTableView reloadData];
    
    if ([self.view viewWithTag:SEARCH_DICTATOR_TAG]) {
        [[self.view viewWithTag:SEARCH_DICTATOR_TAG] removeFromSuperview];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadNewestThumbImage) object:nil];
    [self performSelector:@selector(loadNewestThumbImage) withObject:nil afterDelay:.1];
}

- (void) searchFileFail:(FileSearch*)_fileSearch error:(NSString*)error {
    _reloading = NO;
    [self doFail:error];
    if ((!filteredListContent.count)||([self.filteredListContent count] ==2
                                       &&[[self.filteredListContent objectAtIndex:0] isKindOfClass:[NSString class]]
                                       && [[self.filteredListContent objectAtIndex:0] isEqualToString:@""])) {
        
        self.filteredListContent = [NSMutableArray arrayWithObjects:@"", @"没有找到相关文件。",nil];
    }
    
    [fileSearch release];
    fileSearch = nil;
    
    [self.searchDisplayController.searchResultsTableView reloadData];
    
    if ([self.view viewWithTag:SEARCH_DICTATOR_TAG]) {
        [[self.view viewWithTag:SEARCH_DICTATOR_TAG] removeFromSuperview];
    }
}

- (void) searchCancelFail:(FileSearch*)fileSearch error:(NSString*)error
{
    _reloading = NO;
    [fileSearchCancel release];
    fileSearchCancel = nil;
}
- (void) searchCancelFinish:(FileSearch*)fileSearch
{
    _reloading = NO;
    [fileSearchCancel release];
    fileSearchCancel = nil;
}


//-----------------------------------------------------------

- (void) doFail:(NSString*)error {
    isFinish = YES;
    isNetworkError = YES;
    [dicatorView stopAnimating];
    [self doneLoadingTableViewData];
    if (error) {
        [PCUtilityUiOperate showErrorAlert:error delegate:nil];
    }
}

//----------------------------------------------------------
#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
    if(!self.searchDisplayController.isActive)//文件夹文件列表有下拉刷新（分页），搜索部分不用下拉刷新。
    {
        if (self.selectIndexPath)
        {
            self.isOpen = NO;
            [self didSelectCellRow:NO otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];
            self.selectIndexPath = nil;
        }
        
        [dicatorView startAnimating];
        [self getList];
    }
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
	_reloading = NO;
    if (isSearchDisplay) {
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.searchDisplayController.searchResultsTableView];
    }
    else
    {
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    }
    UIBarButtonItem *tmp = [self.navigationItem.rightBarButtonItems objectAtIndex:0];
    UIButton *refreshImg = (UIButton *)tmp.customView;
    
    [refreshImg.layer removeAllAnimations];
    refreshImg.enabled = YES;
    [dicatorView stopAnimating];
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods and cache thumb image methods
- (NSString*)getLocalThumbImageRootPath
{
    //    FileCache *vfileCache = [[FileCache alloc] init];
    //    vfileCache.currentDeviceID = [PCLogin getResource];
    //    NSString *filePath = [vfileCache getCacheFilePath:self.navigationItem.title withType:TYPE_CACHE_THUMBIMAGE];
    //    [vfileCache release];
    NSString *str = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingFormat:@"/Caches/%@/ThumbImage/",[PCLogin getResource]];
    return str;
}
- (void)reloadCell:(NSArray *)array
{
    if (![array count])
    {
        return;
    }
    UITableView *currentTable = [self.searchDisplayController isActive] ? self.searchDisplayController.searchResultsTableView : self.tableView;
    if ([[NSSet setWithArray:array] intersectsSet:[NSSet setWithArray:[currentTable indexPathsForVisibleRows]]])
    {
        [currentTable beginUpdates];
        [currentTable reloadRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationNone];
        [currentTable endUpdates];
    }
}

-(void)cacheThumbImageWithPath:(NSString *)path andIndexPath:(NSIndexPath *)indexPath
{
    if (![PCLogin getResource] && !isRefresh)
    {
        return;
    }
    self.thumbImgFileCache = [[[FileCache alloc] init] autorelease];
    self.thumbImgFileCache.currentDeviceID = [PCLogin getResource];
    self.thumbImgFileCache.index = indexPath.section;
    self.thumbImgFileCache.isRemoveWhenCancel = YES;
//    NSString *urlStr = [[NSString alloc] initWithFormat:@"GetThumbImage?path=%@&width=82&height=82",
//                        [PCUtilityStringOperate encodeToPercentEscapeString:path]];
//    self.thumbImgFileCache.url = urlStr;
//    [urlStr release];
//    NSLog(@"%@",self.thumbImgFileCache.url);
    [self.thumbImgFileCache cacheFile:path viewType:TYPE_CACHE_THUMBIMAGE viewController:self fileSize:-1 modifyGTMTime:0 showAlert:YES];
}

-(void)cacheFileFinish:(FileCache *)vfileCache
{
    if (vfileCache.viewType == TYPE_CACHE_THUMBIMAGE)
    {
        if (isCoveredByPushing) {
            return;
        }
        UITableView *currentTable = [self.searchDisplayController isActive] ? self.searchDisplayController.searchResultsTableView : self.tableView;
        if ([currentTable numberOfSections] > vfileCache.index) {
            [currentTable beginUpdates];
            [currentTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:vfileCache.index]] withRowAnimation:UITableViewRowAnimationNone];
            [currentTable endUpdates];
        }
        
        if ([needLoadThumbImageArray count])
        {
            [needLoadThumbImageArray removeObjectAtIndex:0];
            if ([needLoadThumbImageArray count])
            {
                [self loadVisibleThumbImageWithIndex:[needLoadThumbImageArray objectAtIndex:0]];
            }
        }
    }
}

-(void)cacheFileFail:(FileCache *)fileCache hostPath:(NSString *)hostPath error:(NSString *)error
{
    if ([needLoadThumbImageArray count])
    {
        [needLoadThumbImageArray removeObjectAtIndex:0];
        if ([needLoadThumbImageArray count])
        {
            [self loadVisibleThumbImageWithIndex:[needLoadThumbImageArray objectAtIndex:0]];
        }
    }
}

-(void)loadVisibleThumbImageWithIndex:(NSIndexPath *)indexPath
{
    
    if (isCoveredByPushing || self.tableView.editing) {
        return;
    }
    UITableView *currentTable = [self.searchDisplayController isActive] ? self.searchDisplayController.searchResultsTableView : self.tableView;
    NSMutableArray *currentData = [self.searchDisplayController isActive] ? filteredListContent : tableData;
    if (![currentData count] || [currentData count]<= indexPath.section) {
        return;
    }
    PCFileInfo *fileInfo = [currentData objectAtIndex:indexPath.section];
    NSString *path = [[self getLocalThumbImageRootPath] stringByAppendingPathComponent:fileInfo.path];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSDictionary *atrDic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        BOOL badFile = NO;
        if ([[atrDic objectForKey:NSFileSize] longLongValue]==0)
        {
            badFile = YES;
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
        
        if ([needLoadThumbImageArray count] && !badFile)
        {
            if (isCoveredByPushing || isRefresh) {
                return;
            }
            [currentTable beginUpdates];
            [currentTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationNone];
            [currentTable endUpdates];
   
            [needLoadThumbImageArray removeObjectAtIndex:0];
        }
        if ([needLoadThumbImageArray count] && !isRefresh)
        {
            [self loadVisibleThumbImageWithIndex:[needLoadThumbImageArray objectAtIndex:0]];
        }
        
        return;
    }

    if (!isRefresh)
    {
        [self cacheThumbImageWithPath:fileInfo.path andIndexPath:indexPath];
    }
}

-(void)cancelThumbImageCache
{
    if (self.thumbImgFileCache)
    {
        self.thumbImgFileCache.delegate = nil;
        [self.thumbImgFileCache cancel];
    }
    if ([needLoadThumbImageArray count]) {
        NSIndexPath *indexPath = [[needLoadThumbImageArray objectAtIndex:0] copy];
        NSMutableArray *currentData = [self.searchDisplayController isActive] ? filteredListContent : tableData;
        if (![currentData count]) {
            [indexPath release];
            return;
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
                       {
                           PCFileInfo *fileInfo = nil;
                           //fix bug 57034  添加 ＝
                           if (indexPath.section>=[currentData count])
                           {
                               [indexPath release];
                               return;
                           }
                           else{
                               if ([[currentData objectAtIndex:indexPath.section] isKindOfClass:[NSDictionary class]]) {
                                   fileInfo = [currentData objectAtIndex:indexPath.section];
                                   NSString *path =[[self getLocalThumbImageRootPath] stringByAppendingPathComponent:fileInfo.path];
                                   if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                                       [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                                   }
                               }
                           }
                           [indexPath release];
                       });
    }
}

-(void)loadNewestThumbImage
{
    [self cancelThumbImageCache];
    isScrolling = NO;
    //加载缩略图
    [needLoadThumbImageArray removeAllObjects];
    UITableView *currentTable = [self.searchDisplayController isActive] ? self.searchDisplayController.searchResultsTableView : self.tableView;
    NSMutableArray *currentData = [self.searchDisplayController isActive] ? filteredListContent : tableData;
    NSArray *array = currentTable.indexPathsForVisibleRows;
    
    if ([currentData count]==0) {
        return;
    }
    for (NSIndexPath *indexPath in array)
    {
        if ([[currentData objectAtIndex:indexPath.section] isKindOfClass:[PCFileInfo class]])
        {
            PCFileInfo *fileInfo = [currentData objectAtIndex:indexPath.section];
            if(fileInfo.mFileType == PC_FILE_IMAGE)
            {
                [needLoadThumbImageArray addObject:indexPath];
            }
        }
    }
    if ([needLoadThumbImageArray count] && !self.tableView.editing)
    {
        [self loadVisibleThumbImageWithIndex:[needLoadThumbImageArray objectAtIndex:0]];
    }
    else
        return;
    
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    isScrolling = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadNewestThumbImage) object:nil];
    [self cancelThumbImageCache];
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollViewDidEndScrollingAnimation:) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadNewestThumbImage) object:nil];
    if (isCoveredByPushing) {
        return;
    }
    [self performSelector:@selector(loadNewestThumbImage)];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollViewDidEndScrollingAnimation:) object:nil];
    //enshore that the end of scroll is fired because apple are twats...
    [self performSelector:@selector(scrollViewDidEndScrollingAnimation:) withObject:nil afterDelay:0.3];
	if (isFinish && !isProcessing && !self.searchDisplayController.isActive && !self.tableView.isEditing)
    {
        [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
        if (isNoMoreData)
        {
            _refreshHeaderView.state = EGONOMoreData;
        }
    }
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	if (isFinish && !isProcessing && !self.searchDisplayController.isActive && !self.tableView.isEditing)
    {
        
        if (isNoMoreData)
        {
            _refreshHeaderView.state = EGONOMoreData;
        }
        else
        {
            [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
        }
    }
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	
	[self reloadTableViewDataSource];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	
	return _reloading; // should return if data source model is reloading
	
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	
	return [NSDate date]; // should return date data source was last changed
	
}

#pragma mark -
-(void)goBindBox
{
    [MobClick event:UM_SETTING_ACTIVATE];
    ActivateBoxViewController *vc = [[ActivateBoxViewController alloc] initWithNibName:@"ActivateBoxViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

-(UIView *)noBoxFoundOrNoContent:(BOOL)noContent
{
    [self enableEidtBtn:NO];
    if (noContent)
    {
        [self resetTableViewFrame];
        tableView.scrollEnabled = NO;
    }
    [dicatorView stopAnimating];
    int scale = IS_IPAD ? 2 : 1;
    if (noContent)
    {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    BOOL isLandScape = [[UIApplication sharedApplication] statusBarOrientation] > UIDeviceOrientationPortraitUpsideDown;
    CGFloat headY = self.tableView.frame.origin.y + TABLE_CELL_HEIGHT;
    if (!noContent) {
        headY = 0;
    }
    if (noContent && !IS_IPAD)
    {
        headY = self.tableView.frame.origin.y;
    }
    CGFloat w = isLandScape ? [UIScreen mainScreen].bounds.size.height : [UIScreen mainScreen].bounds.size.width;
    CGFloat h = isLandScape ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height;
    
    CGRect rect = CGRectMake(0, headY, w, h);
    UIView *headView = [[UIView alloc] initWithFrame:rect];
    headView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [headView setBackgroundColor:[UIColor colorWithRed:226.0f/255.0f green:236.0f/255.0f blue:243.0f/255.0f alpha:1.0f]];
    headView.tag = NOCONTERNVIEWTAG;
    UIImage *emptyImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"empty" ofType:@"png"]];
    UIImageView *emptyImageView = [[UIImageView alloc] initWithImage:emptyImage];
    emptyImageView.tag = ImageTag;
    CGFloat offset =  (isLandScape ? 200 : 300) - ( noContent ? TABLE_CELL_HEIGHT : 0);
    emptyImageView.center = CGPointMake(self.view.center.x, offset);
    [headView addSubview:emptyImageView];
    [emptyImageView release];
    
    UILabel *noBoxLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 80)];
    [noBoxLabel setTextColor:[UIColor blackColor]];
    noBoxLabel.tag = LabelTitleTag;
    noBoxLabel.numberOfLines = 2;
    [noBoxLabel setBackgroundColor:[UIColor clearColor]];
    [noBoxLabel setTextAlignment:NSTextAlignmentCenter];
    [headView addSubview:noBoxLabel];
    noBoxLabel.text = noContent ? NSLocalizedString(@"TeacherTellUsNoEmpty", nil) : NSLocalizedString(@"NotFoundYourBoxs", nil);
    noBoxLabel.center = CGPointMake(self.view.center.x, emptyImageView.frame.origin.y+emptyImageView.frame.size.height+27*scale);
    
    UILabel *lblDes = nil;
    UIButton *goBind =nil;
    if (noContent)
    {
        CGFloat height = noContent ? 60 :30;
        lblDes = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, self.view.frame.size.width-40, height)];
        [lblDes setTextColor:[UIColor grayColor]];
        lblDes.tag = LabelDesTag;
        [lblDes setBackgroundColor:[UIColor clearColor]];
        [lblDes setTextAlignment:NSTextAlignmentCenter];
        lblDes.numberOfLines = 3;
        lblDes.text = NSLocalizedString(@"PopoCloudEmbarrassed", nil);
        [headView addSubview:lblDes];
        [lblDes release];
    }
    else
    {
        goBind = [UIButton buttonWithType:UIButtonTypeCustom];
        [goBind setTitle:NSLocalizedString(@"GoBind", nil) forState:UIControlStateNormal];
        [goBind setTitleColor:[UIColor colorWithRed:66.0/255.0 green:126.0/255.0 blue:176.0/255.0  alpha:1.0] forState:UIControlStateNormal];
        goBind.frame = CGRectMake(0, 0, 200, 200);
        [goBind setBackgroundColor:[UIColor clearColor]];
        [goBind addTarget:self action:@selector(goBindBox) forControlEvents:UIControlEventTouchUpInside];
        [headView addSubview:goBind];
        goBind.tag = LabelDesTag;
    }
    
    
    if (IS_IPAD)
    {
        [noBoxLabel setFont:[UIFont systemFontOfSize:30]];
        if (lblDes)
        {
            [lblDes setFont:[UIFont systemFontOfSize:26]];
            lblDes.center = CGPointMake(self.view.center.x, noBoxLabel.frame.origin.y+noBoxLabel.frame.size.height+70*scale);
        }
        if (goBind)
        {
            goBind.titleLabel.font = [UIFont boldSystemFontOfSize:26];
            goBind.center = CGPointMake(self.view.center.x, isLandScape ? 481.5 : 581.5);
        }
    }
    else
    {
        emptyImageView.center = CGPointMake(self.view.center.x, 55+emptyImage.size.height/2);
        noBoxLabel.center = CGPointMake(self.view.center.x, emptyImageView.frame.origin.y+emptyImageView.frame.size.height+27*scale);
        [noBoxLabel setFont:[UIFont systemFontOfSize:15]];
        if (lblDes)
        {
            [lblDes setFont:[UIFont systemFontOfSize:13]];
            lblDes.center = CGPointMake(self.view.center.x, noBoxLabel.frame.origin.y+noBoxLabel.frame.size.height+35*scale);
        }
        if (goBind)
        {
            goBind.titleLabel.font = [UIFont boldSystemFontOfSize:13];
            goBind.center = CGPointMake(self.view.center.x, 277);
        }
        
    }
    [noBoxLabel release];
    return [headView autorelease];
}

-(UIView *)noContentView
{
    [self enableEidtBtn:NO];
    [self resetTableViewFrame];
    int scale = IS_IPAD ? 2 : 1;
    BOOL isLandScape = [[UIApplication sharedApplication] statusBarOrientation] > UIDeviceOrientationPortraitUpsideDown;
    CGFloat headY = self.tableView.frame.origin.y + TABLE_CELL_HEIGHT;
    
    CGFloat w = isLandScape ? [UIScreen mainScreen].bounds.size.height : [UIScreen mainScreen].bounds.size.width;
    CGFloat h = isLandScape ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height;
    
    CGRect rect = CGRectMake(0, headY, w, h);
    UIView *headView = [[UIView alloc] initWithFrame:rect];
    headView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [headView setBackgroundColor:[UIColor colorWithRed:226.0f/255.0f green:236.0f/255.0f blue:243.0f/255.0f alpha:1.0f]];
    headView.tag = NOCONTERNVIEWTAG;
    UIImage *emptyImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"empty" ofType:@"png"]];
    UIImageView *emptyImageView = [[UIImageView alloc] initWithImage:emptyImage];
    emptyImageView.tag = ImageTag;
    CGFloat offset =  (isLandScape ? 200 : 300)-TABLE_CELL_HEIGHT;
    emptyImageView.center = CGPointMake(self.view.center.x, offset);
    [headView addSubview:emptyImageView];
    [emptyImageView release];
    
    CGFloat height = 120;
    UILabel *noBoxLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 40*scale)];
    noBoxLabel.numberOfLines = 2;
    [noBoxLabel setTextColor:[UIColor blackColor]];
    noBoxLabel.tag = LabelTitleTag;
    [noBoxLabel setBackgroundColor:[UIColor clearColor]];
    [noBoxLabel setTextAlignment:NSTextAlignmentCenter];
    [headView addSubview:noBoxLabel];
    noBoxLabel.text =  NSLocalizedString(@"TeacherTellUsNoEmpty", nil);
    noBoxLabel.center = CGPointMake(self.view.center.x, emptyImageView.frame.origin.y+emptyImageView.frame.size.height+27*scale);
    
    
    UILabel *lblDes = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, self.view.frame.size.width-40, height)];
    [lblDes setTextColor:[UIColor grayColor]];
    lblDes.tag = LabelDesTag;
    [lblDes setBackgroundColor:[UIColor clearColor]];
    [lblDes setTextAlignment:NSTextAlignmentCenter];
    lblDes.numberOfLines = 3;
    lblDes.text = NSLocalizedString(@"PopoCloudEmbarrassed", nil);
    [headView addSubview:lblDes];
    [lblDes release];
    if (IS_IPAD)
    {
        [noBoxLabel setFont:[UIFont systemFontOfSize:30]];
        if (lblDes)
        {
            [lblDes setFont:[UIFont systemFontOfSize:26]];
            lblDes.center = CGPointMake(self.view.center.x, noBoxLabel.frame.origin.y+noBoxLabel.frame.size.height+70*scale);
        }
    }
    else
    {
        emptyImageView.center = CGPointMake(self.view.center.x,emptyImage.size.height/2);
        noBoxLabel.center = CGPointMake(self.view.center.x, emptyImageView.frame.origin.y+emptyImageView.frame.size.height+27*scale);
        [noBoxLabel setFont:[UIFont systemFontOfSize:15]];
        if (lblDes)
        {
            [lblDes setFont:[UIFont systemFontOfSize:13]];
            lblDes.center = CGPointMake(self.view.center.x, noBoxLabel.frame.origin.y+noBoxLabel.frame.size.height+30*scale);
        }
    }
    [noBoxLabel release];
    return [headView autorelease];
}

//刷新数据，其它页面做删除后(fileInfo  表示删除项)可能通过这个函数来更新当前页面
- (void)refreshFileList:(PCFileInfo*)fileInfo
{
    self.isOpen = NO;
    self.selectIndexPath = nil;
    if(self.searchDisplayController.isActive)//搜索页面通过删除数组中的数据项而更新
    {
        if (fileInfo) {
            int num = self.filteredListContent.count;
            for (int i=0 ;i<num;i++) {
                PCFileInfo *info = [self.filteredListContent objectAtIndex:i];
                if ([fileInfo.path isEqualToString:info.path]) {
                    [self.filteredListContent removeObjectAtIndex:i];
                    break;
                }
            }
        }
        if(filteredListContent.count == 0){
            self.filteredListContent = [NSMutableArray arrayWithObjects:@"", @"没有找到相关文件。",nil];
        }
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
    
    //文件列表 通过刷新网络数据更新
    [dicatorView startAnimating];
    isRefresh = YES;
    [self cancelThumbImageCache];
    [self getFileList];
}
-(void)bindBoxView
{
    if ([self.view viewWithTag:NOCONTERNVIEWTAG])
    {
        [[self.view viewWithTag:NOCONTERNVIEWTAG] removeFromSuperview];
    }
    if (!searchBar.hidden)
    {
        searchBar.hidden = YES;
    }
    [self resetTableViewFrame];
    UIView *view = [self noBoxFoundOrNoContent:NO];
    [self.view addSubview:view];
    self.tableView.scrollEnabled = NO;
}
#pragma mark - PCRestClientDelegate

- (void)restClient:(PCRestClient*)client gotFileListInfo:(NSArray*)fileListInfo
{
    if ([fileListInfo count]<[LIMIT integerValue])
    {
        isNoMoreData = YES;
    }
    else
    {
        isNoMoreData = NO;
    }
    self.currentRequest = nil;
    isFinish = YES;
    [self doneLoadingTableViewData];
    if (isRefresh)//如果是右上角的刷新操作
    {
        [tableData removeAllObjects];
    }
    isRefresh = NO;
    if ([tableData indexOfObject:CREATE_FOLDER_STR] == NSNotFound && !self.tableView.editing)
    {
        [tableData addObject:CREATE_FOLDER_STR];
    }
    
    [tableData addObjectsFromArray:fileListInfo];
    if (([tableData count] > [LIMIT integerValue]) && !self.tableView.editing) {
         _refreshHeaderView.hidden = NO;
    }
    if (([tableData count]==1 && !self.tableView.editing) || [tableData count]==0)//表示没有数据
    {
        if (![self.view viewWithTag:NOCONTERNVIEWTAG])
        {
            if(self.searchDisplayController.isActive)
            {
                //fix bug 57018 当前页面是搜索状态的话，不能隐藏搜索框，放到搜索框消失时做调整位置 和 添加 没有文件的提示的背景图
            }
            else{
                UIView *view = [self noContentView];
                [self.view addSubview:view];
            }
            self.tableView.scrollEnabled = NO;
        }
        [self enableEidtBtn:NO];
    }
    else
    {
        [self enableEidtBtn:YES];
        if ([self.view viewWithTag:NOCONTERNVIEWTAG])
        {
            [[self.view viewWithTag:NOCONTERNVIEWTAG] removeFromSuperview];
        }
        if (searchBar.hidden && !self.tableView.editing) {
            searchBar.hidden = NO;
            [self resetTableViewFrame];
        }
        self.tableView.scrollEnabled = YES;
    }
    [tableView reloadData];
    [self resetEGOFrame];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadNewestThumbImage) object:nil];
    [self performSelector:@selector(loadNewestThumbImage)];
}

- (void)restClient:(PCRestClient*)client getFileListInfoFailedWithError:(NSError*)error
{
    isFinish = YES;
    isRefresh = NO;
    isNoMoreData = NO;
    [self doneLoadingTableViewData];
    
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        isNetworkError = YES;
    }
    [ErrorHandler showErrorAlert:error];
    if (error.code == PC_Err_BoxUnbind)
    {
        [self bindBoxView];
        [PCLogin removeDevice:[PCLogin getResource]];
    }
    if (error.code == PC_Err_NoDisk)
    {
        if ([self.view viewWithTag:NOCONTERNVIEWTAG])
        {
            [[self.view viewWithTag:NOCONTERNVIEWTAG] removeFromSuperview];
        }
        [self.view addSubview:[self noBoxFoundOrNoContent:YES]];
    }

    
    self.currentRequest = nil;
}

- (void)restClient:(PCRestClient*)client gotCreateFolderResultInfo:(NSDictionary*)resultInfo
{
    [self unLockUI];
    self.currentRequest = nil;
    if (self.selectIndexPath) {
        self.isOpen = NO;
        // 有一个是开的 allCellsIsClose = no 当前操作的是开的 selectedCellIsClose = no
        [self didSelectCellRow:NO otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];  //关自己
        self.selectIndexPath = nil;
    }
    
    //创建文件夹成功后 更新数据
    [self refreshFileList:nil];
}

- (void)restClient:(PCRestClient*)client getCreateFolderResultFailedWithError:(NSError*)error
{
    [self unLockUI];
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        isNetworkError = YES;
    }
    if (error.code == PC_Err_LackSpace)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"泡泡云盒子端硬盘空间不足，创建失败" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    else
        [ErrorHandler showErrorAlert:error];
    
    self.currentRequest = nil;
}

- (void)restClient:(PCRestClient*)client deletedPath:(NSDictionary *)resultInfo
{
    //[self unLockUI];
    self.currentRequest = nil;
    if (self.selectIndexPath) {
        self.isOpen = NO;
        if (self.searchDisplayController.isActive) {
            [self.filteredListContent removeObjectAtIndex:self.selectIndexPath.section];
            if(filteredListContent.count == 0){
                self.filteredListContent = [NSMutableArray arrayWithObjects:@"", @"没有找到相关文件。",nil];
            }
            self.selectIndexPath = nil;
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
        else{//修改bug 57011
            [self didSelectCellRow:NO otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];
            self.selectIndexPath = nil;
        }
        
        
        [self resetEGOFrame];
        
        [self refreshFileList:nil];
    }
    
    [self unLockUI];
}

- (void)restClient:(PCRestClient*)client deletePathFailedWithError:(NSError*)error
{
    [self unLockUI];
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        isNetworkError = YES;
    }
    [ErrorHandler showErrorAlert:error];
    self.currentRequest = nil;
    if ([deleteArray count])
    {
        [deleteArray removeAllObjects];
        [self cancelAction];
    }
    
}

- (void)restClient:(PCRestClient*)client reNameFile:(NSDictionary *)resultInfo
{
    self.currentRequest = nil;
    [dicatorView startAnimating];
    if (self.selectIndexPath) {
        self.isOpen = NO;
        if (isSearchDisplay) {
            if ([self.tempNewName rangeOfString:self.searchBar.text options:NSCaseInsensitiveSearch].length >0) {
                PCFileInfo *info = [self.filteredListContent objectAtIndex:self.selectIndexPath.section];
                info.name = self.tempNewName;
                NSString *path =  [info.path stringByDeletingLastPathComponent];
                path = [path stringByAppendingPathComponent:self.tempNewName];
                info.path = path;
                [self.filteredListContent replaceObjectAtIndex:self.selectIndexPath.section withObject:info];
                self.selectIndexPath = nil;
                [self.searchDisplayController.searchResultsTableView reloadData];
            }
            else{
                [self.filteredListContent removeObjectAtIndex:self.selectIndexPath.section];
                self.selectIndexPath = nil;
                if(filteredListContent.count == 0){
                    self.filteredListContent = [NSMutableArray arrayWithObjects:@"", @"没有找到相关文件。",nil];
                }
                [self.searchDisplayController.searchResultsTableView reloadData];
            }
        }
        else{
            [self didSelectCellRow:NO otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];
            self.selectIndexPath = nil;
        }
    }
    
    [self refreshFileList:nil];
    [self unLockUI];
}

- (void)restClient:(PCRestClient*)client reNameFileFailedWithError:(NSError*)error
{
    [self unLockUI];
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        isNetworkError = YES;
    }
    [ErrorHandler showErrorAlert:error];
    self.currentRequest = nil;
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == CACHE_FILE_TAG && buttonIndex == 0) {
        if (fileCache) {
            [fileCache release];
            fileCache = nil;
        }
    }
    if (alertView.tag == XIAZAITAG)
    {
        ignoreDownloaded = buttonIndex == 0;
        [self downloadFile];
        return;
    }
    if (alertView.tag == NoSuitableProgramAlertTag) {
        [self dismissMoviePlayerViewControllerAnimated];
    }
    if (buttonIndex == [alertView firstOtherButtonIndex]) {
        if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput) {
            NSString *folderName = [[[alertView textFieldAtIndex:0] text]  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [self lockUI];
            if (alertView.tag == NEW_FOLDER_TAG) {
                self.currentRequest = [restClient  createFolder:[dirPath stringByAppendingPathComponent:folderName]];
            }
            else if (alertView.tag == RENAME_FOLDER_TAG) {
                
                PCFileInfo *fileInfo = (self.searchDisplayController.isActive)?[self.filteredListContent objectAtIndex:self.selectIndexPath.section]:[tableData objectAtIndex:self.selectIndexPath.section];
                
                if ([folderName isEqualToString:fileInfo.name]) {
                    [self unLockUI];
                }
                else{
                    self.currentRequest = [restClient  reNameFile:fileInfo.path  andNewName:folderName];
                    self.tempNewName = folderName;
                }
            }
        }
        else if (alertView.tag == DELETE_FOLDER_TAG) {
            [self lockUI];
            if (self.tableView.editing)
            {
                totalDeleteCount = 0;
                successDeleteCount = 0;
                [self deleteFile];
            }
            else
            {
                PCFileInfo *fileInfo = (self.searchDisplayController.isActive)?[self.filteredListContent objectAtIndex:self.selectIndexPath.section]:[tableData objectAtIndex:self.selectIndexPath.section];
                self.currentRequest = [restClient  deletePath:fileInfo.path];
            }
        }
        else if (CANCEL_COLLECT_TAG == alertView.tag)
        {
            NSMutableArray *currentData = isSearchDisplay?filteredListContent:tableData;
            PCFileInfo *fileInfo = [currentData objectAtIndex:self.selectIndexPath.section];
            [[PCUtilityFileOperate downloadManager] deleteDownloadItem: fileInfo.path fileStatus:[[PCUtilityFileOperate downloadManager] getFileStatus:fileInfo.path andModifyTime:fileInfo.modifyTime]];
        }
        else if (CACHE_FILE_TAG == alertView.tag)
        {
            NSString *filePath = [fileCache getCacheFilePath:currentFileInfo.path withType:TYPE_CACHE_FILE];
            FileCacheController *cacheController = [[FileCacheController alloc] initWithPath:filePath
                                                                       andFinishLoadingState:NO
                                                                               andDataSource:nil
                                                                        andCurrentPCFileInfo:currentFileInfo
                                                                   andLastViewControllerName:self.navigationItem.title];
            if ([fileCache cacheFile:currentFileInfo.path
                            viewType:TYPE_CACHE_FILE
                      viewController:cacheController
                            fileSize:[currentFileInfo.size longLongValue]
                       modifyGTMTime:[currentFileInfo.modifyTime longLongValue]
                           showAlert:YES])
            {
                cacheController.hidesBottomBarWhenPushed = YES;
                cacheController.title = currentFileInfo.name;
                [self.navigationController pushViewController:cacheController animated:YES];
                [self startProcess];
            }
            [cacheController release];
        }
    }
}

- (void)didPresentAlertView:(UIAlertView *)alertView // after animation
{
    if (alertView.tag == RENAME_FOLDER_TAG) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        PCFileInfo *fileInfo = (self.searchDisplayController.isActive)?[self.filteredListContent objectAtIndex:self.selectIndexPath.section]:[tableData objectAtIndex:self.selectIndexPath.section];
        
        NSString *ext = [fileInfo.name pathExtension];
        int extLen = 0;
        if ([ext length]) {
            extLen = ext.length+1;
        }
        
        UITextPosition *fromPosition = textField.beginningOfDocument;
        UITextPosition *endPosition = [textField positionFromPosition:textField.endOfDocument offset:(-1)*extLen];
        [textField   setSelectedTextRange:[textField textRangeFromPosition:fromPosition toPosition:endPosition]];
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    if (alertView.alertViewStyle != UIAlertViewStylePlainTextInput) {
        return YES;
    }
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    NSString *name = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSUInteger length = [name length];
    NSRange range = [name rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/[\\/:*\"<>?|]"]];
    if (length == 0 )
    {
        return NO;
    }
    else if(range.location!=NSNotFound || [name hasPrefix:@"."])
    {
        [PCUtilityUiOperate showTip :NSLocalizedString(@"InvalidName", nil)];
        return NO;
    }
    else if ([name lengthOfBytesUsingEncoding:NSUTF8StringEncoding] > FILE_NAME_MAX_LENGTH ||
             [dirPath stringByAppendingPathComponent:name].length >= FILE_PATH_MAX_LENGTH)
    {
        if (alertView.visible)
        {
            alertView.delegate = nil;
            [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"CannotCreate", nil) delegate:nil];
            alertView.delegate = self;
        }
        return NO;
    }
    
    return YES;
}

#pragma mark  lock and unlock UI
- (void)lockUI
{
    [dicatorView startAnimating];
    self.view.userInteractionEnabled = NO;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.tabBarController.tabBar.userInteractionEnabled = NO;
}

- (void)unLockUI
{
    [dicatorView stopAnimating];
    self.view.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.tabBarController.tabBar.userInteractionEnabled = YES;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// the user clicked one of the OK/Cancel buttons
	if (buttonIndex == 0)
	{
		[self lockUI];
        PCFileInfo *fileInfo = (self.searchDisplayController.isActive)?[self.filteredListContent objectAtIndex:self.selectIndexPath.section]:[tableData objectAtIndex:self.selectIndexPath.section];
        self.currentRequest = [restClient  deletePath:fileInfo.path];
	}
	else
	{
		//NSLog(@"cancel");
	}
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

-(void)appActive
{
    if ([[PCSettings sharedSettings] screenLock] && IS_IPAD)
    {
        if (self.popover) {
            [self.popover dismissPopoverAnimated:NO];
            hasPopover = YES;
        }
    }
}
-(void)restorePopover
{
    if (hasPopover && IS_IPAD)
    {
        BOOL isLandscape = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
        hasPopover = NO;
        [self.popover presentPopoverFromRect:[self popoverShowRect] inView:self.view permittedArrowDirections:isLandscape ? UIPopoverArrowDirectionRight : UIPopoverArrowDirectionUp animated:YES];
    }
}
- (void)playOnlineMusicWithContentUrl:(NSURL*)contentUrl
{
    MPMoviePlayerViewController *playerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:contentUrl];
    [self presentMoviePlayerViewControllerAnimated:playerViewController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerPlaybackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error:nil];
    
    MPMoviePlayerController *player = [playerViewController moviePlayer];
    [player play];
    [playerViewController release];
}


- (void)playOnlineVedioWithContentUrl:(NSURL*)contentUrl
{
    MPMoviePlayerViewController *playerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:contentUrl];
    [self presentMoviePlayerViewControllerAnimated:playerViewController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerPlaybackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    
    MPMoviePlayerController *player = [playerViewController moviePlayer];
    [player play];
    [playerViewController release];
}
#pragma - mark
#pragma NewFolderAndUpload delegate
- (void) createNewFloder
{
    UIAlertView * inputAnswerAlert = [[UIAlertView alloc] initWithTitle:@"新建文件夹"
                                                                message:@"请输入要新建的文件夹名称"
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                      otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    inputAnswerAlert.tag = NEW_FOLDER_TAG;
    inputAnswerAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [inputAnswerAlert textFieldAtIndex:0];
    
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [inputAnswerAlert show];
    [inputAnswerAlert release];
    
}
- (void) uploadPhoto
{
    [self addPhoto:nil];
}

#pragma mark PCFileOperateDelegate
#pragma --
-(void)removeSomePCFileInfoWhenFileOperateFailed:(FileOperate *)fileOperate
{
    if ([[fileOperate finishedPathArray] count] > 0)
    {
        for (NSString *path in [fileOperate finishedPathArray])
        {
            PCFileInfo *info = nil;
            for (PCFileInfo *object in deleteArray)
            {
                if ([object.path isEqualToString:path])
                {
                    info = object;
                    break;
                }
            }
            [deleteArray removeObject:info];
            [tableData removeObject:info];
        }
        [tableView reloadData];
    }
}
-(void)fileOperateFinished:(FileOperate *)fileOperate//文件操作完成
{
    totalDeleteCount += [fileOperate finishedCount];
    successDeleteCount += [fileOperate succeedCount];
    [fileOperate release];
    if ([deleteArray count] > MAXDELETEFILE)
    {
//        for (int i = 0; i < MAXDELETEFILE; i++)
//        {
//            PCFileInfo *info = [deleteArray objectAtIndex:i];
//            [tableData removeObject:info];
//        }
        [deleteArray removeObjectsInRange:NSMakeRange(0, MAXDELETEFILE)];
    }
    else
    {
//        for (int i = 0; i < [deleteArray count]; i++)
//        {
//            PCFileInfo *info = [deleteArray objectAtIndex:i];
//            [tableData removeObject:info];
//        }
        [deleteArray removeAllObjects];
    }
//    [tableView reloadData];
    if ([deleteArray count] > 0)
    {
        [self deleteFile];
        return;
    }
    [self cancelAction];
//    if (successDeleteCount == totalDeleteCount) {
//        [PCUtilityUiOperate showOKAlert:@"成功删除文件" delegate:nil];
//    }
//    else if (successDeleteCount == 0) {
//        [PCUtilityUiOperate showOKAlert:@"删除文件失败" delegate:nil];
//    }
//    else {
        NSString *message = [NSString stringWithFormat:@"操作完成，成功%d个，失败%d个！", successDeleteCount, totalDeleteCount-successDeleteCount];
        [PCUtilityUiOperate showOKAlert:message delegate:nil];
//    }
    [self resetEGOFrame];
    [self refreshFileList:nil];
    [self unLockUI];
    [self removeDeleteProcessView];
}

//当前操作的总个数和完成的个数  以此可以获得进度
-(void)fileOperateFinishedCount:(NSInteger)finishedCount totalCount:(NSInteger)total
{

}
-(void)fileOperateFailed:(FileOperate *)fileOperate error:(NSError*)error
{
    [self removeSomePCFileInfoWhenFileOperateFailed:fileOperate];
    [fileOperate release];
    [self cancelAction];
    [self unLockUI];
    [self removeDeleteProcessView];
    [ErrorHandler showErrorAlert:error];
}

-(void)fileOperateCanceledSuccess:(FileOperate *)fileOperate
{
    [fileOperate release];
    [self unLockUI];
    [self removeDeleteProcessView];
    
}
-(void)fileOperateCanceledFailed:(FileOperate *)fileOperate error:(NSError*)error
{
    [fileOperate release];
    [self unLockUI];
    [self removeDeleteProcessView];
    [ErrorHandler showErrorAlert:error];
}
@end
