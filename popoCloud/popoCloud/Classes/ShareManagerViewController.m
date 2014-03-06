//
//  ShareManagerViewController.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-26.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "ShareManagerViewController.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "FileCache.h"
#import "PCLogin.h"
#import "PCLogout.h"
#import "PCFileCell.h"
#import "PCFileExpansionCell.h"
#import "FileListViewController.h"
#import "FileCacheController.h"
#import "ActivateBoxViewController.h"
#import "NetPenetrate.h"
#import "UIDevice+IdentifierAddition.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#define STATUS_GET_SHARE_LIST 1
#define STATUS_DELETE_SHARE 2
#define STATUS_REGET_SHARE_LIST 3
#define STATUS_CANCEL 4

#define SHARE_TAG  7
#define CACHE_FILE_TAG 11

@interface ShareManagerViewController ()
{
    PCShareServices *pcShare;
}
@end
@implementation ShareManagerViewController

@synthesize tableView;
@synthesize lblText;
@synthesize dicatorView;
@synthesize isOpen;
@synthesize selectIndexPath;
@synthesize imageView;
@synthesize urlConnection;
@synthesize currentFileInfo;
@synthesize hud;
@synthesize lblDes;
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle
-(void)showImageAndLabel
{
    if (![dicatorView isAnimating]) {
        imageView.hidden = NO;
        lblText.text = NSLocalizedString(@"CurretntNoileShare", nil);
        lblText.hidden = NO;
        lblDes.hidden = NO;
        if ([self.view viewWithTag:LabelDesTag])
        {
            lblDes.hidden = YES;
            lblText.text = NSLocalizedString(@"NotFoundYourBoxs", nil);
        }
        
    }
}

-(void)hidenImageAndLabel
{
    imageView.hidden = YES;
    lblText.hidden = YES;
    lblDes.hidden = YES;
    lblText.text = NSLocalizedString(@"CurretntNoileShare", nil);
    if ([self.view viewWithTag:LabelDesTag]) {
        [[self.view viewWithTag:LabelDesTag] removeFromSuperview];
    }
}

- (void)viewDidLoad
{
    pcShare = [[PCShareServices alloc] init];
    pcShare.delegate = self;
    [self hidenImageAndLabel];
    dicatorView.activityIndicatorViewStyle =  UIActivityIndicatorViewStyleWhiteLarge;
    dicatorView.color = [UIColor grayColor];
    dicatorView.center = self.view.center;
    
    self.navigationItem.rightBarButtonItem = [PCUtilityUiOperate createRefresh:self];
    
    tableData = [[NSMutableArray alloc] init];
    
    lblText.text = NSLocalizedString(@"CurretntNoileShare", nil);
    lblText.textColor = [UIColor  blackColor];
    lblDes.text = NSLocalizedString(@"ManageShareFile", nil);
    lblDes.textColor = [UIColor  grayColor];
    self.view.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    tableView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];

    isDeleteShare = NO;
    _isGetShare = NO;
    shareUrl = nil;
    oldOrientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
    [super viewDidLoad];
}

- (void) refreshView
{
    [self hidenImageAndLabel];
    [self getShareList];
    [dicatorView startAnimating];
    UIButton *refreshImg = (UIButton *)self.navigationItem.rightBarButtonItem.customView;
    refreshImg.enabled = NO;
    [PCUtilityUiOperate animateRefreshBtn:refreshImg];
    isDeleteShare = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    if(IS_IPAD)
    {
        if (UIInterfaceOrientationIsPortrait((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation))
        {
            imageView.center = CGPointMake(self.view.center.x, 300);
            lblText.center = CGPointMake(self.view.center.x, 426.5);
            lblDes.center = CGPointMake(self.view.center.x, 581.5);
        }
        else
        {
            imageView.center = CGPointMake(self.view.center.x, 200);
            lblText.center = CGPointMake(self.view.center.x, 326.5);
            lblDes.center = CGPointMake(self.view.center.x, 481.5);
        }
    }
    else
    {
        imageView.center = CGPointMake(self.view.center.x, 127.5);
        lblText.center = CGPointMake(self.view.center.x, 227);
        lblDes.center = CGPointMake(self.view.center.x, 277);
    }
    [self layoutSubviews];
    
    if ([PCLogin getResource])
    {
        [self refreshView];
    }
    else
    {
        [self showImageAndLabel];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [self orientationDidChange:nil];
    if ([PCLogin getAllDevices]==nil || [[PCLogin getAllDevices] count]==0)
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"ShareManagerView"];
    [MobClick event:UM_SHARE_MANAGER];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (shareUrl)
        [shareUrl cancelConnection];
    
    [self hideHUD];
    _isGetShare = NO;
    
    if (self.selectIndexPath)
    {
        [self expansionChange:selectIndexPath needAnimation:NO];
    }
    
    //分享列表点击后会请求2次。第一次是判断文件是否被分享，第二次才是打开。在第一次请求的时候退出，会导致crash。设置一个取消状态预防程序crash
    mStatus = STATUS_CANCEL;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    if (self.urlConnection)
    {
        [PCUtility removeConnectionFromArray:self.urlConnection];
        [self.urlConnection cancel];
        self.urlConnection = nil;
    }
    
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"ShareManagerView"];
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

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self layoutSubviews];
}

#pragma mark - private methods

- (void)hideHUD
{
    if (hud)
    {
        [hud hide:YES];
        self.hud = nil;
    }
}

- (void)layoutSubviews
{
    dicatorView.center = self.view.center;
    if (IS_IPAD)
    {
        CGFloat offset = 0.0;
        if (imageView.center.y==200 && UIInterfaceOrientationIsPortrait((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation))
        {
            offset = 100;
        }
        if(imageView.center.y==300 && UIInterfaceOrientationIsLandscape((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation))
        {
            offset =-100;
        }
        imageView.center = CGPointMake(self.view.center.x, imageView.center.y+offset);
        lblText.center = CGPointMake(self.view.center.x, lblText.center.y+offset);
        lblDes.center = CGPointMake(self.view.center.x, lblDes.center.y+offset);
        if ([self.view viewWithTag:LabelDesTag]) {
            [self.view viewWithTag:LabelDesTag].center = lblDes.center;
            lblDes.hidden = YES;
        }
    }
}

- (void)refreshShare
{
    [self hideHUD];
    [self refreshView];
}

- (void)expansionChange:(NSIndexPath *)indexPath needAnimation:(BOOL)animate
{
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:1 inSection:indexPath.section]];
    UITableViewRowAnimation animation = animate ? UITableViewRowAnimationTop :
    UITableViewRowAnimationNone;
    
    self.isOpen = ![indexPath isEqual:self.selectIndexPath];
    
    PCFileCell *cell = (PCFileCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell changeArrowImageWithExpansion:self.isOpen];
    
    if (!self.isOpen)//关闭自己
    {
        //svn  55313
        self.selectIndexPath = nil;
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:indexPaths
                              withRowAnimation:animation];
        [self.tableView endUpdates];
    }
    else
    {
        if (self.selectIndexPath)//已经打开一个了
        {
            [(PCFileCell *)[self.tableView cellForRowAtIndexPath:selectIndexPath] changeArrowImageWithExpansion:NO];
            
            [self.tableView beginUpdates];
            
            [self.tableView insertRowsAtIndexPaths:indexPaths
                                  withRowAnimation:animation];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:selectIndexPath.section]]
                                  withRowAnimation:animation];
            self.selectIndexPath = indexPath;
            
            [self.tableView endUpdates];
        }
        else//都是关闭状态，打开一个
        {
            self.selectIndexPath = indexPath;
            [self.tableView insertRowsAtIndexPaths:indexPaths
                                  withRowAnimation:animation];
        }
        
        UITableViewCell *selectCell = [self.tableView cellForRowAtIndexPath:selectIndexPath];
        
        //当前滚动到的位置
        CGFloat deltaY = self.tableView.contentOffset.y;
        //cell的位置
        CGFloat cellY = selectCell.frame.origin.y + selectCell.frame.size.height * 2 - 5;
        //tableview的高度
        CGFloat height = self.tableView.frame.size.height;
        //偏移量
        CGFloat offsetY = cellY - deltaY >= height ? cellY - height - deltaY : 0;
        
        [self.tableView setContentOffset:CGPointMake(0, offsetY + deltaY) animated:YES];
    }
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
    
    if (shareUrl && shareUrl.actionSheet)
    {
        [shareUrl.actionSheet dismissWithClickedButtonIndex:shareUrl.actionSheet.cancelButtonIndex
                                                   animated:NO];
        [shareUrl performSelector:@selector(showActionSheet) withObject:nil afterDelay:0.1];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //fix bug 55775 add by libing 2013-6-24
    if (tableData.count)
    {
        [self hidenImageAndLabel];
    }
    else
    {
        [self showImageAndLabel];
    }
    //
    return tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.isOpen && selectIndexPath.section == section ? 2 : 1;
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return self.isOpen && selectIndexPath.section == indexPath.section && indexPath.row ?
    55 : TABLE_CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section >= tableData.count)
    {
        return nil;
    }
    
    if (self.isOpen&&self.selectIndexPath.section == indexPath.section&&indexPath.row!=0)
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
        [cell2 initActionContent:SHARELIST_FILE];
        return cell2;
    }
    else
    {
        NSString *CellIdentifier =    @"fileCellIdentifier";  //[node objectForKey:@"name"];
        
        PCFileCell *cell = [_tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
        {
            cell = [[[PCFileCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
            cell.accessoryType = UITableViewCellAccessoryNone;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        //修改重用引起的问题
        if (self.isOpen&&self.selectIndexPath.section == indexPath.section)
        {
            [cell changeArrowImageWithExpansion:YES];
        }
        else
        {
            [cell changeArrowImageWithExpansion:NO];
        }
        PCFileInfo *node = (PCFileInfo *)[tableData objectAtIndex:indexPath.section];
        [cell changeStatusImageWithFileStatus:[[PCUtilityFileOperate downloadManager] getFileStatus:node.path andModifyTime:nil]];
        
        cell.delegate = self;
        cell.indexRow = indexPath.row;
        cell.indexSection = indexPath.section;
        
        if (indexPath.section < tableData.count)
        {
            //BOOL bNeedAccessCode = node.publicAccess&&([node.publicAccess length]>3);
            cell.textLabel.text = /*bNeedAccessCode?[
            NSString stringWithFormat:@"%@(验证码：%@)",node.name,node.publicAccess]:*/node.name;
            if (node.bFileFoldType) {
                cell.imageView.image = [UIImage imageNamed:@"file_folder.png"];
                cell.detailTextLabel.text = @"";
            }
            else
            {
                cell.imageView.image = [UIImage imageNamed:[PCUtilityFileOperate getImgByExt:node.ext]];
                cell.detailTextLabel.text = [PCUtilityFileOperate formatFileSize:[node.size longLongValue] isNeedBlank:YES];
            }
        }
        return cell;
    }
}

- (void)dealloc
{
    [self hideHUD];
    
    [pcShare release];
    
    self.currentFileInfo = nil;
    self.selectIndexPath = nil;
    
    if (shareUrl && shareUrl.actionSheet)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:shareUrl selector:@selector(showActionSheet) object:nil];
    }
    
    if (shareUrl) [shareUrl release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.localPath = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    
    self.tableView = nil;
    self.lblText = nil;
    self.lblDes = nil;
    self.dicatorView = nil;
    self.imageView = nil;
    
    [tableData release];
    
    [super dealloc];
}

//------------------------------------------------
- (void) getShareList {
    mStatus = STATUS_GET_SHARE_LIST;
    [pcShare getAllShareFiles];
}

- (void) deleteShare:(NSString*)shareID {
    mStatus = STATUS_DELETE_SHARE;
    
    [dicatorView startAnimating];
    UIButton *refreshImg = (UIButton *)self.navigationItem.rightBarButtonItem.customView;
    refreshImg.enabled = NO;
    [PCUtilityUiOperate animateRefreshBtn:refreshImg];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    isDeleteShare = YES;
    [pcShare deleteShareFileWithID:shareID];
    
}

- (void) refreshTable {
    [self.tableView reloadData];
    if (tableData.count) {
        [self.tableView setHidden:NO];
        [self hidenImageAndLabel];
    }
    else {
        [self.tableView setHidden:YES];
        [self showImageAndLabel];
        [self layoutSubviews];
    }
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
	_reloading = NO;
    //	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    UIButton *refreshImg = (UIButton *)self.navigationItem.rightBarButtonItem.customView;
    [refreshImg.layer removeAllAnimations];
    refreshImg.enabled = YES;
    if (!tableData.count) {
        [self showImageAndLabel];
    }
    
}

#pragma mark - PCFileCell delegate
- (void)didSelectCell:(NSIndexPath *)indexPath
{
    if (![PCUtility isNetworkReachable:nil])
    {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"NetNotReachableError", nil) delegate:nil];
        return;
    }
    
    NSInteger section = indexPath.section;
    if (section < tableData.count && !isDeleteShare && !_reloading)
    {
        self.currentFileInfo = tableData[section];
        
        //重新发请求验证
        mStatus = STATUS_REGET_SHARE_LIST;
        if (!_isGetShare)
        {
            [pcShare getAllShareFiles];
            _isGetShare = YES;
            if (!hud)
            {
                self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
                hud.detailsLabelText = nil;
                hud.labelText = NSLocalizedString(@"Verifying Share file exists", nil);
            }
            else
            {
                [hud show:YES];
                hud.detailsLabelText = nil;
                hud.labelText = NSLocalizedString(@"Verifying Share file exists", nil);
            }
            
            hud.mode = MBProgressHUDModeIndeterminate;
            hud.userInteractionEnabled = NO;
        }
    }
}

- (void)expansionView:(NSIndexPath *)indexPath
{
    if (indexPath.section < tableData.count && indexPath.row == 0 && !_reloading && !isDeleteShare && !_isGetShare)
    {
        [self expansionChange:indexPath needAnimation:YES];
    }
}

#pragma mark - PCFileExpansionCell delegate
- (void)shareButtonClick
{
    PCFileInfo *node = [tableData objectAtIndex:(selectIndexPath.section)];
    
    if (!node.bFileFoldType && [node.size longLongValue] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"ShareEmptyFile", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    if (!shareUrl)
        shareUrl = [[PCShareUrl alloc] init];
    
    [shareUrl shareFileWithInfo:node andDelegate:self];
    

}

- (void)cancelShareButtonClick
{
    UIAlertView *Alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"isCancelShare", nil)
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    Alert.tag = SHARE_TAG;
    [Alert show];
    [Alert release];
}

#pragma mark - PCShareUrl delegate
- (void) shareUrlFail:(NSString*)errorDescription {
    [dicatorView stopAnimating];
    [PCUtilityUiOperate showErrorAlert:errorDescription delegate:self];
}

- (void) shareUrlStart {
    [dicatorView startAnimating];
}

- (void) shareUrlFinish {
    [dicatorView stopAnimating];
    if (self.selectIndexPath)
    {
        [self expansionChange:selectIndexPath needAnimation:YES];
    }
}

#pragma mark - callback methods

- (void)refreshData:(id)recognizer
{
    if (self.selectIndexPath)
    {
        [self expansionChange:selectIndexPath needAnimation:NO];
    }
    
    if (!isDeleteShare)
    {
        [self refreshView];
    }
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
    }
}

- (void)openFileWithFileInfo:(PCFileInfo*)fileInfo andFileType:(CacheFileType) fileType{
    [dicatorView stopAnimating];
    FileCache *localFileCache = [[[FileCache alloc] init] autorelease];
    localFileCache.currentDeviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
    self.localPath = [localFileCache getCacheFilePath:fileInfo.path
                                             withType:fileType];
    [PCUtilityFileOperate openFileAtPath:self.localPath WithBackTitle:self.navigationItem.title andFileInfo:fileInfo andNavigationViewControllerDelegate:self];
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
#pragma PCShareServicesDelegate
-(void)getAllShareFilesSuccess:(PCShareServices *)pcShareServices withFileArray:(NSArray *)fileArray
{
    [dicatorView stopAnimating];
    [self doneLoadingTableViewData];
    [tableData removeAllObjects];
    [tableData addObjectsFromArray:fileArray];
    if(mStatus == STATUS_REGET_SHARE_LIST)
    {
         if (currentFileInfo !=nil)
         {
             BOOL containCurrentNode = NO;
             for (PCFileInfo *fileInfo in tableData)
             {
                 if ([currentFileInfo.identify isEqualToString:fileInfo.identify] && [fileInfo.path isEqualToString:currentFileInfo.path])
                 {
                        containCurrentNode = YES;
                        break;
                 }
             }
                
            if (containCurrentNode)
            {
                [self hideHUD];
                //1.5取消了文件或者文件夹详细页面的ui。直接打开文件或者文件夹。modify by xy
                if (!currentFileInfo.bFileFoldType)
                {
                    if ([currentFileInfo.size longLongValue] ==0 )
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"ConfirmEmptyFile", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
                        [alert show];
                        [alert release];
                        _isGetShare = NO;
                        return;
                    }
                    else if(!(currentFileInfo.path&&[PCUtilityFileOperate itemCanOpenWithPath:currentFileInfo.path]))
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"NoSuitableProgram", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
                        [alert show];
                        [alert release];
                        _isGetShare = NO;
                        return;
                    }
                    
                    BOOL bImageCache = NO;
                    fileCache = [[FileCache alloc] init] ;
                    fileCache.currentDeviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
                    [fileCache setProgressView:nil progressScale:1.0];
                    DownloadStatus status = [[PCUtilityFileOperate downloadManager] getFileStatus:currentFileInfo.path
                                                                                    andModifyTime:currentFileInfo.modifyTime];
                    
                    if (([fileCache GetFuLLSizeFileFromCacheWithFileInfo:currentFileInfo  withType:TYPE_CACHE_SLIDEIMAGE]
                         && (bImageCache = !bImageCache))
                        ||
                        ((currentFileInfo.mFileType != PC_FILE_IMAGE)
                         &&
                         [fileCache GetFuLLSizeFileFromCacheWithFileInfo:currentFileInfo withType:TYPE_CACHE_FILE]))
                    {
                        [self endProcess];
                        int fileSaveType = bImageCache? TYPE_CACHE_SLIDEIMAGE:TYPE_CACHE_FILE;
                        if (currentFileInfo.mFileType != PC_FILE_OTHER)
                        {
                            FileCacheController *cacheController = [[FileCacheController alloc] initWithPath:[fileCache getCacheFilePath:currentFileInfo.path
                                                                                                                                withType:fileSaveType]  andFinishLoadingState:YES
                                                                                               andDataSource:tableData
                                                                                        andCurrentPCFileInfo:currentFileInfo
                                                                                   andLastViewControllerName:self.navigationItem.title];
                            
                            cacheController.title = currentFileInfo.name;
                            if (currentFileInfo.mFileType == PC_FILE_IMAGE)
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
                            [self openFileWithFileInfo:currentFileInfo andFileType:TYPE_CACHE_FILE];
                        }
                        [fileCache release];
                        fileCache = nil;
                    }
                    //若文件先下载（收藏）了，则点击该文件还会判断其是否在Download文件夹里，added by ray
                    else if ([fileCache readFileFromCacheWithFileInfo:currentFileInfo  withType:TYPE_DOWNLOAD_FILE] &&
                             (status == kStatusDownloaded || status == kStatusDownloading)&&
                             ( currentFileInfo.mFileType != PC_FILE_IMAGE))
                    {
                        [self endProcess];
                        
                        if (status == kStatusDownloaded)
                        {
                            if (currentFileInfo.mFileType != PC_FILE_OTHER)
                            {
                                
                                FileCacheController *cacheController = [[FileCacheController alloc] initWithPath:[fileCache getCacheFilePath:currentFileInfo.path
                                                                                                                                    withType:TYPE_DOWNLOAD_FILE ]andFinishLoadingState:YES
                                                                                                   andDataSource:tableData
                                                                                            andCurrentPCFileInfo:currentFileInfo
                                                                                       andLastViewControllerName:self.navigationItem.title];
                                cacheController.title = currentFileInfo.name;
                                
                                if (currentFileInfo.mFileType == PC_FILE_IMAGE)
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
                                [self openFileWithFileInfo:currentFileInfo andFileType:TYPE_DOWNLOAD_FILE];
                            }
                        }
                        else//若是正在收藏下载的文件，则不再单独缓存下载，直接显示收藏那边的下载进度
                        {
                            FileCacheController *cacheController = [[FileCacheController alloc] initWithPath:[fileCache getCacheFilePath:currentFileInfo.path
                                                                                                                                withType:TYPE_DOWNLOAD_FILE]  andFinishLoadingState:NO
                                                                                               andDataSource:tableData
                                                                                        andCurrentPCFileInfo:currentFileInfo
                                                                                   andLastViewControllerName:self.navigationItem.title];
                            
                            [[NSNotificationCenter defaultCenter] addObserver:cacheController selector:@selector(downloadProgress:) name:@"RefreshProgress" object:nil];
                            [[NSNotificationCenter defaultCenter] addObserver:cacheController selector:@selector(downloadFinish:) name:@"RefreshTableView" object:nil];
                            
                            cacheController.title = currentFileInfo.name;
                            [self.navigationController pushViewController:cacheController animated:YES];
                            
                            PCFileDownloadingInfo *downloadingInfo = [[PCUtilityFileOperate downloadManager]
                                                                      fetchObject:@"FileDownloadingInfo"
                                                                      hostPath:currentFileInfo.path
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
                        if (currentFileInfo.mFileType != PC_FILE_AUDIO && currentFileInfo.mFileType != PC_FILE_VEDIO)
                        {
                            NSInteger cacheType = currentFileInfo.mFileType == PC_FILE_IMAGE ? TYPE_CACHE_SLIDEIMAGE : TYPE_CACHE_FILE;
                            NSString *filePath = [fileCache getCacheFilePath:currentFileInfo.path withType:cacheType];
                            FileCacheController *cacheController = [[FileCacheController alloc] initWithPath:filePath
                                                                                       andFinishLoadingState:NO
                                                                                               andDataSource:tableData
                                                                                        andCurrentPCFileInfo:currentFileInfo
                                                                                   andLastViewControllerName:self.navigationItem.title];
                            if (currentFileInfo.mFileType == PC_FILE_IMAGE)
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
                                if ([fileCache cacheFile:currentFileInfo.path
                                                viewType:cacheType
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
                            }
                            [cacheController release];
                        }
                        else
                        {
                            if ([NetPenetrate sharedInstance].gCurrentNetworkState == CURRENT_NETWORK_STATE_DEFAULT)
                            {
                                if (self.selectIndexPath)
                                {
                                    [self expansionChange:selectIndexPath needAnimation:YES];
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
                            else if ([PCUtilityFileOperate livingMediaSupport:currentFileInfo.ext])
                            {
                                NSString *url = [NSString stringWithFormat:@"mediaPlay?path=%@", currentFileInfo.path];
                                NSMutableString *urlStr = [NSMutableString stringWithString:url];
                                if ([PCSettings sharedSettings].bSessionSupported ) {
                                    [urlStr appendString:@"&"];
                                    [urlStr appendFormat:@"%@=%@", @"token_id",[PCLogin getToken]];
                                    [urlStr appendString:@"&"];
                                    [urlStr appendFormat:@"%@=%@", @"client_id",[[UIDevice currentDevice] uniqueDeviceIdentifier]];
                                }
                                
                                NSString  *temp = [[NSString stringWithString:urlStr] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                                NSURL *nsUrl = [PCUtility getNSURL:temp];
                                
                                MPMoviePlayerViewController *playerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:nsUrl];
                                [self presentMoviePlayerViewControllerAnimated:playerViewController];
                                
                                [[NSNotificationCenter defaultCenter] addObserver:self
                                                                         selector:@selector(playerPlaybackDidFinish:)
                                                                             name:MPMoviePlayerPlaybackDidFinishNotification
                                                                           object:nil];
                                
                                if (currentFileInfo.mFileType == PC_FILE_AUDIO) {
                                    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
                                    [[AVAudioSession sharedInstance] setActive: YES error:nil];
                                }
                                
                                MPMoviePlayerController *player = [playerViewController moviePlayer];
                                [player play];
                                [playerViewController release];
                                
                                if (fileCache) {
                                    [fileCache release];
                                    fileCache = nil;
                                }
                            }
                            else
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
                }
                else
                {
                    NSMutableArray *folderNames = [PCSettings sharedSettings].folderInfos;
                    
                    NSString *folderName = @"";
                    
                    for (NSDictionary *folderInfo in folderNames)
                    {
                        if ([currentFileInfo.path  rangeOfString:(NSString *)[folderInfo valueForKey:@"path"] ].location != NSNotFound)
                        {
                            folderName = [NSString stringWithFormat:@"%@/%@",(NSString *)[folderInfo valueForKey:@"name"],currentFileInfo.name];
                            break;
                        }
                        else
                        {
                            folderName = currentFileInfo.path;
                        }
                    }
                    
                    FileListViewController *fileListView = [[[FileListViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"FileListView"] bundle:nil] autorelease];
                    fileListView.navigationItem.title = currentFileInfo.name;
                    fileListView.dirPath = currentFileInfo.path;
                    fileListView.dirName = folderName;
                    
                    [self.navigationController pushViewController:fileListView animated:YES];
                }
            }
            else
            {
                [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"NoFileForShareTip", nil) delegate:nil];
                [self refreshShare];
            }
        }
        else
        {
            [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"NoFileForShareTip", nil) delegate:nil];
            [self refreshShare];
        }
        _isGetShare = NO;
    }
    else
        [self refreshTable];
    isDeleteShare = NO;
}
-(void)bindBoxView
{
    tableView.hidden = YES;
    [tableData removeAllObjects];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    lblText.text = NSLocalizedString(@"NotFoundYourBoxs", nil);
    lblText.hidden = NO;
    imageView.hidden = NO;
    lblDes.hidden = YES;
    if (![self.view viewWithTag:LabelDesTag])
    {
        UIButton *goBind = [UIButton buttonWithType:UIButtonTypeCustom];
        [goBind setTitle:NSLocalizedString(@"GoBind", nil) forState:UIControlStateNormal];
        [goBind setTitleColor:[UIColor colorWithRed:66.0/255.0 green:126.0/255.0 blue:176.0/255.0  alpha:1.0] forState:UIControlStateNormal];
        goBind.frame = CGRectMake(0, 0, 200, 200);
        [goBind setBackgroundColor:[UIColor clearColor]];
        [goBind addTarget:self action:@selector(goBindBox) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:goBind];
        goBind.tag = LabelDesTag;
        goBind.center = lblDes.center;
        goBind.titleLabel.font = [UIFont boldSystemFontOfSize:IS_IPAD ? 26 : 13];
    }
    
}
-(void)goBindBox
{
    [MobClick event:UM_SETTING_ACTIVATE];
    ActivateBoxViewController *vc = [[ActivateBoxViewController alloc] initWithNibName:@"ActivateBoxViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

-(void)getAllShareFilesFailed:(PCShareServices *)pcShareServices withError:(NSError *)error
{
    [dicatorView stopAnimating];
    [self doneLoadingTableViewData];
    isDeleteShare = NO;
    _isGetShare = NO;
    [ErrorHandler showErrorAlert:error];
    if (error.code == PC_Err_BoxUnbind)
    {
        [self bindBoxView];
        [PCLogin removeDevice:[PCLogin getResource]];
    }
}
-(void)deleteShareFileWithIDSuccess:(PCShareServices *)pcShareServices
{
    [dicatorView stopAnimating];
    [tableData removeObjectAtIndex:deleteIndex];
    [self refreshTable];
    
    [self doneLoadingTableViewData];
    isDeleteShare = NO;
}
-(void)deleteShareFileWithIDFailed:(PCShareServices *)pcShareServices withError:(NSError *)error
{
    [dicatorView stopAnimating];
    [self doneLoadingTableViewData];
    isDeleteShare = NO;
    [ErrorHandler showErrorAlert:error];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == SHARE_TAG) {
        if (buttonIndex == [alertView firstOtherButtonIndex]) {
            deleteIndex = selectIndexPath.section;
            if (self.selectIndexPath)
            {
                [self expansionChange:selectIndexPath needAnimation:NO];
            }
            
            PCFileInfo *node = [tableData objectAtIndex:deleteIndex];
            [self deleteShare:node.identify];
        }
    }
    else if (alertView.tag == CACHE_FILE_TAG) {
        if (buttonIndex == [alertView firstOtherButtonIndex]) {
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
        else if (fileCache) {
            [fileCache release];
            fileCache = nil;
        }
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

@end

