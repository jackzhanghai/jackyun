//
//  BindPhoneViewController.m
//  popoCloud
//
//  Created by suleyu on 13-5-29.
//
//

#import "BindPhoneViewController.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "PCUtilityUiOperate.h"
#import "PCUserInfo.h"

@interface BindPhoneViewController ()
{
    int waitTime;
    NSTimer *waitTimer;
    PCAccountManagement *accountManagement;
    PCVerifyCode *pcVerify;
}

@property (copy, nonatomic) NSString *phoneNumber;
@property (copy, nonatomic) NSString *verifyCode;

@end

@implementation BindPhoneViewController

@synthesize phoneNumber;
@synthesize verifyCode;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"帐号绑定";
    self.labelAccount.text = [NSString stringWithFormat:@"帐号：%@", [[PCUserInfo currentUser] email]];
    
    [self.bgPhoneNumber setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.bgVerifyCode setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    
    [self.buttonRequestVerifyCode setBackgroundImage:[[UIImage imageNamed:@"btn_a"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateNormal];
    [self.buttonRequestVerifyCode setBackgroundImage:[[UIImage imageNamed:@"btn_a_d"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateHighlighted];
    
    [self.buttonBind setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.buttonBind setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"BindPhoneView"];
}
- (void)viewWillDisappear:(BOOL)animated {
    if (self.isMovingFromParentViewController) {
        if (waitTimer) {
            [waitTimer invalidate];
            waitTimer = nil;
        }
    }
    
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"BindPhoneView"];
}

- (void)viewDidUnload {
    [self setLabelAccount:nil];
    [self setBgPhoneNumber:nil];
    [self setBgVerifyCode:nil];
    [self setTextFieldPhoneNumber:nil];
    [self setTextFieldVerifyCode:nil];
    [self setButtonRequestVerifyCode:nil];
    [self setButtonBind:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    if (waitTimer) {
        [waitTimer invalidate];
        waitTimer = nil;
    }
    
    [self setLabelAccount:nil];
    [self setBgPhoneNumber:nil];
    [self setBgVerifyCode:nil];
    [self setTextFieldPhoneNumber:nil];
    [self setTextFieldVerifyCode:nil];
    [self setButtonRequestVerifyCode:nil];
    [self setButtonBind:nil];
    
    if (accountManagement) {
        [accountManagement release];
    }
    if (pcVerify) {
        [pcVerify release];
    }
    [phoneNumber release];
    [verifyCode release];
    [super dealloc];
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

- (IBAction)hideKeyboard:(id)sender {
    [self.textFieldPhoneNumber resignFirstResponder];
    [self.textFieldVerifyCode resignFirstResponder];
}

- (IBAction)requestVerifyCode:(id)sender {
    NSString *mobile = self.textFieldPhoneNumber.text;
    if (mobile.length == 0)
    {
        [ErrorHandler showAlert:PC_Err_InputPhoneNumber];
        [self.textFieldPhoneNumber becomeFirstResponder];
        return;
    }
    if ([PCUtilityStringOperate checkValidMobileNumber:mobile] == NO) {
        [ErrorHandler showAlert:PC_Err_InvalidPhoneNumber];
        [self.textFieldPhoneNumber becomeFirstResponder];
        return;
    }
    
    [self.textFieldPhoneNumber resignFirstResponder];
    [self.textFieldVerifyCode resignFirstResponder];
    if (pcVerify == nil) {
        pcVerify = [[PCVerifyCode alloc] init];
        pcVerify.delegate = self;
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    [pcVerify generateVerifyCodeWithPhoneNum:mobile];
}

- (IBAction)bind:(id)sender {
    NSString *mobile = self.textFieldPhoneNumber.text;
    if (mobile.length == 0) {
        [ErrorHandler showAlert:PC_Err_InputPhoneNumber];
        [self.textFieldPhoneNumber becomeFirstResponder];
        return;
    }
    if ([PCUtilityStringOperate checkValidMobileNumber:mobile] == NO) {
        [ErrorHandler showAlert:PC_Err_InvalidPhoneNumber];
        [self.textFieldPhoneNumber becomeFirstResponder];
        return;
    }
    
//    if ([mobile isEqualToString:self.phoneNumber] == NO || self.verifyCode.length == 0) {
//        [ErrorHandler showAlert:PC_Err_NoVerifyCode];
//        [self.textFieldPhoneNumber becomeFirstResponder];
//        return;
//    }
    
    if (self.textFieldVerifyCode.text.length == 0) {
        [ErrorHandler showAlert:PC_Err_InputVerifyCode];
        [self.textFieldVerifyCode becomeFirstResponder];
        return;
    }
    
//    if ([self.verifyCode isEqualToString:self.textFieldVerifyCode.text] == NO) {
//        [ErrorHandler showAlert:PC_Err_InvalidVerifyCode];
//        [self.textFieldVerifyCode becomeFirstResponder];
//        return;
//    }
    
    [self hideKeyboard:nil];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    if (accountManagement == nil) {
        accountManagement = [[PCAccountManagement alloc] init];
        accountManagement.delegate = self;
    }
    [accountManagement bindPhone:mobile verifyCode:self.textFieldVerifyCode.text];

}

#pragma mark - textField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.textFieldVerifyCode) {
        if (textField.text.length == 6) {
            [self bind:nil];
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
    
    return allowInput;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.navigationController popViewControllerAnimated:YES];
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

#pragma mark - PCAccountManagementDelegate
-(void)bindPhoneSuccess:(PCAccountManagement *)pcAccountManagement
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [[PCUserInfo currentUser] setPhone:self.textFieldPhoneNumber.text];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"绑定提醒", nil)
                                                    message:NSLocalizedString(@"绑定成功！用该手机号也可以正常登录泡泡云。", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"我知道了", nil)
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)bindPhoneFailed:(PCAccountManagement *)pcAccountManagement withError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    if ([error.domain isEqualToString:KTServerErrorDomain] && error.code == 36) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"绑定提醒", nil)
                                                        message:NSLocalizedString(@"sorry~该手机号已经被绑定啦，请检查手机号码！", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"我知道了", nil)
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    else {
        [ErrorHandler showErrorAlert:error];
    }
}

#pragma mark - PCVerifyCodeDelegate
-(void)generateVerifyCodeSuccess:(PCVerifyCode *)pcVerifyCode verifyCode:(NSString *)_verifyCode
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    waitTime = 60;
    waitTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateWaitTime) userInfo:nil repeats:YES];
    self.buttonRequestVerifyCode.enabled = NO;
    NSString *btnTitle = [NSString stringWithFormat:@"%d秒", waitTime];
    [self.buttonRequestVerifyCode setTitle:btnTitle forState:UIControlStateDisabled];
    
    self.phoneNumber = self.textFieldPhoneNumber.text;
    self.verifyCode = _verifyCode;
    [PCUtilityUiOperate showOKAlert:@"验证码发送成功" delegate:nil];
}

-(void)generateVerifyCodeFailed:(PCVerifyCode *)pcVerifyCode withError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    if ([error.domain isEqualToString:KTServerErrorDomain] && error.code == 1) {
        [ErrorHandler showAlert:PC_Err_InvalidPhoneNumber];
    }
    else {
        [ErrorHandler showErrorAlert:error];
    }
}
@end
