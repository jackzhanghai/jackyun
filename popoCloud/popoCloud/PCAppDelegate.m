//
//  PCAppDelegate.m
//  popoCloud
//
//  Created by Chen Dongxiao on 11-11-14.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "PCAppDelegate.h"
#import "LoginViewController.h"
#import "SettingViewController.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "PCLogin.h"
#import "NetPenetrate.h"
#import "NewAccountViewController.h"
#import "FileUploadManager.h"
#import "CameraUploadManager.h"
#import "FileFolderViewController.h"
#import "PicturesFolderViewController.h"
#import "FileDownloadManagerViewController.h"
#import "ManagementViewController.h"
#import "SettingViewController.h"
#import "MobClick.h"
#import "ScreenLockViewController.h"
#include <sys/xattr.h>
#import "PCUtilityUiOperate.h"

#define BegainTime  @"BegainTime"
#define ScreenLockTime 30.0f

@implementation PCAppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize tabbarContent;
@synthesize backgroundTaskIdentifier;

@synthesize bNetOffline;

#pragma mark - UIApplicationDelegate methods
-(void) loadTabBarController
{
    if (!self.tabbarContent)
    {
        //我的云
        FileFolderViewController *vc1 = [[FileFolderViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"FileFolderView"] bundle:nil];
        vc1.title = NSLocalizedString(@"TabCloud", nil);
        UINavigationController2 *nav1 = [[UINavigationController2 alloc] initWithRootViewController:vc1];
        nav1.tabBarItem.image = [UIImage imageNamed:@"icon_yun.png"];
        nav1.title = NSLocalizedString(@"TabCloud", nil);
        [vc1 release];
        
        //图片集
        PicturesFolderViewController *vc2 = [[PicturesFolderViewController alloc] initWithNibName:
                                             [PCUtilityFileOperate getXibName:@"PicturesFolderView"] bundle:nil];
        vc2.title = NSLocalizedString(@"TabGallery", nil);
        UINavigationController2 *nav2 = [[UINavigationController2 alloc] initWithRootViewController:vc2];
        nav2.tabBarItem.image = [UIImage imageNamed:@"icon_picture.png"];
        nav2.title = NSLocalizedString(@"TabGallery", nil);
        [vc2 release];
        
        //收藏
        //        FileDownloadManagerViewController *vc3 = [[FileDownloadManagerViewController alloc] initWithNibName:
        //                                                  [PCUtilityFileOperate getXibName:@"FileDownloadManagerView"] bundle:nil];
        //        vc3.title = NSLocalizedString(@"Collect", nil);
        //        UINavigationController2 *nav3 = [[UINavigationController2 alloc] initWithRootViewController:vc3];
        //        nav3.tabBarItem.image = [UIImage imageNamed:@"icon_collect.png"];
        //        nav3.title = NSLocalizedString(@"Collect", nil);
        //        [vc3 release];
        
        //管理
        ManagementViewController *vc4= [[ManagementViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"ManagementView"] bundle:nil];
        vc4.title = NSLocalizedString(@"TabManager", nil);
        UINavigationController2 *nav4 = [[UINavigationController2 alloc] initWithRootViewController:vc4];
        nav4.tabBarItem.image = [UIImage imageNamed:@"icon_manager.png"];
        nav4.title = NSLocalizedString(@"TabManager", nil);
        [vc4 release];
        
        //设置
        SettingViewController *vc5 = [[SettingViewController alloc] initWithNibName:
                                      [PCUtilityFileOperate getXibName:@"SettingView"] bundle:nil];
        vc5.title = NSLocalizedString(@"More", nil);
        UINavigationController2 *nav5 = [[UINavigationController2 alloc] initWithRootViewController:vc5];
        nav5.tabBarItem = [[[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemMore tag:0] autorelease];
        nav5.title = NSLocalizedString(@"More", nil);
        [vc5 release];
        
        self.tabbarContent = [[[UITabBarController2 alloc] init] autorelease];
        if (IS_IOS7)
            self.tabbarContent.tabBar.translucent = NO;
        self.tabbarContent.delegate = self;
        self.tabbarContent.viewControllers = [NSArray arrayWithObjects:nav1, nav2, nav4,nav5,nil];
        [nav1 release];
        [nav2 release];
        //        [nav3 release];
        [nav4 release];
        [nav5 release];
        
    }
    self.window.rootViewController = self.tabbarContent;
    //刷新管理
    [self refreshMangementBadge:nil];
    if ([[PCSettings sharedSettings] screenLock])
    {
        if ([[ScreenLockViewController sharedLock] isOnScreen])
        {
            [[ScreenLockViewController sharedLock].view removeFromSuperview];
            [[ScreenLockViewController sharedLock] removeFromParentViewController];
            [ScreenLockViewController show];
        }
    }
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //设置友盟统计
    [self umengTrack];
    
    //检查更新
    [[PCCheckUpdate sharedInstance] checkUpdateSynchronous];
    
    if (self.window == nil)
    {
        self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
        self.window.backgroundColor = [UIColor whiteColor];
    }
    
    [self customizeAppearance];
    
    if ([[PCSettings sharedSettings] screenLock])
    {
        ScreenLockViewController *con = [[ScreenLockViewController alloc] initWithNibName:@"ScreenLockViewController" bundle:nil];
        con.lockType = ScreenLockTypeEnter;
        UINavigationController2 *screenLock = [[[UINavigationController2 alloc] initWithRootViewController:con] autorelease];
        self.window.rootViewController = screenLock;
        [con release];
    }
    else
    {
        LoginViewController * loginVC = [[[LoginViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"LoginView"] bundle:nil] autorelease];
        UINavigationController2 *loginNav = [[[UINavigationController2 alloc] initWithRootViewController:loginVC] autorelease];
        self.window.rootViewController = loginNav;
    }
    [self.window makeKeyAndVisible];
    
    //网络检测
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    internetReach = [[Reachability reachabilityForInternetConnection] retain];
    [internetReach startNotifier];
    [self updateInterfaceWithReachability];
    
    //刷新收藏
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMangementBadge:) name:@"RefreshTableView" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshMangementBadge:)
                                                 name:EVENT_UPLOAD_FILE_NUM
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteLocalFile:) name:DeleteLocalFile object:nil];
    self.bNetOffline = NO;
    return YES;
}
-(void)deleteLocalFile:(NSNotification *)noti
{
    NSString *path = [[noti userInfo] objectForKey:@"path"];
    [[PCUtilityFileOperate downloadManager] deleteFileWithPath:path];
    NSString *cacheStr =[FileCache getRelativePath:path withType:TYPE_CACHE_FILE andDevice:[[PCSettings sharedSettings] currentDeviceIdentifier]];
    if (cacheStr)
    {
        NSString *cachePath = [NSHomeDirectory() stringByAppendingFormat:@"/Library/Caches/%@",cacheStr];
        if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath])
        {
            [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
        }
        [FileCache deleteDownloadFile:cachePath];
    }
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    //    if ([[PCSettings sharedSettings] screenLock])
    //    {
    //        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:BegainTime];
    //        [[NSUserDefaults standardUserDefaults] synchronize];
    //    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    UIDevice * device = [UIDevice currentDevice];
    BOOL backgroundSupported = NO;
    if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
        backgroundSupported = device.multitaskingSupported;
    }
    
    //    if (backgroundSupported &&
    //        ([PCUtility downloadManager].tableDownloading.count ||
    //         [FileUploadManager sharedManager].totalUploadArr.count ||
    //         [CameraUploadManager sharedManager].uploadStatus != kCameraUploadStatus_NoUpload))
    if (backgroundSupported)
    {
        __block PCAppDelegate *weakSelf = self;
        
        self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
            //后台执行时间快要完的时候，把处于等待上传的文件置于暂停状态
            [[FileUploadManager sharedManager] pauseAllUpload:NO];
            [[UIApplication sharedApplication] endBackgroundTask:weakSelf.backgroundTaskIdentifier];
            weakSelf.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];
        
        if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid)
        {
            //wifi关了 再开的情况。将排队中的文件状态改为暂停是不合理的。所以注释掉
            //            [[PCUtility downloadManager] backgroundDownload];
        }
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    
    //    if ([[PCSettings sharedSettings] autoLogin] == NO) {
    //        [SettingViewController settingLogout];
    //    }
    //    else if ([PCLogin getResource]) {
    //        [[CameraUploadManager sharedManager] startCameraUpload];
    //    }
    if ([[PCSettings sharedSettings] screenLock])
    {
        [ScreenLockViewController show];
    }
    [[NetPenetrate sharedInstance] checkNetPenetrate];
    
    if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid)
    {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
    
    if ([PCLogin getResource]) {
        [[CameraUploadManager sharedManager] startCameraUpload];
    }
    
    if ([[PCCheckUpdate sharedInstance] isChecking] == NO) {
        [[PCCheckUpdate sharedInstance] checkUpdate:nil];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self saveContext];
}

#pragma mark - methods from super class

- (void)dealloc
{
    [internetReach stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RefreshTableView" object:nil];
    
    self.tabbarContent = nil;
    [_window release];
    
    [__managedObjectContext release];
    
    [__managedObjectModel release];
    [__persistentStoreCoordinator release];
    
    [internetReach release];
    
    [super dealloc];
}

#pragma mark - public methods

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - private methods

- (void)customizeAppearance
{
    //配置导航栏背景色
    if (IS_IOS7)
    {
        //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        
        NSDictionary *textAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor];
        [[UIBarButtonItem appearance] setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
        
        NSDictionary *disableTextAttributes = [NSDictionary dictionaryWithObject:[UIColor lightGrayColor] forKey:UITextAttributeTextColor];
        [[UIBarButtonItem appearance] setTitleTextAttributes:disableTextAttributes forState:UIControlStateDisabled];
    }
    else
    {
        [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0 green:144 / 255.0 blue:211 / 255.0 alpha:1]];
        
        //配置导航栏后退按钮背景图
        UIImage *btnBackPortrait = [[UIImage imageNamed:@"btn_back_13x5"]
                                    resizableImageWithCapInsets:UIEdgeInsetsMake(0, 13, 0, 5)];
        UIImage *btnBackLandscape = [[UIImage imageNamed:@"btn_back_11x5_l"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(0, 11, 0, 5)];
        
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:btnBackPortrait
                                                          forState:UIControlStateNormal
                                                        barMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:btnBackLandscape
                                                          forState:UIControlStateNormal
                                                        barMetrics:UIBarMetricsLandscapePhone];
        
        //配置导航栏右侧按钮背景图
        UIImage *btnRightPortrait = [[UIImage imageNamed:@"btn_right_5x5"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
        UIImage *btnRightLandscape = [[UIImage imageNamed:@"btn_right_5x5_l"]
                                      resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
        
        [[UIBarButtonItem appearance] setBackgroundImage:btnRightPortrait
                                                forState:UIControlStateNormal
                                              barMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setBackgroundImage:btnRightLandscape
                                                forState:UIControlStateNormal
                                              barMetrics:UIBarMetricsLandscapePhone];
    }
}

- (NetworkStatus)updateInterfaceWithReachability
{
    NetworkStatus netStatus = [internetReach currentReachabilityStatus];
    switch (netStatus)
    {
        case NotReachable:
        {
            [PCUtility setIsLAN:NO];
            [[FileUploadManager sharedManager] pauseAllUpload:NO];//如果网络中断，上传全部暂停
            break;
        }
        case ReachableViaWiFi:
        {
            [PCUtility setIsLAN:YES];
            break;
        }
        case ReachableViaWWAN:
        {
            [PCUtility setIsLAN:NO];
            break;
        }
    }
    
    return netStatus;
}

#pragma mark - callback methods

- (void)reachabilityChanged:(NSNotification *)note
{
    //modified by ray
    [self updateInterfaceWithReachability];
    NetPenetrate *penetrate = [NetPenetrate sharedInstance];
    
    //    if (netStatus == NotReachable) {
    //        [penetrate changePenetrate:CURRENT_NETWORK_STATE_DEFAULT];
    //    }
    //    else {
    [penetrate checkNetPenetrate];
    //    }
}
- (void)refreshMangementBadge:(NSNotification *)note
{
    UITabBarController2 *ta = self.tabbarContent;
    
    NSArray *arrayTab = [ta viewControllers];
    
    UINavigationController *collect = [arrayTab objectAtIndex:2];
    
    int badgeValue = [PCUtilityFileOperate downloadManager].tableDownloading.count + [PCUtilityFileOperate downloadManager].tableDownloadingStoped.count + [FileUploadManager sharedManager].uploadTotalNum;
    if (badgeValue > 0)
    {
        collect.tabBarItem.badgeValue=@"";
    }
    else
    {
        collect.tabBarItem.badgeValue = nil;
    }
}

- (void)mergeContextChangesForNotification:(NSNotification *)aNotification
{
    [self performSelectorOnMainThread:@selector(mergeOnMainThread:)
                           withObject:aNotification
                        waitUntilDone:YES];
}

- (void)mergeOnMainThread:(NSNotification *)aNotification
{
    [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:aNotification];
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"popoCloud" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *dbUrl = [self applicationDocumentsDirectory] ;
    NSURL *storeURL = [dbUrl URLByAppendingPathComponent:@"popoCloud.sqlite"];
    
    // handle db upgrade
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dbFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/DB"];
    if (![fileManager fileExistsAtPath:dbFolder]) {
        [fileManager createDirectoryAtPath:dbFolder withIntermediateDirectories:YES attributes:nil error:nil];
        
        //设置Library/DB文件夹不被备份
        if ([[UIDevice currentDevice].systemVersion compare:@"5.0.1" options:NSNumericSearch] != NSOrderedAscending)
        {
			if (&NSURLIsExcludedFromBackupKey == nil) { // iOS <= 5.0.1
                u_int8_t attrValue = 1;
                setxattr([dbFolder fileSystemRepresentation], "com.apple.MobileBackup", &attrValue, sizeof(attrValue), 0, 0);
            }
            else { // iOS >= 5.1
                [[NSURL fileURLWithPath:dbFolder] setResourceValue:@YES
                                                            forKey:NSURLIsExcludedFromBackupKey
                                                             error:nil];
            }
		}
    }
    
    return [NSURL fileURLWithPath:dbFolder] ;
}

- (void)umengTrack
{
    // [MobClick setCrashReportEnabled:NO]; // 如果不需要捕捉异常，注释掉此行
    //[MobClick setLogEnabled:YES];  // 打开友盟sdk调试，注意Release发布时需要注释掉此行,减少io消耗
    [MobClick setAppVersion:XcodeAppVersion]; //参数为NSString * 类型,自定义app版本信息，如果不设置，默认从CFBundleVersion里取
    //
    [MobClick startWithAppkey:UMENG_IPHONE_APPKEY reportPolicy:(ReportPolicy) REALTIME channelId:nil];
    //   reportPolicy为枚举类型,可以为 REALTIME, BATCH,SENDDAILY,SENDWIFIONLY几种
    //   channelId 为NSString * 类型，channelId 为nil或@""时,默认会被被当作@"App Store"渠道
    
    //      [MobClick checkUpdate];   //自动更新检查, 如果需要自定义更新请使用下面的方法,需要接收一个(NSDictionary *)appInfo的参数
    //    [MobClick checkUpdateWithDelegate:self selector:@selector(updateMethod:)];
    
    //[MobClick updateOnlineConfig];  //在线参数配置
    
    //    1.6.8之前的初始化方法
    [MobClick setDelegate:self reportPolicy:REALTIME];  //建议使用新方法
    
}

#pragma mark -UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == NoNetAlertTag) {
        switch (buttonIndex) {
            case 0:
            {
                [PCUtilityUiOperate logout];
            }
                break;
            case 1:
            {
                [PCUtilityUiOperate gotoFileManagerViewAndPop];
            }
                break;
            default:
                break;
        }
        return;
    }
    else if (alertView.tag == ErrorPWAlertTag)
    {
        [PCUtilityUiOperate logout];
    }
}

@end

@implementation UITabBarController2

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return self.selectedViewController.supportedInterfaceOrientations;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [self.selectedViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

@end

@implementation UINavigationController2

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self)
    {
        self.navigationBar.translucent = NO;
        if (IS_IOS7)
        {
            self.navigationBar.barTintColor = [UIColor colorWithRed:0 green:144 / 255.0 blue:211 / 255.0 alpha:1];
            self.navigationBar.tintColor = [UIColor whiteColor];
            self.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor];
        }
    }
    return self;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return self.topViewController.supportedInterfaceOrientations;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [self.topViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


#pragma mark - UITabBarControllerDelegate methods
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    FileCache* fileCache = [[FileCache alloc] init];
    [fileCache fetchCacheObjects:YES];//执行当缓存文件总存储大小大于1024M时删除Caches文件夹及其所有文件
    [fileCache release];
}

@end
