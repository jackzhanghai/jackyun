//
//  ChangePasswordViewController.m
//  popoCloud
//
//  Created by ice on 13-11-18.
//
//

#import "ChangePasswordViewController.h"
#import "PCUtilityStringOperate.h"
#import "PCSettings.h"
#import "PCUserInfo.h"
#import "PCUtilityEncryptionAlgorithm.h"
@interface ChangePasswordViewController ()

@end

@implementation ChangePasswordViewController
@synthesize oldPasswordField;
@synthesize passwordField;
@synthesize confirmPasswordFiled;
@synthesize confirmChangeBtn;
@synthesize oldPasswordBgImage;
@synthesize passwordBgImage;
@synthesize confirmPasswordBgImage;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"修改密码";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = @"返回";
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    [temporaryBarButtonItem release];
    self.view.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    [self.oldPasswordBgImage setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.passwordBgImage setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.confirmPasswordBgImage setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];

    [self.confirmChangeBtn setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.confirmChangeBtn setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    self.oldPasswordField = nil;
    self.passwordField = nil;
    self.confirmPasswordFiled = nil;
    self.confirmChangeBtn = nil;
    self.oldPasswordBgImage = nil;
    self.passwordBgImage = nil;
    self.confirmPasswordBgImage = nil;
}
-(void)dealloc
{
    if (management) {
        [management release];
        management = nil;
    }
    self.oldPasswordField = nil;
    self.passwordField = nil;
    self.confirmPasswordFiled = nil;
    self.confirmChangeBtn = nil;
    self.oldPasswordBgImage = nil;
    self.passwordBgImage = nil;
    self.confirmPasswordBgImage = nil;
    [super dealloc];
}
- (IBAction)hideKeyboard:(id)sender {
    [self.oldPasswordField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self.confirmPasswordFiled resignFirstResponder];
}
-(void)lockUI
{
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}
-(void)unLockUI
{
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}
-(IBAction)changePasswordAction:(id)sender
{
//    modifyPassword
    if (self.oldPasswordField.text.length == 0)
    {
        [ErrorHandler showAlert:PC_Err_InputPassword];
        [self.oldPasswordField becomeFirstResponder];
        return;
    }
    if ([PCUtilityStringOperate checkValidPassword:self.oldPasswordField.text] == NO)
    {
        [ErrorHandler showAlert:PC_Err_Unknown description:@"旧密码输入格式不正确，请重新输入。"];
        [self.oldPasswordField becomeFirstResponder];
        return;
    }
    
    NSString *password = self.passwordField.text;
    if (password.length == 0)
    {
        [ErrorHandler showAlert:PC_Err_InputPassword];
        [self.passwordField becomeFirstResponder];
        return;
    }
    if ([PCUtilityStringOperate checkValidPassword:password] == NO) {
        [ErrorHandler showAlert:PC_Err_Unknown description:@"新密码输入格式不正确，请重新输入。"];
        [self.passwordField becomeFirstResponder];
        return;
    }
    
    if ((self.confirmPasswordFiled.text.length == 0)) {
        [ErrorHandler showAlert:PC_Err_InputConfirmPassword];
        [self.confirmPasswordFiled becomeFirstResponder];
        return;
    }
    if ([password isEqualToString:self.confirmPasswordFiled.text] == NO) {
        [ErrorHandler showAlert:PC_Err_Unknown description:@"首次输入密码和再次输入密码不一致，请重新输入。"];
        [self.confirmPasswordFiled becomeFirstResponder];
        return;
    }
    if (!management)
    {
        management = [[PCDeviceManagement alloc] init];
        management.delegate = self;
    }
    [management modifyPassword:[NSDictionary dictionaryWithObjectsAndKeys:self.oldPasswordField.text,@"password",self.passwordField.text,@"newPassword", nil]];
    [self hideKeyboard:nil];
    [self lockUI];

}
#pragma PCDeviceManagement Delegate
- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement modifyPasswordSuccess:(NSString*)device
{
    //更新内存里面的密码
    [[PCSettings sharedSettings] setUser:[[PCUserInfo currentUser] userId] name:[[PCSettings sharedSettings] username] password:passwordField.text];
    [[PCUserInfo currentUser] setPassword:[PCUtilityEncryptionAlgorithm md5:passwordField.text]];
    
    [self unLockUI];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"密码修改成功" delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
    [alert show];
    [alert release];
}
- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement modifyPasswordFailedWithError:(NSError*)error
{
    [self unLockUI];
    
    if ([error.domain isEqualToString:KTServerErrorDomain] && error.code == 9) {
        [ErrorHandler showAlert:PC_Err_Unknown description:@"旧密码输入不正确，请重新输入。"];
    }
    else {
        [ErrorHandler showErrorAlert:error];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.navigationController popViewControllerAnimated:YES];
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

@end
