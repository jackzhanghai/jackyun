//
//  RegisterViewController.m
//  popoCloud
//
//  Created by suleyu on 13-5-21.
//
//

#import "RegisterViewController.h"
#import "NewAccountViewController.h"
#import "RegisterProtocolViewController.h"
#import "NoDeviceViewController.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "PCLogin.h"
#import "PCUserInfo.h"
#import "FileUploadManager.h"
#import "PCAppDelegate.h"

@interface RegisterViewController ()
{
    int waitTime;
    NSTimer *waitTimer;
    PCAuthentication *pcAuth;
    PCVerifyCode *generateVerifyCode;
}

@property (retain, nonatomic) NSDate *requestVerifyCodeTime;
@property (copy, nonatomic) NSString *phoneNumber;
@property (copy, nonatomic) NSString *verifyCode;

@end


@implementation RegisterViewController

@synthesize requestVerifyCodeTime;
@synthesize phoneNumber;
@synthesize verifyCode;

#pragma mark - methods from super class

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
    
    self.navigationItem.title = @"注册泡泡云";
    
    // request verify code view
    [self.bgPhoneNumber setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.bgVerifyVode setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    
    [self.buttonRequestVerifyCode setBackgroundImage:[[UIImage imageNamed:@"btn_a"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateNormal];
    [self.buttonRequestVerifyCode setBackgroundImage:[[UIImage imageNamed:@"btn_a_d"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateHighlighted];
    
    [self.buttonInputPassword setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.buttonInputPassword setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];
    
    // input password view
    [self.labelWelcome setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome"]]];
    [self.bgPassword setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.bgConfirmPasswod setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    
    [self.buttonRegister setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.buttonRegister setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.isMovingToParentViewController) {
        if (waitTimer == nil) {
            self.textFieldPhoneNumber.text = nil;
        }
        
        self.textFieldVerifyCode.text = nil;
        self.textFieldPassword.text = nil;
        self.textFieldConfirmPassword.text = nil;
        
        [self.textFieldPhoneNumber resignFirstResponder];
        [self.textFieldVerifyCode resignFirstResponder];
        [self.textFieldPassword resignFirstResponder];
        [self.textFieldConfirmPassword resignFirstResponder];
        
        self.viewVerifyVode.hidden = NO;
        self.viewInputPassword.hidden = YES;
    }
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"RegisterView"];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"RegisterView"];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setViewVerifyVode:nil];
    [self setBgPhoneNumber:nil];
    [self setBgVerifyVode:nil];
    [self setTextFieldPhoneNumber:nil];
    [self setTextFieldVerifyCode:nil];
    [self setButtonRequestVerifyCode:nil];
    [self setButtonInputPassword:nil];
    
    [self setViewInputPassword:nil];
    [self setLabelWelcome:nil];
    [self setBgPassword:nil];
    [self setTextFieldPassword:nil];
    [self setBgConfirmPasswod:nil];
    [self setTextFieldConfirmPassword:nil];
    [self setCheckbox:nil];
    [self setButtonRegister:nil];
    
    [super viewDidUnload];
}

- (void)dealloc
{
    if (waitTimer) {
        [waitTimer invalidate];
        waitTimer = nil;
    }
    
    [self setViewVerifyVode:nil];
    [self setBgPhoneNumber:nil];
    [self setBgVerifyVode:nil];
    [self setTextFieldPhoneNumber:nil];
    [self setTextFieldVerifyCode:nil];
    [self setButtonRequestVerifyCode:nil];
    [self setButtonInputPassword:nil];
    
    [self setViewInputPassword:nil];
    [self setLabelWelcome:nil];
    [self setBgPassword:nil];
    [self setTextFieldPassword:nil];
    [self setBgConfirmPasswod:nil];
    [self setTextFieldConfirmPassword:nil];
    [self setCheckbox:nil];
    [self setButtonRegister:nil];
    if (pcAuth) {
        [pcAuth release];
    }
    if (generateVerifyCode) {
        [generateVerifyCode release];
    }
    [requestVerifyCodeTime release];
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
    if (sender == self.viewVerifyVode) {
        [self.textFieldPhoneNumber resignFirstResponder];
        [self.textFieldVerifyCode resignFirstResponder];
    }
    else if (sender == self.viewInputPassword) {
        [self.textFieldPassword resignFirstResponder];
        [self.textFieldConfirmPassword resignFirstResponder];
    }
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
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    if (generateVerifyCode == nil)
    {
        generateVerifyCode = [[PCVerifyCode alloc] init];
        generateVerifyCode.delegate = self;
    }
    [generateVerifyCode generateVerifyCodeWithPhoneNum:mobile];
}

- (IBAction)inputPassword:(id)sender {
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
    
    if ([mobile isEqualToString:self.phoneNumber] == NO || self.verifyCode.length == 0) {
        [ErrorHandler showAlert:PC_Err_NoVerifyCode];
        return;
    }
    
    if (self.textFieldVerifyCode.text.length == 0) {
        [ErrorHandler showAlert:PC_Err_InputVerifyCode];
        [self.textFieldVerifyCode becomeFirstResponder];
        return;
    }
    
    if ([self.verifyCode isEqualToString:self.textFieldVerifyCode.text] == NO) {
        [ErrorHandler showAlert:PC_Err_InvalidVerifyCode];
        [self.textFieldVerifyCode becomeFirstResponder];
        return;
    }
    
    if ([self.requestVerifyCodeTime timeIntervalSinceNow] < -30*60) {
        [ErrorHandler showAlert:PC_Err_OutdateVerifyCode];
        return;
    }
    
    [self.textFieldPhoneNumber resignFirstResponder];
    [self.textFieldVerifyCode resignFirstResponder];
    
    self.labelWelcome.text = [NSString stringWithFormat:@"用户：%@ 欢迎您！", mobile];
    self.viewVerifyVode.hidden = YES;
    self.viewInputPassword.hidden = NO;
}

- (IBAction)registerWithEmail:(id)sender {
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = @"手机号注册";
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    [temporaryBarButtonItem release];
    
    NewAccountViewController *newAccount = [[[NewAccountViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"NewAccountView"] bundle:nil] autorelease];
    [self.navigationController pushViewController:newAccount animated:YES];
}

- (IBAction)readUserAgreement:(id)sender {
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = @"返回";
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    [temporaryBarButtonItem release];
    
    [self.textFieldPassword resignFirstResponder];
    [self.textFieldConfirmPassword resignFirstResponder];
    
    RegisterProtocolViewController *RegisterProtocol = nil;
    RegisterProtocol = [[[RegisterProtocolViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"RegisterProtocolView"] bundle:nil] autorelease];
    [self.navigationController pushViewController:RegisterProtocol animated:YES];
}

-(void)checkboxClick:(UIButton *)button {
    button.selected = !button.selected;
}

- (IBAction)registerAccount:(id)sender {
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
    
    [self.textFieldPassword resignFirstResponder];
    [self.textFieldConfirmPassword resignFirstResponder];
    
    if (!self.checkbox.selected) {
        [ErrorHandler showAlert:PC_Err_Unknown description:NSLocalizedString(@"AgreedToRegisterProtocol", nil)];
        return;
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    if (pcAuth == nil) {
        pcAuth = [[PCAuthentication alloc] init];
        pcAuth.delegate = self;
    }
    [pcAuth registWithPhoneNum:self.textFieldPhoneNumber.text
                      password:password
                    verifyCode:self.textFieldVerifyCode.text];
}

#pragma mark - textField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.textFieldVerifyCode) {
        if (textField.text.length == 6) {
            [self inputPassword:nil];
        }
    }
    else if (textField == self.textFieldPassword) {
        if (textField.text.length >= 6) {
            [self.textFieldConfirmPassword becomeFirstResponder];
        }
    }
    else if (textField == self.textFieldConfirmPassword) {
        if (textField.text.length && textField.text.length >= self.textFieldPassword.text.length) {
            [self registerAccount:nil];
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

- (void)updateWaitTime
{
    waitTime--;
    if (waitTime > 0) {
        NSString *btnTitle = [NSString stringWithFormat:@"%d秒", waitTime];
        [self.buttonRequestVerifyCode setTitle:btnTitle forState:UIControlStateDisabled];
    }
    else {
        self.textFieldPhoneNumber.enabled = YES;
        self.buttonRequestVerifyCode.enabled = YES;
        [waitTimer invalidate];
        waitTimer = nil;
    }
}

#pragma mark - PCVerifyCodeDelegate
-(void)generateVerifyCodeSuccess:(PCVerifyCode*)pcVerifyCode verifyCode:(NSString *)_verifyCode
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    waitTime = 60;
    waitTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateWaitTime) userInfo:nil repeats:YES];
    self.textFieldPhoneNumber.enabled = NO;
    self.buttonRequestVerifyCode.enabled = NO;
    NSString *btnTitle = [NSString stringWithFormat:@"%d秒", waitTime];
    [self.buttonRequestVerifyCode setTitle:btnTitle forState:UIControlStateDisabled];
    
    self.requestVerifyCodeTime = [NSDate date];
    self.phoneNumber = self.textFieldPhoneNumber.text;
    self.verifyCode = _verifyCode;
    [PCUtilityUiOperate showOKAlert:@"验证码发送成功" delegate:nil];
}

-(void)generateVerifyCodeFailed:(PCVerifyCode*)pcVerifyCode withError:(NSError *)error
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
-(void)phoneRegistSuccess:(PCAuthentication *)pcAuthentication
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    if (waitTimer) {
        self.textFieldPhoneNumber.enabled = YES;
        self.buttonRequestVerifyCode.enabled = YES;
        [waitTimer invalidate];
        waitTimer = nil;
    }
    
    ((PCAppDelegate*)[[UIApplication sharedApplication] delegate]).bNetOffline = NO;
    
//    [[PCUtilityFileOperate downloadManager] deleteDownloadItem];
//    [[FileUploadManager sharedManager] deleteAllUpload];
    [[PCSettings sharedSettings] setUser:[[PCUserInfo currentUser] userId] name:self.textFieldPhoneNumber.text password:self.textFieldPassword.text];
    
    [PCLogin initDevices];
    [[PCUtilityFileOperate downloadManager] reloadData];
    [[FileUploadManager sharedManager] resumeFileUploadInfos];
    
    NoDeviceViewController* noDeviceViewController = [[NoDeviceViewController alloc] initWithNibName:@"NoDeviceView" bundle:nil];
    //[self.navigationController pushViewController:noDeviceViewController animated:YES];
    NSMutableArray *array = [NSMutableArray arrayWithArray:[self.navigationController viewControllers]];
    [array replaceObjectAtIndex:array.count-1 withObject:noDeviceViewController];
    [self.navigationController setViewControllers:array animated:YES];
    [noDeviceViewController release];
}

-(void)phoneRegistFailed:(PCAuthentication *)pcAuthentication withError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [ErrorHandler showErrorAlert:error];
}
@end
