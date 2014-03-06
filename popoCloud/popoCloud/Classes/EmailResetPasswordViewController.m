//
//  EmailResetPasswordViewController.m
//  popoCloud
//
//  Created by suleyu on 13-5-27.
//
//

#import "EmailResetPasswordViewController.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "PCUtilityUiOperate.h"

@interface EmailResetPasswordViewController ()
{
    PCAuthentication *pcAuth;
}
@end

@implementation EmailResetPasswordViewController


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
    self.title = @"泡泡云密码重置";
    [self.bgEmail1 setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.ConfirmBtn setBackgroundImage:[[UIImage imageNamed:@"btn_a"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateNormal];
    [self.ConfirmBtn setBackgroundImage:[[UIImage imageNamed:@"btn_a_d"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateHighlighted];

    [self.nextBtn setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.nextBtn setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];

    [self.bgEmail2 setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.bgEmail3 setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.bgEmail4 setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];

    [self.buttonResetPassword setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.buttonResetPassword setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];
    
    self.firstPage.hidden = NO;
    self.secondPage.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"EmailResetPasswordView"];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"EmailResetPasswordView"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)releaseIBoutlet
{
    self.firstPage = nil;
    self.bgEmail1 = nil;
    self.textFieldEmail = nil;
    self.ConfirmBtn = nil;
    self.nextBtn = nil;
    
    self.bgEmail2 = nil;;
    self.bgEmail3 = nil;;
    self.bgEmail4 = nil;
    self.secondPage = nil;
    self.verifyCodeField = nil;
    self.PWField = nil;
    self.rePWField = nil;
    self.buttonResetPassword= nil;
}

- (void)viewDidUnload
{
    [self releaseIBoutlet];
    [super viewDidUnload];
}

- (void)dealloc
{
    [self releaseIBoutlet];
    if (pcAuth) {
        [pcAuth release];
    }
    [super dealloc];
}

- (IBAction)jumpToSencondPage:(id)sender
{
    NSString *email = [[self.textFieldEmail.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
    if (email.length == 0)
    {
        [ErrorHandler showAlert:PC_Err_InputEmail];
        [self.textFieldEmail becomeFirstResponder];
        return;
    }
    if ([PCUtilityStringOperate checkValidEmail:email] == NO) {
        [ErrorHandler showAlert:PC_Err_InvalidEmail];
        [self.textFieldEmail becomeFirstResponder];
        return;
    }

    self.secondPage.hidden = NO;
    self.verifyCodeField.keyboardType = UIKeyboardTypeNumberPad;
    self.firstPage.hidden = YES;
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
    if (sender == self.firstPage) {
        [self.textFieldEmail resignFirstResponder];
    }
    else if(sender == self.secondPage)
    {
        [self.verifyCodeField resignFirstResponder];
        [self.PWField resignFirstResponder];
        [self.rePWField resignFirstResponder];
    }
}

- (IBAction)resetPassWord:(id)sender
{
    NSString *verifyField = [[self.verifyCodeField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
    NSString *passWord = self.PWField.text ;
    NSString *rePassWord = self.rePWField.text ;
    if (verifyField.length == 0)
    {
        [ErrorHandler showAlert:PC_Err_InputVerifyCode];
        [self.verifyCodeField becomeFirstResponder];
        return;
    }
    else if(  passWord.length == 0 )
    {
        [ErrorHandler showAlert:PC_Err_InputPassword];
        [self.PWField becomeFirstResponder];
        return;
    }
    else if ([PCUtilityStringOperate checkValidPassword:passWord] == NO) {
        [ErrorHandler showAlert:PC_Err_InvalidPassword];
        [self.PWField becomeFirstResponder];
        return;
    }
    else if(  rePassWord.length == 0 )
    {
        [ErrorHandler showAlert:PC_Err_InputPassword];
        [self.rePWField becomeFirstResponder];
        return;
    }
    else if ([passWord isEqualToString:rePassWord] == NO) {
        [ErrorHandler showAlert:PC_Err_PasswordNotSame];
        [self.rePWField becomeFirstResponder];
        return;
    }

    [self.verifyCodeField resignFirstResponder];
    [self.PWField resignFirstResponder];
    [self.rePWField resignFirstResponder];
    
    if (pcAuth == nil) {
        pcAuth = [[PCAuthentication alloc] init];
        pcAuth.delegate = self;
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    [pcAuth resetPasswordWithEmailVerifyCode:verifyField andNewPW:passWord andEmail:[[self.textFieldEmail.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString]];
}

- (IBAction)getEamilVerifyCode:(id)sender {
    NSString *email = [[self.textFieldEmail.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
    if (email.length == 0)
    {
        [ErrorHandler showAlert:PC_Err_InputEmail];
        [self.textFieldEmail becomeFirstResponder];
        return;
    }
    if ([PCUtilityStringOperate checkValidEmail:email] == NO) {
        [ErrorHandler showAlert:PC_Err_InvalidEmail];
        [self.textFieldEmail becomeFirstResponder];
        return;
    }

    [self.textFieldEmail resignFirstResponder];
    
    if (pcAuth == nil) {
        pcAuth = [[PCAuthentication alloc] init];
        pcAuth.delegate = self;
    }

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    [pcAuth getResetPasswordVerifyCodeWithEmail:email];
}

- (void)setNewPassWord
{
    
}

#pragma mark - textField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.textFieldEmail) {
        if ([textField.text rangeOfString:@"@"].length > 0) {
            [self getEamilVerifyCode:nil];
        }
    }
    else if (textField == self.rePWField) {
        if ([textField.text rangeOfString:@"@"].length > 0) {
            if ([self.rePWField.text isEqualToString:self.PWField.text]) {
                [self setNewPassWord];
            }
        }
    }

    return YES;
}

- (IBAction)EmailtextDidChange:(UITextField *)textField
{
    if ([textField.text hasSuffix:@" "]) {
        NSString *tmp = [textField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
        textField.text = tmp;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.secondPage.hidden == NO) {
        NSArray *viewControllers = self.navigationController.viewControllers;
        UIViewController *loginViewController = nil;
        for (UIViewController *vc in viewControllers) {
            if ([vc isKindOfClass:NSClassFromString(@"LoginViewController")]) {
                loginViewController = vc;
            }
        }
        
        if (loginViewController) {
            [self.navigationController popToViewController:loginViewController animated:YES];
        } else {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
{
    if (textField == self.verifyCodeField)
    {
        return range.location < 6;
    }
    return YES;
}
#pragma mark - PCAuthenticationDelegate
- (void)emailGetResetPasswordVerifyCodeSuccess:(PCAuthentication *)pcAuthentication withInfo:(NSDictionary *)dict
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [PCUtilityUiOperate showOKAlert:@"验证码已发送至邮箱，请查收！" delegate:nil];
}

- (void)emailGetResetPasswordVerifyCodeFailed:(PCAuthentication *)pcAuthentication withError:(NSError *)error
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

- (void)emailResetPasswordSuccess:(PCAuthentication *)pcAuthentication withInfo:(NSDictionary *)dict
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

- (void)emailResetPasswordFailed:(PCAuthentication *)pcAuthentication withError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    if ([error.domain isEqualToString:KTServerErrorDomain] && error.code == 1) {
        [ErrorHandler showAlert:PC_Err_InvalidVerifyCode];
    }
    else {
        [ErrorHandler showErrorAlert:error];
    }

}

@end
