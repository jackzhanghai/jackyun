//
//  ResetPasswordViewController.m
//  popoCloud
//
//  Created by suleyu on 13-5-27.
//
//

#import "ResetPasswordViewController.h"
#import "EmailResetPasswordViewController.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "PCUtilityUiOperate.h"

@interface ResetPasswordViewController ()
{
    int waitTime;
    NSTimer *waitTimer;
    PCVerifyCode *generateVerifyCode;
    PCAuthentication *pcAuth;
}

@property (retain, nonatomic) NSMutableData *data;
@property (copy, nonatomic) NSString *phoneNumber;
@property (copy, nonatomic) NSString *verifyCode;

@end

@implementation ResetPasswordViewController
@synthesize data;
@synthesize phoneNumber;
@synthesize verifyCode;

#pragma mark

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
    self.title = @"忘记密码";
    
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = NSLocalizedString(@"ReturnBack", nil);
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    [temporaryBarButtonItem release];
    
    [self.bgPhoneNumber setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.bgVerifyCode setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.bgPassword setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.bgConfirmPasswod setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    
    [self.buttonRequestVerifyCode setBackgroundImage:[[UIImage imageNamed:@"btn_a"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateNormal];
    [self.buttonRequestVerifyCode setBackgroundImage:[[UIImage imageNamed:@"btn_a_d"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateHighlighted];
    
    [self.buttonResetPassword setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.buttonResetPassword setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"ResetPasswordView"];
}
- (void)viewWillDisappear:(BOOL)animated {
    if (self.isMovingFromParentViewController) {
        if (waitTimer) {
            [waitTimer invalidate];
            waitTimer = nil;
        }
    }
    
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"ResetPasswordView"];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    [self setBgPhoneNumber:nil];
    [self setBgVerifyCode:nil];
    [self setBgPassword:nil];
    [self setBgConfirmPasswod:nil];
    
    [self setTextFieldPhoneNumber:nil];
    [self setTextFieldVerifyCode:nil];
    [self setTextFieldPassword:nil];
    [self setTextFieldConfirmPassword:nil];
    
    [self setButtonRequestVerifyCode:nil];
    [self setButtonResetPassword:nil];
    [super viewDidUnload];
}

- (void)dealloc
{
    if (waitTimer) {
        [waitTimer invalidate];
        waitTimer = nil;
    }
    if (pcAuth) {
        [pcAuth release];
    }
    if (generateVerifyCode) {
        [generateVerifyCode release];
    }
    
    [self setBgPhoneNumber:nil];
    [self setBgVerifyCode:nil];
    [self setBgPassword:nil];
    [self setBgConfirmPasswod:nil];
    
    [self setTextFieldPhoneNumber:nil];
    [self setTextFieldVerifyCode:nil];
    [self setTextFieldPassword:nil];
    [self setTextFieldConfirmPassword:nil];
    
    [self setButtonRequestVerifyCode:nil];
    [self setButtonResetPassword:nil];
    
    [data release];
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

#pragma mark

- (IBAction)hideKeyboard:(id)sender {
    [self.textFieldPhoneNumber resignFirstResponder];
    [self.textFieldVerifyCode resignFirstResponder];
    [self.textFieldPassword resignFirstResponder];
    [self.textFieldConfirmPassword resignFirstResponder];
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
    
    [self hideKeyboard:nil];
    
    if (generateVerifyCode==nil) {
        generateVerifyCode = [[PCVerifyCode alloc] init];
        generateVerifyCode.delegate = self;
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    [generateVerifyCode resetPasswordVerifyCodeWithPhoneNum:mobile];
}

- (IBAction)resetPassword:(id)sender {
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
    
    NSString *password = self.textFieldPassword.text;
    if (password.length == 0)
    {
        [ErrorHandler showAlert:PC_Err_InputPassword];
        [self.textFieldPassword becomeFirstResponder];
        return;
    }
    if ([PCUtilityStringOperate checkValidPassword:password] == NO) {
        [ErrorHandler showAlert:PC_Err_InvalidPassword];
        [self.textFieldPassword becomeFirstResponder];
        return;
    }
    
    if ((self.textFieldConfirmPassword.text.length == 0)) {
        [ErrorHandler showAlert:PC_Err_InputConfirmPassword];
        [self.textFieldConfirmPassword becomeFirstResponder];
        return;
    }
    if ([password isEqualToString:self.textFieldConfirmPassword.text] == NO) {
        [ErrorHandler showAlert:PC_Err_PasswordNotSame];
        [self.textFieldConfirmPassword becomeFirstResponder];
        return;
    }
    
//    if ([self.verifyCode isEqualToString:self.textFieldVerifyCode.text] == NO) {
//        [ErrorHandler showAlert:PC_Err_InvalidVerifyCode];
//        [self.textFieldVerifyCode becomeFirstResponder];
//        return;
//    }
    
    [self hideKeyboard:nil];
    
    if (pcAuth == nil) {
        pcAuth = [[PCAuthentication alloc] init];
        pcAuth.delegate = self;
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    [pcAuth resetPasswordWithPhoneNum:mobile password:password verifyCode:self.textFieldVerifyCode.text];
}

- (IBAction)resetPasswordWithEmail:(id)sender {
    EmailResetPasswordViewController *vc = [[EmailResetPasswordViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

#pragma mark - textField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.textFieldVerifyCode) {
        if (textField.text.length == 6) {
            [self.textFieldPassword becomeFirstResponder];
        }
    }
    else if (textField == self.textFieldPassword) {
        if (textField.text.length >= 6) {
            [self.textFieldConfirmPassword becomeFirstResponder];
        }
    }
    else if (textField == self.textFieldConfirmPassword) {
        if (textField.text.length && textField.text.length >= self.textFieldPassword.text.length) {
            [self resetPassword:nil];
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
    else if (textField == self.textFieldPassword) {
        if (range.location >= 16) {
            allowInput = NO;
        }
    }
    else if (textField == self.textFieldConfirmPassword){
        if (range.location >= 16) {
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

#pragma mark - PCAuthenticationDelegate
-(void)phoneResetPasswordSuccess:(PCAuthentication *)pcAuthentication
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"重置密码", nil)
                                                    message:NSLocalizedString(@"密码重置成功！请牢记噢！", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)phoneResetPasswordFailed:(PCAuthentication *)pcAuthentication withError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [ErrorHandler showErrorAlert:error];
}
@end
