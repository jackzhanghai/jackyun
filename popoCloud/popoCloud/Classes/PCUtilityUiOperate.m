//
//  PCUtilityUiOperate.m
//  popoCloud
//
//  Created by xy  on 13-8-26.
//
//
#import <QuartzCore/CoreAnimation.h>
#import "PCUtilityUiOperate.h"
#import "PCUtilityFileOperate.h"
#import "NetPenetrate.h"
#import "PCAppDelegate.h"
#import "FileUploadManager.h"
#import "LoginViewController.h"
#import "CameraUploadManager.h"
#import "PCUtilityShareGlobalVar.h"
#import "PCLogout.h"
#import "FileDownloadManagerViewController.h"
#import "ManagementViewController.h"
#import "PCAppDelegate.h"

@implementation PCUtilityUiOperate

/**
 * 在屏幕上显示自动消失的提示信息,若一行显示不全会多行显示
 * @param msg 信息内容
 */
+ (void)showTip:(NSString *)msg
{
    [PCUtilityUiOperate showTip:msg needMultiline:YES];
}

/**
 * 在屏幕上显示某某文件已收藏成功的提示信息，该函数会截取文件名较长的字符串，只显示前部分文件名后跟省略号（只显示一行文本）
 * @param name 收藏的文件名
 */
+ (void)showHasCollectTip:(NSString *)name
{
    NSInteger length = SUBNAME_LENGTH;
    
    NSString *subName = name.length > length ?
    [[name substringToIndex:length - 3] stringByAppendingString:@"..."] : name;
    NSString *tip = [NSLocalizedString(@"FileHasCollect", nil) stringByReplacingOccurrencesOfString:@"#" withString:subName];
    
    [PCUtilityUiOperate showTip:tip needMultiline:NO];
}

/**
 * 在屏幕上显示自动消失的提示信息
 * @param msg 信息内容
 * @param multiline 是否需要多行显示
 */
+ (void)showTip:(NSString *)msg needMultiline:(BOOL)multiline
{
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].delegate.window];
    if (!hud || (hud.mode !=MBProgressHUDModeText))
    {
        hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window
                                       text:msg
                            showImmediately:YES
                                isMultiline:multiline];
    }
    else
    {
        [hud show:YES];
        if (multiline)
        {
            hud.labelText = nil;
            hud.detailsLabelText = msg;
        }
        else
        {
            hud.detailsLabelText = nil;
            hud.labelText = msg;
        }
    }
    
    UIFont *font = [UIFont systemFontOfSize:20];
    if (multiline)
        hud.detailsLabelFont = font;
    else
        hud.labelFont = font;
    
    hud.mode = MBProgressHUDModeText;
    hud.userInteractionEnabled = NO;
    hud.margin = 5.f;
    hud.yOffset = 20.f;
    
    [hud hide:YES afterDelay:3];
}

/**
 * 动画旋转刷新按钮
 * @param view 刷新按钮的customView：UIButton
 * @return 旋转动画启动返回YES，若正在进行旋转动画则返回NO
 */
+ (BOOL)animateRefreshBtn:(UIView *)view
{
    CALayer *layer = view.layer;
    if ([layer animationForKey:@"transform"])
    {
        return NO;
    }
    
    CAKeyframeAnimation *theAnimation = [CAKeyframeAnimation animation];
    
    theAnimation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeRotation(0,0,0,1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeRotation(3.13,0,0,1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeRotation(6.26,0,0,1)]];
    theAnimation.cumulative =YES;
    theAnimation.removedOnCompletion =YES;
    theAnimation.repeatCount =HUGE_VALF;
    theAnimation.speed = 0.3f;
    
    [layer addAnimation:theAnimation forKey:@"transform"];
    return YES;
}

/**
 * 创建导航栏右侧刷新按钮
 * @param target 刷新按钮点击后执行的回调函数所在的类对象
 * @return UIBarButtonItem实例
 */
+ (UIBarButtonItem *)createRefresh:(id)target
{
    UIButton* refreshButton = [[UIButton alloc] init];
    [refreshButton setImage:[UIImage imageNamed:[PCUtilityFileOperate getImgName:@"navigate_refresh"]] forState:UIControlStateNormal];
    [refreshButton addTarget:target action:@selector(refreshData:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* btnRefreshBtn = [[UIBarButtonItem alloc] initWithCustomView:refreshButton];
    refreshButton.frame = CGRectMake(5, 5, 23, 23);
    [refreshButton release];
    return [btnRefreshBtn autorelease];
}

+ (void) logoutPop
{
    PCAppDelegate *appDelegate = (PCAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSArray *arrayView = appDelegate.tabbarContent.viewControllers;
    for (UINavigationController *nav in arrayView) {
        id<PCLogoutDelegate> delegate = [nav.viewControllers objectAtIndex:0];
        if ([(NSObject *)delegate respondsToSelector:@selector(logOut)])
        {
            [delegate logOut];
        }
        [nav popToRootViewControllerAnimated:NO];
    }
    appDelegate.tabbarContent.selectedIndex = 0;
}

+ (void)PrepareLogout
{
    [PCLogin clear];
    //设置mstatus 为 0
    [ [PCLogin sharedManager]  cancel];
    [PCUtilityShareGlobalVar setUrlServer:@""];
    NetPenetrate *penetrate = [NetPenetrate sharedInstance];
    penetrate.gCurrentNetworkState = CURRENT_NETWORK_STATE_DEFAULT;
    penetrate.isChecking = NO;
    penetrate.defaultHubUrl = nil;
    penetrate.defaultLanUrl = nil;
    penetrate.defaultNatUrl = nil;
    
    //停止上传下载
    [[CameraUploadManager sharedManager] stopCameraUpload];
    [[FileUploadManager sharedManager] pauseAllUpload:YES];
    [[PCUtilityFileOperate downloadManager] stopDownLoading];
    
    //[PCUtilityUiOperate logoutPop];
}

+ (void) logout {
    
    [PCUtilityUiOperate PrepareLogout];
    PCAppDelegate *appDelegate = (PCAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    LoginViewController *loginVC = [[[LoginViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"LoginView"] bundle:nil] autorelease];
    loginVC.bAutoLogin = NO;
    UINavigationController2 *vc = [[[UINavigationController2 alloc] initWithRootViewController:loginVC] autorelease];
    appDelegate.window.rootViewController = vc;
    //释放tabbarContent
    appDelegate.tabbarContent = nil;
    
}


+ (void) showErrorAlert:(NSString *)message delegate:(id)delegate {
    if ( ([message isEqualToString: NSLocalizedString(@"OpenNetwork", nil)]
          ||[message isEqualToString: NSLocalizedString(@"NetNotReachableError", nil)])
        &&((PCAppDelegate*)[[UIApplication sharedApplication] delegate]).bNetOffline ==NO)
    {
        [PCUtilityUiOperate showNoNetAlert:[[UIApplication sharedApplication] delegate]];
    }
    else if([message isEqualToString: NSLocalizedString(@"ErrorUsernameAndPassword", nil)]
            ||  [message isEqualToString:NSLocalizedString(@"PasswordChanged", nil)])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:message
                                                       delegate:(PCAppDelegate*)[[UIApplication sharedApplication] delegate]
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
        alert.tag = ErrorPWAlertTag;
        [alert release];
    }
    else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil/*NSLocalizedString(@"Error", nil)*/ message:message delegate:delegate cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

+ (void) showErrorAlert:(NSString *)message  title:(NSString *)title delegate:(id)delegate {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title/*NSLocalizedString(@"Error", nil)*/ message:message delegate:delegate cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alert show];
    [alert release];
}

+ (void) showOKAlert:(NSString *)message delegate:(id)delegate {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil/*NSLocalizedString(@"Prompt", nil)*/ message:message delegate:delegate cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alert show];
    [alert release];
}

+ (void) showNoNetAlert:(id)delegate {
    ((PCAppDelegate*)[[UIApplication sharedApplication] delegate]).bNetOffline = YES;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:NSLocalizedString(@"NetStateError", nil)
                                                   delegate:delegate
                                          cancelButtonTitle:NSLocalizedString(@"QuiteApp", nil)
                                          otherButtonTitles:NSLocalizedString(@"OfflineCheck", nil) ,nil];
    [alert show];
    alert.tag = NoNetAlertTag;
    [alert release];
}

+ (void) gotoFileManagerViewAndPop{
    [PCUtilityUiOperate PrepareLogout];
    [[PCUtilityFileOperate downloadManager] loadOnlyDownloadedData];
    
    PCAppDelegate *appDelegate = (PCAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    LoginViewController *loginVC = [[[LoginViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"LoginView"] bundle:nil] autorelease];
    loginVC.bAutoLogin = NO;
    
    FileDownloadManagerViewController *downLoadManager =[[[FileDownloadManagerViewController alloc] initWithNibName:
                                                          [PCUtilityFileOperate getXibName:@"FileDownloadManagerView"] bundle:nil] autorelease];
    downLoadManager.title = NSLocalizedString(@"Collect", nil);
    
    UINavigationController2 *vc = [[[UINavigationController2  alloc]  initWithRootViewController:nil] autorelease];
    [vc setViewControllers:[NSArray arrayWithObjects: loginVC ,downLoadManager, nil]  animated:NO];
    
    appDelegate.window.rootViewController = vc;
    //释放tabbarContent
    appDelegate.tabbarContent = nil;
}

@end
