//
//  UnbindBoxViewController.m
//  popoCloud
//
//  Created by suleyu on 13-5-30.
//
//

#import "UnbindBoxViewController.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "PCUtilityEncryptionAlgorithm.h"
#import "PCUserInfo.h"
#import "PCLogin.h"
#import "CameraUploadManager.h"
#import "FileUploadManager.h"
#import "PCAppDelegate.h"
@interface UnbindBoxViewController ()
{
    int waitTime;
    NSTimer *waitTimer;
    PCVerifyCode *pcVerify;
    PCDeviceManagement *deviceManagement;
}

@property (copy, nonatomic) NSString *account;

@end

@implementation UnbindBoxViewController
@synthesize deviceIdentifier;
@synthesize account;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"解绑";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.bgVerifyCode setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.bgSerialNumber setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.bgPassword setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    
    [self.buttonRequestVerifyCode setBackgroundImage:[[UIImage imageNamed:@"btn_a"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateNormal];
    [self.buttonRequestVerifyCode setBackgroundImage:[[UIImage imageNamed:@"btn_a_d"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateHighlighted];
    
    [self.buttonBack setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.buttonBack setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];
    [self.buttonUnbind setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.buttonUnbind setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];
    
    self.account = [[[PCUserInfo currentUser] phone] length] > 0 ? [[PCUserInfo currentUser] phone] : [[PCUserInfo currentUser] email];
    self.labelAccount.text = [NSString stringWithFormat:@"帐号：%@", self.account];
    
    if (IS_IPAD) {
        CGSize labelSize = [self.labelAccount.text sizeWithFont:[UIFont systemFontOfSize:17.0] constrainedToSize:CGSizeMake(580, 21) lineBreakMode:NSLineBreakByWordWrapping];
        self.buttonRequestVerifyCode.frame = CGRectMake(66 + labelSize.width, 112, 90, 39);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self orientationDidChange:self.interfaceOrientation];
    
    if (!IS_IPAD) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification object:self.view.window];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification object:self.view.window];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationWillResignActiveNotification object:self.view.window];
    }
    
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"UnbindBoxView"];
}

-(void)viewWillDisappear:(BOOL)animated {
    if (self.isMovingFromParentViewController) {
        if (waitTimer) {
            [waitTimer invalidate];
            waitTimer = nil;
        }
    }
    
    if (!IS_IPAD) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    }
    
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"UnbindBoxView"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setLabelAccount:nil];
    [self setBgVerifyCode:nil];
    [self setBgSerialNumber:nil];
    [self setBgPassword:nil];
    [self setTextFieldVerifyCode:nil];
    [self setTextFieldSerialNumber:nil];
    [self setTextFieldPassword:nil];
    [self setButtonRequestVerifyCode:nil];
    [self setButtonBack:nil];
    [self setButtonUnbind:nil];
    [self setLabelCustomerService:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    if (waitTimer) {
        [waitTimer invalidate];
        waitTimer = nil;
    }
    
    [self setLabelAccount:nil];
    [self setBgVerifyCode:nil];
    [self setBgSerialNumber:nil];
    [self setBgPassword:nil];
    [self setTextFieldVerifyCode:nil];
    [self setTextFieldSerialNumber:nil];
    [self setTextFieldPassword:nil];
    [self setButtonRequestVerifyCode:nil];
    [self setButtonBack:nil];
    [self setButtonUnbind:nil];
    [self setLabelCustomerService:nil];
    
    [pcVerify release];
    [deviceManagement release];
    [deviceIdentifier release];
    [account release];
    [super dealloc];
}

#pragma mark -  OrientationChange
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
    [self orientationDidChange:interfaceOrientation];
}

- (void)orientationDidChange:(UIInterfaceOrientation)interfaceOrientation
{
    if (!IS_IPAD) return;
    
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        self.buttonBack.frame = CGRectMake(44, 365, 406, 39);
        self.buttonUnbind.frame = CGRectMake(574, 365, 406, 39);
        self.labelCustomerService.frame = CGRectMake(786, 640, 185, 21);
    }
    else {
        self.buttonBack.frame = CGRectMake(44, 365, 330, 39);
        self.buttonUnbind.frame = CGRectMake(394, 365, 330, 39);
        self.labelCustomerService.frame = CGRectMake(530, 500, 185, 21);
    }
}

- (void)keyboardWillShow:(NSNotification *)notif {
    CGRect keyboardBounds;
    [[notif.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    
    CGFloat height = -80; // keyboardBounds.origin.y - (self.buttonBack.frame.origin.y + self.buttonBack.frame.size.height);
    if (!IS_IOS7) {
        height -= 64;
    }
    
    if (height < 0) {
        CGRect frame = self.view.frame;
        frame.origin.y = height;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.3f];
        
        self.view.frame = frame;
        
        [UIView commitAnimations];
    }
}

- (void)keyboardWillHide:(NSNotification *)notif {
    CGRect frame = self.view.frame;
    frame.origin.y = IS_IOS7 ? 64 : 0;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    
    self.view.frame = frame;
    
    [UIView commitAnimations];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self hideKeyboard:nil];
}

- (IBAction)hideKeyboard:(id)sender
{
    [self.textFieldVerifyCode resignFirstResponder];
    [self.textFieldSerialNumber resignFirstResponder];
    [self.textFieldPassword resignFirstResponder];
}

- (IBAction)requestVerifyCode:(id)sender
{
    [self hideKeyboard:nil];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES afterDelay:0.1];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    
    if (pcVerify == nil) {
        pcVerify = [[PCVerifyCode alloc] init];
        pcVerify.delegate = self;
    }
    [pcVerify generateUnbindBoxVerifyCode:self.account];
}

- (IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)unbind:(id)sender
{
    int paramsCount = 0;
    if (self.textFieldPassword.text.length > 0) {
        if ([PCUtilityStringOperate checkValidPassword:self.textFieldPassword.text] == NO) {
            [ErrorHandler showAlert:PC_Err_InvalidPassword];
            [self.textFieldPassword becomeFirstResponder];
            return;
        }
        
        paramsCount++;
    }
    if (self.textFieldVerifyCode.text.length > 0) {
        paramsCount++;
    }
    if (self.textFieldSerialNumber.text.length > 0) {
        paramsCount++;
    }
    
    [self hideKeyboard:nil];
    
    if (paramsCount < 2) {
        [ErrorHandler showAlert:PC_Err_Unknown description:@"请至少填写两项"];
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES afterDelay:0.1];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    if (deviceManagement == nil) {
        deviceManagement = [[PCDeviceManagement alloc] init];
        deviceManagement.delegate = self;
    }
    [deviceManagement unbindBox:self.textFieldVerifyCode.text serialNumber:self.textFieldSerialNumber.text password:self.textFieldPassword.text];
}

#pragma mark - textField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.textFieldVerifyCode) {
        if (textField.text.length == 6) {
            [self.textFieldSerialNumber becomeFirstResponder];
        }
    }
    else if (textField == self.textFieldSerialNumber) {
        if (textField.text.length == 16) {
            [self.textFieldPassword becomeFirstResponder];
        }
    }
    else if (textField == self.textFieldPassword) {
        if (textField.text.length >= 6) {
            [self unbind:nil];
        }
    }
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL allowInput = YES;
    if (textField == self.textFieldVerifyCode) {
        if (range.location >= 6) {
            allowInput = NO;
        }
    }
    else if (textField == self.textFieldSerialNumber) {
        if (range.location >= 16) {
            allowInput = NO;
        }
    }
    else if (textField == self.textFieldPassword){
        if (range.location >= 16) {
            allowInput = NO;
        }
    }
    
    return allowInput;
}

#pragma mark - PCVerifyCodeDelegate
-(void)generateVerifyCodeSuccess:(PCVerifyCode*)pcVerifyCode verifyCode:(NSString *)verifyCode
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    if ([[[PCUserInfo currentUser] phone] length] > 0) {
        waitTime = 60;
        waitTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateWaitTime) userInfo:nil repeats:YES];
        self.buttonRequestVerifyCode.enabled = NO;
        NSString *btnTitle = [NSString stringWithFormat:@"%d秒", waitTime];
        [self.buttonRequestVerifyCode setTitle:btnTitle forState:UIControlStateDisabled];
    }
    
    [PCUtilityUiOperate showOKAlert:@"验证码发送成功" delegate:nil];
}

-(void)generateVerifyCodeFailed:(PCVerifyCode*)pcVerifyCode withError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    if (error.domain == KTServerErrorDomain && error.code == 59)
    {
        [PCUtilityUiOperate showOKAlert:@"邮件已发送，请去邮箱查看。" delegate:nil];
    }
    else
    {
        [ErrorHandler showErrorAlert:error];
    }
}

- (void)updateWaitTime
{
    waitTime--;
    if (waitTime > 0) {
        NSString *btnTitle = [NSString stringWithFormat:@"%d秒", waitTime];
        [self.buttonRequestVerifyCode setTitle:btnTitle forState:UIControlStateDisabled];
    }
    else {
        self.buttonRequestVerifyCode.enabled = YES;
        [waitTimer invalidate];
        waitTimer = nil;
    }
}

#pragma mark - PCDeviceManagementDelegate
- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement unboundBox:(NSString*)device
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    [[CameraUploadManager sharedManager] stopCameraUpload];
    /**
     * fixed 56543 by libing
     */
    //删除所有上传项
    [[FileUploadManager sharedManager] pauseAllUpload:YES];
    [[FileUploadManager sharedManager] deleteAllUpload];
    //删除已经下载项
    [[PCUtilityFileOperate downloadManager] deleteDownloadItem];
    //刷新brageNum
    [[NSNotificationCenter defaultCenter] postNotificationName:EVENT_UPLOAD_FILE_NUM object:nil];
    [[PCUtilityFileOperate downloadManager] reloadData];
    //
    [PCLogin removeDevice:self.deviceIdentifier];
    [PCUtilityUiOperate showOKAlert:@"盒子解绑成功，如要访问请再次激活" delegate:self];
    [MobClick event:UM_BOX_UNBIND];
}

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement unbindBoxFailedWithError:(NSError*)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    if ([error.domain isEqualToString:KTServerErrorDomain] && error.code == 9) {
        [ErrorHandler showAlert:PC_Err_PasswordWrong];
    }
    else {
        [ErrorHandler showErrorAlert:error];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //[self.navigationController popToRootViewControllerAnimated:YES];
    [PCUtilityUiOperate logoutPop];
}

@end
