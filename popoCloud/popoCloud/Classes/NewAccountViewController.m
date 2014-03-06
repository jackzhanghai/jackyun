//
//  NewAccountViewController.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-8.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "LoginViewController.h"
#import "NewAccountViewController.h"
#import "RegisterProtocolViewController.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "PCUtilityFileOperate.h"

@implementation NewAccountViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"注册泡泡云";
    
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = @"返回";
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    [temporaryBarButtonItem release];
    
    isKeywordShow = NO;
    
    [self.bgUser setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.bgPassword setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.bgRePassword setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    
    [self.btnRegister setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)]
                           forState:UIControlStateNormal];
    [self.btnRegister setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)]
                           forState:UIControlStateHighlighted];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backupgroupTap:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    tapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:tapGestureRecognizer];   //只需要点击非文字输入区域就会响应
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
    [self.txtUser resignFirstResponder];
    [self.txtPassword resignFirstResponder];
    [self.txtRePassword resignFirstResponder];
}

- (void)viewDidUnload
{
    [self setBgUser:nil];
    [self setBgPassword:nil];
    [self setBgRePassword:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.txtUser = nil;
    self.txtPassword = nil;
    self.txtRePassword = nil;
    self.checkbox = nil;
    self.btnRegisterProtocol = nil;
    self.btnRegister = nil;
}

- (void)dealloc
{
    [self setBgUser:nil];
    [self setBgPassword:nil];
    [self setBgRePassword:nil];
    
    self.txtUser = nil;
    self.txtPassword = nil;
    self.txtRePassword = nil;
    self.checkbox = nil;
    self.btnRegisterProtocol = nil;
    self.btnRegister = nil;
    if (pcAuth) {
        [pcAuth release];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationWillResignActiveNotification object:self.view.window];
    [MobClick beginLogPageView:@"NewAccountView"];
}

-(void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"NewAccountView"];
}

- (void)keyboardWillShow:(NSNotification *)notif {
    if (IS_IPAD) return;
    
    if (isKeywordShow) return;
    
    isKeywordShow = YES;
    
    CGRect keyboardBounds;
    [[notif.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    
    CGFloat height = -9; //keyboardBounds.origin.y - (self.btnRegister.frame.origin.y + self.btnRegister.frame.size.height) + 20;
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
    if (IS_IPAD) return;
    
    if (!isKeywordShow) return;
    isKeywordShow = NO;
    
    CGRect frame = self.view.frame;
    frame.origin.y = IS_IOS7 ? 64 : 0;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    
    self.view.frame = frame;
    
    [UIView commitAnimations];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self.txtUser resignFirstResponder];
    [self.txtPassword resignFirstResponder];
    [self.txtRePassword resignFirstResponder];
}

#pragma mark

-(IBAction)checkboxClick:(UIButton *)btn
{
    btn.selected = !btn.selected;
}

- (IBAction) btnRegisterProtocolClicked:(id)sender {

    [self.txtUser resignFirstResponder];
    [self.txtPassword resignFirstResponder];
    [self.txtRePassword resignFirstResponder];

    RegisterProtocolViewController *RegisterProtocol = nil;
    RegisterProtocol = [[[RegisterProtocolViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"RegisterProtocolView"] bundle:nil] autorelease]; 
    [self.navigationController pushViewController:RegisterProtocol animated:YES];
}

- (IBAction) btnRegisterClicked:(id)sender {
    NSString *email = [[self.txtUser.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
    if (email.length == 0)
    {
        [ErrorHandler showAlert:PC_Err_InputEmail];
        [self.txtUser becomeFirstResponder];
        return;
    }
    if ([PCUtilityStringOperate checkValidEmail:email] == NO) {
        [ErrorHandler showAlert:PC_Err_InvalidEmail];
        [self.txtUser becomeFirstResponder];
        return;
    }
    
    NSString *password = self.txtPassword.text;
    if (password.length == 0)
    {
        [ErrorHandler showAlert:PC_Err_InputPassword];
        [self.txtPassword becomeFirstResponder];
        return;
    }
    if ([PCUtilityStringOperate checkValidPassword:password] == NO) {
        [ErrorHandler showAlert:PC_Err_InvalidPassword];
        [self.txtPassword becomeFirstResponder];
        return;
    }
    
    if ((self.txtRePassword.text.length == 0)) {
        [ErrorHandler showAlert:PC_Err_InputConfirmPassword];
        [self.txtRePassword becomeFirstResponder];
        return;
    }
    if ([password isEqualToString:self.txtRePassword.text] == NO) {
        [ErrorHandler showAlert:PC_Err_PasswordNotSame];
        [self.txtRePassword becomeFirstResponder];
        return;
    }
    
    [self.txtUser resignFirstResponder];
    [self.txtPassword resignFirstResponder];
    [self.txtRePassword resignFirstResponder];
    
    if (!self.checkbox.selected) {
        [ErrorHandler showAlert:PC_Err_Unknown description:NSLocalizedString(@"AgreedToRegisterProtocol", nil)];
        return;
    }
    
    
    if (pcAuth == nil) {
        pcAuth = [[PCAuthentication alloc] init];
        pcAuth.delegate = self;
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    [pcAuth registWithEmail:email password:password];
}

- (IBAction)EmailtextDidChange:(UITextField *)textField
{
    if ([textField.text hasSuffix:@" "]) {
        NSString *tmp = [textField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
        textField.text = tmp;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.txtUser) {
        if ([textField.text rangeOfString:@"@"].length > 0) {
            [self.txtPassword becomeFirstResponder];
        }
    }
    else if (textField == self.txtPassword) {
        if (textField.text.length >= 6) {
            [self.txtRePassword becomeFirstResponder];
        }
    }
    else if (textField == self.txtRePassword) {
        if (textField.text.length && textField.text.length >= self.txtPassword.text.length) {
            [self btnRegisterClicked:nil];
        }
    }
    
    return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL allowInput = YES;
    if (textField == self.txtPassword) {
        if (range.location >= 16) {
            allowInput = NO;
        }
    }
    else if (textField == self.txtRePassword){
        if (range.location >= 16) {
            allowInput = NO;
        }
    }
    
    return allowInput;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
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

#pragma mark - PCAuthenticationDelegate
-(void)emailRegistSuccess:(PCAuthentication *)pcAuthentication
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [MobClick event:UM_REGISTER_EMAIL];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"RegisterSuccessTitle", nil)
                                                    message:NSLocalizedString(@"RegisterSuccessContent", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)emailRegistFailed:(PCAuthentication *)pcAuthentication withError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    if ([error.domain isEqualToString:KTServerErrorDomain] && error.code == 46) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"EmailHasBeenRegisteredTitle", nil)
                                                        message:NSLocalizedString(@"EmailHasBeenRegisteredMessage", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    else
    {
        [ErrorHandler showErrorAlert:error];
    }
}
@end
