//
//  UnbindEmailViewController.m
//  popoCloud
//
//  Created by suleyu on 13-5-29.
//
//

#import "UnbindEmailViewController.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "PCUserInfo.h"

@interface UnbindEmailViewController ()
{
    PCAccountManagement *accountManagement;
}
@end

@implementation UnbindEmailViewController

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
    self.title = @"解绑";
    self.labelAccount.text = [NSString stringWithFormat:@"泡泡云ID：%@", [[PCUserInfo currentUser] userId]];
    self.labelEmail.text = [[PCUserInfo currentUser] email];
    
    [self.bgPassword setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    
    [self.buttonUnbind setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.buttonUnbind setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"UnbindEmailView"];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"UnbindEmailView"];
}

- (void)viewDidUnload {
    [self setLabelAccount:nil];
    [self setLabelEmail:nil];
    [self setBgPassword:nil];
    [self setTextFieldPassword:nil];
    [self setButtonUnbind:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    [self setLabelAccount:nil];
    [self setLabelEmail:nil];
    [self setBgPassword:nil];
    [self setTextFieldPassword:nil];
    [self setButtonUnbind:nil];
    if (accountManagement) {
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
    [self.textFieldPassword resignFirstResponder];
}

- (IBAction)unbind:(id)sender {
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
    
    [self.textFieldPassword resignFirstResponder];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    if (accountManagement == nil)
    {
        accountManagement = [[PCAccountManagement alloc] init];
        accountManagement.delegate = self;
    }
    [accountManagement unbindEmailWithPassword:self.textFieldPassword.text];

}

#pragma mark - textField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.textFieldPassword) {
        if (textField.text.length >= 6) {
            [self unbind:nil];
        }
    }
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return range.location < 16;
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - PCAccountManagementDeleagte
-(void)unbindEmailSuccess:(PCAccountManagement *)pcAccountManagement
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [[PCUserInfo currentUser] setEmail:nil];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:NSLocalizedString(@"解绑成功！您可以再重新去设置中绑定其他帐号～", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"我知道了", nil)
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
    [MobClick event:UM_UNBIND_SUCCESS];
}

-(void)unbindEmailFailed:(PCAccountManagement *)pcAccountManagement withError:(NSError *)error
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
@end
