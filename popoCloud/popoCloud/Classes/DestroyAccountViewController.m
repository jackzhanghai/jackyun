//
//  DestroyAccountViewController.m
//  popoCloud
//
//  Created by suleyu on 13-7-8.
//
//

#import "DestroyAccountViewController.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "PCUtilityEncryptionAlgorithm.h"
#import "PCUserInfo.h"
#import "FileUploadManager.h"

@interface DestroyAccountViewController ()
{
    PCAccountManagement *accountManagement;
}
@end

@implementation DestroyAccountViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        self.title = @"清除帐号";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([[[PCUserInfo currentUser] phone] length] > 0) {
        if ([[[PCUserInfo currentUser] email] length] > 0) {
            self.labelAccount.text = [NSString stringWithFormat:@"%@ 和 %@", [[PCUserInfo currentUser] phone], [[PCUserInfo currentUser] email]];
        }
        else {
            self.labelAccount.text = [[PCUserInfo currentUser] phone];
        }
    }
    else {
        self.labelAccount.text = [[PCUserInfo currentUser] email];
    }
    
    [self.bgPassword setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    
    [self.buttonDeleteAccount setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.buttonDeleteAccount setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setLabelAccount:nil];
    [self setBgPassword:nil];
    [self setTextFieldPassword:nil];
    [self setButtonDeleteAccount:nil];
    [super viewDidUnload];
}

- (void)dealloc
{
    [self setLabelAccount:nil];
    [self setBgPassword:nil];
    [self setTextFieldPassword:nil];
    [self setButtonDeleteAccount:nil];
    
    [accountManagement release];
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

- (IBAction)deleteAccount:(id)sender {
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
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES afterDelay:0.1];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    
    if (accountManagement == nil)
    {
        accountManagement = [[PCAccountManagement alloc] init];
        accountManagement.delegate = self;
    }
    [accountManagement destroyAccountWithPassword:self.textFieldPassword.text];
}

#pragma mark - textField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return range.location < 16;
}

#pragma mark - PCAccountManagementDelegate

-(void)destroyAccountSuccess:(PCAccountManagement*)pcAccountManagement
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    [[PCUtilityFileOperate downloadManager] deleteDownloadItem];
    
    //删除所有得上传
    [[FileUploadManager sharedManager] deleteAllUpload];
    [[PCSettings sharedSettings] setUser:@"" name:@"" password:@""];
    
    [PCUtilityUiOperate logout];
    [PCUtilityUiOperate showOKAlert:@"帐号已清除，您可以重新注册或与其他帐号绑定～" delegate:nil];
}

-(void)destroyAccountFailed:(PCAccountManagement *)pcAccountManagement withError:(NSError *)error
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
