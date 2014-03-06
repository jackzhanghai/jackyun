//
//  LoginViewController.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-8.
//  Copyright 2011年 Kortide. All rights reserved.
//
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "LoginViewController.h"
#import "RegisterViewController.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "PCUtilityUiOperate.h"
#import "ModalAlert.h"
#import "RegisterProtocolViewController.h"
#import "PCLogin.h"
#import "NoDeviceViewController.h"
#import "ResetPasswordViewController.h"
#import "FileFolderViewController.h"
#import "PCUserInfo.h"
#import "FileUploadManager.h"
#import "CameraUploadManager.h"
#import "PCAppDelegate.h"
#import "ManagementViewController.h"
#import "FileDownloadManagerViewController.h"
#import "BoxUpgradeViewController.h"
#import "BoxForceUpgradeViewController.h"

#define USER_NAME_ARRAY    @"UserArray"

#define VERIFY_EMAIL    5

@interface LoginViewController ()
{
    RegisterViewController *registerViewController;
}

@end

@implementation LoginViewController

//@synthesize tabbarContent;
@synthesize txtUser, txtPassword, checkbox;
@synthesize btnNewAccount, btnForgetPassword, lblLogin, lblAutoLogin,lblUser,lblPassword,btnLogin;
@synthesize dicatorView;
@synthesize bAutoLogin;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.hidesBottomBarWhenPushed = YES;
        bAutoLogin = YES;
        self.bLoginFinished = NO;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
-(void)layoutView
{
    [self orientationDidChange:self.interfaceOrientation];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutView) name:@"ScreenLockCorrect" object:nil];
    // Do any additional setup after loading the view from its nib.
    [checkbox addTarget:self action:@selector(checkboxClick:) forControlEvents:UIControlEventTouchUpInside];
    
    self.title = NSLocalizedString(@"Login", nil);
    
    self.lblUser.text = NSLocalizedString(@"Email", nil);
    self.lblPassword.text= NSLocalizedString(@"UserPassword", nil);
    //lblLogin.text = NSLocalizedString(@"Login", nil);
    [btnLogin setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
    
    [btnNewAccount setTitle:NSLocalizedString(@"RegisterNewAccount", nil) forState:UIControlStateNormal];
    [btnForgetPassword setTitle:NSLocalizedString(@"ForgetPassword", nil) forState:UIControlStateNormal];
    lblAutoLogin.text = NSLocalizedString(@"AutoLogin", nil);
    txtUser.placeholder = NSLocalizedString(@"LoginUser", nil);
    txtPassword.placeholder = NSLocalizedString(@"LoginPassword", nil);
    
    [btnLogin setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)]
                        forState:UIControlStateNormal];
    [btnLogin setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)]
                        forState:UIControlStateHighlighted];
    
    [btnNewAccount setBackgroundImage:[[UIImage imageNamed:@"btn_register"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)]
                             forState:UIControlStateNormal];
    [btnNewAccount setBackgroundImage:[[UIImage imageNamed:@"btn_register_d"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)]
                             forState:UIControlStateHighlighted];
    
    // the image will be stretched to fill the button, if you resize it.
    isKeywordShow = NO;
    txtUser.text = [[PCSettings sharedSettings] username];
    
    if ([[PCSettings sharedSettings] autoLogin]) {
        txtPassword.text = [[PCSettings sharedSettings] password];
        checkbox.selected = YES;
        if (bAutoLogin) {
            if ([[PCCheckUpdate sharedInstance] isUpdate]) {
                [[PCCheckUpdate sharedInstance] setDelegate:self];
            }
            else if (txtUser.text.length > 0) {
                [self btnLoginClicked:nil];
            }
        }
    }
    else {
        txtPassword.text = @"";
    }
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self    action:@selector(backupgroupTap:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    tapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer: tapGestureRecognizer];   //只需要点击非文字输入区域就会响应
    //    [tapGestureRecognizer setCancelsTouchesInView:NO];
    [tapGestureRecognizer release];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UIButton class]]) {
        return NO;
    }
    return YES;
}

-(void)backupgroupTap:(id)sender{
    [txtUser resignFirstResponder]; //关闭所有UITextField控件的键盘。。。
    [txtPassword resignFirstResponder];
}

- (void)viewDidUnload
{
    [self setLoginView:nil];
    [self setLogoView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    // self.tabbarContent = nil;
    self.btnLogin = nil;
    self.txtUser = nil;
    self.txtPassword = nil;
    self.checkbox = nil;
    self.btnNewAccount = nil;
    self.btnForgetPassword = nil;
    self.lblLogin = nil;
    self.lblAutoLogin = nil;
    self.dicatorView = nil;
    self.lblUser = nil;
    self.lblPassword = nil;
}



- (IBAction) btnLoginClicked:(id)sender {
    [txtUser resignFirstResponder];
    [txtPassword resignFirstResponder];
    
    NSString *tmpStr = [txtUser.text lowercaseString];
    NSString *username = [tmpStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *password = txtPassword.text;
    
    if (username.length == 0)
    {
        [PCUtilityUiOperate showTip:NSLocalizedString(@"InputUsername", nil)];
        //[txtUser becomeFirstResponder];
        return;
    }
    if (password.length == 0)
    {
        [PCUtilityUiOperate showTip:NSLocalizedString(@"InputPassword", nil)];
        //[txtPassword becomeFirstResponder];
        return;
    }
    if ([PCUtilityStringOperate checkValidMobileNumber:tmpStr] == NO && [PCUtilityStringOperate checkValidEmail:username] == NO)
    {
        [ErrorHandler showAlert:PC_Err_InvalidUsername];
        //[txtUser becomeFirstResponder];
        return;
    }
    if ([PCUtilityStringOperate checkValidPassword:password] == NO) {
        [ErrorHandler showAlert:PC_Err_InvalidPassword];
        //[txtPassword becomeFirstResponder];
        return;
    }
    
    if (pcAuth == nil) {
        pcAuth = [[PCAuthentication alloc] init];
        pcAuth.delegate = self;
    }
    
    [MBProgressHUD showHUDAddedTo:self.loginView animated:YES afterDelay:0.1];
    [pcAuth login:username password:password];
}

- (IBAction) btnNewAccountClicked:(id)sender {
    [txtUser resignFirstResponder];
    [txtPassword resignFirstResponder];
    
    if (registerViewController == nil) {
        registerViewController = [[RegisterViewController alloc] initWithNibName:@"RegisterViewController" bundle:nil];
    }
    [self.navigationController pushViewController:registerViewController animated:YES];
}


- (void)viewWillAppear:(BOOL)animated {
    
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(EmailtextDidChange:)
    //                                                 name:UITextFieldTextDidChangeNotification object:nil];
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationWillResignActiveNotification object:self.view.window];
    
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    //
    //	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [self.navigationController setNavigationBarHidden:YES animated:hasAppeared];
    [self orientationDidChange:self.interfaceOrientation];
    self.title = NSLocalizedString(@"Login", nil);
    
    
    [super viewWillAppear:animated];
    hasAppeared = YES;
    
    [MobClick beginLogPageView:@"LoginView"];
}

-(void)viewWillDisappear:(BOOL)animated {
    bAutoLogin = NO;
    [self setEditing:NO animated:YES];
    //    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    //	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    //    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
    //登录跳转没做动画效果，不需设置导航条动画，其他跳转需要动画的平滑效果。
    if(!self.bLoginFinished)
    {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
    [super viewWillDisappear:animated];
    
    [MobClick endLogPageView:@"LoginView"];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [txtUser resignFirstResponder];
    [txtPassword resignFirstResponder];
}

- (void)keyboardWillShow:(NSNotification *)notif {
    
    if (isKeywordShow) return;
    
    isKeywordShow = YES;
    
    CGRect keyboardBounds;
    [[notif.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue: &keyboardBounds];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    
    for (UIView  *subView in self.view.subviews)
    {
        CGRect frame = subView.frame;
        //frame.size.height = frame.size.height - keyboardBounds.size.height;
        if (IS_IPAD) {
            frame = CGRectMake(frame.origin.x, frame.origin.y-HEIGHT_FOR_KEYBORD, frame.size.width, frame.size.height);
        }
        else
        {
            frame = CGRectMake(frame.origin.x, frame.origin.y-HEIGHT_FOR_KEYBORD/3, frame.size.width, frame.size.height);
        }
        
        subView.frame = frame;
    }
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notif {
    
    if (!isKeywordShow) return;
    isKeywordShow = NO;
    
    CGRect keyboardBounds;
    [[notif.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    
    CGRect frame = self.view.frame;
    CGRect bounds = [[UIScreen mainScreen] bounds];
    frame.size.height = bounds.size.height - 20; //frame.size.height + keyboardBounds.size.height;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    
    for (UIView  *subView in self.view.subviews)
    {
        CGRect frame = subView.frame;
        //frame.size.height = frame.size.height - keyboardBounds.size.height;
        if (IS_IPAD) {
            frame = CGRectMake(frame.origin.x, frame.origin.y+HEIGHT_FOR_KEYBORD, frame.size.width, frame.size.height);
        }
        else
        {
            frame = CGRectMake(frame.origin.x, frame.origin.y+HEIGHT_FOR_KEYBORD/3, frame.size.width, frame.size.height);
        }
        
        subView.frame = frame;
    }
    
    [UIView commitAnimations];
}

- (BOOL)validateEmail:(NSString*)anEmail{
    
    if( ([anEmail rangeOfString:@"@"].length != 0 ) &&  ([anEmail rangeOfString:@"."].length != 0) )
    {
        NSMutableCharacterSet *invalidCharSet = [[[[NSCharacterSet alphanumericCharacterSet] invertedSet]mutableCopy]autorelease];
        [invalidCharSet removeCharactersInString:@"_-"];
        
        //设定比较规则，不区分大小写
        NSRange range1 = [anEmail rangeOfString:@"@" options:NSCaseInsensitiveSearch];
        
        //取得用户名部分
        NSString *usernamePart = [anEmail substringToIndex:range1.location];
        NSArray *stringsArray1 = [usernamePart componentsSeparatedByString:@"."];
        for (NSString *string in stringsArray1) {
            NSRange rangeOfInavlidChars=[string rangeOfCharacterFromSet: invalidCharSet];
            if(rangeOfInavlidChars.length !=0 || [string isEqualToString:@""])
                return NO;
        }
        
        //取得域名部分
        NSString *domainPart = [anEmail substringFromIndex:range1.location+1];
        NSArray *stringsArray2 = [domainPart componentsSeparatedByString:@"."];
        
        for (NSString *string in stringsArray2) {
            NSRange rangeOfInavlidChars=[string rangeOfCharacterFromSet:invalidCharSet];
            if(rangeOfInavlidChars.length !=0 || [string isEqualToString:@""])
                return NO;
        }
        
        return YES;
    }
    else {
        return NO;
    }
}

- (IBAction)EmailtextDidChange:(id)sender
{
    if ([txtUser.text rangeOfString:@" "].length>0) {
        NSString *tmp = [txtUser.text stringByReplacingOccurrencesOfString:@" " withString:@""];
        txtUser.text = tmp;
    }
}

//- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string   // return NO to not change text
//{
//    NSLog(@"range.location = %d, string = %@", range.location, string);
//    if (textField == txtUser) {
//        if ([string rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location != NSNotFound)
//        {
//            return NO;
//        }
//    }
//
//    return YES;
//}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if(textField == txtUser)
    {
        textField.returnKeyType = UIReturnKeyNext;
    }
    else
    {
        textField.returnKeyType = UIReturnKeyDone;
    }
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == txtUser)
    {
        if ((txtUser.text.length == 0)) {
            //                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"InputUsernameAndPassword", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
            //                [alert show];
            //                [alert release];
            [PCUtilityUiOperate showTip:NSLocalizedString(@"InputUsername", nil)];
        }
        else
        {
            [txtPassword becomeFirstResponder];
        }
    }
    else
    {
        [self btnLoginClicked:nil];
    }
    return YES;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setLoginView:nil];
    [self setLogoView:nil];
    
    // self.tabbarContent = nil;
    self.btnLogin = nil;
    self.txtUser = nil;
    self.txtPassword = nil;
    self.checkbox = nil;
    self.btnNewAccount = nil;
    self.btnForgetPassword = nil;
    self.lblLogin = nil;
    self.lblAutoLogin = nil;
    self.dicatorView = nil;
    self.lblUser = nil;
    self.lblPassword = nil;
    [registerViewController release];
    [pcAuth release];
    [super dealloc];
}

-(void)checkboxClick:(UIButton *)btn
{
    btn.selected = !btn.selected;
}
//---------------------------------------------------------------

#pragma mark

- (void) loginFail:(NSString*)error title:(NSString*)title {
    if ([title isEqualToString:NSLocalizedString(@"ErrorEmailTitle", nil)])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:error
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"SendVerifyEmail", nil)
                                                  otherButtonTitles:NSLocalizedString(@"Makesure", nil), nil];
        [alertView show];
        alertView.tag = VERIFY_EMAIL;
        [alertView release];
        
    }
    else
    {
        [PCUtilityUiOperate showErrorAlert:error  title:title delegate:self];
    }
}

- (void) loginFail:(NSString*)error
{
    [PCUtilityUiOperate showErrorAlert:error delegate:self];
}

- (void) loginFinish
{
    //如果登陆的不是之前登陆的账号,删除下载; 停止上个账号的上传并设置所有上传文件为暂停
    //    NSString *userId = [PCSettings sharedSettings].userId;
    //    if (userId.length > 0 && [userId isEqualToString:[[PCUserInfo currentUser] userId]] == NO)
    //    {
    //        [[PCUtilityFileOperate downloadManager] deleteDownloadItem];
    //        [[FileUploadManager sharedManager] deleteAllUpload];
    //    }
    
    ((PCAppDelegate*)[[UIApplication sharedApplication] delegate]).bNetOffline = NO;
    
    NSString *tmpStr = [txtUser.text lowercaseString];
    NSString *username = [tmpStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [[PCSettings sharedSettings] setUser:[[PCUserInfo currentUser] userId] name:username password:txtPassword.text];
    [[PCSettings sharedSettings] setAutoLogin:checkbox.selected];
    
    //从数据库获取上传下载信息
    [PCUtilityFileOperate checkDownloadFilesExist];
    [[PCUtilityFileOperate downloadManager] reloadData];
    [[FileUploadManager sharedManager] resumeFileUploadInfos];
    
    //获取设备列表
    [[PCLogin sharedManager] getDevicesList:self];
}

- (void) loginFail:(PCLogin*)pcLogin error:(NSString*)error
{
    [self showMainView];
}

- (void) loginFinish:(PCLogin*)pcLogin
{
    NSArray *allDevices = [PCLogin getAllDevices];
    if (allDevices && [allDevices count] == 0) {
        [MBProgressHUD hideHUDForView:self.loginView animated:YES];
        
        NoDeviceViewController *noDeviceViewController = [[NoDeviceViewController alloc] initWithNibName:@"NoDeviceView" bundle:nil];
        [self.navigationController pushViewController:noDeviceViewController animated:YES];
        [noDeviceViewController release];
    }
    else {
        DeviceInfo *device = allDevices[0];
        if (device.isUpgrading) {
            [MBProgressHUD hideHUDForView:self.loginView animated:YES];
            
            BoxUpgradeViewController *view = [[BoxUpgradeViewController alloc] initWithNibName:@"BoxUpgradeViewController" bundle:nil];
            view.isLogin = YES;
            [self.navigationController pushViewController:view animated:YES];
            [view release];
        }
        else if (device.online) {
            float hardVersion = ceilf([device.hardwareVersion floatValue]);
            if (hardVersion >= 2) {
                [pcLogin getBoxNeedUpgrade:self];
            }
            else {
                [self showMainView];
            }
        }
        else {
            [self showMainView];
        }
    }
}

- (void)gotBoxNeedUpgrade:(BOOL)isNeed necessary:(BOOL)isNecessary
{
    if (isNeed && isNecessary) {
        [MBProgressHUD hideHUDForView:self.loginView animated:YES];
        
        BoxForceUpgradeViewController *view = [[BoxForceUpgradeViewController alloc] initWithNibName:@"BoxForceUpgradeViewController" bundle:nil];
        [self.navigationController pushViewController:view animated:YES];
        [view release];
    }
    else {
        [self showMainView];
    }
}

- (void)getBoxNeedUpgradeFailedWithError:(NSError*)error
{
    [self showMainView];
}

- (void)showMainView
{
    [MBProgressHUD hideHUDForView:self.loginView animated:YES];
    
    if ([PCLogin getResource]) {
        [[CameraUploadManager sharedManager] startCameraUpload];
    }
    
    self.bLoginFinished = YES;
    PCAppDelegate *app = (PCAppDelegate *)[UIApplication sharedApplication].delegate;
    [app loadTabBarController];
}

//--------------------------------------------------------------

- (void) checkUpadteFinish:(PCCheckUpdate*)pcCheckUpdate
{
    if ([[PCSettings sharedSettings] autoLogin]) {
        [self btnLoginClicked:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == NoNetAlertTag) {
        switch (buttonIndex) {
            case 0:
            {
                
            }
                break;
            case 1:
            {
                [[PCUtilityFileOperate downloadManager] loadOnlyDownloadedData];
                
                FileDownloadManagerViewController *vc3 = [[[FileDownloadManagerViewController alloc] initWithNibName:
                                                           [PCUtilityFileOperate getXibName:@"FileDownloadManagerView"] bundle:nil] autorelease];
                vc3.title = NSLocalizedString(@"Collect", nil);
                [self.navigationController pushViewController:vc3 animated:YES];
            }
                break;
            default:
                break;
        }
        return;
    }
    
    if (alertView.tag == VERIFY_EMAIL) {
        if (buttonIndex == 0)
        {
            NSString *tmpStr = [txtUser.text lowercaseString];
            tmpStr = [tmpStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            [MBProgressHUD showHUDAddedTo:self.loginView animated:YES afterDelay:0.1];
            [pcAuth sendVerifyEmail:tmpStr password:txtPassword.text];
        }
    }
}


#pragma mark -  OrientationChange
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self  orientationDidChange:interfaceOrientation];
}

- (void)orientationDidChange:(UIInterfaceOrientation)interfaceOrientation
{
    UIInterfaceOrientation to = interfaceOrientation;
    
    int  height1 = 0;
    int  height2 = 0;
    if (isKeywordShow) {
        height1 = HEIGHT_FOR_KEYBORD;
        height2 = HEIGHT_FOR_KEYBORD/3;
    }
    if (to == UIInterfaceOrientationPortrait || to == UIInterfaceOrientationPortraitUpsideDown) {
        if (IS_IPAD) {
            self.logoView.frame = CGRectMake(269, 110-height1, 230, 279);
            self.loginView.frame = CGRectMake(0, 300-height1, 768, 450);
            UIView *introButton = [self.view viewWithTag:INTRO_PART_VIEW_TAG];
            introButton.frame = CGRectMake(523, 958, 100, 25);
        }
        else {
            self.logoView.frame = CGRectMake(102, 26-height2, 115, 140);
            self.loginView.frame = CGRectMake(0, 113-height2, 320, 260);
        }
    }
    else if (to == UIInterfaceOrientationLandscapeLeft || to == UIInterfaceOrientationLandscapeRight) {
        if (IS_IPAD) {
            self.logoView.frame = CGRectMake(100, 170-height1, 230, 279);
            self.loginView.frame = CGRectMake(275, 100-height1, 700, 450);
            UIView *introButton = [self.view viewWithTag:INTRO_PART_VIEW_TAG];
            introButton.frame = CGRectMake(798, 702, 100, 25);
        }
        else {
            self.logoView.frame = CGRectMake(30, 40-height2, 115, 140);
            self.loginView.frame = CGRectMake(160, 0-height2, 320, 260);
        }
    }
}


- (IBAction) btnForgetPasswordClicked:(id)sender {
    self.title = NSLocalizedString(@"ReturnBack", nil);
    ResetPasswordViewController *vc = [[ResetPasswordViewController alloc] initWithNibName:@"ResetPasswordViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
    return;
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
- (BOOL)correctNameAndPW
{
    NSString *tmpStr = [txtUser.text lowercaseString];
    NSString *username = [tmpStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *password = txtPassword.text;
    
    if (![username isEqualToString:[PCSettings sharedSettings].username]  ||
        ![password isEqualToString:[PCSettings sharedSettings].password]) {
        return  NO;
    }
    
    return YES;
}
#pragma mark - PCAuthenticationDelegate

- (void)loginFinished:(PCAuthentication *)pcAuthentication
{
    [MobClick event:UM_LOGIN_SUCCESS];
    
    //    [MBProgressHUD hideHUDForView:self.loginView animated:YES];
    
    [self loginFinish];
}

- (void)loginFailed:(PCAuthentication *)pcAuthentication withError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.loginView animated:YES];
    
    if ([error.domain isEqualToString:KTServerErrorDomain]) {
        switch (error.code) {
            case PC_Err_Unknown:
                [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"AccessServerError", nil) delegate:nil];
                break;
                
            case 9:
                [self loginFail:NSLocalizedString(@"ErrorUsernameAndPassword", nil) title:NSLocalizedString(@"Error", nil)];
                break;
                
            case 27:
                [self loginFail:NSLocalizedString(@"ErrorEmail", nil) title:NSLocalizedString(@"ErrorEmailTitle", nil)];
                break;
                
            default:
                [self loginFail:[error.userInfo valueForKey:@"message"] title:NSLocalizedString(@"Error", nil)];
                break;
        }
    }
    else {
        //[ErrorHandler showErrorAlert:error];
        if ([error.domain isEqualToString:NSURLErrorDomain] &&
            !(error.code == NSURLErrorTimedOut)) {
            //没网络
            if (![self correctNameAndPW]) {
                [PCUtilityUiOperate showErrorAlert: NSLocalizedString(@"NetStateErrorTryLater", nil) delegate:nil];
            }
            else{
                [PCUtilityUiOperate showNoNetAlert:self];
            }
        }
        else{
            [ErrorHandler showErrorAlert:error];
        }
    }
}

- (void)sendVerifyEmailSuccess:(PCAuthentication *)pcAuthentication
{
    [MBProgressHUD hideHUDForView:self.loginView animated:YES];
    
    [PCUtilityUiOperate showOKAlert:@"激活邮件已发送，请登录邮箱激活泡泡云帐号。" delegate:self];
}

- (void)sendVerifyEmailFailed:(PCAuthentication *)pcAuthentication withError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.loginView animated:YES];
    
    if ([error.domain isEqualToString:KTServerErrorDomain] && error.code == 59) {
        [ErrorHandler showAlert:PC_Err_Unknown description:@"邮件已发送，请去邮箱查看。"];
    }
    else {
        [ErrorHandler showErrorAlert:error];
    }
}

@end
