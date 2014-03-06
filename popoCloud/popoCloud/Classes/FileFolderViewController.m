//
//  FilesViewController.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-10.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "FileFolderViewController.h"
#import "FileListViewController.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "FileSearch.h"
#import "PCLogin.h"
#import "FileCacheController.h"
#import <QuickLook/QuickLook.h>
#import "PCAppDelegate.h"
#import "LoginViewController.h"
#import "ActivateBoxViewController.h"
#import "CameraUploadManager.h"
#import "PCFileInfo.h"
#import "PCDiskInfo.h"

#define STATUS_GET_FOLDER_INFO 1
#define STATUS_GET_FOLDER_SIZE 2

#define WARNING_IMAGE_TAG  8
#define CONFIRM_CANCEL_COLLECT_TAG  7

//static BOOL firstJumpFromLoginView = YES;

@implementation FileFolderViewController

@synthesize tableView;
@synthesize searchBar;
@synthesize dicatorView;
@synthesize picturetableView;
@synthesize lblResult;
@synthesize localPath;
@synthesize filteredListContent, savedSearchTerm, searchWasActive;
@synthesize isOpen;
@synthesize selectIndexPath;
@synthesize historyfilteredListContent;
@synthesize currentRequest;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    bViewFirstAppear = YES;
    
    self.searchBar.placeholder = NSLocalizedString(@"SearchBarPlaceHolder", nil);
    if (!IS_IPAD) {
        // Change search bar text font
        UITextField *searchField = [self.searchBar valueForKey:@"_searchField"];
        searchField.font = [UIFont systemFontOfSize:13.0f];
    }
    
    dicatorView.activityIndicatorViewStyle =  UIActivityIndicatorViewStyleWhiteLarge;
    dicatorView.color = [UIColor grayColor];
 
    CGPoint centPoint = self.view.center;
    self.lblResult = [[[UILabel alloc] initWithFrame:CGRectMake(centPoint.x-100, centPoint.y-100, 200, centPoint.y)] autorelease];
    self.lblResult.textColor = [UIColor blueColor];
    self.lblResult.text = NSLocalizedString(@"NoResultForSearch", nil);
    self.lblResult.backgroundColor = [UIColor  clearColor];
    self.lblResult.textAlignment = UITextAlignmentCenter;
    
//    if (!tableData) {
    tableData = [[NSMutableArray alloc] init];
    
    isFinish = YES;
    isNetworkError = NO;
    isRefresh = YES;
    isSearchDisplay = NO;
    shareUrl = nil;
	//  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];
    [_refreshHeaderPictureView refreshLastUpdatedDate];
    
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationItem.rightBarButtonItem = [PCUtilityUiOperate createRefresh:self];
    
    self.filteredListContent = [NSMutableArray array];
    
    if (self.savedSearchTerm)
    {
        [self.searchDisplayController setActive:self.searchWasActive];
        [self.searchDisplayController.searchBar setText:savedSearchTerm];
        
        self.savedSearchTerm = nil;
    }
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    _refreshHeaderView=nil;
    _refreshHeaderPictureView=nil;
     self.filteredListContent = nil;
    self.lblResult = nil;
}

-(void)setTabeleHeadViewCenter
{
    if (!self.picturetableView.hidden)
    {
        UIView *header = self.picturetableView.tableHeaderView;
        if (header)
        {
            UIImageView *image = (UIImageView *)[header viewWithTag:ImageTag];
            CGFloat offset = 0.0;
            if (IS_IPAD)
            {
                if (image)
                {
                    if (image.center.y == 300 && UIDeviceOrientationIsLandscape((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation))
                    {
                        offset =-100;
                    }
                    if (image.center.y == 200 && UIDeviceOrientationIsPortrait((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation))
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
            
            UILabel *des = (UILabel *)[header viewWithTag:LabelDesTag];
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
            
            UILabel *lblDes = (UILabel *)[header viewWithTag:LabelDesDetailTag];
            if (lblDes)
            {
                lblDes.center = CGPointMake(self.view.center.x, lblDes.center.y);
            }
            UIButton *goBind = (UIButton *)[header viewWithTag:LabelDesTag];
            if (goBind)
            {
                goBind.center = CGPointMake(self.view.center.x, goBind.center.y);
            }
        }
    }
}

-(void)loadDeviceFailed
{
    [dicatorView stopAnimating];
    int scale = IS_IPAD ? 2 : 1;
    UIView *headerView = [[UIView alloc] initWithFrame:self.view.frame];
    headerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    headerView.autoresizesSubviews = YES;
    headerView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    UIImage *emptyImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"empty" ofType:@"png"]];
    UIImageView *emptyImageView = [[UIImageView alloc] initWithImage:emptyImage];
    emptyImageView.tag = ImageTag;
    CGFloat y = 100;
    if (IS_IPAD && UIDeviceOrientationIsPortrait((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation) )
    {
        y=150;
    }
    emptyImageView.center = CGPointMake(self.view.center.x, y*scale);
    [headerView addSubview:emptyImageView];
    [emptyImageView release];
    
    UILabel *noBoxLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 30)];
    [noBoxLabel setTextColor:[UIColor blackColor]];
    noBoxLabel.tag = LabelTitleTag;
    [noBoxLabel setBackgroundColor:[UIColor clearColor]];
    [noBoxLabel setTextAlignment:NSTextAlignmentCenter];
    [headerView addSubview:noBoxLabel];
    noBoxLabel.text =NSLocalizedString(@"LoadBoxFailed", nil);
    noBoxLabel.center = CGPointMake(self.view.center.x, emptyImageView.frame.origin.y+emptyImageView.frame.size.height+27*scale);
    
    UILabel *lblDes = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 60)];
    [lblDes setTextColor:[UIColor grayColor]];
    lblDes.numberOfLines = 2;
    lblDes.tag = LabelDesTag;
    [lblDes setBackgroundColor:[UIColor clearColor]];
    [lblDes setTextAlignment:NSTextAlignmentCenter];
    lblDes.text = NSLocalizedString(@"PopoCloudKonwFailedAndRefreshAgain", nil);
    lblDes.center = CGPointMake(self.view.center.x, noBoxLabel.frame.origin.y+noBoxLabel.frame.size.height+70*scale);
    [headerView addSubview:lblDes];
            
    
    if (IS_IPAD)
    {
        [noBoxLabel setFont:[UIFont systemFontOfSize:30]];
        [lblDes setFont:[UIFont systemFontOfSize:26]];
    }
    else
    {
        [noBoxLabel setFont:[UIFont systemFontOfSize:15]];
        [lblDes setFont:[UIFont systemFontOfSize:13]];
        emptyImageView.center = CGPointMake(self.view.center.x, 55+emptyImage.size.height/2);
        noBoxLabel.center = CGPointMake(self.view.center.x, emptyImageView.frame.origin.y+emptyImageView.frame.size.height+27);
        lblDes.center = CGPointMake(self.view.center.x, noBoxLabel.frame.origin.y+noBoxLabel.frame.size.height+35);
    
    }
    [noBoxLabel release];
    [lblDes release];
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.tableView.hidden = YES;
    self.picturetableView.hidden = NO;
    self.picturetableView.tableHeaderView = headerView;
    [headerView release];
}

-(void)goBindBox
{
    [MobClick event:UM_SETTING_ACTIVATE];
    ActivateBoxViewController *vc = [[ActivateBoxViewController alloc] initWithNibName:@"ActivateBoxViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}
-(void)noBoxFoundOrNoContent:(BOOL)noContent
{
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
    UIView *headView = [[UIView alloc] initWithFrame:self.view.frame];
    headView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];

    headView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    UIImage *emptyImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"empty" ofType:@"png"]];
    UIImageView *emptyImageView = [[UIImageView alloc] initWithImage:emptyImage];
    emptyImageView.tag = ImageTag;
    CGFloat y = 100;
    if (IS_IPAD && UIDeviceOrientationIsPortrait((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation) )
    {
        y=150;
    }
    emptyImageView.center = CGPointMake(self.view.center.x, y*scale);
    [headView addSubview:emptyImageView];
    [emptyImageView release];
    
    UILabel *noBoxLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 30)];
    [noBoxLabel setTextColor:[UIColor blackColor]];
    noBoxLabel.tag = LabelTitleTag;
    [noBoxLabel setBackgroundColor:[UIColor clearColor]];
    [noBoxLabel setTextAlignment:NSTextAlignmentCenter];
    [headView addSubview:noBoxLabel];
    noBoxLabel.text = noContent ? NSLocalizedString(@"NoFileCurrent", nil) : NSLocalizedString(@"NotFoundYourBoxs", nil);
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
        lblDes.numberOfLines = 2;
        lblDes.text = NSLocalizedString(@"TeacherTellUsNoEmpty", nil);
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
            goBind.center = CGPointMake(self.view.center.x, noBoxLabel.frame.origin.y+noBoxLabel.frame.size.height+70*scale);
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
            goBind.center = CGPointMake(self.view.center.x, noBoxLabel.frame.origin.y+noBoxLabel.frame.size.height+35*scale);
        }
        
    }
    [noBoxLabel release];
    self.picturetableView.tableHeaderView = headView;
    [headView release];
    self.tableView.hidden = YES;
    self.picturetableView.hidden = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"FilesFolderView"];
    self.navigationItem.rightBarButtonItem.enabled = YES;
    //xy add 针对bug54853 
    PCAppDelegate *appDelegate = (PCAppDelegate*)[[UIApplication sharedApplication] delegate] ;
    appDelegate.tabbarContent.selectedIndex = 0;
    
    //搜索页面中，不需要做特殊处理。
    if (self.searchDisplayController.active) {
        [self.searchDisplayController.searchResultsTableView reloadData];
        [self.searchBar becomeFirstResponder];
        return;
    }
    
    //[self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController setNavigationBarHidden:NO];
    
    
    if (bViewFirstAppear == YES) {
        CGFloat width = self.view.bounds.size.width;
        CGFloat height = self.view.bounds.size.height;
        self.searchBar.hidden = YES;
        self.tableView.frame = CGRectMake(0, 0, width, height);
        bViewFirstAppear = NO;
    }

//    if ([[PCSettings sharedSettings] currentDeviceType] == DEVICE_TYPE_POPOBOX)
//    {
//        self.navigationItem.title = NSLocalizedString(@"selectDisk", nil);
//    }
//    else
//    {
        self.navigationItem.title = NSLocalizedString(@"paopaoyun", nil);
//    }
    
//    modify by xy bugID:54192
//    刚选择完设备后不显示背景图片和没有任何文件资源的提示，加载完成后再显示。
   
    if ([dicatorView isAnimating])
    {
        self.picturetableView.hidden = YES;
    }
   
    //bugID：54349   当设备无硬盘时，文件管理和图片集两个页面的提示信息图标可上下拖动 modify by xy
    picturetableView.scrollEnabled = NO;    
    if ([PCLogin getAllDevices]==nil)
    {
        [self loadDeviceFailed];
    }
    else if([[PCLogin getAllDevices] count]==0)
    {
        [self noBoxFoundOrNoContent:NO];
    }
    else{
        if ([PCLogin getResource] && (isNetworkError || isRefresh)) {
            isRefresh = NO;
            [dicatorView startAnimating];
            UIButton *refreshImg = (UIButton *)self.navigationItem.rightBarButtonItem.customView;
            refreshImg.enabled = NO;
            [PCUtilityUiOperate animateRefreshBtn:refreshImg];
            
            [tableData removeAllObjects];
            [tableView reloadData];
            [self getFolderList];
            refreshImg.enabled = NO;
        }
        else
        {
            if ([tableData count] == 0 && isFinish )
            {
                self.tableView.hidden = YES;
                [self noBoxFoundOrNoContent:YES];
                
            }
        }
    }
    
    if (!isFinish)
    {
        [dicatorView startAnimating];
        UIButton *refreshImg = (UIButton *)self.navigationItem.rightBarButtonItem.customView;
        refreshImg.enabled = NO;
        [PCUtilityUiOperate animateRefreshBtn:refreshImg];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self layoutSubviews];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"FilesFolderView"];
    if (shareUrl)
        [shareUrl cancelConnection];
    
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
    
    if (self.searchDisplayController.isActive) {
        if(([self.filteredListContent count] ==2)
             &&[[self.filteredListContent objectAtIndex:1] isKindOfClass:[NSString class]]
)
        {
            self.filteredListContent = [NSMutableArray arrayWithObjects: @"",@"点击搜索按钮进行搜索", nil];
        }
    }
    
    if (self.isMovingFromParentViewController) {
        [self cancelProcess];
    }
    //[self.searchDisplayController setActive:NO animated:NO];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.searchWasActive = [self.searchDisplayController isActive];
    self.savedSearchTerm = [self.searchDisplayController.searchBar text];
}

#pragma mark -
#pragma mark QLPreviewControllerDataSource

// Returns the number of items that the preview controller should preview
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)previewController
{
    return 1;
}

- (void)previewControllerDidDismiss:(QLPreviewController *)controller
{
    // if the preview dismissed (done button touched), use this method to post-process previews
}

// returns the item that the preview controller should preview
- (id)previewController:(QLPreviewController *)previewController previewItemAtIndex:(NSInteger)idx
{
    return [NSURL fileURLWithPath:localPath];
}

- (void)previewControllerWillDismiss:(QLPreviewController *)controller
{
    if (self.navigationController) {
        [self.navigationController setToolbarHidden:YES animated:NO];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self layoutSubviews];
    if ([self.view viewWithTag:SEARCH_DICTATOR_TAG]) {
        ((UIView*)[self.view viewWithTag:SEARCH_DICTATOR_TAG]).center = self.view.center;
    }

}

#pragma mark - private methods
- (void)layoutSubviews
{
    dicatorView.center = self.view.center;
    if (IS_IPAD)
    {
        [self setTabeleHeadViewCenter];
        [self.tableView reloadData];
    }
}
/*
- (NSString*) formatFileSize:(long long)size isNeedBlank:(BOOL)isNeedBlank {
    NSString *result = nil;
    NSString *blank = @"";
    if (isNeedBlank) blank = @" ";
    if (size >= 1048576) {
        result = [NSString stringWithFormat:@"%.2f%@GB",  (double)size / 1048576, blank];
    }
    else if (size >= 1024) {
        result = [NSString stringWithFormat:@"%.1f%@MB",  (double)size / 1024, blank];
    }
    else {
        result = [NSString stringWithFormat:@"%.0f%@KB",  (double)size, blank];
    }
    return result;
}
*/

- (void) refreshTable
{
    [self layoutSubviews];
    
    if (isSearchDisplay) {
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
    else
    {
        [self.tableView reloadData];
        if (tableData.count)
        {
            [PCSettings sharedSettings].folderInfos  = tableData;
            
            CGFloat width = tableView.bounds.size.width;
            CGFloat height = tableView.bounds.size.height;
            CGFloat searchBarHeight = [searchBar bounds].size.height;
            if([[PCSettings sharedSettings] currentDeviceType] == DEVICE_TYPE_POPOBOX)
            {
                self.tableView.frame = CGRectMake(0, 0, width, height);
                self.tableView.hidden = NO;
                self.searchBar.hidden = YES;
                self.picturetableView.hidden = YES;
            }
            else
            {
                self.tableView.frame = CGRectMake(0, searchBarHeight, width, height);
                self.tableView.hidden = NO;
                self.searchBar.hidden = NO;
                self.picturetableView.hidden = YES;
            }
        }
        else {
            self.tableView.hidden = YES;
            self.searchBar.hidden = YES;
            [self noBoxFoundOrNoContent:YES];
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

- (void) shareUrlFail:(NSString*)errorDescription {
    [dicatorView stopAnimating];
    [PCUtilityUiOperate showErrorAlert:errorDescription delegate:nil];
}

- (void) shareUrlStart {
    [dicatorView startAnimating];
}

- (void) shareUrlFinish {
    [dicatorView stopAnimating];
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
        return 1;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor colorWithRed:247.0f/255.0f green:247.0f/255.0f blue:247.0f/255.0f alpha:1.0f];
    NSLog(@"%@",NSStringFromCGRect(cell.bounds));
}

- (NSInteger)tableView:(UITableView *)t_tableView numberOfRowsInSection:(NSInteger)section
{
    if (t_tableView == self.searchDisplayController.searchResultsTableView)
	{
        if (self.isOpen)
        {
            if (self.selectIndexPath.section == section)
            {
                return 2;
            }
        }
        else{
            return 1;
        }
    }
	else
	{
        return [tableData count];
    }
    
    return 0;
}


-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (self.isOpen&&self.selectIndexPath.section == indexPath.section&&indexPath.row!=0)
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
    static NSString *CellIdentifierNormal = @"NormalCell";
    
    if (_tableView == self.searchDisplayController.searchResultsTableView)
    {
        if ([self.filteredListContent count] ==2
            &&[[self.filteredListContent objectAtIndex:0] isKindOfClass:[NSString class]]
            && [[self.filteredListContent objectAtIndex:0] isEqualToString:@""]) {
            UITableViewCell *cellNormal = [_tableView dequeueReusableCellWithIdentifier:CellIdentifierNormal];
            
            if (cellNormal == nil)
            {
                cellNormal = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault
                                                     reuseIdentifier: CellIdentifierNormal] autorelease];
                cellNormal.selectionStyle = UITableViewCellSelectionStyleNone;
                cellNormal.accessoryType = UITableViewCellAccessoryNone;
                cellNormal.textLabel.font = [UIFont systemFontOfSize:16];
                cellNormal.textLabel.textColor = [UIColor darkGrayColor];
                cellNormal.textLabel.textAlignment = UITextAlignmentCenter;
            }
            
            cellNormal.textLabel.text = [self.filteredListContent objectAtIndex:indexPath.section];
            return cellNormal;
        }
    }

    
    if (_tableView == self.tableView) {
        return [self createCellForFileListTableAtIndexPath:indexPath];
    }
    else
    {
        return [self createCellForSearchTableAtIndexPath:indexPath];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  
    if (isFinish && (_tableView == self.tableView))
    {
        if (indexPath.row < tableData.count)
            {
                FileListViewController *fileListView = [[FileListViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"FileListView"] bundle:nil] ;
                PCFileInfo *fileInfo = [tableData objectAtIndex:indexPath.row];
                if ([[PCSettings sharedSettings] currentDeviceType] == DEVICE_TYPE_POPOBOX)
                {
                    fileListView.navigationItem.title = NSLocalizedString(@"paopaoyun", nil);
                    UIBarButtonItem *backItem = [[UIBarButtonItem alloc]init];
                    backItem.title = NSLocalizedString(@"disk", nil);
                    backItem.tintColor = [UIColor colorWithRed:129/255.0 green:129/255.0  blue:129/255.0 alpha:1.0];
                    self.navigationItem.backBarButtonItem = backItem;
                    [backItem release];
                }
                else
                {
                    fileListView.navigationItem.title = fileInfo.name;
                }
                
                fileListView.dirPath   = fileInfo.path;
                fileListView.dirName = fileInfo.name;
                [self.navigationController pushViewController:fileListView animated:YES];
                [fileListView release];
        }
        [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
}

- (void)dealloc {
    self.lblResult = nil;
    self.localPath = nil;
    if (shareUrl) [shareUrl release];
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
    self.selectIndexPath = nil;
    _refreshHeaderView=nil;
    _refreshHeaderPictureView=nil;
    [tableData release];
    [folderSizeData release];
    
    if (self.currentRequest) {
        [restClient cancelRequest:self.currentRequest];
        self.currentRequest = nil;
    }
    [restClient release];
    
    [super dealloc];
}

//------------------------------------------------
- (void) getFolderList {
    isFinish = NO;
    isNetworkError = NO;
    
    if (restClient == nil) {
        restClient = [[PCRestClient alloc] init];
        restClient.delegate = self;
    }

    if ([[PCSettings sharedSettings] currentDeviceType] == DEVICE_TYPE_POPOBOX)
    {
        [self getFolderSize];
    }
    else
    {
        [self getFolderInfo];
    }
}

//获取磁盘空间
- (void) getFolderSize
{
    self.currentRequest = [restClient getAllDiskSpaceInfo];
}

//获取磁盘信息
- (void) getFolderInfo
{
    self.currentRequest = [restClient getFileListInfo:nil];
}

//-------------------------------------------------------------


#pragma mark - UISearchDisplayDelegate Mehtods
- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView
{
    isSearchDisplay = YES;
    _refreshHeaderView = nil;
    self.filteredListContent = [NSMutableArray arrayWithObjects: @"",@"点击搜索按钮进行搜索", nil];
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView;
{
    if (shareUrl)
        [shareUrl cancelConnection];
    
    if (self.selectIndexPath)
    {
        self.isOpen = NO;
        [self didSelectCellRow:NO otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];
        self.selectIndexPath = nil;
    }
    [self.tableView reloadData];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView
{
     isSearchDisplay = NO;
    _refreshHeaderView = nil;

    if (fileSearch) {
        fileSearchCancel =    [[FileSearch alloc] init];
        [fileSearchCancel searchCancelWithdelegate:self  andSerchID:[fileSearch currentSearchID]];
        [PCUtilityUiOperate showOKAlert: NSLocalizedString(@"SearchBeCancel", nil) delegate:self];
        [fileSearch cancel];
        [fileSearch release];
        fileSearch = nil;
    }

    [self.filteredListContent removeAllObjects];
    [self.historyfilteredListContent removeAllObjects];

    //[dicatorView stopAnimating];
    if ([self.view viewWithTag:SEARCH_DICTATOR_TAG]) {
        [[self.view viewWithTag:SEARCH_DICTATOR_TAG] removeFromSuperview];
    }

    
    if (tableData && (tableData.count>0))
    {
        [lblResult setHidden:YES];
    }
    else
    {
        [lblResult setHidden:NO];
    }
}

#pragma mark - UISearchBarDelegate Mehtods
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText  // called when text changes (including clear)
{
    //有搜索结果数据，并且当前搜索框内容包含上次搜索关键字
    BOOL hasResults = ([historyfilteredListContent count]>0)&&[[self.historyfilteredListContent objectAtIndex:0] isKindOfClass:[NSDictionary class]];
    BOOL hasResults2 = ([filteredListContent count]>0)&&[[self.filteredListContent objectAtIndex:0] isKindOfClass:[NSDictionary class]];
    
    
    if ((self.keyWord  && searchText)
        &&(hasResults2||hasResults)
        &&([searchText  rangeOfString:self.keyWord options:NSCaseInsensitiveSearch].length == [self.keyWord length]))
    {
        NSMutableArray *newArray =[NSMutableArray array];
        if (!historyfilteredListContent || ([historyfilteredListContent count]==0)) {
            self.historyfilteredListContent = [NSMutableArray array];
            for (NSDictionary *node in self.filteredListContent)
            {
                [historyfilteredListContent addObject:node];
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
    if (_searchBar.text.length < 2) {
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

    [self.historyfilteredListContent removeAllObjects];
    self.filteredListContent = [NSMutableArray arrayWithObjects:@"",@"搜索中",nil];
    [self.searchDisplayController.searchResultsTableView reloadData];

    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *searchText = [_searchBar.text stringByTrimmingCharactersInSet:set];
    
    if (!fileSearch)
        fileSearch = [[FileSearch alloc] init];
    [fileSearch searchFile:@"/" key:searchText delegate:self];

    
//    [dicatorView startAnimating];
//    [self.view bringSubviewToFront:dicatorView];

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
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)_searchBar
{
    searchBar.text = @"";
    [searchBar resignFirstResponder];
}


//-----------------------------------------------------------
- (void) doFail:(NSString*)error {
    isFinish = YES;
    isNetworkError = YES;
    [dicatorView stopAnimating];
    [self doneLoadingTableViewData];
    [PCUtilityUiOperate showErrorAlert:error delegate:nil];
}

- (void) getDeviceList
{
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[PCLogin sharedManager] getDevicesList:self];
}

- (void) loginFail:(PCLogin*)pcLogin error:(NSString*)error
{
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [PCUtilityUiOperate showErrorAlert:error delegate:nil];
}

- (void) loginFinish:(PCLogin*)pcLogin {
//    [pcLogin release];
//    [tableData removeAllObjects];
//    [tableView reloadData];
//    [self getFolderList];
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if ([PCLogin getResource])
    {
        [self refreshData:nil];
        [[CameraUploadManager sharedManager] startCameraUpload];
    }
    else
    {
        if ([[PCLogin getAllDevices] count]==0)
        {
            [self noBoxFoundOrNoContent:NO];
        }
    }
}

- (void) logOut {
    isRefresh = YES;
    isNetworkError = NO;
    isFinish = YES;
    if (self.currentRequest) {
        [restClient cancelRequest:self.currentRequest];
        self.currentRequest = nil;
    }
    [tableData removeAllObjects];
    [tableView reloadData];
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
}

- (void) showProgressView {
    //    [self progressingViewRelease];
    progressingViewController = [[PCProgressingViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"PCProgressingView"] bundle:nil];
    [self.view.window addSubview:progressingViewController.view];
}

//----------------------------------------------------------
#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
    _reloading = YES;
    [dicatorView startAnimating];
    
//    modify by xy  bugID:54229 去掉选择磁盘界面点刷新按钮的跳动
//    [tableData removeAllObjects];
//    [tableView reloadData];
    [self getFolderList];
	
}

- (void)doneLoadingTableViewData{
    if([tableData count]==0)
    {
        self.tableView.hidden = YES;
        self.picturetableView.hidden = NO;
        [self noBoxFoundOrNoContent:YES];
    }
	//  model should call this when its done loading
	_reloading = NO;
    if (isSearchDisplay) {
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.searchDisplayController.searchResultsTableView];
    }
    else
    {
       [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView]; 
    }
	
    [_refreshHeaderPictureView egoRefreshScrollViewDataSourceDidFinishedLoading:self.picturetableView];
	
    [dicatorView stopAnimating];
    UIButton *refreshImg = (UIButton *)self.navigationItem.rightBarButtonItem.customView;
    [refreshImg.layer removeAllAnimations];
    refreshImg.enabled = YES;
}


#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{	
	if (isFinish) {
        [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
        [_refreshHeaderPictureView egoRefreshScrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	if (isFinish) {
        [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
        [_refreshHeaderPictureView egoRefreshScrollViewDidEndDragging:scrollView];
    }
}


#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	
	[self reloadTableViewDataSource];
//	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
	
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	
	return _reloading; // should return if data source model is reloading
	
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	
	return [NSDate date]; // should return date data source was last changed
	
}


#pragma mark - callback methods

- (void)refreshData:(id)recognizer
{
    if ([PCLogin getResource] == nil) {
        [self getDeviceList];
        return;
    }
    
    if (!self.picturetableView.hidden) {
        self.picturetableView.hidden = YES;
    }
    UIButton *refreshImg = (UIButton *)self.navigationItem.rightBarButtonItem.customView;
    refreshImg.enabled = NO;
    [PCUtilityUiOperate animateRefreshBtn:refreshImg];
    
    [self reloadTableViewDataSource];
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
    //||后面表示 是开始搜索前的 提示信息数据，并没有搜索到结果数据
    if ((!filteredListContent.count)||([self.filteredListContent count] ==2
                                       &&[[self.filteredListContent objectAtIndex:0] isKindOfClass:[NSString class]]
                                       && [[self.filteredListContent objectAtIndex:0] isEqualToString:@""])) {
        
        self.filteredListContent = [NSMutableArray arrayWithObjects:@"", @"没有找到相关文件。",nil];
        //        lblResult.text = NSLocalizedString(@"NoResultForSearch", nil);
        //        [lblResult setHidden:NO];
    }
    
    [fileSearch release];
    fileSearch = nil;
    if ([self.view viewWithTag:SEARCH_DICTATOR_TAG]) {
        [[self.view viewWithTag:SEARCH_DICTATOR_TAG] removeFromSuperview];
    }

    [self.searchDisplayController.searchResultsTableView reloadData];
    
    isFinish = YES;
    [self doneLoadingTableViewData];
}

- (void) searchFileFail:(FileSearch*)_fileSearch error:(NSString*)error {
    [self doFail:error];
    if ((!filteredListContent.count)||([self.filteredListContent count] ==2
                                       &&[[self.filteredListContent objectAtIndex:0] isKindOfClass:[NSString class]]
                                       && [[self.filteredListContent objectAtIndex:0] isEqualToString:@""])) {
        
        self.filteredListContent = [NSMutableArray arrayWithObjects:@"", @"没有找到相关文件。",nil];
        //        lblResult.text = NSLocalizedString(@"NoResultForSearch", nil);
        //        [lblResult setHidden:NO];
    }
    
    [fileSearch release];
    fileSearch = nil;
    
    [self.searchDisplayController.searchResultsTableView reloadData];

    isFinish = YES;

    //[self doneLoadingTableViewData];
    if ([self.view viewWithTag:SEARCH_DICTATOR_TAG]) {
        [[self.view viewWithTag:SEARCH_DICTATOR_TAG] removeFromSuperview];
    }
}

- (void) searchCancelFail:(FileSearch*)fileSearch error:(NSString*)error
{
    [fileSearchCancel release];
    fileSearchCancel = nil;
}
- (void) searchCancelFinish:(FileSearch*)fileSearch
{
    [fileSearchCancel release];
    fileSearchCancel = nil;
}


//create cell
- (UITableViewCell *)createCellForSearchTableAtIndexPath:(NSIndexPath *)indexPath
{
	PCFileInfo *fileInfo =[self.filteredListContent objectAtIndex:indexPath.section];
    if (self.isOpen&&self.selectIndexPath.section == indexPath.section&&indexPath.row!=0)
    {
        static NSString *CellIdentifier = @"Cell2";
        PCFileExpansionCell *cell2 = [self.searchDisplayController.searchResultsTableView dequeueReusableCellWithIdentifier:CellIdentifier];
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
        cell2.tag = indexPath.section;
        if (fileInfo.bFileFoldType)
        {
            [cell2 initActionContent:FILELIST_FOLDER];
        }
        else
        {
			DownloadStatus status = [[PCUtilityFileOperate downloadManager] getFileStatus:fileInfo.path
																 andModifyTime:fileInfo.modifyTime];
            if (status == kStatusNoDownload)
            {
                [cell2 initActionContent:FILELIST_FILE_NO_FAVORITE];
            }
            else
            {
                [cell2 initActionContent:FILELIST_FILE_FAVORITE];
            }
        }
        return cell2;
    }
    else
    {
        static NSString *CellIdentifier = @"fileCellIdentifier";
        PCFileCell *cell = [self.searchDisplayController.searchResultsTableView  dequeueReusableCellWithIdentifier:CellIdentifier];
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
        
        DownloadStatus status = [[PCUtilityFileOperate downloadManager] getFileStatus:fileInfo.path
															 andModifyTime:fileInfo.modifyTime];
        
        cell.delegate = self;
        cell.indexRow = indexPath.row;
        cell.indexSection = indexPath.section;
        
        if (fileInfo.bFileFoldType)
        {
            [cell changeStatusImageWithFileStatus:status];
            
            cell.imageView.image = [UIImage imageNamed:@"file_folder.png"];
            cell.detailTextLabel.text = nil;
        }
        else
        {
            cell.imageView.image = [UIImage imageNamed:[PCUtilityFileOperate getImgByExt:fileInfo.ext]];
            cell.detailTextLabel.text = [PCUtilityFileOperate formatFileSize:[fileInfo.size longLongValue] isNeedBlank:YES];
            [cell changeStatusImageWithFileStatus:status];
        }
        cell.textLabel.text = fileInfo.name;
        return cell;
    }
}

- (UITableViewCell *)createCellForFileListTableAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier1 = @"Cell1";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier1] autorelease];
    }
    UIView *subView = [cell.contentView viewWithTag:WARNING_IMAGE_TAG];
    if (subView) {
            [subView removeFromSuperview];
    }
    
    if (indexPath.row < tableData.count) {
        PCFileInfo *fileInfo = [tableData objectAtIndex:indexPath.row];
        if ([[PCSettings sharedSettings] currentDeviceType] == DEVICE_TYPE_POPOBOX)
        {
            //            NSLog(@"是盒子 显示磁盘容量");
            cell.textLabel.text = fileInfo.name; //waring.png
            cell.imageView.image = [UIImage imageNamed:@"disk.png"];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:10.0f];
           
            if ([folderSizeData count] == 0)
            {
                cell.detailTextLabel.textColor = [UIColor redColor];
                cell.detailTextLabel.text  = NSLocalizedString(@"getDiskInfoError", nil);
                return cell;
            }
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];
            [folderSizeData enumerateObjectsUsingBlock:^(PCDiskInfo *fileSizeInfo, NSUInteger idx, BOOL *stop)
             {
                 if ([fileSizeInfo.path isEqualToString:fileInfo.path]) {
                     long long max = [fileSizeInfo.max longLongValue] * 1024;
                     long long used = [fileSizeInfo.used longLongValue] * 1024;
                     
                     long long canUse = max - used;
                     if ((double)canUse/max*100 < 5)
                     {
                         BOOL isLandScape = [UIApplication sharedApplication].statusBarOrientation > UIInterfaceOrientationPortraitUpsideDown;
                         CGFloat x = [UIScreen mainScreen].bounds.size.width - 2*(IS_IPAD ? 40 : 5) - 80;
                         if (IS_IPAD && isLandScape)
                         {
                             x=864;
                         }
                         UIView *warningView = [[UIView alloc] initWithFrame:CGRectMake(x, 28, 60, 20)];
                         [cell.contentView addSubview:warningView];
                         warningView.tag = WARNING_IMAGE_TAG;
                        
                         UIImageView *warningImgView =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"disk_warn.png"]];
                         warningImgView.frame = CGRectMake(0, 4, 15, 15);
                         [warningView addSubview:warningImgView];
                         [warningImgView release];
                         
                         UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, 40, 20)];
                         label.backgroundColor = [UIColor clearColor];
                         label.textColor = [UIColor redColor];
                         label.text = @"空间提醒";
                         label.font = [UIFont systemFontOfSize:10.0f];
                         [warningView addSubview:label];
                         [label release];
                         
                         [warningView release];
                         
                     }
                     else
                     {
                         //cell.detailTextLabel.textColor = [UIColor darkGrayColor];
                     }
                     cell.detailTextLabel.text  =
                     [NSString stringWithFormat:@"%@: %@    %@: %@",NSLocalizedString(@"TotalSpaceSize", nil),[PCUtilityFileOperate formatFileSize:max isNeedBlank:YES],
                      NSLocalizedString(@"UsedSpaceSize", nil),[PCUtilityFileOperate formatFileSize:canUse isNeedBlank:YES]];
                     *stop = YES;
                 }
         }];
        }
        else
        {
            //             NSLog(@"是PC 不显示磁盘容量");
            cell.textLabel.text = fileInfo.name;
            
            if (fileInfo.bFileFoldType)
            {
                cell.imageView.image = [UIImage imageNamed:@"file_folder.png"];
            }
            else
            {
                cell.imageView.image = [UIImage imageNamed:[PCUtilityFileOperate getImgByExt:fileInfo.ext]];
            }
            cell.detailTextLabel.text = @"";
        }
    }
    
    return cell;
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
    fileCache = [[FileCache alloc] init];
    DownloadStatus status = [[PCUtilityFileOperate downloadManager] getFileStatus:fileInfo.path
                                                         andModifyTime:fileInfo.modifyTime];
    BOOL bImageCache = NO;
    
    fileCache.currentDeviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
    [fileCache setProgressView:progressingViewController.progressView progressScale:1.0];
    if ([fileInfo.size longLongValue] ==0 ) {
        [self stopCheckAndOpenFileWithError:NSLocalizedString(@"ConfirmEmptyFile", nil)];
    }
    //add by libing 2013-6-26 fix bug bug54838  bug 55854
    else if(!(fileInfo.path&&[PCUtilityFileOperate itemCanOpenWithPath:fileInfo.path]))
    {
        [self stopCheckAndOpenFileWithError:NSLocalizedString(@"NoSuitableProgram", nil)];
    }
    //非图片文件并有cache缓存 或 图片有缓存在 slideimage
    else if (([fileCache readFileFromCacheWithFileInfo:fileInfo withType:TYPE_CACHE_SLIDEIMAGE]
              && (bImageCache = !bImageCache))
             ||
             ((fileInfo.mFileType != PC_FILE_IMAGE)
              &&
              [fileCache GetFuLLSizeFileFromCacheWithFileInfo:fileInfo withType:TYPE_CACHE_FILE]))
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
                [self.navigationController pushViewController:newController animated:YES];
                [newController release];
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
    //图片不再用收藏类型的，用图片集类型的，防止图片过大消耗内存
    else if ([fileCache readFileFromCacheWithFileInfo:fileInfo withType:TYPE_DOWNLOAD_FILE] &&
             (status == kStatusDownloaded || status == kStatusDownloading)&&
             (fileInfo.mFileType != PC_FILE_IMAGE))
    {
        [self endProcess];
        
        if (status == kStatusDownloaded)
        {
            if (fileInfo.mFileType != PC_FILE_OTHER)
            {
                FileCacheController *cacheController = [[FileCacheController alloc] initWithPath:[fileCache getCacheFilePath:fileInfo.path
                                                                                                                    withType:TYPE_DOWNLOAD_FILE]
                                                                           andFinishLoadingState:YES
                                                                                   andDataSource:currentData
                                                                                  andCurrentPCFileInfo:fileInfo
                                                                       andLastViewControllerName:self.navigationItem.title];
                cacheController.title =  fileInfo.name;
                
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
        NSString *filePath =nil;
        int fileType = TYPE_CACHE_FILE;
        if (fileInfo.mFileType == PC_FILE_IMAGE) {
            fileType =TYPE_CACHE_SLIDEIMAGE;
        }
        filePath = [fileCache getCacheFilePath:fileInfo.path withType:fileType];
        FileCacheController *cacheController = [[FileCacheController alloc] initWithPath:            filePath
                                                                   andFinishLoadingState:NO
                                                                           andDataSource:currentData
                                                                          andCurrentPCFileInfo:fileInfo
                                                               andLastViewControllerName:self.navigationItem.title];
        
        if (fileInfo.mFileType == PC_FILE_IMAGE)
        {
            KTPhotoScrollViewController *newController = [[KTPhotoScrollViewController alloc]
                                                          initWithDataSource:cacheController
                                                          andStartWithPhotoAtIndex:cacheController.startWithIndex_];
            [self.navigationController pushViewController:newController animated:YES];                            [newController release];
        }
        else{
            if ([fileCache cacheFile:fileInfo.path viewType:fileType viewController:cacheController fileSize:[fileInfo.size longLongValue] modifyGTMTime:[fileInfo.modifyTime longLongValue]  showAlert:YES]) {
                cacheController.hidesBottomBarWhenPushed = YES;
                cacheController.title = fileInfo.name;
                [self.navigationController pushViewController:cacheController animated:YES];
                [self startProcess];
            }
        }
        [cacheController release];
    }
}

#pragma mark - PCFileCell delegate
- (void)didSelectCell:(NSIndexPath *)indexPath//只有搜索结果的tableview的cell 有这个响应
{
    if (isProcessing) return;
    if (indexPath.section < self.filteredListContent.count)
    {
        PCFileInfo *fileInfo = [self.filteredListContent objectAtIndex:indexPath.section];
        if (fileInfo.bFileFoldType) {
            FileListViewController *fileListView = [[FileListViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"FileListView"] bundle:nil];
            fileListView.navigationItem.title = fileInfo.name;
            fileListView.dirPath = fileInfo.path;
            [self.navigationController pushViewController:fileListView animated:YES];
            [fileListView release];
        }
        else {
            [self checkAndOpenFileWithFileInfo:fileInfo andTotalData:self.filteredListContent];
        }
    }

    [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)expansionView:(NSIndexPath *)indexPath
{
     if (indexPath.section < self.filteredListContent.count && indexPath.row == 0 && _reloading == NO)
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
                [self didSelectCellRow:NO otherCellIsOpen:YES currentIndexPath:indexPath];
            }
        }
    }
}

/**
 * 打开工具cell
 * @param  allCellsIsClose  所有的cell是否都是关闭的
 * @param  otherCellIsOpen  操作的cell以外的cell是否有打开的
 */
- (void)didSelectCellRow:(BOOL)allCellsIsClose otherCellIsOpen:(BOOL)selectedCellIsClose currentIndexPath:(NSIndexPath *) currentIndexPath;
{
    self.isOpen = allCellsIsClose;
    
    //PCFileCell *cell = (PCFileCell *)[currentTable cellForRowAtIndexPath:self.selectIndexPath];
    UITableViewCell *cell = (UITableViewCell *)[self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:self.selectIndexPath];
    if (cell  && [cell isKindOfClass:[PCFileCell class]]) {
        [(PCFileCell*)cell changeArrowImageWithExpansion:allCellsIsClose];
    }

    [self.searchDisplayController.searchResultsTableView beginUpdates];
    
    int section = self.selectIndexPath.section;
	NSMutableArray* rowToInsert = [[NSMutableArray alloc] init];
    NSIndexPath* indexPathToInsert = [NSIndexPath indexPathForRow:1 inSection:section];
    [rowToInsert addObject:indexPathToInsert];
	
	if (allCellsIsClose)
    {
        [self.searchDisplayController.searchResultsTableView insertRowsAtIndexPaths:rowToInsert withRowAnimation:UITableViewRowAnimationTop];
    }
	else
    {
        [self.searchDisplayController.searchResultsTableView deleteRowsAtIndexPaths:rowToInsert withRowAnimation:UITableViewRowAnimationTop];
    }
    
	[rowToInsert release];
	
	[self.searchDisplayController.searchResultsTableView endUpdates];
    
    if (selectedCellIsClose)
    {
        self.isOpen = YES;
        self.selectIndexPath = [currentIndexPath retain];
        [currentIndexPath release];
        [self didSelectCellRow:YES otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];
    }
    
    if (self.isOpen)
    {
        UITableViewCell *cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:selectIndexPath];
        
        //当前滚动到的位置
        CGFloat deltaY = self.searchDisplayController.searchResultsTableView.contentOffset.y;
        //cell的位置
        CGPoint position = CGPointMake(0, cell.frame.origin.y + cell.frame.size.height*2 -5 );
        //tableview的高度
        CGFloat height = self.searchDisplayController.searchResultsTableView.frame.size.height;
        
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
        
        [self.searchDisplayController.searchResultsTableView setContentOffset:CGPointMake(0, offsetY + deltaY) animated:YES];
    }
}

#pragma mark - PCFileExpansionCell delegate
- (void)shareButtonClick
{
    NSMutableArray *currentData = isSearchDisplay?filteredListContent:tableData;
    PCFileInfo *fileInfo = [currentData objectAtIndex:self.selectIndexPath.section];;
    if (!shareUrl)
        shareUrl = [[PCShareUrl alloc] init];
    [shareUrl shareFileWithInfo:fileInfo andDelegate:self];
}

- (void)collectButtonClick
{
    NSMutableArray *currentData = isSearchDisplay?filteredListContent:tableData;
    PCFileInfo *fileInfo = [currentData objectAtIndex:self.selectIndexPath.section];
    fileCache = [[FileCache alloc] init];
    fileCache.currentDeviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
    
    if ([fileInfo.size longLongValue] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"ConfirmEmptyFile", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
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
        [[PCUtilityFileOperate downloadManager] addItem:fileInfo.path fileSize:[fileInfo.size longLongValue] modifyGTMTime:[fileInfo.modifyTime longLongValue]];
        //这里能点开的只有 搜索table. self.table 是最上层的没收藏。
        if (isSearchDisplay) {
             [self.searchDisplayController.searchResultsTableView reloadData];
        }
        else
        {
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
    Alert.tag = CONFIRM_CANCEL_COLLECT_TAG;
    [Alert show];
    [Alert release];
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

#pragma mark - PCRestClientDelegate

- (void)restClient:(PCRestClient*)client gotDiskSpace:(NSArray*)disks
{
    self.currentRequest = nil;
    isFinish = YES;
    
    if (folderSizeData)
        [folderSizeData removeAllObjects];
    else
        folderSizeData = [[NSMutableArray alloc] init];
    [folderSizeData addObjectsFromArray:disks];
    
    self.currentRequest = nil;
    [self getFolderInfo];
}

- (void)restClient:(PCRestClient*)client getDiskSpaceFailedWithError:(NSError*)error
{
    isFinish = YES;
    [self doneLoadingTableViewData];
    
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        isNetworkError = YES;
    }
    if (error.code == PC_Err_NoDisk) {
        [self noBoxFoundOrNoContent:YES];
    }
    if (error.code == PC_Err_BoxUnbind) {
        [self noBoxFoundOrNoContent:NO];
        [PCLogin removeDevice:[PCLogin getResource]];
    }
    [ErrorHandler showErrorAlert:error];
    
    self.currentRequest = nil;
}

- (void)restClient:(PCRestClient*)client gotFileListInfo:(NSArray*)fileListInfo
{
    self.currentRequest = nil;
    isFinish = YES;
    [self doneLoadingTableViewData];
    
    [tableData removeAllObjects];
    [tableData addObjectsFromArray:fileListInfo];

    [self refreshTable];
}

- (void)restClient:(PCRestClient*)client getFileListInfoFailedWithError:(NSError*)error
{
    isFinish = YES;
    [self doneLoadingTableViewData];
    
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        isNetworkError = YES;
    }
    if (error.code == PC_Err_NoDisk) {
        [tableData removeAllObjects];
        [tableView reloadData];
        [self noBoxFoundOrNoContent:YES];
    }
    if (error.code == PC_Err_BoxUnbind) {
        [self noBoxFoundOrNoContent:NO];
        [PCLogin removeDevice:[PCLogin getResource]];
    }
    [ErrorHandler showErrorAlert:error];
    
    self.currentRequest = nil;
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == [alertView firstOtherButtonIndex]) {
        if (alertView.tag == CONFIRM_CANCEL_COLLECT_TAG) {
            NSMutableArray *currentData = isSearchDisplay?filteredListContent:tableData;
            UITableView *currentTable = isSearchDisplay?self.searchDisplayController.searchResultsTableView:tableView;
            PCFileInfo *fileInfo = [currentData objectAtIndex:self.selectIndexPath.section];
            [[PCUtilityFileOperate downloadManager] deleteDownloadItem: fileInfo.path fileStatus:[[PCUtilityFileOperate downloadManager] getFileStatus:fileInfo.path andModifyTime:fileInfo.modifyTime]];
            [currentTable reloadData];
        }
    }
}

@end
