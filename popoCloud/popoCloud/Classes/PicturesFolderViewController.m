//
//  PicturesViewController.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-10.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "PicturesFolderViewController.h"
#import "CameraUploadSettingViewController.h"
#import "PictureScanFolderViewController.h"

#import "PCUtility.h"
#import "PCUtilityUiOperate.h"
#import "PCUtilityStringOperate.h"
#import "PCLogin.h"
#import "JSON.h"
#import "CameraUploadManager.h"

#import "PictureListController.h"
#import "ActivateBoxViewController.h"
#import "KxMenu.h"
#import <QuartzCore/QuartzCore.h>

#import "PCUtilityFileOperate.h"
#import "PCFileCell.h"

#import "DragButton.h"

#define BUTTON_SET  10000
#define BUTTON_EDIT 10001

#define TOOLVIEWTAG 10201
#define NOCONTERNVIEWTAG 1998
#define THUMBNAIL_COUNT 12
#define DELETE_FOLDER_TAG 9898
#define   PROCESSVIEWTAG 33333
#define   EDITTAG 44444
#define  SELECT_TAG 5555
#define  ICON_TAG 6666

@implementation PicturesFolderViewController

@synthesize tableView;
@synthesize picturetableView;
@synthesize dicatorView;
@synthesize currentRequest;
@synthesize menuArray;
@synthesize mDragBtn;
@synthesize mGroupType;

#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.mGroupType = @"folder";
        lastDragBtnPoint = CGPointMake(0, 0);
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuDismiss:)
//                                                     name:KX_MENU_DISMISS object:nil];
    }
    return self;
}

- (void)menuDismiss:(NSNotification *)notif
{
//    mDragBtn.frame =  CGRectMake(self.view.frame.size.width-40, 0, 30, 40);
//    
//    
//    [UIView animateWithDuration:0.2
//                     animations:^(void) {
//                         
//                         //self.alpha = 0;
//                         mDragBtn.frame =  CGRectMake(self.view.frame.size.width-40, 0, 30, 40);
//                         
//                     } completion:^(BOOL finished) {
//
//                     }];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) getDeviceList
{
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[PCLogin sharedManager] getDevicesList:self];
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
                    
                    image.center = CGPointMake(self.view.center.x, image.center.y+offset);
                }
            }
            
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
                lblDes.frame = CGRectMake(lblDes.frame.origin.x, lblDes.frame.origin.y, self.view.frame.size.width-40, lblDes.frame.size.height);
                lblDes.center = CGPointMake(self.view.center.x, lblDes.center.y+offset);
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
    CGFloat y = 55 + emptyImage.size.height/2;
    if (IS_IPAD) {
        if (UIDeviceOrientationIsPortrait((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation)) {
            y = 300;
        }
        else {
            y = 200;
        }
    }
    emptyImageView.center = CGPointMake(self.view.center.x, y);
    [headerView addSubview:emptyImageView];
    [emptyImageView release];
    
    UILabel *noBoxLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 30)];
    [noBoxLabel setTextColor:[UIColor blackColor]];
    noBoxLabel.tag = LabelTitleTag;
    [noBoxLabel setBackgroundColor:[UIColor clearColor]];
    [noBoxLabel setTextAlignment:NSTextAlignmentCenter];
    [noBoxLabel setFont:[UIFont systemFontOfSize:15*scale]];
    [headerView addSubview:noBoxLabel];
    noBoxLabel.text =NSLocalizedString(@"LoadBoxFailed", nil);
    noBoxLabel.center = CGPointMake(self.view.center.x, emptyImageView.frame.origin.y+emptyImageView.frame.size.height+27*scale);
    [noBoxLabel release];
    
    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [refreshButton setTitle:@"刷新看看" forState:UIControlStateNormal];
    [refreshButton setTitleColor:UIColorFromRGB(0x0030ff) forState:UIControlStateNormal];
    refreshButton.titleLabel.font = [UIFont boldSystemFontOfSize:13*scale];
    refreshButton.frame = CGRectMake(self.view.center.x - 60, noBoxLabel.frame.origin.y + noBoxLabel.frame.size.height + 5*scale*scale*scale, 120, 15*scale);
    [refreshButton setBackgroundColor:[UIColor clearColor]];
    [refreshButton addTarget:self action:@selector(refreshData:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:refreshButton];
    refreshButton.tag = LabelDesTag;
    
    UILabel *lblDes = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 60)];
    [lblDes setTextColor:[UIColor grayColor]];
    lblDes.tag = LabelDesDetailTag;
    lblDes.numberOfLines = 2;
    [lblDes setBackgroundColor:[UIColor clearColor]];
    [lblDes setTextAlignment:NSTextAlignmentCenter];
    [lblDes setFont:[UIFont systemFontOfSize:13*scale]];
    lblDes.text = NSLocalizedString(@"PopoCloudKonwFailedAndRefreshAgain", nil);
    lblDes.center = CGPointMake(self.view.center.x, noBoxLabel.frame.origin.y+noBoxLabel.frame.size.height+35*scale*scale);
    [headerView addSubview:lblDes];
    [lblDes release];
    
    [self enableSetButton:NO];
    self.mDragBtn.hidden = YES;
    [KxMenu dismissMenu];
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
    [self enableSetButton:noContent];
    [self enableEditButton:NO];
        
    UIView *headView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    headView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    UIImage *emptyImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"empty" ofType:@"png"]];
    UIImageView *emptyImageView = [[UIImageView alloc] initWithImage:emptyImage];
    emptyImageView.tag = ImageTag;
    CGFloat y = 55 + emptyImage.size.height/2;
    if (IS_IPAD) {
        if (UIDeviceOrientationIsPortrait((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation)) {
            y = 300;
        }
        else {
            y = 200;
        }
    }
    emptyImageView.center = CGPointMake(self.view.center.x, y);
    [headView addSubview:emptyImageView];
    [emptyImageView release];
    
    UILabel *noBoxLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, noContent ? 50*scale : 30)];
    [noBoxLabel setTextColor:[UIColor blackColor]];
    noBoxLabel.tag = LabelTitleTag;
    [noBoxLabel setBackgroundColor:[UIColor clearColor]];
    [noBoxLabel setTextAlignment:NSTextAlignmentCenter];
    [noBoxLabel setFont:[UIFont systemFontOfSize:15*scale]];
    noBoxLabel.numberOfLines = 0;
    [headView addSubview:noBoxLabel];
    noBoxLabel.center = CGPointMake(self.view.center.x, emptyImageView.frame.origin.y+emptyImageView.frame.size.height+27*scale);
    [noBoxLabel release];
    
    y = noBoxLabel.frame.origin.y+noBoxLabel.frame.size.height;
    if (noContent)
    {
        self.mDragBtn.hidden = NO;
        
        UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [refreshButton setTitle:@"刷新看看" forState:UIControlStateNormal];
        [refreshButton setTitleColor:UIColorFromRGB(0x0030ff) forState:UIControlStateNormal];
        refreshButton.titleLabel.font = [UIFont boldSystemFontOfSize:13*scale];
        refreshButton.frame = CGRectMake(self.view.center.x - 60, y, 120, 15*scale);
        [refreshButton setBackgroundColor:[UIColor clearColor]];
        [refreshButton addTarget:self action:@selector(refreshData:) forControlEvents:UIControlEventTouchUpInside];
        [headView addSubview:refreshButton];
        refreshButton.tag = LabelDesTag;
        
        if ([self.mGroupType isEqualToString:@"folder"]) {
            noBoxLabel.text = NSLocalizedString(@"NoPictureFolder", nil);
        }
        else {
            noBoxLabel.text = NSLocalizedString(@"NoImageCurrent", nil);
            
            UILabel *lblDes = [[UILabel alloc] initWithFrame:CGRectMake(20, y + 60*scale - 60, self.view.frame.size.width-40, 120)];
            [lblDes setTextColor:[UIColor grayColor]];
            lblDes.tag = LabelDesDetailTag;
            [lblDes setBackgroundColor:[UIColor clearColor]];
            [lblDes setTextAlignment:NSTextAlignmentCenter];
            [lblDes setFont:[UIFont systemFontOfSize:13*scale]];
            lblDes.numberOfLines = 0;
            if ([self.mGroupType isEqualToString:@"month"]) {
                lblDes.text = NSLocalizedString(@"PopoCloudDespiseYou", nil);
            }
            else if ([self.mGroupType isEqualToString:@"label"]) {
                lblDes.text = NSLocalizedString(@"NoPictureFavorite", nil);
            }
            [headView addSubview:lblDes];
            [lblDes release];
        }
    }
    else
    {
        CGRect  originalFrame = self.mDragBtn.frame;
        originalFrame.origin.y = 0;
        self.mDragBtn.frame = originalFrame;
        self.mDragBtn.hidden = YES;
        [KxMenu dismissMenu];
        noBoxLabel.text = NSLocalizedString(@"NotFoundYourBoxs", nil);
        
        UIButton *goBind = [UIButton buttonWithType:UIButtonTypeCustom];
        [goBind setTitle:NSLocalizedString(@"GoBind", nil) forState:UIControlStateNormal];
        [goBind setTitleColor:[UIColor colorWithRed:66.0/255.0 green:126.0/255.0 blue:176.0/255.0  alpha:1.0] forState:UIControlStateNormal];
        goBind.titleLabel.font = [UIFont boldSystemFontOfSize:13*scale];
        goBind.frame = CGRectMake(self.view.center.x - 100, y + 35*scale*scale - 100, 200, 200);
        [goBind setBackgroundColor:[UIColor clearColor]];
        [goBind addTarget:self action:@selector(goBindBox) forControlEvents:UIControlEventTouchUpInside];
        [headView addSubview:goBind];
        goBind.tag = LabelDesTag;
    }
    
    self.picturetableView.tableHeaderView = headView;
    [headView release];
    self.tableView.hidden = YES;
    self.picturetableView.hidden = NO;
}

- (void)createMenu
{
    NSArray *menuItems =
    @[
      [KxMenuItem menuItem:@"按文件夹查看"
                     image:  [UIImage imageNamed:@"paixu_filename"]
                    target:self
                    action:@selector(pushMenuItem:)],
      
      [KxMenuItem menuItem:@"按月份查看"
                     image:[UIImage imageNamed:@"paixu_time"]
                    target:self
                    action:@selector(pushMenuItem:)],
      
      [KxMenuItem menuItem:@"查看我喜欢"
                     image: [UIImage imageNamed:@"paixu_favorite"]
                    target:self
                    action:@selector(pushMenuItem:)],];
    self.menuArray = menuItems;

}

- (void)createHeaderView
{
    /* Refresh View */
    _refreshHeaderView = [[EGORefreshTableHeaderViewOriginal alloc] initWithFrame:CGRectMake(0, -self.tableView.bounds.size.height, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
//    _refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0, -100, self.tableView.bounds.size.width, 100)];
    _refreshHeaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _refreshHeaderView.delegate = self;
    [self.tableView addSubview:_refreshHeaderView];
    //self.tableView.tableHeaderView = _refreshHeaderView;
    [_refreshHeaderView refreshLastUpdatedDate];
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadEGOTableViewDataSource{
    
    //  should be calling your tableviews data source model to reload
    //  put here just for demo
    _reloading = YES;
}

- (void)doneLoadingEGOTableViewData{
    
    //  model should call this when its done loading
    _reloading = NO;
    [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods
- (void)egoRefreshTableHeaderOriginalDidTriggerRefresh:(EGORefreshTableHeaderViewOriginal*)view
{
    [self reloadTableViewDataSource];
}

- (NSDate*)egoRefreshTableHeaderOriginalDataSourceLastUpdated:(EGORefreshTableHeaderViewOriginal*)view
{
     return [NSDate date];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    downloadOrDeleteArray = [[NSMutableArray alloc] init];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    isFinish = NO;
    isNetworkError = NO;
    self.currentRequest = nil;

    tableList = [[NSMutableArray alloc] init];
    
    self.tableView.rowHeight = TABLE_CELL_HEIGHT;
    self.tableView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    self.tableView.hidden = NO;
    self.picturetableView.hidden = YES;
    self.picturetableView.scrollEnabled = NO;
    
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = @"返回";
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    [temporaryBarButtonItem release];
    
    [self addSetBtn];
    
    if ([PCLogin getResource]) {
        isRefresh = NO;
        [self reloadTableViewDataSource];
    }
    else {
        isRefresh = YES;
    }
    
    
    [self createHeaderView];
    [self createMenu];
    
    DragButton *dragBtn = [[DragButton alloc] initWithImage:[UIImage imageNamed:@"listdown.png"] ];

    dragBtn.delegate = self;
    dragBtn.frame = CGRectMake(self.view.frame.size.width-40, 0, 30, 40);
    dragBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
    dragBtn.userInteractionEnabled = YES;
//    [dragBtn addTarget:self action:@selector(drag:) forControlEvents:UIControlEventTouchDragInside];
//    [dragBtn addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    self.mDragBtn = dragBtn;
    [self.view addSubview:dragBtn];
    
}

#pragma _mark   dragLocationDelegate

-(void)startDragBtn:(DragButton *)btn dragPoint:(CGPoint)point
{
    startPoint = point;
    lastDragBtnPoint = mDragBtn.frame.origin;
}


-(void)dragBtn:(DragButton *)btn dragPoint:(CGPoint)point
{
    int maxH = 5*4+32*menuArray.count;//32 行高 ,  5＊2  顶和底分别离首行和末行的间隙。
    int y = point.y-startPoint.y;

    CGRect  originalFrame = self.mDragBtn.frame;
    originalFrame.origin.y =y+lastDragBtnPoint.y;
    if (originalFrame.origin.y<0 ||  originalFrame.origin.y>maxH) {
        return;
    }
    if (y<3&&y>-3) {//至少拖2像素
        return;
    }

    self.mDragBtn.frame = originalFrame;
    
    [KxMenu showMenuInView:self.view
                 fromPoint:originalFrame.origin
                 menuItems:self.menuArray];
    
    [self.view bringSubviewToFront:mDragBtn];
}

-(void)endDragBtn:(DragButton *)btn dragPoint:(CGPoint)point;
{
    //startPoint = CGPointMake(-1, -1);
    [self  dragBtnScrollBackAtPoint:point];
}

-(void)cancelDragBtn:(DragButton *)btn dragPoint:(CGPoint)point
{
    //startPoint = CGPointMake(-1, -1);
}

-(void)dragBtnScrollBackAtPoint:(CGPoint)point
{
    int maxH = 5*4+32*menuArray.count;//32 行高 ,  5＊2  顶和底分别离首行和末行的间隙。
    int y = point.y-startPoint.y;
    CGRect  originalFrame = self.mDragBtn.frame;
    originalFrame.origin.y =y+lastDragBtnPoint.y;
    if (originalFrame.origin.y>maxH/2) {
        originalFrame.origin.y = maxH;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.3f];
        
        self.mDragBtn.frame = originalFrame;
        [KxMenu showMenuInView:self.view
                     fromPoint:originalFrame.origin
                     menuItems:self.menuArray];
        
        [UIView commitAnimations];

    }
    else{
        originalFrame.origin.y = 0;
        [KxMenu dismissMenu];
        self.mDragBtn.frame = originalFrame;
    }
}

//- (void)click:(UIButton*)sender
//{
//    mDragBtn.frame = CGRectMake(self.view.frame.size.width-40, 0, 30, 40);
//    
//    [KxMenu showMenuInView:self.view
//                 fromPoint:lastDragBtnPoint
//                 menuItems:self.menuArray];
//    [self.view bringSubviewToFront:mDragBtn];
//}

//- (void)drag:(UIButton*)sender
//{
//    [KxMenu showMenuInView:self.view
//                  fromRect:CGRectMake(self.view.frame.size.width-46, -6, 40, 2)
//                 menuItems:self.menuArray];
//}


- (void) pushMenuItem:(KxMenuItem *)sender
{
    NSLog(@"%@", sender);
    self.mDragBtn.frame = CGRectMake(self.view.frame.size.width-40, 0, 30, 40);
    if ([sender.title isEqualToString:@"按文件夹查看"]) {
       self.mGroupType = @"folder";
        [self addSetBtn];
        [self cancelAction];
    }
    else if ([sender.title isEqualToString:@"按月份查看"]) {
         self.mGroupType = @"month";
        [self addSetBtn];
        [self cancelAction];
    }
    else if ([sender.title isEqualToString:@"查看我喜欢"]) {
         self.mGroupType = @"label";
        [self addEditBtnAndSetBtn];
    }
    [self refreshData:nil];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
//    _refreshHeaderView=nil;
//    _refreshHeaderPictureView=nil;

}

- (void)viewWillAppear:(BOOL)animated
{
//    [[CameraUploadManager sharedManager] addObserver:self
//                                          forKeyPath:@"uploadStatus"
//                                             options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
//                                             context:NULL];
//    [[CameraUploadManager sharedManager] addObserver:self
//                                          forKeyPath:@"uploadNum"
//                                             options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
//                                             context:NULL];

//    [self refreshTable:0];
    [super viewWillAppear:animated];
    [self layoutSubviews];
    [MobClick beginLogPageView:@"PicturesFolderView"];
    

    if ([PCLogin getAllDevices]==nil)
    {
        [self loadDeviceFailed];
        return;
    }
    if ([[PCLogin getAllDevices] count]==0)
    {
        [self noBoxFoundOrNoContent:NO];
        return;
    }
}

//fix bug:54747, v4074
- (void)viewWillDisappear:(BOOL)animated
{
//    [[CameraUploadManager sharedManager] removeObserver:self forKeyPath:@"uploadStatus"];
//    [[CameraUploadManager sharedManager] removeObserver:self forKeyPath:@"uploadNum"];
//    
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"PicturesFolderView"];
    //isRefresh = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    if ([PCLogin getResource] && (isNetworkError || isRefresh)) {
        isRefresh = NO;
        [self releaseData];
        [tableView reloadData];
        [self reloadTableViewDataSource];
    }

    [super viewDidAppear:animated];
}

- (void)dealloc
{
//    [[NSNotificationCenter defaultCenter] removeObserver:self 
//                                                 name:KX_MENU_DISMISS object:nil];
    [downloadOrDeleteArray release];
    [menuArray release];
    [mGroupType release];
    [mDragBtn release];
    [tableList release];
    [_refreshHeaderView release];
    self.tableView = nil;
    self.picturetableView = nil;
    self.dicatorView = nil;
    self.currentRequest = nil;
    if (pcClient)
    {
        [pcClient release];
    }
    
    [super dealloc];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self layoutSubviews];
    self.mDragBtn.frame = CGRectMake(self.view.frame.size.width-40, 0, 30, 40);
}

#pragma mark - callback methods

- (void)refreshData:(id)recognizer
{
    if ([PCLogin getResource] == nil) {
        [self getDeviceList];
    }
    else {
        [self reloadTableViewDataSource];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
/*    if ([keyPath isEqualToString:@"uploadNum"])
    {
        NSInteger uploadNum = ((NSNumber *)change[NSKeyValueChangeNewKey]).integerValue;
        if (uploadNum == 0)
        {
            uploadStatus = noUpload;
        }
    }
    else
    {
        BOOL canUpload = ((NSNumber *)change[NSKeyValueChangeNewKey]).boolValue;
        uploadStatus = canUpload ? beingUpload : waitForUpload;
    }
*/
    NSArray *visibleIndexPaths = self.tableView.indexPathsForVisibleRows;
    if ([visibleIndexPaths containsObject:[NSIndexPath indexPathForRow:0 inSection:0]])
    {
        [self refreshTable:0];
    }
}


-(BOOL)hasSelectCellWithIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = indexPath.row;
    if (index >=[tableList count])
    {
        return NO;
    }
    NSDictionary *info = [tableList objectAtIndex:index];
    if (info)
    {
        if ([downloadOrDeleteArray containsObject:info])
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    return NO;
    
}

//显示文件信息的cell
- (UITableViewCell*)  createFileInfoCellForTable:(UITableView*)currentTable   andPath:(NSIndexPath*)indexPath
{
    static NSString *CellIdentifierFileInfoCell = @"FileInfoCell";
    PCFileCell *cell = [currentTable dequeueReusableCellWithIdentifier:CellIdentifierFileInfoCell];
    if (cell == nil)
    {
        cell = [[[PCFileCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifierFileInfoCell] autorelease];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        [cell.arrowImageView removeFromSuperview];
    }
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    cell.arrowImageView = nil;
    cell.delegate = self;
    cell.indexRow = indexPath.row;
    cell.indexSection = indexPath.section;

    NSDictionary *dic = [tableList objectAtIndex:indexPath.row];
    cell.textLabel.text = dic[@"name"];
    cell.imageView.image = [UIImage imageNamed:@"file_folder.png"];
    cell.detailTextLabel.text = nil;
    [self changeCellSelectedIamge:indexPath cell:cell isSelected:NO];
    return cell;
}

- (void)eidtStatusSelected:(NSIndexPath *)token andCell:(PCFileCell *)cell
{
    [self changeCellSelectedIamge:token cell:cell isSelected:YES];
}

//在编辑状态下选中了cell
-(void)changeCellSelectedIamge:(NSIndexPath *)indexPath cell:(PCFileCell *)cell isSelected:(BOOL)selected
{
    if (!self.tableView.editing) {
        return;
    }
    if (indexPath.row > [tableList count])
    {
        return;
    }
    NSDictionary *info = [tableList objectAtIndex:indexPath.row];
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
            BOOL selectAll = [downloadOrDeleteArray count]==[tableList count] ? YES : NO;
            [downloadOrDeleteArray removeObject:info];
            if (selectAll)
            {
                [(ToolView*)[self.tabBarController.tabBar viewWithTag:TOOLVIEWTAG] changeTitleOfSelectAll];
            }
            [cell changeSelectImage:NO];
        }
        else
        {
            [downloadOrDeleteArray addObject:info];
            [cell changeSelectImage:YES];
            BOOL selectAll = [downloadOrDeleteArray count]==[tableList count] ? YES : NO;
            if (selectAll)
            {
                [(ToolView*)[self.tabBarController.tabBar viewWithTag:TOOLVIEWTAG] changeTitleOfSelectAll];
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


#pragma mark - Table view data source
#pragma mark - Table view delegate
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //fix bug 55775 add by libing 2013-6-24
    if (!tableList.count) {
        [self.tableView setHidden:YES];
        [self enableEditButton:NO];
        [self.picturetableView setHidden:NO];
    }
    else
    {
        [self.tableView setHidden:NO];
        [self.picturetableView setHidden:YES];
        [self enableEditButton:YES];
    }
    //
    ///!!!:此处最后一个值暂时改为0，隐藏掉第一个cell
    return section ? tableList.count : 0;
}


- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:CellIdentifier] autorelease];
        cell.backgroundColor = [UIColor clearColor];
    }
    
// Configure the cell...
    if (indexPath.section)
    {
        return [self  createFileInfoCellForTable:_tableView   andPath:indexPath];
        
//        cell.textLabel.textColor = [UIColor blackColor];
//        cell.detailTextLabel.text = nil;
//        cell.accessoryView = nil;
//        
//        NSDictionary *node = tableList[indexPath.row];
//        NSString *name = node[@"name"];
//        if ([self.mGroupType isEqualToString:@"month"]) {
//            NSString *year = [name substringToIndex:4];
//            NSInteger month = [name substringFromIndex:5].integerValue;
//            name = [year stringByAppendingFormat:@"%@%d%@", NSLocalizedString(@"Year", nil), month, NSLocalizedString(@"Month", nil)];
//        }
//        cell.textLabel.text = name;
//        UIImageView *selectImgV = (UIImageView*)[cell.contentView viewWithTag:SELECT_TAG];
//        UIImageView *iconimgV = (UIImageView*)[cell.contentView viewWithTag:ICON_TAG];
//        
//        if (isEditing)
//        {
//            selectImgV.hidden = NO;
//            BOOL selected = [self hasSelectCellWithIndexPath:indexPath];
//            
//            if (selected)
//            {
//                selectImgV.image = [UIImage imageNamed:@"checkbox_d"];
//            }
//            else
//            {
//                selectImgV.image = [UIImage imageNamed:@"checkbox"];
//            }
//
//        }
//        else{
//            selectImgV.hidden = YES;
//        }
//       iconimgV.image = [UIImage imageNamed:@"file_folder.png"];
    }
    else
    {
        cell.textLabel.textColor = [UIColor colorWithRed:.25f green:.7f blue:.996f alpha:1];
        cell.imageView.image = nil;
        
        if ([[PCSettings sharedSettings] autoCameraUpload] == NO) {
            cell.textLabel.text = NSLocalizedString(@"Open Camera Upload", nil);
            cell.detailTextLabel.text = nil;
        }
        else {
            cell.textLabel.text = NSLocalizedString(@"AutoUploadPic", nil);
            
            NSString *detailText = nil;
            switch ([[CameraUploadManager sharedManager] uploadStatus]) {
                case kCameraUploadStatus_NoUpload:
                    detailText = NSLocalizedString(@"NoUpdatedPic", nil);
                    break;
                    
                case kCameraUploadStatus_Preparing:
                    detailText = NSLocalizedString(@"FindUpdatedPic", nil);
                    break;

                case kCameraUploadStatus_Uploading:
                    detailText = [NSString stringWithFormat:@"%d%@",[CameraUploadManager sharedManager].uploadNum,
                                  NSLocalizedString(@"BeingAutoUpload", nil)];
                    break;
                    
                case kCameraUploadStatus_Failed:
                    detailText = [NSString stringWithFormat:@"%d%@",[CameraUploadManager sharedManager].uploadNum,
                                  NSLocalizedString(@"AutoUploadFailed", nil)];
                    break;
                    
                case kCameraUploadStatus_Wait:
                    detailText = [NSString stringWithFormat:@"%d%@",[CameraUploadManager sharedManager].uploadNum,
                                  NSLocalizedString(@"WaitForAutoUpload", nil)];
                    break;
                    
                case kCameraUploadStatus_Denied:
                    detailText = NSLocalizedString(@"UploadAccessDeny", nil);
                    break;
                    
                default:
                    detailText = NSLocalizedString(@"ConnetError", nil);
                    break;
            }
            cell.detailTextLabel.text = detailText;
        }
        
        if (!cell.accessoryView)
        {
            UIImage *uploadImg = [UIImage imageNamed:@"upload.png"];
            cell.accessoryView = [[[UIImageView alloc] initWithImage:uploadImg] autorelease];
        }
    }

    return cell;
}

//#pragma mark - Table view delegate
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath

#pragma mark - PCFileCell delegate
- (void)didSelectCell:(NSIndexPath *)indexPath
{
    if (indexPath.section)
    {
        NSDictionary *node = tableList[indexPath.row];
        
        if ([self.mGroupType isEqualToString:@"folder"]) {
            PictureScanFolderViewController *vc = [[PictureScanFolderViewController alloc] initWithStyle:UITableViewStylePlain editing:NO];
            vc.dirPath = [node objectForKey:@"name"];
            [self.navigationController pushViewController:vc animated:YES];
            [vc release];
        }
        else {
            PictureListController *pictureListView = [[PictureListController alloc] init] ;
            pictureListView.title = [node objectForKey:@"name"];
            pictureListView.groupName = pictureListView.title;
            pictureListView.mGroupType = self.mGroupType;
    //        pictureListView.fileCount = [[node objectForKey:@"count"] integerValue];
            [self.navigationController pushViewController:pictureListView animated:YES];
            [pictureListView release];
        }
    }
    else//显示自动上传不同状态的界面，需要根据uploadStatus的枚举值判断显示不同界面
    {
        if ([[PCSettings sharedSettings] autoCameraUpload] == NO) {
            CameraUploadSettingViewController *vc = [[[CameraUploadSettingViewController alloc] initWithNibName:@"CameraUploadSettingView" bundle:nil] autorelease];
            vc.effectiveImmediately = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - private methods

- (void)cancelConnection
{
    if (pcClient)
    {
        [pcClient cancelRequest:self.currentRequest];
    }
}

- (void)layoutSubviews
{
    dicatorView.center = self.view.center;
        
    if (IS_IPAD)
    {
        [self setTabeleHeadViewCenter];
    }
}

- (void) releaseData {
    [tableList removeAllObjects];
}

//------------------------------------------------
- (void) getFolderList {
    isNetworkError = NO;
    isFinish = NO;
    if (self.currentRequest) {
        [self cancelConnection];
    }
    if (pcClient == nil) {
        pcClient = [[PCRestClient alloc] init];
        pcClient.delegate = self;
    }

    NSString *sortedType = nil;
    if ([self.mGroupType isEqualToString:@"label"] ) {
          sortedType = @"modifyTime desc";
    }
    else if([self.mGroupType isEqualToString:@"month"] )
    {
        sortedType = @"name desc";
    }
    else if([self.mGroupType isEqualToString:@"folder"] )
    {
        sortedType = @"name asc";
    }
    
    self.currentRequest = [pcClient getPictureGroupByInfo:sortedType andGroupType:self.mGroupType];
}

- (void)refreshTable:(NSInteger)loadType
{
    if (loadType == 2)
    {
        [self.tableView reloadData];
    }
    else
    {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:loadType]
                      withRowAnimation:UITableViewRowAnimationNone];
    }
    
    if (tableList.count) {
        [self.tableView setHidden:NO];
        [self.picturetableView setHidden:YES];
        [self enableEditButton:YES];
    }
    else {
        [self.tableView setHidden:YES];
        [self enableEditButton:NO];
        [self.picturetableView setHidden:NO];
//        [lblText setHidden:NO];
    }
}

//-----------------------------------------------------------
- (void) doFail:(NSString*)error {
    isFinish = YES;
    isNetworkError = YES;
    [self doneLoadingTableViewData];
    self.currentRequest = nil;
    [PCUtilityUiOperate showErrorAlert:error delegate:self];
}

- (void) loginFail:(PCLogin*)pcLogin error:(NSString*)error {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    [PCUtilityUiOperate showErrorAlert:error delegate:self];
    //[self doFail:error];
}

- (void) loginFinish:(PCLogin*)pcLogin {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    if ([[PCLogin getAllDevices] count]==0)
    {
        [self noBoxFoundOrNoContent:NO];
        return;
    }
    
    [self enableSetButton:YES];
    [self releaseData];
    [tableView reloadData];
    [self reloadTableViewDataSource];
    
    [[CameraUploadManager sharedManager] startCameraUpload];
}

- (void) logOut {
     isNetworkError = NO;
    self.tableView.hidden = NO;
    self.picturetableView.hidden = YES;
    
    [self releaseData];
    [tableView reloadData];
    isRefresh = YES;
    if (!isFinish) {
        if (self.currentRequest) {
            [self cancelConnection];
        }
        isFinish = YES;
    }
}

- (void) networkNoReachableFail:(NSString*)error {
    [self doFail:error];
}
//-----------------------------------------------------------------
#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource
{
    _reloading = YES;
    if (!self.picturetableView.hidden)
    {
        self.picturetableView.hidden = YES;
    }
    
    [self getFolderList];
    
//    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [dicatorView startAnimating];
}

- (void)doneLoadingTableViewData{
	
    if ([tableList count]==0)
    {
        [self noBoxFoundOrNoContent:YES];
    }
    else {
        self.mDragBtn.hidden = NO;
        [self enableEditButton:YES];
    }

	//  model should call this when its done loading
//    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    [self  doneLoadingEGOTableViewData];
    [dicatorView stopAnimating];
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
#pragma 
-(void)restClient:(PCRestClient *)client getPictureGroupByInfoSuccess:(NSArray *)resultInfo
{
    isFinish = YES;
    [self releaseData];

    [tableList addObjectsFromArray:resultInfo];

    [self doneLoadingTableViewData];
    [self refreshTable:1];
    self.currentRequest = nil;

}
-(void)restClient:(PCRestClient *)client getPictureGroupByInfoFailedWithError:(NSError *)error
{
    [self doneLoadingTableViewData];
    isFinish = YES;
    if ([error.domain isEqualToString:NSURLErrorDomain])
    {
        isNetworkError = YES;
    }
    
    if (error.code == PC_Err_BoxUnbind) {
        [self noBoxFoundOrNoContent:NO];
        [PCLogin removeDevice:[PCLogin getResource]];
    }
    else {
        [self noBoxFoundOrNoContent:YES];
    }
    
    if (error.code == PC_Err_FileNotExist)
    {
        [self releaseData];
        [self refreshTable:1];
        self.currentRequest = nil;
        return;
    }
    [ErrorHandler showErrorAlert:error];
    self.currentRequest = nil;
}

- (void)addSetBtn
{
    UIButton *setButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 23, 23)];
    [setButton setImage:[UIImage imageNamed:@"settings_you"] forState:UIControlStateNormal];
    [setButton addTarget:self action:@selector(setScanFolder) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *setButtonItem = [[UIBarButtonItem alloc] initWithCustomView:setButton];
    setButtonItem.tag = BUTTON_SET;
    [setButton release];
    
//    UIBarButtonItem *refreshButtonItem = [PCUtilityUiOperate createRefresh:self];
//    
//    UIButton* spaceButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
//    UIBarButtonItem* spaceButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spaceButton];
//    [spaceButton release];
    
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:setButtonItem,nil]];
    
//    [spaceButtonItem release];
    [setButtonItem release];
}

- (void)addEditBtnAndSetBtn
{
    UIButton *setButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 23, 23)];
    [setButton setImage:[UIImage imageNamed:@"settings_you"] forState:UIControlStateNormal];
    [setButton addTarget:self action:@selector(setScanFolder) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *setButtonItem = [[UIBarButtonItem alloc] initWithCustomView:setButton];
    setButtonItem.tag = BUTTON_SET;
    [setButton release];
    

    UIButton *edit = [[UIButton alloc] init];
    [edit setImage:[UIImage imageNamed:[PCUtilityFileOperate getImgName:@"file_edit"]] forState:UIControlStateNormal];
    [edit addTarget:self action:@selector(editAction) forControlEvents:UIControlEventTouchUpInside];
    
    edit.frame = CGRectMake(5, 5, 23, 23);
    UIBarButtonItem *editBtn = [[UIBarButtonItem alloc] initWithCustomView:edit];
    editBtn.tag =  BUTTON_EDIT;
    [edit release];
    
    UIButton* spaceButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
        UIBarButtonItem* spaceButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spaceButton];
        [spaceButton release];
    
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:setButtonItem,spaceButtonItem,editBtn ,nil]];
    
    [spaceButtonItem release];
    [editBtn release];
    [setButtonItem release];
}

-(void)addCancelNavBtn
{
//    UIButton *setButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 23, 23)];
//    [setButton setImage:[UIImage imageNamed:@"settings_you"] forState:UIControlStateNormal];
//    [setButton addTarget:self action:@selector(setScanFolder) forControlEvents:UIControlEventTouchUpInside];
//    UIBarButtonItem *setButtonItem = [[UIBarButtonItem alloc] initWithCustomView:setButton];
//    setButtonItem.tag = BUTTON_SET;
//    [setButton release];
    
    //
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)];    //
    
//    UIButton* spaceButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
//    UIBarButtonItem* spaceButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spaceButton];
//    [spaceButton release];
    
//    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:setButtonItem,spaceButtonItem,cancel ,nil]];
    
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:cancel ,nil]];
    //[spaceButtonItem release];
    [cancel release];
   // [setButtonItem release];
    
    CGRect  originalFrame = self.mDragBtn.frame;
    originalFrame.origin.y = 0;
    self.mDragBtn.frame = originalFrame;
    self.mDragBtn.hidden = YES;
    [KxMenu dismissMenu];
}

-(void)cancelAction
{
    mDragBtn.hidden = NO;
    if([self.mGroupType isEqualToString: @"label"])
    {
        [self addEditBtnAndSetBtn];
    }

    if (downloadOrDeleteArray)
    {
        [downloadOrDeleteArray removeAllObjects];
    }
    tableView.editing = NO;
    self.navigationItem.hidesBackButton = NO;
    [self hideToolView];
    isEditing = NO;
    [tableView reloadData];
}



-(void)editAction
{
    [self showToolView];
    [self addCancelNavBtn];
    isEditing = YES;
    tableView.editing = YES;
    [tableView  reloadData];
}

//隐藏toolview
- (void)hideToolView
{
    if ([self.tabBarController.tabBar viewWithTag:TOOLVIEWTAG])
    {
        ToolView *view = (ToolView *)[self.tabBarController.tabBar viewWithTag:TOOLVIEWTAG];
        [view resetTitleAndStatus];
        view.hidden = YES;
    }
}

//显示toolview
- (void)showToolView
{
    if (![self.tabBarController.tabBar viewWithTag:TOOLVIEWTAG])
    {
        ToolView *toolView = [[[NSBundle mainBundle] loadNibNamed:@"ToolView" owner:nil options:nil] objectAtIndex:0];
//        toolView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        toolView.tag = TOOLVIEWTAG;
        if ([self.mGroupType isEqualToString:@"month"]) {
            toolView.toolViewType = QuanXuanShanChuWoXiHuan;
        }
        else if([self.mGroupType isEqualToString:@"label"])
        {
            toolView.toolViewType = QuanXuanRemoveWoxihuan;
        }
        toolView.toolViewDelegate = self;
        [self.tabBarController.tabBar addSubview:toolView];
    }
    else
    {
        [self.tabBarController.tabBar viewWithTag:TOOLVIEWTAG].hidden = NO;
        [self.tabBarController.tabBar bringSubviewToFront:[self.tabBarController.tabBar viewWithTag:TOOLVIEWTAG]];
    }
    [self enableToolViewBtn:NO];
    [self toolViewFrame];
}

-(void)toolViewFrame
{
    if ([self.tabBarController.tabBar viewWithTag:TOOLVIEWTAG])
    {
        ToolView *toolView = (ToolView *)[self.tabBarController.tabBar viewWithTag:TOOLVIEWTAG];
        CGRect rect = toolView.bounds;
        rect.origin.x = 0;
        rect.origin.y = 0;
        rect.size = self.tabBarController.tabBar.frame.size;
        toolView.frame = rect;
    }
}

-(void)enableToolViewBtn:(BOOL)enable
{
    if ([self.tabBarController.tabBar viewWithTag:TOOLVIEWTAG])
    {
        ToolView *view = (ToolView *)[self.tabBarController.tabBar viewWithTag:TOOLVIEWTAG];
        if (!view.hidden)
        {
            [view enableBtnDownloadAndDelete:enable];
        }
    }
}


-(void)enableSetButton:(BOOL)enable
{
    for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems)
    {
        if (item.tag == BUTTON_SET)
        {
            item.enabled = enable;
            break;
        }
    }
}

-(void)enableEditButton:(BOOL)enable
{
    for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems)
    {
        if (item.tag == BUTTON_EDIT)
        {
            item.enabled = enable;
            break;
        }
    }
}


- (void)setScanFolder
{
    isRefresh = YES;
    PictureScanFolderViewController *vc = [[PictureScanFolderViewController alloc] initWithStyle:UITableViewStylePlain editing:YES];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

-(void)doSelectAll
{
    [downloadOrDeleteArray removeAllObjects];
    [downloadOrDeleteArray addObjectsFromArray:tableList];
    if ([downloadOrDeleteArray count]) {
        [self enableToolViewBtn:YES];
    }
}

-(void)didSelectBtn:(NSInteger)tag
{
    NSLog(@"tag %d",tag);
    if (tag == QuanXuanTag)//全选
    {
        [self doSelectAll];
        [tableView reloadData];
    }
    else if (tag == QuanBuXuanTag)//全不选
    {
        [downloadOrDeleteArray removeAllObjects];
        [tableView reloadData];
        [self enableToolViewBtn:NO];
    }
//    if (tag == WoXiHuanTag)
//    {
//        if (pcClient == nil) {
//            pcClient = [[PCRestClient alloc] init];
//            pcClient.delegate = self;
//        }
//        //[self createLoadingView:NO];
//        self.currentRequest = [pcClient getPictureGroupByInfo:[PCUtilityStringOperate encodeToPercentEscapeString:@"modifyTime desc"] andGroupType:@"label"];
//    }
    else if (tag == RemoveWoxihuanTag) {
        [self removeFavoriteImg];
    }
    
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
    for (NSDictionary *node in realArray)
    {
        [pathStr appendFormat:@"\"%@\",",node[@"name"]];
    }
    [pathStr deleteCharactersInRange:NSMakeRange(pathStr.length-1, 1)];
    [pathStr appendString:@"]"];
    [realArray release];
    return [pathStr autorelease];
}

- (void)removeFavoriteImg
{
    [dicatorView startAnimating];
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGetDelImageLabel:)];
    request.process = @"DelImageLabel";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      [PCUtilityStringOperate encodeToPercentEscapeString:
                       [self loadDeletePath:downloadOrDeleteArray] ]
                      ,@"names",
                      nil];
    self.currentRequest = request;
    [request start];
}

-(void)requestDidGetDelImageLabel:(PCURLRequest *)request
{
    self.currentRequest = nil;
    [dicatorView stopAnimating];
    
    if (request.error) {
        if ([request.error.domain isEqualToString:NSURLErrorDomain] && request.error.code != NSURLErrorTimedOut) {
            [ErrorHandler showErrorAlert:request.error];
            return;
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                [PCUtilityUiOperate showTip:@"成功删除我喜欢文件夹！"];
                
                [tableList removeObjectsInArray:downloadOrDeleteArray];
                [downloadOrDeleteArray removeAllObjects];
                [tableView reloadData];
                if ([tableList count]==0)
                {
                    [self noBoxFoundOrNoContent:YES];
                }
                [self cancelAction];
                return;
            }
        }
    }
    
    [self cancelAction];
    [PCUtilityUiOperate showTip:@"删除我喜欢文件夹失败，请稍候重试！"];
}

@end
