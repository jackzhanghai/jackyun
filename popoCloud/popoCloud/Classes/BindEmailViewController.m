//
//  BindEmailViewController.m
//  popoCloud
//
//  Created by suleyu on 13-5-29.
//
//

#import "BindEmailViewController.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "PCUserInfo.h"

@interface BindEmailViewController ()
{
    PCAccountManagement *accountManagement;
}
@end

@implementation BindEmailViewController

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
    self.labelAccount.text = [NSString stringWithFormat:@"帐号：%@", [[PCUserInfo currentUser] phone]];
    self.textFieldEmail.text = [[PCUserInfo currentUser] email];
    
    [self.bgEmail setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    
    [self.buttonBind setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.buttonBind setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"BindEmailView"];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"BindEmailView"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setLabelAccount:nil];
    [self setBgEmail:nil];
    [self setTextFieldEmail:nil];
    [self setButtonBind:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    [self setLabelAccount:nil];
    [self setBgEmail:nil];
    [self setTextFieldEmail:nil];
    [self setButtonBind:nil];
    if (accountManagement)
    {
        [accountManagement cancelAllRequests];
        [accountManagement release];
    }
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
    [self.textFieldEmail resignFirstResponder];
}

- (IBAction)bind:(id)sender {
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
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    if (accountManagement == nil)
    {
        accountManagement = [[PCAccountManagement alloc] init];
        accountManagement.delegate = self;
    }
    //绑定邮箱
    [accountManagement bindEmail:email];

}

#pragma mark - textField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.textFieldEmail) {
        if ([textField.text rangeOfString:@"@"].length > 0) {
            [self bind:nil];
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
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - PCAccountManagementDelegate
-(void)bindEmailSuccess:(PCAccountManagement *)pcAccountManagement
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    NSString *email = [[self.textFieldEmail.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
    [[PCUserInfo currentUser] setEmail:email];
    [[PCUserInfo currentUser] setEmailVerified:NO];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"绑定提醒", nil)
                                                    message:NSLocalizedString(@"认证邮件已发送到您的邮箱，认证激活邮件后，才能正常使用该邮箱登录。", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"我知道了", nil)
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)bindEmailFailed:(PCAccountManagement *)pcAccountManagement withError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    if ([error.domain isEqualToString:KTServerErrorDomain]) {
        if (error.code == 46) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"绑定提醒", nil)
                                                            message:NSLocalizedString(@"sorry~该邮箱已经被绑定啦，请检查邮箱输入内容！", nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"我知道了", nil)
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
        else if (error.code == 59) {
            [ErrorHandler showAlert:PC_Err_Unknown description:@"邮件已发送，请去邮箱查看。" delegate:self];
        }
        else {
            [ErrorHandler showErrorAlert:error];
        }
    }
    else {
        [ErrorHandler showErrorAlert:error];
    }
}
@end
