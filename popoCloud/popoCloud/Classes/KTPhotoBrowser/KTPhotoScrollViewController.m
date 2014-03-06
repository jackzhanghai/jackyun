//
//  KTPhotoScrollViewController.m
//  KTPhotoBrowser
//
//  Created by Kirby Turner on 2/4/10.
//  Copyright 2010 White Peak Software Inc. All rights reserved.
//

#import "KTPhotoScrollViewController.h"
#import "KTPhotoBrowserDataSource.h"
#import "KTPhotoBrowserGlobal.h"
#import "KTPhotoView.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "FileCacheController.h"
#import "PCFileInfo.h"
#import "FileListViewController.h"
#import "ScreenLockViewController.h"
#import "PCAppDelegate.h"
#import "PCUtilityStringOperate.h"
#import "PCLogin.h"

const CGFloat ktkDefaultPortraitToolbarHeight   = 44;
const CGFloat ktkDefaultLandscapeToolbarHeight  = 33;
const CGFloat ktkDefaultToolbarHeight = 44;

#define BUTTON_DELETEPHOTO 0
#define BUTTON_CANCEL 1

#define MAIN_TITLE_TAG  3
#define SUB_TITLE_TAG     4

#define DELET_PHOTO_TAG  6

#define   NEW_FOLDER_TAG                7

@interface KTTitleView : UIView
{
    UILabel *mainTitleView;
    UILabel *subTitleView;
}

@end
@implementation KTTitleView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        mainTitleView = [[[UILabel alloc] initWithFrame:CGRectMake(0,0,frame.size.width,frame.size.height*2/3)] autorelease];
        mainTitleView.textAlignment = UITextAlignmentCenter;
//        mainTitleView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        mainTitleView.font = [UIFont boldSystemFontOfSize:20];
        mainTitleView.textColor = [UIColor whiteColor];
        mainTitleView.backgroundColor = [UIColor clearColor];
        mainTitleView.tag = MAIN_TITLE_TAG;
        [self addSubview:mainTitleView];
        
        subTitleView = [[[UILabel alloc] initWithFrame:CGRectMake(0,frame.size.height*2/3,frame.size.width,frame.size.height/3)] autorelease];
        subTitleView.textAlignment = UITextAlignmentCenter;
//        subTitleView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        subTitleView.font = [UIFont boldSystemFontOfSize:12];
        subTitleView.textColor = [UIColor whiteColor];
        subTitleView.tag = SUB_TITLE_TAG;
        subTitleView.backgroundColor = [UIColor clearColor];
        [self addSubview:subTitleView];
    }
    return self;
}

@end

@interface KTPhotoScrollViewController (KTPrivate)
- (void)setCurrentIndex:(NSInteger)newIndex;
- (void)toggleChrome:(BOOL)hide;
- (void)startChromeDisplayTimer;
- (void)cancelChromeDisplayTimer;
- (void)hideChrome;
- (void)showChrome;
- (void)swapCurrentAndNextPhotos;
- (void)sharePhoto;
- (void)collectPhoto;
- (void)toggleNavButtons;
- (CGRect)frameForPagingScrollView;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (void)loadPhoto:(NSInteger)index;
- (void)unloadPhoto:(NSInteger)index;
- (int)photoCurrentIndex;
@end

@implementation KTPhotoScrollViewController

@synthesize statusBarStyle = statusBarStyle_;
@synthesize statusbarHidden = statusbarHidden_;
@synthesize currentRequest;
@synthesize bDeletepPhoneContent;
@synthesize bShowToolBar;
@synthesize m_fileCache;
@synthesize mGroupType;
@synthesize currentFavoriteFileName;
@synthesize mFavoriteList;
@synthesize groupName;

- (int)photoCurrentIndex
{
    return currentIndex_;
}

- (void)showPicScrollView:(BOOL)bShow
{
    scrollView_.hidden = bShow;
}

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.m_fileCache) {
        self.m_fileCache.delegate = nil;
        [self.m_fileCache cancel];
        self.m_fileCache = nil;
    }
    
    [pcClient cancelRequest:self.currentRequest];
    [pcClient release];
    [groupName release];
    [mFavoriteBG release];
    [mFavoriteList release];
    [mTable release];
    self.currentFavoriteFileName = nil;
   [collectBtn release], collectBtn = nil;
   [shareBtn release], shareBtn = nil;
   [deleteBtn release], deleteBtn = nil;
   [woXiHuanBtn release],woXiHuanBtn = nil;
   [scrollView_ release], scrollView_ = nil;
   [toolbar_ release], toolbar_ = nil;
   [photoViews_ release], photoViews_ = nil;
  
   [dataSource_ release], dataSource_ = nil;  
   self.shareUrl = nil;
    self.dicatorView = nil;
    if (self.currentRequest) {
        [restClient cancelRequest:self.currentRequest];
        self.currentRequest = nil;
    }
    [restClient release];
    [mGroupType release];
   [super dealloc];
}

- (id)initWithDataSource:(id <KTPhotoBrowserDataSource>)dataSource andStartWithPhotoAtIndex:(NSUInteger)index 
{
   if (self = [super init]) {
     startWithIndex_ = index;
     dataSource_ = [dataSource retain];
     
     // Make sure to set wantsFullScreenLayout or the photo
     // will not display behind the status bar.
       if (!IS_IOS7) {
           [self setWantsFullScreenLayout:YES];
       }
     

     BOOL isStatusbarHidden = [[UIApplication sharedApplication] isStatusBarHidden];
     [self setStatusbarHidden:isStatusbarHidden];
     
     self.hidesBottomBarWhenPushed = YES;
       
    firstVisiblePageIndexBeforeRotation_ = startWithIndex_;
    percentScrolledIntoFirstVisiblePage_ = 0;
    bShowToolBar = YES;
   }
   return self;
}

- (void)loadView 
{
   [super loadView];
   
   CGRect scrollFrame = [self frameForPagingScrollView];
   UIScrollView *newView = [[UIScrollView alloc] initWithFrame:scrollFrame];
   [newView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
   [newView setDelegate:self];
   
   UIColor *backgroundColor = [dataSource_ respondsToSelector:@selector(imageBackgroundColor)] ?
                                [dataSource_ imageBackgroundColor] : [UIColor blackColor];  
   [newView setBackgroundColor:backgroundColor];
   [newView setAutoresizesSubviews:YES];
   [newView setPagingEnabled:YES];
   [newView setShowsVerticalScrollIndicator:NO];
   [newView setShowsHorizontalScrollIndicator:NO];
   
   [[self view] addSubview:newView];
   
   scrollView_ = [newView retain];
   
   [newView release];
    

    if (bShowToolBar)
    {
        deleteBtn = [[UIBarButtonItem alloc]
                     initWithImage:[UIImage imageNamed:@"del.png"]
                     style:UIBarButtonItemStylePlain
                     target:self
                     action:@selector(deleteButtonClick:)];
        
        UIBarItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                         target:nil
                                                                         action:nil];
        
        CGRect screenFrame = [[UIScreen mainScreen] bounds];
        CGRect toolbarFrame = CGRectMake(0,
                                         screenFrame.size.height - ktkDefaultToolbarHeight,
                                         screenFrame.size.width,
                                         ktkDefaultToolbarHeight);
        
        toolbar_ = [[UIToolbar alloc] initWithFrame:toolbarFrame];
        [toolbar_ setAutoresizingMask:UIViewAutoresizingFlexibleWidth
         |UIViewAutoresizingFlexibleHeight
         | UIViewAutoresizingFlexibleTopMargin
         | UIViewAutoresizingFlexibleRightMargin];
        [toolbar_ setBarStyle:UIBarStyleBlack];
        toolbar_.translucent = YES;
        
        if (((PCAppDelegate *)[UIApplication sharedApplication].delegate).bNetOffline)
        {
            [toolbar_ setItems:[NSArray arrayWithObjects:space,deleteBtn,space,nil]];
        }
        else
        {
            collectBtn = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"save.png"]
                          style:UIBarButtonItemStylePlain
                          target:self
                          action:@selector(collectButtonClick:)];
            
            shareBtn = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"icon_share.png"]
                        style:UIBarButtonItemStylePlain
                        target:self
                        action:@selector(sharePhoto)];
            

            if ([self.mGroupType isEqualToString:@"label"]) {
                 woXiHuanBtn = [[UIBarButtonItem alloc]
                               initWithImage:[UIImage imageNamed:@"icon_yichuxihuan.png"]
                               style:UIBarButtonItemStylePlain
                               target:self
                               action:@selector(removeWoXihuan)];
            }
            else{
                woXiHuanBtn = [[UIBarButtonItem alloc]
                               initWithImage:[UIImage imageNamed:@"icon_xihuan.png"]
                               style:UIBarButtonItemStylePlain
                               target:self
                               action:@selector(addWoXihuan)];
            }
            
            [toolbar_ setItems:[NSArray arrayWithObjects:space,collectBtn,space,shareBtn,space,deleteBtn,space,woXiHuanBtn,space,nil]];
        }
        [[self view] addSubview:toolbar_];
        
        [space release];
    }
}

- (void)setTitleWithCurrentPhotoIndex
{
    if ([dataSource_ respondsToSelector:@selector(getFileInfoNodeAtIndex:)])
    {
        if (currentIndex_ < 0 || currentIndex_ >= photoCount_) {
            
        }
        else
        {
            NSString *formatString = NSLocalizedString(@"%1$i /%2$i", @"Picture X out of Y total.");
            NSString *title = [NSString stringWithFormat:formatString, currentIndex_ + 1, photoCount_, nil];

            PCFileInfo *fileInfo = [dataSource_ getFileInfoNodeAtIndex:currentIndex_];
            
            [self setMainTitle:fileInfo.name andSubTitle:title];
        }
    }
}

- (void)scrollToIndex:(NSInteger)index
{
   CGRect frame = scrollView_.frame;
   frame.origin.x = frame.size.width * index;
   frame.origin.y = 0;
   [scrollView_ scrollRectToVisible:frame animated:NO];
}

- (void)setScrollViewContentSize
{
   NSInteger pageCount = photoCount_;
   if (pageCount == 0) {
      pageCount = 1;
   }

   CGSize size = CGSizeMake(scrollView_.frame.size.width * pageCount, 
                            scrollView_.frame.size.height / 2);   // Cut in half to prevent horizontal scrolling.
   [scrollView_ setContentSize:size];
}

- (void)setMainTitle:(NSString*)mTitle andSubTitle:(NSString*)subTitle
{
    if (self.navigationItem.titleView) {
        UILabel *mainView = (UILabel*)[self.navigationItem.titleView viewWithTag:MAIN_TITLE_TAG];
        UILabel *subView = (UILabel*)[self.navigationItem.titleView viewWithTag:SUB_TITLE_TAG];
        if (mainView!=nil)
        {
            if (mTitle)
            {
                mTitle = [mTitle lastPathComponent];
            }
            mainView.text =mTitle;
        }
        if (subView !=nil)
        {
            subView.text = subTitle;
        }
        
        //如果前一页是9/10.那副标题长度是9/10，滑动到10／10时候，原来的副标题长度不够，会出现...，所以切换图片（title会变化）后，也调整下标题栏的size.
        [self layoutTitleView];
    }
}

- (void)createTitleView
{
    KTTitleView *title = [[KTTitleView alloc] initWithFrame:self.navigationController.navigationBar.frame];
    self.navigationItem.titleView =title;
    [title release];
}

- (void)viewDidLoad 
{
   [super viewDidLoad];
    self.mFavoriteList = [NSMutableArray array];
    self.dicatorView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
    self.dicatorView.color = [UIColor grayColor];
    [self.view addSubview:self.dicatorView];
    self.dicatorView.center = self.view.center;
    self.dicatorView.autoresizingMask =    UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin|
    UIViewAutoresizingFlexibleBottomMargin;

   photoCount_ = [dataSource_ numberOfPhotos];
   [self setScrollViewContentSize];
   
   photoViews_ = [[NSMutableArray alloc] initWithCapacity:photoCount_];
   for (int i=0; i < photoCount_; i++) {
      [photoViews_ addObject:[NSNull null]];
   }
    [self  createTitleView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackgroud) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setNavFrame) name:@"ShouldSetNavFrame" object:nil];
    [self createTable];
//    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
//        self.edgesForExtendedLayout = UIRectEdgeAll;
//    }
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

- (void)cancelButtonClick
{
    mFavoriteBG.hidden = YES;
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

-(void)setNavFrame
{
    UINavigationBar *navbar = [[self navigationController] navigationBar];
    CGRect frame = [navbar frame];
    frame.origin.y = 20;
    [navbar setFrame:frame];
}
-(void)enterBackgroud
{
    [self cancelChromeDisplayTimer];
    if (IS_IPAD)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];
    }
}
- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	[self unloadPhoto:currentIndex_+1];
    [self unloadPhoto:currentIndex_-1];
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated 
{
   [super viewWillAppear:animated];
   [MobClick beginLogPageView:@"PhotoScrollView"];
   // The first time the view appears, store away the previous controller's values so we can reset on pop.
   UINavigationBar *navbar = [[self navigationController] navigationBar];
   if (!viewDidAppearOnce_) {
      viewDidAppearOnce_ = YES;
      navbarWasTranslucent_ = [navbar isTranslucent];
      statusBarStyle_ = [[UIApplication sharedApplication] statusBarStyle];
   }
   // Then ensure translucency. Without it, the view will appear below rather than under it.  
   [navbar setTranslucent:YES];
    if (IS_IPAD) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
    }
    else
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
    }

   // Set the scroll view's content size, auto-scroll to the stating photo,
   // and setup the other display elements.
   [self setScrollViewContentSize];
   [self setCurrentIndex:startWithIndex_];
   [self scrollToIndex:startWithIndex_];

   [self setTitleWithCurrentPhotoIndex];
   [self toggleNavButtons];
   [self startChromeDisplayTimer];

}

- (void)layoutTitleView
{
    UIView *titleView = self.navigationItem.titleView;
    UILabel *subTitle = (UILabel*)[self.navigationItem.titleView viewWithTag:SUB_TITLE_TAG];
    UILabel *mainTitle = (UILabel*)[self.navigationItem.titleView viewWithTag:MAIN_TITLE_TAG];
    CGRect titleRect = titleView.frame;
    CGSize mainTextSize = [mainTitle.text sizeWithFont:mainTitle.font];
    CGSize subTextSize = [subTitle.text sizeWithFont:subTitle.font];
    
    if (titleRect.origin.x+mainTextSize.width/2>= self.view.frame.size.width/2) {
        mainTitle.textAlignment = UITextAlignmentLeft;
        mainTitle.frame = CGRectMake(0, 0, titleRect.size.width, titleRect.size.height*2/3);
    }
    else{
        int startX = self.view.frame.size.width/2-titleRect.origin.x-mainTextSize.width/2;
        mainTitle.textAlignment = UITextAlignmentCenter;
        mainTitle.frame = CGRectMake(startX, 0, mainTextSize.width, titleRect.size.height*2/3);
    }
    if (titleRect.origin.x+subTextSize.width/2>= self.view.frame.size.width/2) {
        subTitle.textAlignment = UITextAlignmentLeft;
        subTitle.frame = CGRectMake(0, titleRect.size.height*2/3, titleRect.size.width, titleRect.size.height/3);
    }
    else{
        int startX = self.view.frame.size.width/2-subTextSize.width/2-titleRect.origin.x;
        subTitle.textAlignment = UITextAlignmentCenter;
        subTitle.frame = CGRectMake(startX, titleRect.size.height*2/3, subTextSize.width, titleRect.size.height/3);
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self layoutTitleView];
}

- (void)viewWillLayoutSubviews
{
    if (IS_IOS7) {
        CGRect bounds = scrollView_.bounds;
        bounds.origin.y = 0;
        scrollView_.bounds = bounds;
    }
    
    NSArray *subviews = [scrollView_ subviews];
    //防止图片不居中（否则 imageview 区域不会覆盖导航条区域）
    for (KTPhotoView *photoView in subviews) {
        [photoView setFrame:[self frameForPageAtIndex:[photoView index]]];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self cancelChromeDisplayTimer];
    if (self.m_fileCache) {
        [self.m_fileCache cancel];
        self.m_fileCache = nil;
    }
    if (self.shareUrl)
        [self.shareUrl cancelConnection];
    
    UINavigationBar *navbar = [[self navigationController] navigationBar];
    [navbar setTranslucent:navbarWasTranslucent_];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"PhotoScrollView"];
}

- (void)viewDidDisappear:(BOOL)animated 
{
   [super viewDidDisappear:animated];
}

- (void)deleteCurrentPhoto 
{
   if (dataSource_) {
      // TODO: Animate the deletion of the current photo.
       if ([dataSource_ respondsToSelector:@selector(getFileInfoNodeAtIndex:)])
       {
           if (currentIndex_ < 0 || currentIndex_ >= photoCount_) {
               return;
           }
            [self lockUI];
           if (self.bDeletepPhoneContent) {
               [self restClient:nil deletedPath:nil];
           }
           else{
               if (restClient == nil) {
                   restClient = [[PCRestClient alloc] init];
                   restClient.delegate = self;
               }
               
               PCFileInfo *fileInfo = [dataSource_ getFileInfoNodeAtIndex:currentIndex_];
               self.currentRequest = [restClient  deletePath:fileInfo.path];
           }
       }
   }
}

- (void)toggleNavButtons 
{
//   [previousButton_ setEnabled:(currentIndex_ > 0)];
//   [nextButton_ setEnabled:(currentIndex_ < photoCount_ - 1)];
}

- (void)refreshAfterDelete
{
    PCFileInfo *fileInfo = [dataSource_ getFileInfoNodeAtIndex:currentIndex_];
    
    self.currentRequest = nil;
    NSInteger photoIndexToDelete = currentIndex_;
    [self unloadPhoto:photoIndexToDelete];
    [dataSource_ deleteImageAtIndex:photoIndexToDelete];
    
    NSArray *controllers = self.navigationController.viewControllers;
    UIViewController *listController = controllers[controllers.count - 2];
    if ([listController respondsToSelector:@selector(refreshFileList:)]) {
        [listController performSelector:@selector(refreshFileList:) withObject:fileInfo];
    }
    
    photoCount_ -= 1;
    if (photoCount_ == 0) {
        [self showChrome];
        [[self navigationController] popViewControllerAnimated:YES];
    } else {
        NSInteger nextIndex = photoIndexToDelete;
        if (nextIndex == photoCount_) {
            nextIndex -= 1;
        }
        [self setCurrentIndex:nextIndex];
        [self setScrollViewContentSize];
    }
}

#pragma mark - PCRestClientDelegate

- (void)restClient:(PCRestClient*)client deletedPath:(NSDictionary *)resultInfo
{
    [self unLockUI];
    [self refreshAfterDelete];
}


- (void)restClient:(PCRestClient*)client deletePathFailedWithError:(NSError*)error
{
    [self unLockUI];
    [ErrorHandler showErrorAlert:error];
    self.currentRequest = nil;
}

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

- (CGRect)frameForPageAtIndex:(NSUInteger)index 
{
   // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
   // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
   // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
   // because it has a rotation transform applied.
   CGRect bounds = [scrollView_ bounds];
   CGRect pageFrame = bounds;
   pageFrame.size.width -= (2 * PADDING);
   pageFrame.origin.x = (bounds.size.width * index) + PADDING;
   return pageFrame;
}


#pragma mark -
#pragma mark Photo (Page) Management

- (void)loadPhoto:(NSInteger)index
{
   if (index < 0 || index >= photoCount_) {
      return;
   }
   id currentPhotoView = [photoViews_ objectAtIndex:index];
   if (NO == [currentPhotoView isKindOfClass:[KTPhotoView class]]) {
      // Load the photo view.
      CGRect frame = [self frameForPageAtIndex:index];
      KTPhotoView *photoView = [[KTPhotoView alloc] initWithFrame:frame];
      [photoView setScroller:self];
      [photoView setIndex:index];
       photoView.labelProgress.hidden = YES;
      [photoView setBackgroundColor:[UIColor clearColor]];
      
      // Set the photo image.
      if (dataSource_) {
         if ([dataSource_ respondsToSelector:@selector(imageAtIndex:photoView:)] == NO) {
            UIImage *image = [dataSource_ imageAtIndex:index];
            [photoView setImage:image];
         } else {
            [dataSource_ imageAtIndex:index photoView:photoView];
         }
      }
      

      [scrollView_ addSubview:photoView];
      [photoViews_ replaceObjectAtIndex:index withObject:photoView];
      [photoView release];
   } else {
      // Turn off zooming.
      [currentPhotoView turnOffZoom];
   }
}

- (void)unloadPhoto:(NSInteger)index
{
   if (index < 0 || index >= photoCount_) {
      return;
   }
   id currentPhotoView = [photoViews_ objectAtIndex:index];
   if ([currentPhotoView isKindOfClass:[KTPhotoView class]]) {
       if (((KTPhotoView*)currentPhotoView).currentCache) {
           [((KTPhotoView*)currentPhotoView).currentCache cancel];
           ((KTPhotoView*)currentPhotoView).currentCache.delegate = nil;
           ((KTPhotoView*)currentPhotoView).currentCache = nil;
       }

      [currentPhotoView removeFromSuperview];
      [photoViews_ replaceObjectAtIndex:index withObject:[NSNull null]];
   }
}

- (void)setCurrentIndex:(NSInteger)newIndex
{
   currentIndex_ = newIndex;
    NSLog(@"当前的图片的位置   %d",newIndex);
   [self loadPhoto:currentIndex_];
    //只在wifi网络下  进行预加载
    if ( [PCUtility isWifi] )
    {
        [self loadPhoto:currentIndex_ + 1];
        [self loadPhoto:currentIndex_ - 1];

    }
    
   [self unloadPhoto:currentIndex_ + 2];
   [self unloadPhoto:currentIndex_ - 2];
   
   [self setTitleWithCurrentPhotoIndex];
   [self toggleNavButtons];
}


#pragma mark -
#pragma mark Rotation Magic

- (void)updateToolbarWithOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    if (toolbar_) {
        CGRect toolbarFrame = toolbar_.frame;
        if ((interfaceOrientation) == UIInterfaceOrientationPortrait || (interfaceOrientation) == UIInterfaceOrientationPortraitUpsideDown) {
            toolbarFrame.size.height = ktkDefaultPortraitToolbarHeight;
        } else {
            toolbarFrame.size.height = ktkDefaultLandscapeToolbarHeight+1;
        }
        
        toolbarFrame.size.width = self.view.frame.size.width;
        toolbarFrame.origin.y =  self.view.frame.size.height - toolbarFrame.size.height;
        toolbar_.frame = toolbarFrame;
    }
}

- (void)layoutScrollViewSubviews
{
   [self setScrollViewContentSize];

   NSArray *subviews = [scrollView_ subviews];
   
   for (KTPhotoView *photoView in subviews) {
      CGPoint restorePoint = [photoView pointToCenterAfterRotation];
      
      [photoView setFrame:[self frameForPageAtIndex:[photoView index]]];
       
       CGFloat restoreScale = [photoView scaleToRestoreAfterRotation];
       //
//       UIInterfaceOrientation *orient = self.interfaceOrientation;
//       if (photoView.imageView_.image) {
//           [photoView  setContentModeForImgSize:photoView.imageView_.image.size];
//       }

       //
       
//      [photoView setMaxMinZoomScalesForCurrentBounds];
      [photoView restoreCenterPoint:restorePoint scale:restoreScale];
   }
   
   // adjust contentOffset to preserve page location based on values collected prior to location
   CGFloat pageWidth = scrollView_.bounds.size.width;
   CGFloat newOffset = (firstVisiblePageIndexBeforeRotation_ * pageWidth) + (percentScrolledIntoFirstVisiblePage_ * pageWidth);
   scrollView_.contentOffset = CGPointMake(newOffset, 0);
   
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (self.shareUrl && self.shareUrl.actionSheet)
    {
        [self.shareUrl.actionSheet dismissWithClickedButtonIndex:self.shareUrl.actionSheet.cancelButtonIndex
                                                   animated:NO];
        [self.shareUrl performSelector:@selector(showActionSheet) withObject:nil afterDelay:0.1];
    }
    UIView *sheet = [self.view.window viewWithTag:SHEETVIEWTAG];
    if ([sheet isKindOfClass:[UIActionSheet class]]) {
        
        [(UIActionSheet*)sheet dismissWithClickedButtonIndex:1 animated:NO];
        [self performSelector:@selector(deleteButtonClick:) withObject:nil afterDelay:0.1];
    }
    
    [self startChromeDisplayTimer];
//    if(IS_IPAD)
//    {
        [self layoutTitleView];
//    }
}
-(BOOL)shouldAutorotate
{
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations
{
    return  UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
   return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
                                duration:(NSTimeInterval)duration 
{
   // here, our pagingScrollView bounds have not yet been updated for the new interface orientation. So this is a good
   // place to calculate the content offset that we will need in the new orientation
   CGFloat offset = scrollView_.contentOffset.x;
   CGFloat pageWidth = scrollView_.bounds.size.width;
    if (pageWidth == 0) {
        pageWidth = 1;
    }
   
   if (offset >= 0) {
      firstVisiblePageIndexBeforeRotation_ = floorf(offset / pageWidth);
      percentScrolledIntoFirstVisiblePage_ = (offset - (firstVisiblePageIndexBeforeRotation_ * pageWidth)) / pageWidth;
   } else {
      firstVisiblePageIndexBeforeRotation_ = 0;
      percentScrolledIntoFirstVisiblePage_ = offset / pageWidth;
   }    
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration 
{
   [self layoutScrollViewSubviews];
   [self  adjustAlertModeViewFrame];
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

- (UIView *)rotatingFooterView
{
   return toolbar_;
}


#pragma mark -
#pragma mark Chrome Helpers

- (void)toggleChromeDisplay 
{
   [self toggleChrome:!isChromeHidden_];
}

- (void)toggleChrome:(BOOL)hide 
{
    isChromeHidden_ = hide;
//   if (hide) {
//      [UIView beginAnimations:nil context:nil];
//      [UIView setAnimationDuration:0.1];
//   }
   
//    if ( ! [self isStatusbarHidden] )
//    {
        [[UIApplication sharedApplication] setStatusBarHidden:hide withAnimation:NO];
        self.navigationController.navigationBarHidden = hide;
//    }

   CGFloat alpha = hide ? 0.0 : 1.0;
   
   // Must set the navigation bar's alpha, otherwise the photo
   // view will be pushed until the navigation bar.
   UINavigationBar *navbar = [[self navigationController] navigationBar];
   [navbar setAlpha:alpha];
    
    //if (isChromeHidden_ && statusbarHidden_ == NO) {
    if (1) {
        UINavigationBar *navbar = [[self navigationController] navigationBar];
        CGRect frame = [navbar frame];
        frame.origin.y = 20;
        [navbar setFrame:frame];
    }

   [toolbar_ setAlpha:alpha];
   [self.view setNeedsLayout];
    
//   if (hide) {
      //[UIView commitAnimations];
//   }
   
   if ( ! isChromeHidden_ ) {
      [self startChromeDisplayTimer];
   }
}

- (void)hideChrome 
{
   if (chromeHideTimer_ && [chromeHideTimer_ isValid]) {
      [chromeHideTimer_ invalidate];
      chromeHideTimer_ = nil;
   }
    if ([[PCSettings sharedSettings] screenLock])
    {
        if ([[ScreenLockViewController sharedLock] isOnScreen])
        {
            if (IS_IPAD)
            {
                [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];
            }
            
            return;
        }
        
    }
   [self toggleChrome:YES];
}

- (void)showChrome 
{
   [self toggleChrome:NO];
}

- (void)startChromeDisplayTimer 
{
   [self cancelChromeDisplayTimer];
   chromeHideTimer_ = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                       target:self 
                                                     selector:@selector(hideChrome)
                                                     userInfo:nil
                                                      repeats:NO];
}

- (void)cancelChromeDisplayTimer 
{
   if (chromeHideTimer_) {
      [chromeHideTimer_ invalidate];
      chromeHideTimer_ = nil;
   }
}


#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView 
{
   CGFloat pageWidth = scrollView.frame.size.width;
   float fractionalPage = scrollView.contentOffset.x / pageWidth;
   NSInteger page = floor(fractionalPage);
    if (page < 0) {
        page = 0;
    }
	if (page != currentIndex_) {
		[self setCurrentIndex:page];
	}
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView 
{
   [self hideChrome];
}

#pragma mark - callback methods
- (void) shareUrlFail:(NSString*)errorDescription {
    [self  unLockUI];
    [PCUtilityUiOperate showErrorAlert:errorDescription delegate:self];
}
- (void) shareUrlComplete {
    [self unLockUI];
    [self startChromeDisplayTimer];
}

- (void) shareUrlStart {
    //分享网络请求期间  锁住ui, 避免用户乱点 出各种问题，简化逻辑。
    [self lockUI];
}

- (void) shareUrlFinish {
    [self unLockUI];
    self.view.userInteractionEnabled = YES;
}

- (void) saveAlbum:(NSString*)path {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    UIImageWriteToSavedPhotosAlbum([UIImage imageWithContentsOfFile:path], self, @selector(imageSavedToPhotosAlbum:didFinishSavingWithError:contextInfo:), nil);
    [pool release];
}

- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [self.dicatorView stopAnimating];
    toolbar_.userInteractionEnabled = YES;
    scrollView_.scrollEnabled = YES;

    if (error) {
        [PCUtilityUiOperate showErrorAlert:[error localizedDescription] delegate:nil];
    }
    else {
        [PCUtilityUiOperate showOKAlert:NSLocalizedString(@"PictureAlreadySave", nil) delegate:nil];
    }
}

#pragma mark -
#pragma mark Toolbar Actions

- (void)sharePhoto
{
    if ([dataSource_ respondsToSelector:@selector(getFileInfoNodeAtIndex:)])
    {
        if (currentIndex_ < 0 || currentIndex_ >= photoCount_) {
            return;
        }

        PCFileInfo *fileInfo = [dataSource_ getFileInfoNodeAtIndex:currentIndex_];
        if (self.shareUrl)
            [self.shareUrl cancelConnection];

        self.shareUrl = [[[PCShareUrl alloc] init] autorelease];
        //开始分享时，不要让定时器做自动消失状态栏的操作，防止分享页顶部排版错乱。
        [self cancelChromeDisplayTimer];
        //modify by xy  bugID： 54133  不要下载。
        [self.shareUrl shareFileWithInfo:fileInfo andDelegate:self];
    }
}

- (void)removeWoXihuan
{
    if ([dataSource_ respondsToSelector:@selector(getFileInfoNodeAtIndex:)])
    {
        if (currentIndex_ < 0 || currentIndex_ >= photoCount_) {
            return;
        }
        
       [self removeFavoriteImg];

    }
}

- (void)addWoXihuan
{
    if ([dataSource_ respondsToSelector:@selector(getFileInfoNodeAtIndex:)])
    {
        if (currentIndex_ < 0 || currentIndex_ >= photoCount_) {
            return;
        }
        [self getWoXiHuanList];
    }
}

- (void)getWoXiHuanList
{
    [self lockUI];
    if (pcClient == nil) {
        pcClient = [[PCRestClient alloc] init];
        pcClient.delegate = self;
    }
    //[self createLoadingView:NO];
    self.currentRequest = [pcClient getPictureGroupByInfo:[PCUtilityStringOperate encodeToPercentEscapeString:@"modifyTime desc"] andGroupType:@"label"];
}

- (void)deleteButtonClick:(id)sender
{
    if ([dataSource_ respondsToSelector:@selector(getFileInfoNodeAtIndex:)])
    {
        if (currentIndex_ < 0 || currentIndex_ >= photoCount_) {
            return;
        }
        
        PCFileInfo *fileInfo = [dataSource_ getFileInfoNodeAtIndex:currentIndex_];
        if (fileInfo) {
            NSString *warning = bDeletepPhoneContent ? NSLocalizedString(@"ConfirmDel", nil) : @"确定删除云盘文件?\n(此操作会删除帐号下云盘中的相应文件)";
//            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:warning
//                                                                     delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
//            actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
//            actionSheet.tag =SHEETVIEWTAG;
//            [actionSheet showFromTabBar:self.tabBarController.tabBar];
//            [actionSheet release];
            
            UIAlertView *Alert = [[UIAlertView alloc] initWithTitle:warning
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                  otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
            Alert.tag = DELET_PHOTO_TAG;
            [Alert show];
            [Alert release];

        }
    }
}

- (void)collectButtonClick:(id)sender
{
    if ([dataSource_ respondsToSelector:@selector(getFileInfoNodeAtIndex:)])
    {
        if (currentIndex_ < 0 || currentIndex_ >= photoCount_) {
            return;
        }

        PCFileInfo *fileInfo = [dataSource_ getFileInfoNodeAtIndex:currentIndex_];
        if (fileInfo) {
            if ([fileInfo.size longLongValue] == 0) {
                [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"CollectEmptyFile", nil)
                                             title:NSLocalizedString(@"Prompt", nil)
                                          delegate:nil];
                return;
            }
            
            [self unloadPhoto:currentIndex_+1];
            [self unloadPhoto:currentIndex_-1];
            if (self.m_fileCache) {
                return;
            }
            [self.dicatorView startAnimating];
            toolbar_.userInteractionEnabled = NO;
            scrollView_.scrollEnabled = NO;
            FileCache* fileCache = [[[FileCache alloc] init] autorelease];
            self.m_fileCache = fileCache;
            [fileCache cacheFile:fileInfo.path viewType:TYPE_CACHE_IMAGE viewController:self fileSize:[fileInfo.size  longLongValue]  modifyGTMTime:[fileInfo.modifyTime longLongValue] showAlert:NO];
        }
    }
}

- (void) cacheFileFinish:(FileCache*)fileCache {
    switch (fileCache.viewType) {
        case TYPE_CACHE_IMAGE:
            [self saveAlbum:fileCache.localPath];
            break;
        default:
            break;
    }
    self.m_fileCache = nil;
}


- (void) cacheFileFail:(FileCache*)fileCache hostPath:(NSString *)hostPath error:(NSString*)error {
    [self.dicatorView stopAnimating];
    toolbar_.userInteractionEnabled = YES;
    scrollView_.scrollEnabled = YES;
    [PCUtilityUiOperate showErrorAlert:error delegate:nil];
    self.m_fileCache = nil;
}

- (void) cacheFileProgress:(float)progress hostPath:(NSString *)hostPath {
    
}

#pragma mark - UIActionSheetDelegate

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex 
{
   if (buttonIndex == BUTTON_DELETEPHOTO) {
      [self deleteCurrentPhoto];
   }
    
   //[self startChromeDisplayTimer];
}

#pragma mark - lock and unlock UI
- (void)lockUI
{
    [self.dicatorView startAnimating];
    self.view.userInteractionEnabled = NO;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.tabBarController.tabBar.userInteractionEnabled = NO;
}

- (void)unLockUI
{
    [self.dicatorView stopAnimating];
    self.view.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.tabBarController.tabBar.userInteractionEnabled = YES;
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == [alertView firstOtherButtonIndex]) {
        if (alertView.tag == DELET_PHOTO_TAG) {
            [self deleteCurrentPhoto];
        }
        else if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput) {
            NSString *folderName = [[[alertView textFieldAtIndex:0] text]  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (alertView.tag == NEW_FOLDER_TAG) {
                
                self.currentFavoriteFileName = folderName;
                [self  setFavoriteImg];
                mFavoriteBG.hidden = YES;
            }
        }

    }
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


- (void)setFavoriteImg
{
    [self lockUI];
    PCFileInfo *fileInfo = [dataSource_ getFileInfoNodeAtIndex:currentIndex_];
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGetSetImgLabel:)];
    request.process = @"SetImageLabel";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      [PCUtilityStringOperate encodeToPercentEscapeString:
                       [self loadDeletePath:[NSMutableArray   arrayWithObject:fileInfo]] ],@"imagepaths",
                      [PCUtilityStringOperate encodeToPercentEscapeString:self.currentFavoriteFileName],@"imagefolder",
                      nil];
    
    self.currentRequest = request;
    [request release];
    [request start];
}

- (void)removeFavoriteImg
{
    [self lockUI];
    PCFileInfo *fileInfo = [dataSource_ getFileInfoNodeAtIndex:currentIndex_];
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGetDelImageFromLabel:)];
    request.process = @"DelImageFromLabel";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      [PCUtilityStringOperate encodeToPercentEscapeString:
                       [self loadDeletePath:[NSMutableArray   arrayWithObject:fileInfo]]],@"imagepaths",
                      [PCUtilityStringOperate encodeToPercentEscapeString:self.groupName],@"imagefolder",
                      nil];
    
    
    self.currentRequest = request;
    [request release];
    [request start];
}

-(void)requestDidGetDelImageFromLabel:(PCURLRequest *)request
{
    self.currentRequest = nil;
    [self unLockUI];
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
                [PCUtilityUiOperate showTip:@"成功移除我喜欢图片！"];
                [self refreshAfterDelete];
                return;
            }
        }
    }
    
    [PCUtilityUiOperate showTip:@"移除我喜欢图片失败，请稍候重试！"];
}

-(void)requestDidGetSetImgLabel:(PCURLRequest *)request
{
    [self unLockUI];
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


-(NSString *)loadDeletePath:(NSMutableArray *)array
{
    NSMutableString *pathStr = [[NSMutableString alloc] initWithString:@"["];
    for (PCFileInfo *info in array)
    {
        [pathStr appendFormat:@"\"%@\",",info.path];
    }
    [pathStr deleteCharactersInRange:NSMakeRange(pathStr.length-1, 1)];
    [pathStr appendString:@"]"];
    return [pathStr autorelease];
}

#pragma mark  PCRestClientDelegate
-(void)restClient:(PCRestClient *)client getPictureGroupByInfoSuccess:(NSArray *)resultInfo
{
    [self  unLockUI];
    [self.mFavoriteList removeAllObjects];
    
    [self.mFavoriteList  addObjectsFromArray:resultInfo];
    [self.mFavoriteList insertObject:[NSDictionary dictionaryWithObject:@"新建文件夹" forKey:@"name"   ] atIndex:0];
    // [self doneLoadingTableViewData];
    self.currentRequest = nil;
    
    [self showAlertModeView];
    
}
-(void)restClient:(PCRestClient *)client getPictureGroupByInfoFailedWithError:(NSError *)error
{
    // [self removeLoadingView];
    [self  unLockUI];
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
    
    
    NSDictionary *node = self.mFavoriteList[indexPath.row];
    self.currentFavoriteFileName = node[@"name"];
    mFavoriteBG.hidden = YES;
    
    [self  setFavoriteImg];
}

                      
@end
