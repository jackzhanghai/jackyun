//
//  PictureScanFolderViewController.m
//  popoCloud
//
//  Created by suleyu on 14-2-7.
//
//

#import "PictureScanFolderViewController.h"
#import "EGORefreshTableHeaderViewOriginal.h"
#import "PCFileCell.h"
#import "PCUtilityUiOperate.h"
#import "PCRestClient.h"
#import "PCLogin.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityDataManagement.h"
#import "PCAppDelegate.h"

#import "ELCAlbumPickerController.h"
#import "ELCImagePickerController.h"
#import "SettingPhotosPermissionViewController.h"
#import "FileUploadInfo.h"
#import "FileUploadManager.h"

@interface PictureScanFolderViewController () <PCRestClientDelegate, PCFileCellDelegate, PCFileCacheDelegate, EGORefreshTableHeaderOriginalDelegate, ELCImagePickerControllerDelegate, UIPopoverControllerDelegate>
{
    BOOL editing;
    PCRestClient *restClient;
    NSMutableDictionary *selectedDic;
    NSMutableArray *needLoadThumbImageArray;
    UIActivityIndicatorView *activityIndicator;
}

@property (nonatomic, retain) FileCache *thumbImgFileCache;
@property (nonatomic, retain) EGORefreshTableHeaderViewOriginal *refreshHeaderView;
@property (retain, nonatomic) UIPopoverController *popover;

@end

@implementation PictureScanFolderViewController
@synthesize dirName;
@synthesize dirPath;
@synthesize fileList;
@synthesize addFolders;
@synthesize delFolders;
@synthesize thumbImgFileCache;
@synthesize refreshHeaderView;
@synthesize popover;

#pragma mark - View lifecycle

- (id)initWithStyle:(UITableViewStyle)style editing:(BOOL)edit
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.hidesBottomBarWhenPushed = YES;
        editing = edit;
        if (editing) {
            selectedDic = [[NSMutableDictionary alloc] init];
        }
        needLoadThumbImageArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    if (editing) {
        self.navigationItem.rightBarButtonItem = [PCUtilityUiOperate createRefresh:self];
    }
    else {
        UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 23, 23)];
        [addButton setImage:[UIImage imageNamed:@"navigate_add"] forState:UIControlStateNormal];
        [addButton addTarget:self action:@selector(uploadPhoto) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc] initWithCustomView:addButton];
        self.navigationItem.rightBarButtonItem = addButtonItem;
        [addButtonItem release];
        [addButton release];
        
        [self createRefreshHeaderView];
    }
    
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = @"返回";
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    [temporaryBarButtonItem release];
    
    if (self.dirName) {
        self.title = self.dirName;
    }
    else if (self.dirPath) {
        self.title = [self.dirPath lastPathComponent];
    }
    else if (editing) {
        self.title = @"设置显示图片";
    }
    
    self.tableView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    self.tableView.rowHeight = TABLE_CELL_HEIGHT;
    self.tableView.editing = editing;
    
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if (activityIndicator == nil)
    {
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self.tableView addSubview:activityIndicator];
        activityIndicator.color = [UIColor grayColor];
        activityIndicator.center = CGPointMake(self.tableView.frame.size.width/2, self.tableView.frame.size.height/2);
        activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    }
    
    [self reloadTableViewDataSource];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hidePopover) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restorePopover) name:@"ScreenLockCorrect" object:nil];
}

- (void)createRefreshHeaderView
{
    EGORefreshTableHeaderViewOriginal *refreshView = [[EGORefreshTableHeaderViewOriginal alloc] initWithFrame:CGRectMake(0, -self.tableView.bounds.size.height, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
    refreshView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    refreshView.delegate = self;
    [self.tableView addSubview:refreshView];
    self.refreshHeaderView = refreshView;
    [refreshView release];
}

- (void)createEditTableHeaderView
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    headerView.backgroundColor = [UIColor colorWithRed:205.0f/255.0f green:230.0f/255.0f blue:1.0f alpha:1.0f];
    self.tableView.tableHeaderView = headerView;
    
    UILabel *headerMainLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 6, 200, 20)];
    headerMainLabel.backgroundColor = [UIColor clearColor];
    headerMainLabel.textColor = [UIColor colorWithRed:4.0f/255.0f green:140.0f/255.0f blue:202.0f/255.0f alpha:1.0f];
    headerMainLabel.text = @"请选择显示图片";
    headerMainLabel.font = [UIFont systemFontOfSize:15.0f];
    [headerView addSubview:headerMainLabel];
    [headerMainLabel release];
    
    UILabel *headerPromptLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 29, 200, 15)];
    headerPromptLabel.backgroundColor = [UIColor clearColor];
    headerPromptLabel.textColor = [UIColor colorWithRed:86.0f/255.0f green:187.0f/255.0f blue:1.0f alpha:1.0f];
    headerPromptLabel.text = @"可选择指定多个包含图片的文件夹";
    headerPromptLabel.font = [UIFont systemFontOfSize:13.0f];
    [headerView addSubview:headerPromptLabel];
    [headerPromptLabel release];
    
    UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    submitButton.frame = CGRectMake(self.view.frame.size.width - (IS_IPAD ? 78 : 67), 10, 60, 30);
    submitButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    submitButton.titleLabel.font = [UIFont systemFontOfSize:14.0f];
    [submitButton setBackgroundImage:[UIImage imageNamed:@"queding"] forState:UIControlStateNormal];
    [submitButton setBackgroundImage:[UIImage imageNamed:@"queding_d"] forState:UIControlStateHighlighted];
    [submitButton setTitle:@"提交" forState:UIControlStateNormal];
    [submitButton addTarget:self action:@selector(submit:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:submitButton];
    [headerView release];
}

-(void)createNoContentView
{
    int scale = IS_IPAD ? 2 : 1;
    BOOL isLandScape = [[UIApplication sharedApplication] statusBarOrientation] > UIDeviceOrientationPortraitUpsideDown;
    
    UIView *headView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [headView setBackgroundColor:[UIColor clearColor]];
    
    UIImage *emptyImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"empty" ofType:@"png"]];
    UIImageView *emptyImageView = [[UIImageView alloc] initWithImage:emptyImage];
    emptyImageView.tag = ImageTag;
    CGFloat offset = IS_IPAD ? (isLandScape ? 200 : 300) : TABLE_CELL_HEIGHT + emptyImage.size.height/2;
    emptyImageView.center = CGPointMake(self.view.center.x, offset);
    [headView addSubview:emptyImageView];
    [emptyImageView release];
    
    UILabel *noBoxLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50*scale)];
    [noBoxLabel setTextColor:[UIColor blackColor]];
    noBoxLabel.tag = LabelTitleTag;
    [noBoxLabel setBackgroundColor:[UIColor clearColor]];
    [noBoxLabel setTextAlignment:NSTextAlignmentCenter];
    [noBoxLabel setFont:[UIFont systemFontOfSize:15*scale]];
    [headView addSubview:noBoxLabel];
    noBoxLabel.text = NSLocalizedString(@"NoImageCurrent", nil);
    noBoxLabel.center = CGPointMake(self.view.center.x, emptyImageView.frame.origin.y+emptyImageView.frame.size.height+27*scale);
    [noBoxLabel release];
    
    if (!editing) {
        UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [refreshButton setTitle:@"刷新看看" forState:UIControlStateNormal];
        [refreshButton setTitleColor:UIColorFromRGB(0x0030ff) forState:UIControlStateNormal];
        refreshButton.titleLabel.font = [UIFont boldSystemFontOfSize:13*scale];
        refreshButton.frame = CGRectMake(self.view.center.x - 60, noBoxLabel.frame.origin.y+noBoxLabel.frame.size.height, 120, 15*scale);
        [refreshButton setBackgroundColor:[UIColor clearColor]];
        [refreshButton addTarget:self action:@selector(refreshData:) forControlEvents:UIControlEventTouchUpInside];
        [headView addSubview:refreshButton];
        refreshButton.tag = LabelDesTag;
    }
    
    UILabel *lblDes = [[UILabel alloc] initWithFrame:CGRectMake(20, noBoxLabel.frame.origin.y+noBoxLabel.frame.size.height+60*scale-60, self.view.frame.size.width-40, 120)];
    [lblDes setTextColor:[UIColor grayColor]];
    lblDes.tag = LabelDesDetailTag;
    [lblDes setBackgroundColor:[UIColor clearColor]];
    [lblDes setTextAlignment:NSTextAlignmentCenter];
    [lblDes setFont:[UIFont systemFontOfSize:13*scale]];
    lblDes.numberOfLines = 0;
    lblDes.text = NSLocalizedString(@"PopoCloudDespiseYou", nil);
    [headView addSubview:lblDes];
    [lblDes release];
    
    self.tableView.tableHeaderView = headView;
    self.tableView.scrollEnabled = NO;
    [headView release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.fileList = nil;
    self.refreshHeaderView = nil;
    [selectedDic removeAllObjects];
    [activityIndicator release];
    activityIndicator = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancelThumbImageCache];
    
    [dirName release];
    [dirPath release];
    [fileList release];
    [addFolders release];
    [delFolders release];
    [restClient release];
    [selectedDic release];
    [needLoadThumbImageArray release];
    [refreshHeaderView release];
    [activityIndicator release];
    [popover release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [self orientationDidChange:self.interfaceOrientation];
    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
    
    if (self.fileList.count > 0) {
        [self performSelector:@selector(loadNewestThumbImage) withObject:nil afterDelay:0.5f];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [restClient cancelAllRequests];
    [self doneLoadingTableViewData];
    [self cancelThumbImageCache];
    [self deletePopover];
}

#pragma mark - Autorotate orientation

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
    return IS_IPAD || interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self orientationDidChange:interfaceOrientation];
}

- (void)orientationDidChange:(UIInterfaceOrientation)interfaceOrientation
{
    if (IS_IPAD) {
        UIView *header = self.tableView.tableHeaderView;
        if (header)
        {
            UIImageView *image = (UIImageView *)[header viewWithTag:ImageTag];
            if (image)
            {
                CGFloat offset = 0.0;
                if (image.center.y == 300 && UIDeviceOrientationIsLandscape(interfaceOrientation))
                {
                    offset = -100;
                }
                if (image.center.y == 200 && UIDeviceOrientationIsPortrait(interfaceOrientation))
                {
                    offset = 100;
                }
                image.center = CGPointMake(self.view.center.x, image.center.y+offset);
                
                UILabel *title = (UILabel *)[header viewWithTag:LabelTitleTag];
                if (title)
                {
                    title.center = CGPointMake(self.view.center.x, title.center.y+offset);
                }
                
                UILabel *des = (UILabel *)[header viewWithTag:LabelDesTag];
                if (des)
                {
                    des.center = CGPointMake(self.view.center.x, des.center.y+offset);
                }
                
                UILabel *lblDes = (UILabel *)[header viewWithTag:LabelDesDetailTag];
                if (lblDes)
                {
                    lblDes.center = CGPointMake(self.view.center.x, lblDes.center.y+offset);
                }
            }
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.fileList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    PCFileCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[PCFileCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.delegate = self;
        cell.indexSection = -1;
    }
    
    cell.indexRow = indexPath.row;
    
    PCFileInfo *fileInfo = self.fileList[indexPath.row];
    cell.textLabel.text = fileInfo.name;
    
    if (editing && fileInfo.bFileFoldType) {
        BOOL isAdded = fileInfo.bIsAdded;
        if (selectedDic[fileInfo.path]) {
            isAdded = [selectedDic[fileInfo.path] boolValue];
        }
        [cell changeSelectImage:isAdded hidden:NO];
    }
    else {
        [cell changeSelectImage:fileInfo.bIsAdded hidden:YES];
    }
    
    if (fileInfo.bFileFoldType)
    {
        cell.imageView.image = [UIImage imageNamed:@"file_folder.png"];
    }
    else
    {
        UIImage *image = nil;
        NSString *cacheFolder = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"]
                                 stringByAppendingFormat:@"/Caches/%@/ThumbImage/", [PCLogin getResource]];
        NSString *path =[cacheFolder stringByAppendingPathComponent:fileInfo.path];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            image = [UIImage imageWithContentsOfFile:path];
            if (image) {
                CGRect rect = CGRectMake(0, 0, 40, 40);
                UIGraphicsBeginImageContextWithOptions(rect.size,YES,[UIScreen mainScreen].scale);
                [image drawInRect:rect];
                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
        }
        cell.imageView.image = image ? image : [UIImage imageNamed:@"file_pic.png"];
    }
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Data Source Loading / Reloading Methods
- (void)reloadTableViewDataSource
{
    [self cancelThumbImageCache];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [activityIndicator startAnimating];
    
    if (editing) {
        [PCUtilityUiOperate animateRefreshBtn:self.navigationItem.rightBarButtonItem.customView];
    }
    
    if (restClient == nil) {
        restClient = [[PCRestClient alloc] init];
        restClient.delegate = self;
    }
    [restClient getPictureFileList:self.dirPath];
}

- (void)doneLoadingTableViewData
{
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [activityIndicator stopAnimating];
    
    if (editing) {
        UIButton *refreshImg = (UIButton *)self.navigationItem.rightBarButtonItem.customView;
        [refreshImg.layer removeAllAnimations];
    }
    else {
        [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    }
}

- (void)refreshData:(id)recognizer
{
    [self reloadTableViewDataSource];
}

- (void)submit:(UIButton *)sender
{
    NSMutableArray *_addFolders = [NSMutableArray array];
    NSMutableArray *_delFolders = [NSMutableArray array];
    for (PCFileInfo *fileInfo in self.fileList)
    {
        if (!fileInfo.bFileFoldType)
            break;
        
        BOOL isAdded = fileInfo.bIsAdded;
        if (selectedDic[fileInfo.path]) {
            isAdded = [selectedDic[fileInfo.path] boolValue];
        }
        if (isAdded) {
            [_addFolders addObject:fileInfo];
        }
        else {
            [_delFolders addObject:fileInfo];
        }
    }
    
    self.addFolders = _addFolders;
    self.delFolders = _delFolders;
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES afterDelay:0.1];
    [restClient setPictureScanFolder:_addFolders exceptFolder:_delFolders];
}

//删除图片操作，会回调过来
- (void)refreshFileList:(PCFileInfo*)fileInfo
{
    if (fileInfo == nil)
        return;
    
    for (PCFileInfo *info in self.fileList) {
        if ([fileInfo.path isEqualToString:info.path]) {
            [self.fileList removeObject:info];
            if (self.fileList.count == 0) {
                [self createNoContentView];
            }
            break;
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self cancelThumbImageCache];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    
    if (!decelerate)
    {
        [self performSelector:@selector(loadNewestThumbImage) withObject:nil afterDelay:0.5f];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self performSelector:@selector(loadNewestThumbImage) withObject:nil afterDelay:0.5f];
}

#pragma mark - EGORefreshTableHeaderDelegate Methods
- (void)egoRefreshTableHeaderOriginalDidTriggerRefresh:(EGORefreshTableHeaderViewOriginal*)view
{
    [self reloadTableViewDataSource];
}

#pragma mark - PCRestClientDelegate

- (void)restClient:(PCRestClient*)client gotPictureFileList:(NSArray*)fileListInfo
{
    if (editing) {
        [selectedDic removeAllObjects];
        self.fileList = [NSMutableArray arrayWithCapacity:fileListInfo.count];
        [self.fileList addObjectsFromArray:fileListInfo];
        
        if (self.fileList.count == 0) {
            [self createNoContentView];
        }
        else {
            self.tableView.scrollEnabled = YES;
            
            if (((PCFileInfo*)(self.fileList[0])).bFileFoldType) {
                [self createEditTableHeaderView];
            }
            else {
                self.tableView.tableHeaderView = nil;
            }
        }
    }
    else {
        NSMutableArray *temp = [[NSMutableArray alloc] init];
        for (PCFileInfo *file in fileListInfo) {
            if (file.bIsAdded) {
                [temp addObject:file];
            }
        }
        self.fileList = temp;
        [temp release];
        
        if (self.fileList.count == 0) {
            [self createNoContentView];
        }
        else {
            self.tableView.tableHeaderView = nil;
            self.tableView.scrollEnabled = YES;
        }
    }
    
    [self.tableView reloadData];
    [self doneLoadingTableViewData];
    
    [self performSelector:@selector(loadNewestThumbImage) withObject:nil afterDelay:0.5f];
}

- (void)restClient:(PCRestClient*)client getPictureFileListFailedWithError:(NSError*)error
{
    [self doneLoadingTableViewData];
    [ErrorHandler showErrorAlert:error];
}

- (void)restClient:(PCRestClient*)client setPictureScanFolderSuccess:(NSDictionary *)resultInfo
{
    for (PCFileInfo *file in self.addFolders) {
        file.bIsAdded = YES;
    }
    self.addFolders = nil;
    
    if (self.delFolders) {
        if (self.delFolders.count > 0) {
            [restClient deletePictureScanFolder:self.delFolders];
            return;
        }
        else {
            self.delFolders = nil;
        }
    }
    
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [PCUtilityUiOperate showTip:@"设置已提交，请不要轻意修改文件夹名称。"];
}

- (void)restClient:(PCRestClient*)client setPictureScanFolderFailedWithError:(NSError*)error
{
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [ErrorHandler showErrorAlert:error];
}

- (void)restClient:(PCRestClient*)client deletePictureScanFolderSuccess:(NSDictionary *)resultInfo
{
    for (PCFileInfo *file in self.delFolders) {
        file.bIsAdded = NO;
    }
    self.delFolders = nil;
    
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [PCUtilityUiOperate showTip:@"设置已提交，请不要轻意修改文件夹名称。"];
}

- (void)restClient:(PCRestClient*)client deletePictureScanFolderFailedWithError:(NSError*)error
{
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [ErrorHandler showErrorAlert:error];
}

#pragma mark - PCFileCellDelegate
- (void)didSelectCell:(NSIndexPath *)indexPath
{
    if (indexPath.row >= self.fileList.count)
        return;
    
    PCFileInfo *fileInfo = self.fileList[indexPath.row];
    
    if (fileInfo.bFileFoldType) {
        PictureScanFolderViewController *vc = [[PictureScanFolderViewController alloc] initWithStyle:UITableViewStylePlain editing:editing];
        vc.dirName = fileInfo.name;
        vc.dirPath = fileInfo.path;
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
    }
    else {
        [self openImageFile:fileInfo];
    }
}

- (void)openImageFile:(PCFileInfo*)fileInfo
{
    FileCache *fileCache = [[FileCache alloc] init];
    fileCache.currentDeviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
    NSString *filePath = [fileCache getCacheFilePath:fileInfo.path withType:TYPE_CACHE_SLIDEIMAGE];
    BOOL cached = [fileCache readFileFromCacheWithFileInfo:fileInfo withType:TYPE_CACHE_SLIDEIMAGE];
    [fileCache release];
    
    FileCacheController *cacheController = [[FileCacheController alloc] initWithPath:filePath
                                                               andFinishLoadingState:cached
                                                                       andDataSource:self.fileList
                                                                andCurrentPCFileInfo:fileInfo
                                                           andLastViewControllerName:self.navigationItem.title];
    KTPhotoScrollViewController *newController = [[KTPhotoScrollViewController alloc]
                                                  initWithDataSource:cacheController
                                                  andStartWithPhotoAtIndex:cacheController.startWithIndex_];
    newController.bShowToolBar = !editing;
    [self.navigationController pushViewController:newController animated:YES];
    [newController release];
    [cacheController release];
}

- (void)eidtStatusSelected:(NSIndexPath *)indexPath andCell:(PCFileCell *)cell
{
    if (indexPath.row >= self.fileList.count)
        return;
    
    PCFileInfo *fileInfo = self.fileList[indexPath.row];
    if (fileInfo.bFileFoldType) {
        BOOL isAdded = fileInfo.bIsAdded;
        if (selectedDic[fileInfo.path]) {
            isAdded = [selectedDic[fileInfo.path] boolValue];
        }
        selectedDic[fileInfo.path] = @(!isAdded);
        [cell changeSelectImage:!isAdded hidden:NO];
    }
}

#pragma mark - Download thumbnail

-(void)loadNewestThumbImage
{
    [self cancelThumbImageCache];
    
    NSArray *visibleRows = self.tableView.indexPathsForVisibleRows;
    for (NSIndexPath *indexPath in visibleRows)
    {
        PCFileInfo *fileInfo = self.fileList[indexPath.row];
        if(fileInfo.mFileType == PC_FILE_IMAGE)
        {
            [needLoadThumbImageArray addObject:indexPath];
        }
    }
    
    if (needLoadThumbImageArray.count > 0)
    {
        [self loadFirstVisibleThumbImage];
    }
}

-(void)loadFirstVisibleThumbImage
{
    NSIndexPath *indexPath = needLoadThumbImageArray[0];
    PCFileInfo *fileInfo = self.fileList[indexPath.row];
    NSString *cacheFolder = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"]
                             stringByAppendingFormat:@"/Caches/%@/ThumbImage/", [PCLogin getResource]];
    NSString *path = [cacheFolder stringByAppendingPathComponent:fileInfo.path];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSDictionary *atrDic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        if ([[atrDic objectForKey:NSFileSize] longLongValue] > 0)
        {
            [needLoadThumbImageArray removeObjectAtIndex:0];
            if (needLoadThumbImageArray.count > 0)
            {
                [self loadFirstVisibleThumbImage];
            }
            return;
        }
        else {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
    }
    
    if (self.thumbImgFileCache)
    {
        self.thumbImgFileCache.delegate = nil;
        [self.thumbImgFileCache cancel];
        self.thumbImgFileCache = nil;
    }
    
    FileCache *fileCache = [[FileCache alloc] init];
    fileCache.currentDeviceID = [PCLogin getResource];
    fileCache.index = indexPath.row;
    fileCache.isRemoveWhenCancel = YES;
    self.thumbImgFileCache = fileCache;
    [fileCache release];
    
    [self.thumbImgFileCache cacheFile:fileInfo.path
                             viewType:TYPE_CACHE_THUMBIMAGE
                       viewController:self
                             fileSize:-1
                        modifyGTMTime:0
                            showAlert:NO];
}

-(void)cancelThumbImageCache
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadNewestThumbImage) object:nil];
    
    if (self.thumbImgFileCache)
    {
        self.thumbImgFileCache.delegate = nil;
        [self.thumbImgFileCache cancel];
        self.thumbImgFileCache = nil;
    }
    
    [needLoadThumbImageArray removeAllObjects];
}

#pragma mark PCFileCacheDelegate

-(void)cacheFileFinish:(FileCache *)fileCache
{
    if (self.fileList.count > fileCache.index) {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:fileCache.index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    self.thumbImgFileCache = nil;
    
    if (needLoadThumbImageArray.count > 0)
    {
        [needLoadThumbImageArray removeObjectAtIndex:0];
        if (needLoadThumbImageArray.count > 0)
        {
            [self loadFirstVisibleThumbImage];
        }
    }
}

-(void)cacheFileFail:(FileCache *)fileCache hostPath:(NSString *)hostPath error:(NSString *)error
{
    self.thumbImgFileCache = nil;
    
    if (needLoadThumbImageArray.count > 0)
    {
        [needLoadThumbImageArray removeObjectAtIndex:0];
        if (needLoadThumbImageArray.count > 0)
        {
            [self loadFirstVisibleThumbImage];
        }
    }
}

#pragma mark - Upload photo

- (void)uploadPhoto
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

- (void)showPopover:(UIViewController *)controller
{
    self.popover = [[[UIPopoverController alloc] initWithContentViewController:controller] autorelease];
    self.popover.delegate = self;
    [self.popover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny  animated:YES];
}

- (void)deletePopover
{
    if (self.popover)
    {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
}

-(void)hidePopover
{
    if (self.popover && [[PCSettings sharedSettings] screenLock])
    {
        [self.popover dismissPopoverAnimated:NO];
    }
}

-(void)restorePopover
{
    if (self.popover)
    {
        [self.popover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny  animated:YES];
    }
}

#pragma mark UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.popover = nil;
}

#pragma mark ELCImagePickerControllerDelegate

- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    NSMutableArray *addFileArr = [NSMutableArray arrayWithCapacity:info.count];
    
    [info enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop){
        
        NSString *imageName = dict[@"imageName"];
        NSString *url = [dict[UIImagePickerControllerReferenceURL] absoluteString];
        NSString *path = [dirPath stringByAppendingPathComponent:imageName];
        NSNumber *size = dict[@"imageSize"];
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
        [fileUploadInfo setDiskName:path];
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

@end
