//
//  PictureListController.m
//  popoCloud
//
//  Created by leijun on 12-10-18.
//
//

#import "PictureListController.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "PCUtilityDataManagement.h"
#import "PCUtilityStringOperate.h"
#import "FileCache.h"
#import "ZipArchive.h"
#import "KKIndexPath.h"
#import "KKGridViewCell.h"
#import "FileCacheController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "ActivateBoxViewController.h"
#import "PicturesFolderViewController.h"
#define   NEW_FOLDER_TAG                1

#define TOOLVIEWTAG 10201
#define NOCONTERNVIEWTAG 1998
#define THUMBNAIL_COUNT 12
#define DELETE_FOLDER_TAG 9898
#define   PROCESSVIEWTAG 33333
#define   EDIT_TAG 33334
#define LIMIT (IS_IPAD ? ([UIScreen mainScreen].scale > 1.0f ? ([UIApplication sharedApplication].statusBarOrientation > UIDeviceOrientationPortraitUpsideDown ? @"264" : @"240") : @"60") : (IS_IPHONE5 ? @"45" : @"36"))

#define MINICELLPADDING 4

@interface PictureListController()
{
    PCRestClient *pcRestClient;
}
@property (nonatomic,getter = visiableStartIndex) int visiableStartIndex;
@property (nonatomic,getter = visiableEndIndex) int visiableEndIndex;
@end
static const char *kIndexPathAssociationKey = "indexPathKey";

@implementation PictureListController

@synthesize groupName,fileCount,fileList,fileDict,deviceID;
@synthesize visiableEndIndex,visiableStartIndex;
@synthesize currentRequest;
@synthesize mFavoriteList;
@synthesize currentFavoriteFileName;
@synthesize mGroupType;

- (void)lockUI
{
    self.view.userInteractionEnabled = NO;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.tabBarController.tabBar.userInteractionEnabled = NO;
}

- (void)unLockUI
{
    self.view.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.tabBarController.tabBar.userInteractionEnabled = YES;
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
-(void)goBindBox
{
    [MobClick event:UM_SETTING_ACTIVATE];
    ActivateBoxViewController *vc = [[ActivateBoxViewController alloc] initWithNibName:@"ActivateBoxViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}
-(void)removeNoContentView
{
    UIView *view = [self.view viewWithTag:NOCONTERNVIEWTAG];
    if (view && ![view isKindOfClass:[KKGridViewCell class]])
    {
        [view removeFromSuperview];
    }
}
-(UIView *)noBoxFoundOrNoContent:(BOOL)noContent
{
    NSLog(@"加上空白页面");
    [self enableEidtBtn:NO];
    [dicatorView stopAnimating];
    int scale = IS_IPAD ? 2 : 1;
    BOOL isLandScape = [[UIApplication sharedApplication] statusBarOrientation] > UIDeviceOrientationPortraitUpsideDown;
    
    CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    UIView *headView = [[UIView alloc] initWithFrame:rect];
    headView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [headView setBackgroundColor:[UIColor clearColor]];
    headView.tag = NOCONTERNVIEWTAG;
    
    UIImage *emptyImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"empty-gray" ofType:@"png"]];
    UIImageView *emptyImageView = [[UIImageView alloc] initWithImage:emptyImage];
    emptyImageView.tag = ImageTag;
    CGFloat offset =  isLandScape ? 200 : 300;
    emptyImageView.center = CGPointMake(self.view.center.x, offset);
    [headView addSubview:emptyImageView];
    [emptyImageView release];
    
    UILabel *noBoxLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 80)];
    [noBoxLabel setTextColor:[UIColor whiteColor]];
    noBoxLabel.tag = LabelTitleTag;
    noBoxLabel.numberOfLines = 2;
    [noBoxLabel setBackgroundColor:[UIColor clearColor]];
    [noBoxLabel setTextAlignment:NSTextAlignmentCenter];
    [headView addSubview:noBoxLabel];
    noBoxLabel.text = noContent ? @"从小老师就教育咱们，就算不会也不要留空嘛~" : NSLocalizedString(@"NotFoundYourBoxs", nil);
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
        lblDes.text = @"小泡泡偷偷地BS你，哈哈没有啦~";
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

//added by libing 2013-6-27 fix bug55905
-(int)visiableStartIndex
{
    NSArray *visibleIndexPaths = self.gridView.visibleIndexPaths;
    if ([visibleIndexPaths count] > 0)
    {
        @try
        {
            KKIndexPath *indexPath = [visibleIndexPaths objectAtIndex:0];
            return [indexPath index];
        }
        @catch (NSException *exception)
        {
            DLogInfo(@"图片集获取页面起始位置异常%@",exception);
            return 0;
        }

    }
    else
        return 0;
}

-(int)visiableEndIndex
{
    NSArray *visibleIndexPaths = self.gridView.visibleIndexPaths;
    if ([visibleIndexPaths count] > 0)
    {
        @try
        {
            KKIndexPath *indexPath = [visibleIndexPaths lastObject];
            return [indexPath index];
        }
        @catch (NSException *exception)
        {
            DLogInfo(@"图片集获取页面起始位置异常%@",exception);
            return 0;
        }
    }
    else
    {
        if(IS_IPAD)
            return 42;
        else if (IS_IPHONE5)
            return 24;
        else
            return 20;
    }
    
}
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
//隐藏toolview
- (void)hideToolView
{
    if ([self.view viewWithTag:TOOLVIEWTAG])
    {
        ToolView *view = (ToolView *)[self.view viewWithTag:TOOLVIEWTAG];
        [view resetTitleAndStatus];
        view.hidden = YES;
    }
}
//显示toolview
- (void)showToolView
{
    if (![self.view viewWithTag:TOOLVIEWTAG])
    {
        ToolView *toolView = [[[NSBundle mainBundle] loadNibNamed:@"ToolView" owner:nil options:nil] objectAtIndex:0];
        toolView.tag = TOOLVIEWTAG;
        if ([self.mGroupType isEqualToString:@"month"]) {
            toolView.toolViewType = QuanXuanShanChuWoXiHuan;
        }
        else if([self.mGroupType isEqualToString:@"label"])
        {
            toolView.toolViewType = QuanXuanRemoveWoxihuan;
        }
        toolView.toolViewDelegate = self;
        [self.view addSubview:toolView];
    }
    else
    {
        [self.view viewWithTag:TOOLVIEWTAG].hidden = NO;
        [self.view bringSubviewToFront:[self.view viewWithTag:TOOLVIEWTAG]];
    }
    [self enableToolViewBtn:NO];
    [self toolViewFrame];
}
-(void)cancelAction
{
    self.navigationItem.hidesBackButton = NO;
    [self addRefreshBtnAddEditBtn];
    if (downloadOrDeleteArray)
    {
        [downloadOrDeleteArray removeAllObjects];
    }
    [self hideToolView];
    isEditing = NO;
    [self.gridView reloadData];
    if ([fileList count] >= [LIMIT integerValue]) {
        _refreshBottomView.hidden = NO;
    }
    [self setEGORefreshOrigin];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadNewestThumbImage) object:nil];
    [self performSelector:@selector(loadNewestThumbImage)];
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
    curIndex = self.visiableEndIndex+1;
    [self removeLoadingView];
    curIndex = self.visiableStartIndex;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadNewestThumbImage) object:nil];
    [self cancelCache:YES];
    self.navigationItem.hidesBackButton = YES;
    if (downloadOrDeleteArray)
    {
        [downloadOrDeleteArray removeAllObjects];
    }
    [self addCancelNavBtn];
    [self showToolView];
    isEditing = YES;
    [self.gridView reloadData];
    _refreshBottomView.hidden = YES;
}
-(void)enableEidtBtn:(BOOL)enable
{
    for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems)
    {
        if (item.tag == EDIT_TAG)
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
    editBtn.tag = EDIT_TAG;
    [edit release];
    
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects: editBtn,nil]];
    
   
    [editBtn release];
}

//
- (id)init
{
    if (self = [super init])
    {
        self.deviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (int)getThumbersPerRowWithInitNum:(int)thumbsPerRow
{
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize size = IS_IPAD ? CGSizeMake(THUMBNAIL_WIDTH_IPAD / scale , THUMBNAIL_HEIGHT_IPAD/scale) :
    CGSizeMake(THUMBNAIL_SIZE, THUMBNAIL_SIZE);
    
    int viewWidth =  self.view.frame.size.width;
    if (viewWidth - thumbsPerRow*size.width <(1+thumbsPerRow)*MINICELLPADDING) {
        thumbsPerRow--;
        return [self getThumbersPerRowWithInitNum:thumbsPerRow];
    }
    else{
        return thumbsPerRow;
    }
}

#pragma mark - methods from super class
-(void)resetCellPadding
{
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize size = IS_IPAD ? CGSizeMake(THUMBNAIL_WIDTH_IPAD / scale , THUMBNAIL_HEIGHT_IPAD/scale) :
    CGSizeMake(THUMBNAIL_SIZE, THUMBNAIL_SIZE);
//    BOOL isLandscape = self.interfaceOrientation > UIInterfaceOrientationPortraitUpsideDown;
//    int numPerRow = 0;
//    int numPerColum = 0;
//    
//    if (scale == 2)
//    {
//        numPerRow = 12;
//        numPerColum = 8;
//    }
//    else
//    {
//        numPerRow = 6;
//        numPerColum = 5;
//    }

    
//    NSInteger thumbsPerRow = isLandscape ? (IS_IPAD ? numPerRow : 6) : (IS_IPAD ? numPerColum : 3);
    

    int viewWidth =  self.view.frame.size.width;
    NSInteger thumbsPerRow = [self getThumbersPerRowWithInitNum:viewWidth/size.width];
    
    
    
//    NSInteger frameWidth = isLandscape ? [UIScreen mainScreen].bounds.size.height :[UIScreen mainScreen].bounds.size.width;
    
    NSInteger padding = round((viewWidth - size.width * thumbsPerRow) / (thumbsPerRow + 1));
    
    self.gridView.cellPadding = CGSizeMake(padding, padding);
	self.gridView.cellSize = size;
}
//设置上拉加载更多的y坐标
-(void)setEGORefreshOrigin
{
    CGFloat y =  self.gridView.contentSize.height > self.gridView.bounds.size.height ? self.gridView.contentSize.height : self.gridView.bounds.size.height;
    if (_refreshBottomView)
    {
        _refreshBottomView.frame = CGRectMake(0, y, _refreshBottomView.bounds.size.width,  _refreshBottomView.bounds.size.height);
    }
}

- (void)createHeaderView
{
    /* Refresh View */
    _refreshHeaderView = [[EGORefreshTableHeaderViewOriginal alloc] initWithFrame:CGRectMake(0, -self.gridView.bounds.size.height, self.gridView.bounds.size.width, self.gridView.bounds.size.height)];
    //    _refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0, -100, self.tableView.bounds.size.width, 100)];
    _refreshHeaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _refreshHeaderView.delegate = self;
    [self.gridView addSubview:_refreshHeaderView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mFavoriteList = [NSMutableArray array];
    downloadOrDeleteArray = [[NSMutableArray alloc] init];
    
    self.view.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    isRefresh = NO;
    isNoMoreData = NO;
    
    pcRestClient = [[PCRestClient alloc] init];
    pcRestClient.delegate = self;
    
    _refreshBottomView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.gridView.bounds.size.width, EGOHEIGHT)];
    _refreshBottomView.delegate = self;
    _refreshBottomView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.gridView addSubview:_refreshBottomView];
    [self.gridView setBackgroundColor:[UIColor  blackColor]];
    _refreshBottomView.hidden = YES;
    [self setEGORefreshOrigin];
    self.fileList = [NSMutableArray array];
    
    self.thumbsDic = [NSMutableDictionary dictionary];
    self.thumbsPathDic = [NSMutableDictionary dictionary];
    oldOrientation = UIDeviceOrientationUnknown;
    dicSetQueue = dispatch_queue_create([NSBundle mainBundle].bundleIdentifier.UTF8String, DISPATCH_QUEUE_CONCURRENT);
    
//    self.navigationItem.rightBarButtonItem = [PCUtilityUiOperate createRefresh:self];
    [self addRefreshBtnAddEditBtn];
    isEditing = NO;
    cahceEndIndex = 0;
    cacheStartIndex = 0;
    bDownloadThumbnailFailed = NO;
    [self showLocalThumbPics];
    [self reloadTableViewDataSource];
    
    [self createHeaderView];
    

    [self createTable];
}

- (void)createTable
{
    mFavoriteBG = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 390)];
    UIImageView *bg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 390)];
    bg.image = [[UIImage imageNamed: @"TSAlertViewBackground.png"] stretchableImageWithLeftCapWidth: 15 topCapHeight: 30];
    [mFavoriteBG addSubview:bg];
    bg.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [bg release];
    mTable = [[UITableView alloc] initWithFrame:CGRectMake(10, 40, 280, 300) style:UITableViewStylePlain];
    
    [mFavoriteBG addSubview:mTable];
    mTable.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    mTable.delegate = self;
    mTable.dataSource = self;
    [self.view addSubview:mFavoriteBG];
    mFavoriteBG.hidden = YES;
    
    [self createTableFooter];
    [self createTableHeader];
}


- (void)createTableHeader
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, mFavoriteBG.frame.size.width, 40)];
    label.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth;
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.text = @"添加到我喜欢";
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];
    label.textColor = [UIColor whiteColor];
    [mFavoriteBG addSubview:label];
    [label release];
}

- (void)createTableFooter
{
    UIImage* buttonBgNormal = [UIImage imageNamed: @"TSAlertViewButtonBackground.png"];
    buttonBgNormal = [buttonBgNormal stretchableImageWithLeftCapWidth: buttonBgNormal.size.width / 2.0 topCapHeight: buttonBgNormal.size.height / 2.0];
    UIButton*cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setBackgroundImage: buttonBgNormal forState: UIControlStateNormal];
    cancelButton.frame = CGRectMake(mFavoriteBG.frame.size.width/2-50 , 342, 100,36);
    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    cancelButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    [mFavoriteBG addSubview: cancelButton];
}

- (void)showAlertModeView
{
    mFavoriteBG.hidden = NO;
    [self adjustAlertModeViewFrame];
}

- (void)adjustAlertModeViewFrame
{
    if (IS_IPAD) {
            mFavoriteBG.frame = CGRectMake(0, 0, self.view.frame.size.width/2,  MIN(self.view.frame.size.height/2,90+ TABLE_CELL_HEIGHT *(self.mFavoriteList.count+1)));
    }
    else
    {
        mFavoriteBG.frame = CGRectMake(0, 0, MAX(280,self.view.frame.size.width*3/5),  MIN(self.view.frame.size.height*2/3,90+ TABLE_CELL_HEIGHT *(self.mFavoriteList.count+1)));
    }

    mFavoriteBG.center = self.view.center;
    [mTable reloadData];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    DLogInfo(@"PictureListController didReceiveMemoryWarning");
    [self.thumbsDic removeAllObjects];
}

- (void)dealloc
{
    DLogInfo(@"PictureListController dealloc");
    NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
    [notiCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [notiCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    dispatch_release(dicSetQueue);
	
    [mGroupType release];
    if (getPicFailAlertView)
        [getPicFailAlertView release];
    [pcClient release];
    [currentFavoriteFileName release];
    [self removeLoadingView];
    [mTable release];
    [mFavoriteBG release];
    [mFavoriteList release];
    self.zipFileCache = nil;
    [self.imgFileCache cancel];
    self.imgFileCache = nil;
    [pcRestClient release];
    
    self.currentRequest = nil;
    self.fileList = nil;
    self.fileDict = nil;
    self.thumbsDic = nil;
    self.deviceID = nil;
    self.groupName = nil;
    self.thumbsPathDic = nil;
    
    [downloadOrDeleteArray release];
    [super dealloc];
}
//取消当前请求
-(void)cancelCurrentRequest
{
    [pcRestClient cancelRequest:self.currentRequest];
    isNetworkError = YES;
    bGettingPicList = NO;
    if (dicatorView)
    {
        [dicatorView stopAnimating];
    }
    [self doneLoadingTableViewData];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"PictureList"];
    
    NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
    [notiCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [notiCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    self.bDisAppearing = YES;
    oldOrientation = (UIDeviceOrientation)self.interfaceOrientation;
    [self cancelCurrentRequest];
    [self cancelCache:!self.bCoverdByPushing];
}
- (void)viewWillAppear:(BOOL)animated
{
    [self resetCellPadding];
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"PictureList"];
    
    NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
    [notiCenter addObserver:self
                   selector:@selector(becomeActive:)
                       name:UIApplicationDidBecomeActiveNotification
                     object:nil];
    
    [notiCenter addObserver:self
                   selector:@selector(enterBackground:)
                       name:UIApplicationDidEnterBackgroundNotification
                     object:nil];
    
    if (oldOrientation != UIDeviceOrientationUnknown &&
        ((oldOrientation <= UIDeviceOrientationPortraitUpsideDown &&
          self.interfaceOrientation > UIInterfaceOrientationPortraitUpsideDown) ||
         (self.interfaceOrientation <= UIInterfaceOrientationPortraitUpsideDown &&
          oldOrientation > UIDeviceOrientationPortraitUpsideDown)))
    {
        [self layoutSubviews];
    }
    
    self.bCoverdByPushing = NO;
    self.bDisAppearing = NO;
    
    if (bNeedRefresh) {
        [self refreshData:nil];
    }
    else{
        if (isNetworkError)
        {
            isNetworkError = NO;
            
            if (!bGettingPicList)
            {
                if (!isNoMoreData)
                {
                    [self reloadTableViewDataSource];
                }
                
            }
        }
        
        if (self.zipFileCache)
        {
            [self becomeActive:nil];
        }
        else if (curIndex < self.visiableEndIndex+1)
        {
//            [PCUtilityUiOperate animateRefreshBtn:self.navigationItem.rightBarButtonItem.customView];
            //从当前可见cell的第一个加载
            [self showOrDownloadThumbZip:curIndex];
        }
    }
    [self setEGORefreshOrigin];
    if (!_reloading)
    {
        if ([fileList count] == 0) {
            if (![self.view viewWithTag:NOCONTERNVIEWTAG])
            {
                [self.view addSubview:[self noBoxFoundOrNoContent:YES]];
            }
            
        }
    }

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
    [self  adjustAlertModeViewFrame];
    if (IS_IPAD)
    {
        [self resetCellPadding];
        [self loadNewestThumbImage];
    }
    CGFloat y =  self.gridView.contentSize.height > self.gridView.bounds.size.height ? self.gridView.contentSize.height : self.gridView.bounds.size.height;
    _refreshBottomView.frame = CGRectMake(0,y, self.gridView.bounds.size.width, EGOHEIGHT);
    if ([self.view viewWithTag:PROCESSVIEWTAG]) {
        ((UIView*)[self.view viewWithTag:PROCESSVIEWTAG]).center = self.view.center;
        [self resetActivityFrame];
    }
}

- (void)layoutSubviews
{
    if (dicatorView)
    {
        CGRect appFrame = [UIScreen mainScreen].applicationFrame;
        NSInteger tabBarHeight = self.tabBarController.tabBar ? self.tabBarController.tabBar.frame.size.height : 0;
        NSInteger appHeight = 0, appWidth = 0;
        
        if (self.interfaceOrientation > UIInterfaceOrientationPortraitUpsideDown)
        {
            appWidth = appFrame.size.height;
            appHeight = appFrame.size.width;
        }
        else
        {
            appWidth = appFrame.size.width;
            appHeight = appFrame.size.height;
        }
        
        NSInteger height = appHeight - self.navigationController.navigationBar.frame.size.height - tabBarHeight;
        
        dicatorView.center = CGPointMake(appWidth / 2, height / 2);
    }
    if (lblProgress)
    {
        lblProgress.center = CGPointMake(dicatorView.center.x, CGRectGetMaxY(dicatorView.frame) + 20);
    }
    [self setNoContentViewCenter];
}

#pragma mark - callback methods

- (void)refreshData:(id)recognizer
{
    isRefresh = YES;
    isNoMoreData = NO;
    [self reloadTableViewDataSource];
}

- (void)becomeActive:(NSNotification *)note
{
    if (self.zipFileCache && curIndex < fileCount)
    {
        [self createLoadingView:NO];
        NSString *path = [NSString stringWithFormat:@"%@/%d-%d.zip", groupName, self.zipFileCache.index, self.visiableEndIndex];
        DLogInfo(@"becomeActive hostPath=%@",path);
        
        [self.zipFileCache cacheFile:path viewType:TYPE_CACHE_THUMBIMAGE_ZIP viewController:self fileSize:-1 modifyGTMTime:0 showAlert:YES];
    }
}

- (void)enterBackground:(NSNotification *)note
{
    DLogInfo(@"enterBackground zipFileCache=%@",self.zipFileCache);
    [self cancelCurrentRequest];
    [self cancelCache:YES];
}

#pragma mark - private methods

- (void)reloadSomeCells:(NSMutableSet *)indexPaths
{
    NSArray *array = [indexPaths allObjects];
    NSArray *sortArray = [array sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]]];
    if ([sortArray count])
    {
        curIndex = [((KKIndexPath *)[sortArray lastObject]) index]+1;
        
        if (curIndex>=self.visiableEndIndex+1)
        {
            curIndex=self.visiableEndIndex+1;
        }
    }
    else
    {
        if (indexPaths)
        {
            [indexPaths release];
            indexPaths = nil;
        }
        return;
    }
    if (indexPaths.count)
    {
        [indexPaths intersectSet:[NSSet setWithArray:self.gridView.visibleIndexPaths]];
        
        if (indexPaths.count)
        {
            [self.gridView reloadItemsAtIndexPaths:indexPaths];
        }
    }
    if (indexPaths)
    {
        [indexPaths release];
        indexPaths = nil;
    }

}

- (void)setCacheObject:(id)obj forKey:(id)key
{
    dispatch_barrier_async(dicSetQueue, ^{
        [_thumbsDic setObject:obj forKey:key];
    });
}

- (id)cacheObjectForKey:(id)key
{
    __block id obj;
    dispatch_sync(dicSetQueue, ^{
        obj = [[_thumbsDic objectForKey:key] retain];
    });
    return [obj autorelease];
}
//取消下载缩略图
- (void)cancelCache:(BOOL)needToRemove
{
    if (self.zipFileCache)
    {
        self.zipFileCache.delegate = nil;
        [self.zipFileCache cancel];
    }
    
    if (needToRemove && self.imgFileCache)
    {
        [self removeLoadingView];
        
        self.imgFileCache.delegate = nil;
        [self.imgFileCache cancel];
        self.imgFileCache = nil;
    }
}

- (void)createAnimatingView
{
    if (!dicatorView)
    {
        dicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        dicatorView.color = [UIColor grayColor];
        [self.view addSubview:dicatorView];
    }
    dicatorView.center = self.gridView.center;
    [dicatorView startAnimating];
}

//创建加载显示
- (void)createLoadingView:(BOOL)hasLabel
{
    [self createAnimatingView];
    
    if (hasLabel)
    {
        if (!lblProgress)
        {
            lblProgress = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 58, 21)];
            lblProgress.textAlignment = UITextAlignmentCenter;
            lblProgress.textColor = [UIColor darkGrayColor];
            lblProgress.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            lblProgress.backgroundColor = [UIColor clearColor];
            lblProgress.center = CGPointMake(dicatorView.center.x, CGRectGetMaxY(dicatorView.frame) + 20);
            
            [self.view addSubview:lblProgress];
        }
    }
    
    [self layoutSubviews];
}
//移除加载显示符
- (void)removeLoadingView
{
    if (dicatorView) {
        if ((curIndex == self.visiableEndIndex+1 && !bGettingPicList) || bDownloadThumbnailFailed || isNetworkError)
        {
            [dicatorView stopAnimating];
            [dicatorView removeFromSuperview];
            [dicatorView release];
            dicatorView = nil;
            bDownloadThumbnailFailed = NO;
        }
    }
    if (lblProgress) {
        [lblProgress removeFromSuperview];
        [lblProgress release];
        lblProgress = nil;
    }
    [self doneLoadingTableViewData];
}
//去图片列表
- (void) getPictureList
{
    if ([self.view viewWithTag:NOCONTERNVIEWTAG] && ![[self.view viewWithTag:NOCONTERNVIEWTAG] isKindOfClass:[KKGridViewCell class]])
    {
        [fileList removeAllObjects];
        fileCount = [fileList count];
        [self.gridView reloadData];
        [self removeNoContentView];
    }
    if (self.currentRequest)
    {
        [pcRestClient cancelRequest:self.currentRequest];
    }
    bGettingPicList = YES;
    NSString *start = [NSString stringWithFormat:@"%d",isRefresh ? 0 : [self.fileList count]];
    self.currentRequest = [pcRestClient pictureListGetGroupImageByInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                        [PCUtilityStringOperate encodeToPercentEscapeString:groupName],@"groupName",
                                                                        start,@"start",
                                                                        LIMIT,@"limit",nil]];
}

-(void) removeCacheDirectory:(NSString*)path {
    NSError *error = nil;
    NSLog(@"removeCacheDirectory path=%@",path);
    if (path && [path isKindOfClass:[NSString class]])
    {
        if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error])
            DLogError(@"Fail:removeCacheDirectory:%@",path);
    }
}
//从数据库里面取指定的缓存数据
- (PCFileCacheInfo *)getNewestThumbForPCFileInfo:(PCFileInfo*)fileInfo
                                     forNewIndex:(int)index
                                     indexChange:(BOOL *)hasChange
                                        childMOC:(NSManagedObjectContext *)childContext
{
    NSString *hash = fileInfo.hash;
    
    //    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(fileKey == %@)AND((thumbIndex == %d)) AND (path BEGINSWITH %@)", hash, index,[self getLocalThumbImageRootPath]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(fileKey == %@) AND (path BEGINSWITH %@)", hash,[self getLocalThumbImageRootPath]];
    
    NSArray *fetchArray = [PCUtilityDataManagement fetchObjects:@"FileCacheInfo"
                                                sortDescriptors:nil
                                                      predicate:predicate
                                                     fetchLimit:0
                                                      threadMOC:childContext];
    
    PCFileCacheInfo *fileCacheInfo = nil;
    NSUInteger count = fetchArray.count;
    
    if (count)
    {
        fileCacheInfo = fetchArray[0];
        //        NSNumber *modifyTime = fileInfo.modifyTime;
        BOOL modifyTimeChange = fileCacheInfo.modifyTime.longLongValue != fileInfo.modifyTime.longLongValue;
        
        if (modifyTimeChange)
        {
            fileCacheInfo.modifyTime = [NSString stringWithFormat:@"%@", fileInfo.modifyTime];
        }
        
        //if (*hasChange || modifyTimeChange)
        if ( modifyTimeChange)
        {
            [self saveDB:childContext];
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSHomeDirectory() stringByAppendingString:fileCacheInfo.path]])
        {
            return fileCacheInfo;
        }
    }
    
    return nil;
}
//保存缩略图信息到数据库
- (void)saveThumbImageInfoToCoreDataWithKey:(NSString*)fileKey
                                    andPath:(NSString*)path
                                   andIndex:(NSInteger)index
                                   childMOC:(NSManagedObjectContext *)childContext
{
    if (index >= fileList.count) return;
    
    PCFileCacheInfo *thumb = [NSEntityDescription insertNewObjectForEntityForName:@"FileCacheInfo"
                                                           inManagedObjectContext:childContext];
    
    PCFileInfo *fileInfo = fileList[index];
    
    unsigned long long size = [fileKey isEqualToString:@"0"] ? 0 :
    [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil].fileSize;
    
    thumb.thumbIndex = [NSNumber numberWithInt:index];
    thumb.path = path;
    thumb.type = @"Cache";
    thumb.modifyGTMTime = 0;
    thumb.size = @(size);
    thumb.modifyTime = [NSString stringWithFormat:@"%@", fileInfo.modifyTime];
    thumb.timeZone = fileInfo.path;//此处把timezone存储为云端相对路径hostPath，是便于下次缓存显示时，用户点击某个缩略图传入的hostPath是正确的值
    thumb.fileKey = fileKey;
    NSLog(@"CURRENT thumb to save: %@",thumb);
    [self saveDB:childContext];
}


//解压下载下来的缩略图压缩包
- (void)viewThumbImageZip:(NSString *)path startIndex:(NSInteger)index
{
    //去掉block 修复bug 56001
    PictureListController *weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        int startIndex = weakSelf.visiableStartIndex;
        int endIndex = weakSelf.visiableEndIndex;
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        DLogNotice(@"viewThumbImageZip path=%@",path);
        
        ZipArchive *zipArchive = [[ZipArchive alloc] init];
        BOOL isZipSuccess = [zipArchive UnzipOpenFile:path];
        DLogInfo(@"UnzipOpenFile isZipSuccess=%d",isZipSuccess);
        
        NSMutableSet *indexPaths = [[NSMutableSet alloc] initWithCapacity:THUMBNAIL_COUNT];
        
        if (isZipSuccess)
        {
            NSString *unzipPath = [path stringByDeletingPathExtension];
            isZipSuccess = [zipArchive UnzipFileTo:unzipPath overWrite:YES];
            DLogInfo(@"UnzipFileTo isZipSuccess=%d",isZipSuccess);
            
            if (isZipSuccess)
            {
                NSString *jsonPath = [unzipPath stringByAppendingPathComponent:@"Path2ThumbMap.json"];
                NSString *json = [NSString stringWithContentsOfFile:jsonPath
                                                           encoding:NSUTF8StringEncoding
                                                              error:NULL];
                if (weakSelf)
                    [weakSelf removeCacheDirectory:jsonPath];
                
                if (json.length <= 2)//fix bug55305,下载的zip文件只有Path2ThumbMap.json，且其内容仅有{}
                {
                    goto main_label;
                }
                
                NSMutableArray *jsonArr = [[NSMutableArray alloc] init];
                
                NSString *subStr = [json substringWithRange:NSMakeRange(1, json.length - 2)];
                NSArray *tempArr = [subStr componentsSeparatedByString:@","];
                
                for (NSString *str in tempArr)
                {
                    NSString *key = [str componentsSeparatedByString:@":"][0];
                    [jsonArr addObject:[key substringWithRange:NSMakeRange(1, key.length - 2)]];
                }
                
                NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                [childContext setParentContext:[PCUtilityDataManagement managedObjectContext]];
                for (NSString *key in jsonArr)
                {
                    if (!weakSelf.fileDict)
                        break;
                    
                    NSInteger thumbIndex = 0;
                    id obj = weakSelf.fileDict[key];
                    
                    if ([obj isKindOfClass:[NSMutableArray class]])
                    {
                        NSMutableArray *arr = obj;
                        if (arr.count == 0)
                            continue;
                        int removeIndex = 0;
                        for (id object in arr)
                        {
                            if ([object integerValue]>=startIndex && [object integerValue]<=endIndex)
                            {
                                thumbIndex = [object integerValue];
                                removeIndex = [arr indexOfObject:object];
                                break;
                            }
                        }
                        [arr removeObjectAtIndex:removeIndex];
                        //                        thumbIndex = [arr[0] integerValue];
                        //                        [arr removeObjectAtIndex:0];
                    }
                    else
                    {
                        thumbIndex = [obj integerValue];
                    }
                    DLogInfo(@"thumbImgName=%@,thumbIndex=%d",key,thumbIndex);
                    
                    if (weakSelf)
                    {
                        NSString *thumbImgPath = [unzipPath stringByAppendingPathComponent:key];
                        NSString *savePath = [thumbImgPath substringFromIndex:[NSHomeDirectory() length]];
                        weakSelf.thumbsPathDic[key] = thumbImgPath;
                        [self processThumbImage:thumbImgPath];
                        [weakSelf saveThumbImageInfoToCoreDataWithKey:key
                                                              andPath:savePath
                                                             andIndex:thumbIndex
                                                             childMOC:childContext];
                        
                        [indexPaths addObject:[KKIndexPath indexPathForIndex:thumbIndex inSection:0]];
                        UIImage *img = [UIImage imageWithContentsOfFile:thumbImgPath];
                        [self setCacheObject:img ? img : [NSNull null] forKey:@(thumbIndex)];
                    }
                }
                
                [jsonArr release];
                [childContext release];
            }
        }
        
    main_label:
        [zipArchive UnzipCloseFile];
        [zipArchive release];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf)
            {
                [weakSelf removeCacheDirectory:path];
                if (![indexPaths count]) {
                    NSMutableSet *set = [[NSMutableSet alloc] initWithArray:weakSelf.gridView.visibleIndexPaths];
                    [weakSelf reloadSomeCells:set];
                    curIndex = self.visiableStartIndex;
                }
                else
                {
                    [weakSelf reloadSomeCells:indexPaths];
                }
                DLogInfo(@"viewThumbImageZip curIndex=%d,fileCount=%d",curIndex,self.fileCount);
                if (cahceEndIndex <= self.visiableEndIndex+1)
                {
                    if (!weakSelf.bDisAppearing)
                    {
                        if (cahceEndIndex == self.visiableEndIndex+1)
                        {
                            curIndex = self.visiableEndIndex+1;
                            [weakSelf loadThumbFinish:YES];
                        }
                        else
                        {
                            [weakSelf showOrDownloadThumbZip:cahceEndIndex];
                        }
                    }
                }
                else
                {
                    [weakSelf loadThumbFinish:YES];
                    if (!isZipSuccess && !getPicFailAlertView)
                    {
                        getPicFailAlertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"DownloadThumbImageFail", nil) delegate:weakSelf cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
                        [getPicFailAlertView show];
                    }
                }
            }
        });
        
        [pool release];
    });
}
//拼接需要下载缩略图的hash值，选出不需要下载缩略图的cell，并更新它
- (NSString *)getThumbImageZip:(NSInteger)startIndex
					  childMOC:(NSManagedObjectContext *)childContext
{
    if (!self.bDisAppearing)
    {
        NSInteger endIndex = startIndex+THUMBNAIL_COUNT;
        if (endIndex > fileCount)
        {
            endIndex = fileCount;
        }
        if(endIndex >=self.visiableEndIndex+1)
        {
            endIndex =self.visiableEndIndex+1;
        }
        cahceEndIndex = endIndex;
        
        NSMutableString *paths = [NSMutableString string];
        [paths retain];
        
        BOOL bFirst = YES;
        
        NSMutableSet *indexPaths = [[NSMutableSet alloc] init];
        
        int i = startIndex;
        while (i < endIndex && !self.bDisAppearing && !bGettingPicList && !self.gridView.isDragging)
        {
            for (; i < endIndex && !self.bDisAppearing && !bGettingPicList; i++)
            {
                if ([paths length] > 432)
                {
                    i = endIndex;
                    break;
                }
                if (i>=[fileList count])
                {
                    break;
                }
                PCFileInfo *fileInfo = fileList[i];
                
                BOOL hasChangeIndex = YES;
                
                //如果没有cache 则要把这个node的hash值加到paths里面去
                PCFileCacheInfo *thumbCacheInfo = [self getNewestThumbForPCFileInfo:fileInfo
                                                                        forNewIndex:i
                                                                        indexChange:&hasChangeIndex
                                                                           childMOC:childContext];
                if (!thumbCacheInfo)
                {
                    NSString *hash = fileInfo.hash;
                    if ([hash isEqualToString:@"BigImage"])
                    {
                        [indexPaths addObject:[KKIndexPath indexPathForIndex:i inSection:0]];
                        continue;
                    }
                    else if ([hash isEqualToString:@"0"])
                    {
                        self.thumbsPathDic[hash] = [[NSBundle mainBundle] pathForResource:@"damage_thumb" ofType:@"png"];
                        [self saveThumbImageInfoToCoreDataWithKey:@"0"
                                                          andPath:[self getLocalThumbImageRootPath]
                                                         andIndex:i
                                                         childMOC:childContext];
                        [indexPaths addObject:[KKIndexPath indexPathForIndex:i inSection:0]];
                        
                        continue;
                    }
                    
                    if (!bFirst)
                    {
                        [paths appendFormat:@", \"%@\"", hash];
                        cacheStartIndex = MIN(cacheStartIndex, i);
                    }
                    else
                    {
                        cacheStartIndex = i;
                        [paths appendFormat:@"[\"%@\"", hash];
                        bFirst = NO;
                    }
                }
                else if (hasChangeIndex)
                {
                    self.thumbsPathDic[thumbCacheInfo.fileKey] = [thumbCacheInfo.fileKey isEqualToString:@"0"] ?
                    [[NSBundle mainBundle] pathForResource:@"damage_thumb" ofType:@"png"] :
                    [NSHomeDirectory() stringByAppendingString:thumbCacheInfo.path];
                    
                    [indexPaths addObject:[KKIndexPath indexPathForIndex:i inSection:0]];
                }
                
                if ([paths length] < 400 && i == endIndex-1 && endIndex < self.visiableEndIndex+1)
                {
                    endIndex+=1;
                    if (endIndex > fileCount)
                    {
                        cahceEndIndex = endIndex - 1;
                    }
                    else
                        cahceEndIndex = endIndex;
                }
            }
            
            if (self.bDisAppearing)
            {
                [indexPaths release];
                indexPaths = nil;
                [paths release];
                return nil;
            }
            else
            {
                if (bFirst)//没有图片需要更新
                {
                    endIndex += THUMBNAIL_COUNT;
                    if (endIndex > self.visiableEndIndex+1)
                        endIndex = self.visiableEndIndex+1;
                }
                else
                {
                    break;
                }
            }
        }
        
        if (self.bDisAppearing)
        {
            [indexPaths release];
            indexPaths = nil;
            [paths release];
            return nil;
        }
        
        [self performSelectorOnMainThread:@selector(reloadSomeCells:) withObject:indexPaths waitUntilDone:NO];
        
        if (!bFirst)
        {
            [paths appendString:@"]"];
            [paths release];
            return paths;
        }
        else {
            [paths release];
        }
    }
    
    return nil;
}
//下载缩略图
- (void)cacheZipFile:(NSString *)paths startIndex:(NSInteger)startIndex
{
    self.zipFileCache = [[[FileCache alloc] init] autorelease];
    self.zipFileCache.index = startIndex;
    self.zipFileCache.currentDeviceID = deviceID;
    self.zipFileCache.url = [NSString stringWithFormat:@"GetThumbImageZipByHash?Hash=%@",
                             [PCUtilityStringOperate encodeToPercentEscapeString:paths]];
    NSLog(@"%@",self.zipFileCache.url);
    bDownloadThumbnailFailed = NO;
    if (!self.bDisAppearing && !bGettingPicList && !self.gridView.isDragging)
    {
        [self createLoadingView:NO];
        NSString *path = [NSString stringWithFormat:@"%@/%d-%d.zip", groupName, startIndex, cahceEndIndex];
        [self.zipFileCache cacheFile:path viewType:TYPE_CACHE_THUMBIMAGE_ZIP viewController:self fileSize:-1 modifyGTMTime:0 showAlert:YES];
    }
}
//下载缩略图
- (void)showOrDownloadThumbZip:(NSInteger)startIndex
{
    
    PictureListController *weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        if (weakSelf)
        {
            NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [childContext setParentContext:[PCUtilityDataManagement managedObjectContext]];
            
            NSString *paths = [weakSelf getThumbImageZip:startIndex childMOC:childContext];
            [childContext release];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (isEditing)
                {
                    return;
                }
                if (weakSelf)
                {
                    if (paths.length)
                    {
                        if (weakSelf)
                        {
                            [weakSelf cacheZipFile:paths startIndex:cacheStartIndex];
                        }
                        
                    }
                    else
                    {
                        if (weakSelf)
                        {
                            [weakSelf loadThumbFinish:YES];
                        }
                    }
                    
                }
            });
        }
        
        [pool release];
    });
}

- (NSString*)getLocalThumbImageRootPath
{
    FileCache* fileCache = [[FileCache alloc] init];
    fileCache.currentDeviceID = deviceID;
    NSString *filePath = [fileCache getCacheFilePath:groupName withType:TYPE_CACHE_THUMBIMAGE_ZIP];
    filePath = [filePath substringFromIndex:[NSHomeDirectory() length]];
    [fileCache release];
    
    return filePath;
}
//从数据库里面去cache数据
- (NSArray*)thumbFileListInDB
{
    NSString *path = [self getLocalThumbImageRootPath];
    
    [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSLocalDomainMask, YES) objectAtIndex:0];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"thumbIndex" ascending:YES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(path BEGINSWITH %@) AND (NOT path ENDSWITH[c] %@) AND (thumbIndex > -1)", path, @".zip"];
    
    NSArray *fetchArray = [PCUtilityDataManagement fetchObjects:@"FileCacheInfo"
                                                sortDescriptors:@[sort]
                                                      predicate:predicate
                                                     fetchLimit:0
                                                      cacheName:@"Root"];
    DLogInfo(@"数据库cache文件%@,个数%d",path,[fetchArray count]);
    
    return fetchArray.count ? [NSMutableArray arrayWithArray:[[fetchArray retain] autorelease]] : nil;
}
//去本地缓存数据出来
- (void)showLocalThumbPics
{
    NSArray *results = [self thumbFileListInDB];
    NSUInteger thumbNum = results.count;
    for (int i = 0, start = 0, end = 0; i < thumbNum; i++)
    {
        PCFileCacheInfo *info = results[i];
        end = info.thumbIndex.intValue;
        if (!info.fileKey) {
            info.fileKey =@"0";
        }
        self.thumbsPathDic[info.fileKey] =   [info.fileKey isEqualToString:@"0"] ?
        [[NSBundle mainBundle] pathForResource:@"damage_thumb" ofType:@"png"] : [NSHomeDirectory() stringByAppendingString:info.path];
        
        for (int j = start; j < end; j++)
        {
            [self.thumbsDic setObject:[NSNull null] forKey:@(j)];
        }
        start = end+1;
    }
}

- (void)refreshLocalThumbPics//更新 删除 废弃的数据
{
    
    if (!isNoMoreData)
    {
        return;
    }
    if (!fileDict || self.bDisAppearing)//网络不成功
    {
        return;
    }
    
    NSArray *results = [self thumbFileListInDB];
    BOOL bChanged = NO;
    
    NSMutableArray *fileInfoArray = [[NSMutableArray alloc] initWithArray:fileList];
    NSMutableSet *fileSet = [[NSMutableSet alloc] init];
    NSMutableSet *cacheSet = [[NSMutableSet alloc] init];
    
    for (PCFileInfo *fileInfo in fileInfoArray)
    {
        [fileSet addObject:fileInfo.hash];
    }
    for (PCFileCacheInfo *info in results)
    {
        [cacheSet addObject:info.fileKey];
    }
    [cacheSet minusSet:fileSet];
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if ([cacheSet count])
    {
        for (NSString *hash in [cacheSet allObjects])
        {
            for (PCFileCacheInfo *info in results)
            {
                if ([info.fileKey isEqualToString:hash])
                {
                    [self removeCacheDirectory:[NSHomeDirectory() stringByAppendingString:info.path]];
                    [[PCUtilityDataManagement managedObjectContext] deleteObject:info];
                    bChanged = YES;
                }
            }
        }
    }
    [pool release];
    [cacheSet release];
    [fileSet release];
    [fileInfoArray release];
    
    if (bChanged)
    {
        [PCUtilityDataManagement saveInfos];
    }
}
//月份里面的图片数据取得之后，刷新cell
- (void)refreshThumbsWithDic:(NSDictionary*)dict
{
    if (!(self.bDisAppearing && !self.bCoverdByPushing))
    {
        self.thumbsDic = [NSMutableDictionary dictionary];
        NSArray *dataArray = dict[@"data"];
        if ([dataArray count]<[LIMIT integerValue])
        {
            isNoMoreData = YES;
        }
        else
        {
            isNoMoreData = NO;
            if (_refreshBottomView && (_refreshBottomView.state == EGONOMoreData))
            {
                _refreshBottomView.state = EGOOPullRefreshNormal;
            }
        }
        
        if (isRefresh)
        {
            [self.fileList removeAllObjects];
            isRefresh = NO;
        }
        for (NSDictionary* fileInfoDic in dataArray)
        {
            PCFileInfo *fileInfo = [[[PCFileInfo alloc] initWithImageFileInfo:fileInfoDic] autorelease];
            [self.fileList addObject:fileInfo];
        }
        fileCount = fileList.count;
        if (fileCount >= [LIMIT integerValue] && !isEditing)
        {
            _refreshBottomView.hidden = NO;
        }
        [self enableEidtBtn:fileCount>0];
        self.fileDict = [NSMutableDictionary dictionary];
        [self removeNoContentView];
        if (fileCount == 0)
        {
             [self.view addSubview:[self noBoxFoundOrNoContent:YES]];
        }
        
        [self.gridView reloadData];
        
        if (isNoMoreData)
        {
            [self loadThumbFinish:YES];
        }
        [self setEGORefreshOrigin];
        [self.fileList enumerateObjectsUsingBlock:^(PCFileInfo *fileInfo, NSUInteger idx, BOOL *stop) {
            NSString *hash = fileInfo.hash;
            //            DLogInfo(@"path=%@",((NSDictionary *)obj)[@"path"]);
            if (hash)
            {
                if ([hash isEqualToString:@"0"])//损坏的图片缩略图以0标识
                {
                    NSMutableArray *arr = fileDict[hash];
                    if (!arr)
                    {
                        fileDict[hash] = [NSMutableArray arrayWithObject:@(idx)];
                    }
                    else
                    {
                        [arr addObject:@(idx)];
                    }
                }
                else if (![hash isEqualToString:@"BigImage"])
                {
                    ///!!!:hash值可能会有相同的，按理说应该由盒子端改
                    id obj = fileDict[hash];
                    if (!obj)
                    {
                        fileDict[hash] = @(idx);
                    }
                    else
                    {
                        if ([obj isKindOfClass:[NSMutableArray class]])
                        {
                            [obj addObject:@(idx)];
                        }
                        else
                        {
                            fileDict[hash] = [NSMutableArray arrayWithObjects:obj, @(idx), nil];
                        }
                    }
                }
            }
        }];
        DLogInfo(@"fileDict.count=%d",fileDict.count);
        
        if (fileDict.count)
        {
            [self showOrDownloadThumbZip:self.visiableStartIndex];
        }
        else
        {
            [self loadThumbFinish:NO];
        }
    }
    else
    {
        isNetworkError = YES;
        [self loadThumbFinish:NO];
    }
}

- (void)saveDB:(NSManagedObjectContext *)context
{
    NSError *error = nil;
    if (![context save:&error])
    {
        DLogError(@"save child context database error:%@", error.localizedDescription);
    }
    
    NSManagedObjectContext *mainContext = [PCUtilityDataManagement managedObjectContext];
    
    [mainContext performBlock:^{
        NSError *err = nil;
        if (![mainContext save:&err])
        {
            DLogError(@"save database error:%@", err.localizedDescription);
        }
    }];
}

- (void)loadThumbFinish:(BOOL)clearDB
{
    [self removeLoadingView];
    [self doneLoadingTableViewData];
    if (clearDB)
        [self refreshLocalThumbPics];//删除数据库里的无用数据
}
-(void)doSelectAll
{
    for (PCFileInfo *info in fileList)
    {
        if (![downloadOrDeleteArray containsObject:info])
        {
            [downloadOrDeleteArray addObject:info];
        }
    }
    if ([downloadOrDeleteArray count]) {
        [self enableToolViewBtn:YES];
    }
}

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
#pragma mark - ToolViewDelegate
-(void)deleteFile
{
    [self lockUI];
    if (![downloadOrDeleteArray count])
    {
        return;
    }
    [self createDeleteProcessView];
    FileOperate *fileOperate = [[FileOperate alloc] init];
    [fileOperate fileOperateWithPath:[self loadDeletePath:downloadOrDeleteArray] method:@"remove" delegateOwner:self];
    fileOperate.totalFileCount = [downloadOrDeleteArray count] > MAXDELETEFILE ? MAXDELETEFILE : [downloadOrDeleteArray count];
}
-(void)didSelectBtn:(NSInteger)tag
{
    NSLog(@"tag %d",tag);
    if (tag == QuanXuanTag)//全选
    {
        [self doSelectAll];
        [self.gridView reloadData];
    }
    if (tag == QuanBuXuanTag)//全不选
    {
        [downloadOrDeleteArray removeAllObjects];
        [self.gridView reloadData];
        [self enableToolViewBtn:NO];
    }
    if (tag == ShanChuTag)//删除
    {
        if ([downloadOrDeleteArray count] > 0)
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
    if (tag == WoXiHuanTag)
    {
        [self getWoXiHuanList];
    }
    if (tag == RemoveWoxihuanTag) {
        [self removeFavoriteImg];
    }
}


- (void)getWoXiHuanList
{
    [self createAnimatingView];
    [self lockUI];
    if (pcClient == nil) {
        pcClient = [[PCRestClient alloc] init];
        pcClient.delegate = self;
    }
    //[self createLoadingView:NO];
    self.currentRequest = [pcClient getPictureGroupByInfo:[PCUtilityStringOperate encodeToPercentEscapeString:@"modifyTime desc"] andGroupType:@"label"];
}

#pragma
-(void)restClient:(PCRestClient *)client getPictureGroupByInfoSuccess:(NSArray *)resultInfo
{
    [dicatorView stopAnimating];
    [self unLockUI];
    // [self removeLoadingView];
    [self.mFavoriteList removeAllObjects];
    
    [self.mFavoriteList  addObjectsFromArray:resultInfo];
    [self.mFavoriteList insertObject:[NSDictionary dictionaryWithObject:@"新建文件夹" forKey:@"name"   ] atIndex:0];
   // [self doneLoadingTableViewData];
    self.currentRequest = nil;
    
    [self showAlertModeView];
    
}
-(void)restClient:(PCRestClient *)client getPictureGroupByInfoFailedWithError:(NSError *)error
{
    [dicatorView stopAnimating];
    [self unLockUI];
    // [self removeLoadingView];
    if (error.code == 1003) {
        self.currentRequest = nil;
        
        [self.mFavoriteList removeAllObjects];
        
        [self.mFavoriteList insertObject:[NSDictionary dictionaryWithObject:@"新建文件夹" forKey:@"name"   ] atIndex:0];

        [self showAlertModeView];

        return;
    }
    if (error.code == PC_Err_BoxUnbind) {
        [PCLogin removeDevice:[PCLogin getResource]];
    }
    if (error.code == PC_Err_FileNotExist && [self.mFavoriteList count]==0)
    {
        self.currentRequest = nil;
        return;
    }
    [ErrorHandler showErrorAlert:error];
    self.currentRequest = nil;
}


- (void)cancelButtonClick
{
    mFavoriteBG.hidden = YES;
}

-(BOOL)hasSelectCellWithIndexPath:(KKIndexPath *)indexPath
{
    NSUInteger index = indexPath.index;
    if (index >=[fileList count])
    {
        return NO;
    }
    PCFileInfo *info = (PCFileInfo *)[fileList objectAtIndex:index];
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
#pragma mark - KKGridViewDataSource

- (NSUInteger)gridView:(KKGridView *)gridView numberOfItemsInSection:(NSUInteger)section
{
    return fileCount;
}

- (KKGridViewCell *)gridView:(KKGridView *)gridView cellForItemAtIndexPath:(KKIndexPath *)indexPath
{
	NSUInteger index = indexPath.index;
	
    NSString *cellID = [KKGridViewCell cellIdentifier];
    KKGridViewCell *cell = [gridView dequeueReusableCellWithIdentifier:cellID];
    if (!cell)
    {
        cell = [[[KKGridViewCell alloc] initWithFrame:(CGRect){ .size = gridView.cellSize } reuseIdentifier:cellID] autorelease];
    }
    else
    {
        objc_setAssociatedObject(cell, kIndexPathAssociationKey, nil, OBJC_ASSOCIATION_RETAIN);
    }
    cell.imageView.image = [UIImage imageNamed:@"picture.png"];
    [cell setEditing:isEditing animated:NO];
	if (isEditing)
    {
        [cell changeSelectImage:[self hasSelectCellWithIndexPath:indexPath]];
    }
    NSNumber *indexKey = @(index);
	id obj = [self cacheObjectForKey:indexKey];
    
    if (obj && obj != [NSNull null])
    {
        cell.imageView.image = obj;
        if ( (((UIImage*)obj).size.width< cell.imageView.frame.size.width)
            &&
            (((UIImage*)obj).size.height< cell.imageView.frame.size.height)) {
            cell.imageView.contentMode = UIViewContentModeCenter;
        }
        else{
            cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        }
        
    }
    else
    {
        PCFileInfo *info = (PCFileInfo *)[fileList objectAtIndex:index];
        NSString *thumbPath = self.thumbsPathDic[info.hash];
        if (thumbPath)
        {
            UIImage *img = [UIImage imageWithContentsOfFile:thumbPath];
            if (img) {
                cell.imageView.image = img;
                if ( (img.size.width< cell.imageView.frame.size.width)
                    &&
                    (img.size.height< cell.imageView.frame.size.height)) {
                    cell.imageView.contentMode = UIViewContentModeCenter;
                }
                else{
                    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
                }
                
                if (self.imgFileCache == nil){
                    [self removeLoadingView];
                }
            }
            [self setCacheObject:img ? img : [NSNull null] forKey:indexKey];
        }
        else
        {
            cell.imageView.image = [UIImage imageNamed:@"picture.png"];
            cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        }
    }
	
    cell.layer.borderColor = [UIColor whiteColor].CGColor;
    cell.layer.borderWidth = 2;
    return cell;
}

#pragma mark - KKGridViewDelegate methods
- (void)gridView:(KKGridView *)gridView didSelectItemAtIndexPath:(KKIndexPath *)indexPath
{
    if (isEditing)
    {
        KKGridViewCell *cell = [gridView cellForIndexPath:indexPath];
        if ([self hasSelectCellWithIndexPath:indexPath]) {
            BOOL selectAll = [downloadOrDeleteArray count]==[fileList count] ? YES : NO;
            [downloadOrDeleteArray removeObject:[fileList objectAtIndex:indexPath.index]];
            if (selectAll)
            {
                [(ToolView *)[self.view viewWithTag:TOOLVIEWTAG] changeTitleOfSelectAll];
            }
            [cell changeSelectImage:NO];
        }
        else
        {
            [downloadOrDeleteArray addObject:[fileList objectAtIndex:indexPath.index]];
            [cell changeSelectImage:YES];
            BOOL selectAll = [downloadOrDeleteArray count]==[fileList count] ? YES : NO;
            if (selectAll)
            {
                [(ToolView *)[self.view viewWithTag:TOOLVIEWTAG] changeTitleOfSelectAll];
            }

        }
        [self enableToolViewBtn:[downloadOrDeleteArray count] > 0 ? YES : NO];
        return;
    }
    [self removeLoadingView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadNewestThumbImage) object:nil];
    NSUInteger index = indexPath.index;
    if (fileList.count > index)
    {
        if (fileList)
        {
            if (self.imgFileCache) {
                [self.imgFileCache cancel];
                self.imgFileCache = nil;
            }
            PCFileInfo *fileInfo = fileList[index];
            self.imgFileCache = [[[FileCache alloc] init] autorelease];
            self.imgFileCache.index = index;
            self.imgFileCache.currentDeviceID = deviceID;
            
            if ([self.imgFileCache readFileFromCacheWithFileInfo:fileInfo withType:TYPE_CACHE_SLIDEIMAGE])
            {
                [self pushSlideImageWithStartIndex:index andImageDownLoaded:YES];
                return;
            }
            [self pushSlideImageWithStartIndex:index andImageDownLoaded:NO];
        }
    }
    else {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"PicUnvailable", nil) delegate:self];
    }
}

#pragma mark - PCFileCacheDelegate methods
//下载成功
- (void) cacheFileFinish:(FileCache *)fileCache
{
    switch (fileCache.viewType) {
        case TYPE_CACHE_THUMBIMAGE_ZIP:
        {
            NSString *localPath = [NSString stringWithString:fileCache.localPath];
            [self viewThumbImageZip:localPath startIndex:fileCache.index];
            self.zipFileCache = nil;
            break;
        }
        case TYPE_CACHE_SLIDEIMAGE:
        {
            [self removeLoadingView];
            if (fileCache.fileSize == 0)//盒子解绑或离线，返回的Content-Length头字段为0，fix bug54740
            {
                self.imgFileCache = nil;
                [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"BoxOffline", nil) delegate:nil];
            }
            else
            {
                NSString *path = [fileCache.localPath copy];
                NSInteger index = fileCache.index;
                self.imgFileCache = nil;//此处该句需要在viewSlideImage之前执行
                //[self viewSlideImage:path viewIndex:index];
                [self pushSlideImageWithStartIndex:index andImageDownLoaded:YES];
                [path release];
            }
            
            break;
        }
        default:
            break;
    }
    
    if (fileCount == 0)  {
        DLogInfo(@"PictureListController cacheFileFinish FileNotFound");
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"FileNotFound", nil) delegate:self];
    }
}
//下载缩略图失败
- (void) cacheFileFail:(FileCache*)fileCache hostPath:(NSString *)hostPath error:(NSString*)error
{
    BOOL isThumbError = fileCache.viewType != TYPE_CACHE_SLIDEIMAGE;
    
    [self loadThumbFinish:isThumbError];
    
    if (isThumbError)
    {
        isNetworkError = YES;
        [PCUtilityUiOperate showTip:error];
        curIndex = fileCache.index;//此处添加该句是为了让下载失败的zip文件可以重新下载
        self.zipFileCache = nil;
        bDownloadThumbnailFailed = YES;
        [self removeLoadingView];
    }
    else
    {
        if (fileCache.isTimeout)//盒子断电，网络请求会超时，fix bug54740
        {
            //FILECACHE 释放前 释放数组里的引用，
            self.imgFileCache = nil;
            [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"BoxOffline", nil) delegate:nil];
        }
        else
        {
            NSString *path = [fileCache.localPath copy];
            NSInteger index = fileCache.index;
            self.imgFileCache = nil;//此处该句需要在viewSlideImage之前执行
            //[self viewSlideImage:path viewIndex:index];
            [self pushSlideImageWithStartIndex:index andImageDownLoaded:YES];
            [path release];
        }
    }
}
#pragma mark - UIAlertViewDelegate method
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView == getPicFailAlertView)
    {
        [getPicFailAlertView release];
        getPicFailAlertView = nil;
    }
}

#pragma mark - Data Source Loading / Reloading Methods
//加载数据函数
- (void)reloadTableViewDataSource
{
    _reloading = YES;
    [self createLoadingView:NO];
    
//    [PCUtilityUiOperate animateRefreshBtn:self.navigationItem.rightBarButtonItem.customView];
//    self.navigationItem.rightBarButtonItem.enabled = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadNewestThumbImage) object:nil];
    [self cancelCache:YES];
    [self getPictureList];
    
}
//完成加载的时候
- (void)doneLoadingTableViewData
{
	[self  doneLoadingEGOTableViewData];
    //  model should call this when its done loading
//    if (dicatorView==nil || ![dicatorView isAnimating])
//    {
//        UIButton *refreshImg = (UIButton *)self.navigationItem.rightBarButtonItem.customView;
//        [refreshImg.layer removeAllAnimations];
//        self.navigationItem.rightBarButtonItem.enabled = YES;
//    }
	_reloading = NO;
	[_refreshBottomView egoRefreshScrollViewDataSourceDidFinishedLoading:self.gridView];
}

//加载当前屏幕上显示cell的缩略图
-(void)loadNewestThumbImage
{
    if (bGettingPicList || isEditing)
    {
        return;
    }
    [self cancelCache:YES];
    [self showOrDownloadThumbZip:self.visiableStartIndex];
}
//点击图片浏览大图函数
- (void)pushSlideImageWithStartIndex:(int)index andImageDownLoaded:(BOOL)bDownLoaded
{
    self.bCoverdByPushing = YES;
    PCFileInfo *fileInfo = fileList[index];
    self.imgFileCache = nil;
    FileCache *fileCache = [[FileCache alloc] init] ;
    FileCacheController *cacheController = [[FileCacheController alloc] initWithPath:[fileCache getCacheFilePath:fileInfo.path
                                                                                                        withType:TYPE_CACHE_SLIDEIMAGE]  andFinishLoadingState:bDownLoaded
                                                                       andDataSource:self.fileList
                                                                andCurrentPCFileInfo:fileInfo
                                                           andLastViewControllerName:self.navigationItem.title];
    
    cacheController.title = fileInfo.name;
    KTPhotoScrollViewController *newController = [[KTPhotoScrollViewController alloc]
                                                  initWithDataSource:cacheController
                                                  andStartWithPhotoAtIndex:index];
    [fileCache release];
    newController.mGroupType = self.mGroupType;
    newController.groupName = self.groupName;
    [cacheController release];
    [self.navigationController pushViewController:newController animated:YES];
    [newController release];
}
//压缩图片
- (void) processThumbImage:(NSString*)thumbImgPath
{
    UIImage *img = [UIImage imageWithContentsOfFile:thumbImgPath];
    
    if ((img.size.width==150&&img.size.height>150)
        ||(img.size.height==150&&img.size.width>150))
    {
        CGRect  newRect;
        if (img.size.height>150) {
            newRect = CGRectMake(0, (img.size.height-150)/2, 150, 150);
        }
        else{
            newRect = CGRectMake((img.size.width-150)/2, 0, 150,150);
        }
        
        CGImageRef subImageRef = CGImageCreateWithImageInRect(img.CGImage, newRect);
        CGRect smallBounds = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));
        
        UIGraphicsBeginImageContext(smallBounds.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextDrawImage(context, smallBounds, subImageRef);
        UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
        UIGraphicsEndImageContext();
        CGImageRelease(subImageRef);
        
        NSData *imgData = UIImageJPEGRepresentation(smallImage,0.9);
        [imgData writeToFile:thumbImgPath atomically:YES];
    }
}

- (void)refreshFileList:(PCFileInfo*)fileInfo
{
    //删除图片操作  会回调过来 同步 本地数据
    if (fileInfo) {
        int num = self.fileList.count;
        for (int i=0 ;i<num;i++) {
            PCFileInfo *info = [self.fileList objectAtIndex:i];
            if ([fileInfo.path isEqualToString:info.path]) {
                [self.fileList removeObjectAtIndex:i];
                fileCount-=1;
                break;
            }
        }
    }
    
    //重新网络请求刷数据，不然图片新的排序可能错乱
    if (fileCount>0) {
        bNeedRefresh = YES;
    }
    else                //如果最后一张图片在大图浏览时删除了了，这里本地数据不做删除的话
        //会有已经删掉的图显示（box没图时网络请求返回错误，而不是空数据
        //就不会刷新）
    {
        //立即刷新可能 最后删除的那个图还在
        bNeedRefresh = NO;
        fileCount = 0;
        [self.fileList removeAllObjects];
        [self.thumbsDic removeAllObjects];
        [self.gridView reloadData];
    }
}

#pragma UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView == mTable) {
        return;
    }
    curIndex = self.visiableEndIndex+1;
    [self removeLoadingView];
    curIndex = self.visiableStartIndex;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadNewestThumbImage) object:nil];
    [self cancelCache:YES];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView == mTable) {
        return;
    }
    
    [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    if (!bGettingPicList && !isEditing) {
        if (isNoMoreData) {
            _refreshBottomView.state = EGONOMoreData;
            return;
        }
        [_refreshBottomView egoRefreshScrollViewDidEndDragging:scrollView];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)sender
{
    if (sender == mTable) {
        return;
    }
    
    [_refreshHeaderView egoRefreshScrollViewDidScroll:sender];//顶部下拉刷新
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    //enshore that the end of scroll is fired because apple are twats...
    [self performSelector:@selector(scrollViewDidEndScrollingAnimation:) withObject:nil afterDelay:0.3];
    if (!bGettingPicList && !isEditing)
    {
        if (isNoMoreData)
        {
            _refreshBottomView.state = EGONOMoreData;
        }
        [_refreshBottomView egoRefreshScrollViewDidScroll:sender];
    }
 }

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (scrollView == mTable) {
        return;
    }
    [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    curIndex = self.visiableStartIndex;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadNewestThumbImage) object:nil];
    [self performSelector:@selector(loadNewestThumbImage)];
}
#pragma mark -
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && alertView.tag == DELETE_FOLDER_TAG)
    {
        totalDeleteCount = [downloadOrDeleteArray count];
        successDeleteCount = 0;
        [self deleteFile];
    }
    else if (buttonIndex == [alertView firstOtherButtonIndex]) {
        if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput) {
            NSString *folderName = [[[alertView textFieldAtIndex:0] text]  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (alertView.tag == NEW_FOLDER_TAG) {
                
                self.currentFavoriteFileName = folderName;
                [self  setFavoriteImg];
                mFavoriteBG.hidden = YES;
            }
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
#pragma PCRestClientDelegate
- (void)restClient:(PCRestClient*)client pictureListGetGroupImageByInfoSuccess:(NSDictionary *)resultInfo
{
    bGettingPicList = NO;
    isNetworkError = NO;
    bNeedRefresh = NO;
    [dicatorView stopAnimating];
    [self doneLoadingTableViewData];
    [self refreshThumbsWithDic:resultInfo];
    self.currentRequest = nil;
}
- (void)restClient:(PCRestClient*)client pictureListGetGroupImageByInfoFailedWithError:(NSError*)error
{
    bGettingPicList = NO;
    bNeedRefresh = NO;
    [dicatorView stopAnimating];
    [self doneLoadingTableViewData];
    if (error.code == PC_Err_BoxUnbind)
    {
        [self removeNoContentView];
        UIView *view = [self noBoxFoundOrNoContent:NO];
        [self.view addSubview:view];
        [PCLogin removeDevice:[PCLogin getResource]];
    }
    else
    {
        [self removeNoContentView];
        if ([self.fileList count]==0 || error.code == PC_Err_NoDisk)
        {
            [self.view addSubview:[self noBoxFoundOrNoContent:YES]];
        }
    }

    if ([error.domain isEqualToString:NSURLErrorDomain])
    {
        isNetworkError = YES;
    }
    else if ([error.domain isEqualToString:KTServerErrorDomain] && error.code == PC_Err_FileNotExist)
    {
        self.currentRequest = nil;
        isNoMoreData = YES;
        
        if (isRefresh) {
            isRefresh = NO;
            [fileList removeAllObjects];
            fileCount = 0;
            [self.gridView reloadData];
            [self.view addSubview:[self noBoxFoundOrNoContent:YES]];
            [self enableEidtBtn:NO];
        }
        return;
    }
    
    [ErrorHandler showErrorAlert:error];
    self.currentRequest = nil;
    isRefresh = NO;
}

#pragma mark - PCFileOperateDelegate
-(void)removeSomePCFileInfoWhenFileOperateFailed:(FileOperate *)fileOperate
{
    if ([[fileOperate finishedPathArray] count] > 0)
    {
        for (NSString *path in [fileOperate finishedPathArray])
        {
            PCFileInfo *info = nil;
            for (PCFileInfo *object in downloadOrDeleteArray)
            {
                if ([object.path isEqualToString:path])
                {
                    info = object;
                    break;
                }
            }
            [downloadOrDeleteArray removeObject:info];
            [fileList removeObject:info];
            fileCount = [fileList count];
        }
        [self.gridView reloadData];
    }
}
-(void)fileOperateFinished:(FileOperate *)fileOperate//文件操作完成
{
    successDeleteCount += [fileOperate succeedCount];
    [fileOperate release];
    if ([downloadOrDeleteArray count] > MAXDELETEFILE)
    {
//        for (int i = 0; i < MAXDELETEFILE; i++)
//        {
//            PCFileInfo *info = [downloadOrDeleteArray objectAtIndex:i];
//            [fileList removeObject:info];
//        }
        [downloadOrDeleteArray removeObjectsInRange:NSMakeRange(0, MAXDELETEFILE)];
    }
    else
    {
//        for (int i = 0; i < [downloadOrDeleteArray count]; i++)
//        {
//            PCFileInfo *info = [downloadOrDeleteArray objectAtIndex:i];
//            [fileList removeObject:info];
//        }
        [downloadOrDeleteArray removeAllObjects];
    }
//    fileCount = [fileList count];
//    [self.gridView reloadData];
    if ([downloadOrDeleteArray count] > 0)
    {
        [self deleteFile];
        return;
    }
    [self cancelAction];
    if (successDeleteCount == totalDeleteCount) {
        [PCUtilityUiOperate showTip:@"图片删除成功！"];
    }
//    else if (successDeleteCount == 0) {
//        [PCUtilityUiOperate showTip:@"图片删除失败，请稍候重试！"];
//    }
    else {
        //NSString *message = [NSString stringWithFormat:@"操作完成，成功%d个，失败%d个！", successDeleteCount, totalDeleteCount-successDeleteCount];
        [PCUtilityUiOperate showTip:@"部分图片删除失败，请稍候重试！"];
    }
    [self refreshData:nil];
    [self unLockUI];
    [self setEGORefreshOrigin];
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

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadEGOTableViewDataSource{
    
    //  should be calling your tableviews data source model to reload
    //  put here just for demo
    [self refreshData:nil];
}

- (void)doneLoadingEGOTableViewData{
    
    //  model should call this when its done loading
    _reloading = NO;
    [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.gridView];
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods
- (void)egoRefreshTableHeaderOriginalDidTriggerRefresh:(EGORefreshTableHeaderViewOriginal*)view
{
    [self reloadEGOTableViewDataSource];
}

- (NSDate*)egoRefreshTableHeaderOriginalDataSourceLastUpdated:(EGORefreshTableHeaderViewOriginal*)view
{
    return [NSDate date];
}




#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return  TABLE_CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.mFavoriteList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:CellIdentifier] autorelease];
        cell.backgroundColor = [UIColor clearColor];
    }
    
    // Configure the cell...
    cell.textLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.text = nil;
    cell.accessoryView = nil;
    
//    MonthItem *item = self.mFavoriteList[indexPath.row];
//    cell.textLabel.text = item.name;
//    cell.imageView.image = [UIImage imageNamed:@"file_folder.png"];
//    
//    
//    cell.textLabel.textColor = [UIColor blackColor];
//    cell.detailTextLabel.text = nil;
//    cell.accessoryView = nil;
    
    NSDictionary *node = self.mFavoriteList[indexPath.row];
    NSString *name = node[@"name"];
    cell.textLabel.text = name;
    cell.imageView.image = [UIImage imageNamed:@"file_folder.png"];
    return cell;
}


/**
 代理方法
 选择了指定索引路径的表格行
 @param tableView 表格
 @param indexPath 索引路径
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        [self createNewFloder];
        return;
    }
    
    if (pcClient == nil) {
        pcClient = [[PCRestClient alloc] init];
        pcClient.delegate = self;
    }
    

    NSDictionary *node = self.mFavoriteList[indexPath.row];
    self.currentFavoriteFileName = node[@"name"];
    mFavoriteBG.hidden = YES;
    
    [self  setFavoriteImg];
}

- (void)setFavoriteImg
{
    [self lockUI];
    [self createAnimatingView];
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGetSetImgLabel:)];
    request.process = @"SetImageLabel";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      [PCUtilityStringOperate encodeToPercentEscapeString:
                       [self loadDeletePath:downloadOrDeleteArray] ],@"imagepaths",
                      [PCUtilityStringOperate encodeToPercentEscapeString:self.currentFavoriteFileName],@"imagefolder",
                      nil];
    
    
    self.currentRequest = request;
    [request start];
}

- (void)removeFavoriteImg
{
    [self createAnimatingView];;
    [self lockUI];
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGetDelImageFromLabel:)];
    request.process = @"DelImageFromLabel";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      [PCUtilityStringOperate encodeToPercentEscapeString:
                       [self loadDeletePath:downloadOrDeleteArray] ],@"imagepaths",
                      [PCUtilityStringOperate encodeToPercentEscapeString:self.groupName],@"imagefolder",
                      nil];
    
    
    self.currentRequest = request;
    [request start];
}

-(void)requestDidGetDelImageFromLabel:(PCURLRequest *)request
{
    self.currentRequest = nil;
    [self unLockUI];
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
                //NSString *tip = [NSString stringWithFormat:@"图片已从\"我喜欢文件夹%@\"中删除",self.groupName];
                [PCUtilityUiOperate showTip:@"成功移除我喜欢图片！"];
                
                [_thumbsDic removeAllObjects];
                [self.fileList removeObjectsInArray:downloadOrDeleteArray];
                fileCount = [self.fileList count];
                [downloadOrDeleteArray removeAllObjects];
                [self.gridView reloadData];
                [self cancelAction];
                [self enableEidtBtn:fileCount>0];
                [self removeNoContentView];
                if (fileCount == 0)
                {
                    [self.view addSubview:[self noBoxFoundOrNoContent:YES]];
                }
                return;
            }
        }
    }
    
    [self cancelAction];
    [PCUtilityUiOperate showTip:@"移除我喜欢图片失败，请稍候重试！"];
}

-(void)requestDidGetSetImgLabel:(PCURLRequest *)request
{
    [self unLockUI];
    [dicatorView stopAnimating];
    if (request.error) {
        [ErrorHandler showErrorAlert:request.error];
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                NSString *tip = [NSString stringWithFormat:@"图片已成功添加到\"%@\"",self.currentFavoriteFileName];
                 [PCUtilityUiOperate showTip :tip];
            }
            else {
                if ([dict objectForKey:@"errCode"]) {
                    result = [[dict objectForKey:@"errCode"] intValue];
                }
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                [ErrorHandler showErrorAlert:error];
            }
        }
        else {
            NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
            [ErrorHandler showErrorAlert:error];
        }
    }
    self.currentRequest = nil;
    [self cancelAction];
}



- (void) createNewFloder
{
    UIAlertView * inputAnswerAlert = [[UIAlertView alloc] initWithTitle:@"新建文件夹"
                                                                message:@"请输入要新建的文件夹名称"
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                      otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    inputAnswerAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [inputAnswerAlert textFieldAtIndex:0];
    inputAnswerAlert.tag = NEW_FOLDER_TAG;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [inputAnswerAlert show];
    [inputAnswerAlert release];
    
}


- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    if (alertView.alertViewStyle != UIAlertViewStylePlainTextInput) {
        return YES;
    }
    UITextField *textField = [alertView textFieldAtIndex:0];
    if (textField)
    {
        NSString *name = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        NSUInteger length = [name length];
        NSRange range = [name rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/[\\/:*\"<>?|]"]];
        
        if (length == 0 )
        {
            return NO;
        }
        else if(range.location!=NSNotFound)
        {
            [PCUtilityUiOperate showTip :NSLocalizedString(@"InvalidName", nil)];
            return NO;
        }
        else if ([name lengthOfBytesUsingEncoding:NSUTF8StringEncoding] > FILE_NAME_MAX_LENGTH)
        {
            if (alertView.visible)
            {
                alertView.delegate = nil;
                [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"NameTooLong", nil) delegate:nil];
                alertView.delegate = self;
            }
            return NO;
        }
    }
    
    
    return YES;
}

@end
