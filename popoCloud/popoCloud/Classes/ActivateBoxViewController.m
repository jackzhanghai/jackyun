//
//  ActivateBoxViewController.m
//  popoCloud
//
//  Created by suleyu on 13-5-27.
//
//

#import "ActivateBoxViewController.h"
#import "PCAppDelegate.h"
#import "PCLogout.h"
#import "PCUserInfo.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "PCUtilityUiOperate.h"
#import "CameraUploadManager.h"

#import <QuartzCore/QuartzCore.h>
#import "ZBarSDK.h"
#define  FAILEDTAG 119
@interface ActivateBoxViewController ()
{
    ZBarReaderViewController *reader;
    UIView *trackView;
    PCDeviceManagement *deviceManagement;
}

@end

@implementation ActivateBoxViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"激活泡泡云盒子";
    
    [self.bgScanResult setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    [self.bgSerialNumber setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)]];
    
    [self.textFieldSerialNumber addTarget:self action:@selector(textFiledDidChanged:) forControlEvents:UIControlEventEditingChanged];
    
    [self.buttonScan setBackgroundImage:[[UIImage imageNamed:@"btn_a"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateNormal];
    [self.buttonScan setBackgroundImage:[[UIImage imageNamed:@"btn_a_d"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateHighlighted];
    
    [self.buttonActivate setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.buttonActivate setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationWillResignActiveNotification object:self.view.window];
    if (IS_IPAD && self.isMovingToParentViewController) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:)
                                                     name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"ActivateBoxView"];
}

-(void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    if (IS_IPAD && self.isMovingFromParentViewController) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"ActivateBoxView"];
}

- (void)viewDidUnload {
    [self setButtonScan:nil];
    [self setButtonActivate:nil];
    [self setBgScanResult:nil];
    [self setBgSerialNumber:nil];
    [self setTextFieldScanResult:nil];
    [self setTextFieldSerialNumber:nil];
    [super viewDidUnload];
}

- (void)dealloc
{
    [self setButtonScan:nil];
    [self setButtonActivate:nil];
    [self setBgScanResult:nil];
    [self setBgSerialNumber:nil];
    [self setTextFieldScanResult:nil];
    [self setTextFieldSerialNumber:nil];
    
    [reader release];
    [trackView release];
    [deviceManagement release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
- (void)keyboardWillShow:(NSNotification *)notif {
    CGRect keyboardBounds;
    [[notif.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    
    CGFloat keyboardHeight = (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) ? keyboardBounds.size.width : keyboardBounds.size.height;
    CGFloat height = self.view.frame.size.height - keyboardHeight - self.buttonActivate.frame.origin.y - self.buttonActivate.frame.size.height;
    if (IS_IOS7) {
        height += 64;
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
    [self.textFieldSerialNumber resignFirstResponder];
}

- (IBAction)hideKeyboard:(id)sender {
    [self.textFieldSerialNumber resignFirstResponder];
}

- (IBAction)scanBtnClick:(id)sender {
    [self.textFieldSerialNumber resignFirstResponder];
    
    if (reader == nil) {
        reader = [ZBarReaderViewController new];
        reader.readerDelegate = self;
        reader.tracksSymbols = NO;
        reader.supportedOrientationsMask = IS_IPAD ? ZBarOrientationMaskAll : UIInterfaceOrientationPortrait;
        
        CGSize readerViewSize = reader.readerView.frame.size;
        CGFloat width = IS_IPAD ? 450 : 240;
        CGFloat x = (readerViewSize.width - width) / 2;
        CGFloat y = (readerViewSize.height - width) / 2;
        trackView = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, width)];
        trackView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        trackView.backgroundColor = [UIColor clearColor];
        trackView.layer.borderWidth = 2;
        trackView.layer.borderColor = [UIColor greenColor].CGColor;
        [reader.readerView addSubview:trackView];
        [trackView release];
        
        ZBarImageScanner *scanner = reader.scanner;
        //[scanner setSymbology:0 config:ZBAR_CFG_ENABLE to: 0];
        //[scanner setSymbology:ZBAR_EAN13 config:ZBAR_CFG_ENABLE to: 1];
        //[scanner setSymbology: ZBAR_CODE128 config: ZBAR_CFG_ENABLE to: 1];
        [scanner setSymbology:ZBAR_I25 config:ZBAR_CFG_ENABLE to:0];
        //[scanner setSymbology:ZBAR_QRCODE config:ZBAR_CFG_ENABLE to:0];
    }
    
    // present and release the controller
    [self presentModalViewController:reader animated:YES];
    [self orientationDidChange:nil];
}

- (void)orientationDidChange:(NSNotification *)note
{
    if (reader == nil) return;
    
    CGSize readerViewSize = reader.readerView.frame.size;
    CGFloat y = trackView.frame.origin.y;
    CGFloat height = trackView.frame.size.height;
    //NSLog(@"%f, %f, %f", readerViewSize.height, y, height);
    
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        reader.readerView.scanCrop = CGRectMake(0, y / readerViewSize.height, 1, height / readerViewSize.height);
        //NSLog(@"Landscape: %f, %f", reader.readerView.scanCrop.origin.y, reader.readerView.scanCrop.size.height);
    }
    else {
        reader.readerView.scanCrop = CGRectMake(y / readerViewSize.height, 0, height / readerViewSize.height, 1);
        //NSLog(@"Portrait: %f, %f", reader.readerView.scanCrop.origin.x, reader.readerView.scanCrop.size.width);
    }
}

- (void)imagePickerController:(UIImagePickerController*)readerVC didFinishPickingMediaWithInfo: (NSDictionary*) info
{
    // ADD: get the decode results
    id<NSFastEnumeration> results = [info objectForKey: ZBarReaderControllerResults];
    NSString *serialNumber = nil;
    for (ZBarSymbol *symbol in results) {
        if ([PCUtilityStringOperate checkValidSerialNumber:symbol.data]) {
            serialNumber = symbol.data;
            break;
        }
    }
    
    if (serialNumber == nil) {
        //[PCUtility showTip:@"扫描到的条形码不是泡泡云盒子的S/N码"];
        return;
    }
    
    self.textFieldScanResult.text = serialNumber;
    self.textFieldSerialNumber.text = nil;
    self.buttonActivate.enabled = YES;
    
    // ADD: dismiss the controller (NB dismiss from the *reader*!)
    [reader dismissModalViewControllerAnimated:YES];
    [reader release];
    reader = nil;
}

- (IBAction)activateBtnClick:(id)sender {
    NSString *serialNumber = self.textFieldSerialNumber.text;
    if (serialNumber.length == 0) {
        serialNumber = self.textFieldScanResult.text;
        [MobClick event:UM_ACTIVATE_SCANNING];
    }
    else
    {
        [MobClick event:UM_ACTIVATE_INPUT];
    }
    
    if ([PCUtilityStringOperate checkValidSerialNumber:serialNumber] == NO) {
        [PCUtilityUiOperate showErrorAlert:@"输入错误，请检查～" delegate:nil];
        return;
    }
    
    [self.textFieldSerialNumber resignFirstResponder];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES afterDelay:0.1];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    if (deviceManagement == nil) {
        deviceManagement = [[PCDeviceManagement alloc] init];
        deviceManagement.delegate = self;
    }
    [deviceManagement bindBox:serialNumber];
}

#pragma mark - textField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.textFieldSerialNumber) {
        if (textField.text.length == 16) {
            [self activateBtnClick:nil];
        }
    }
    
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
{
    return range.location < 16;
}

- (void)textFiledDidChanged:(UITextField *)textField
{
    if ([textField.text rangeOfString:@" "].length>0) {
        NSString *tmp = [textField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
        textField.text = tmp;
    }
    self.buttonActivate.enabled = textField.text.length == 16 || (textField.text.length == 0 && self.textFieldScanResult.text.length > 0);
}

#pragma mark - PCDeviceManagementDelegate

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement boundBox:(DeviceInfo*)device
{
    //[PCLogin addDevice:device];
    //[[PCLogin sharedManager] logIn:self node:device];
    [[PCLogin sharedManager] getDevicesList:self];
    [MobClick event:UM_ACTIVATE_SUCCESS];
}

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement bindBoxFailedWithError:(NSError*)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    if ([error.domain isEqualToString:KTServerErrorDomain] && error.code == 1) {
        [ErrorHandler showAlert:PC_Err_InvalidSerialNumber];
    }
    else {
        [ErrorHandler showErrorAlert:error];
    }
}

#pragma mark - PCLoginDelegate

- (void)loginFail:(PCLogin*)pcLogin error:(NSString*)error
{
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [PCUtilityUiOperate showOKAlert:@"因网络的延时,绑定泡泡云盒子成功后到盒子显示在线,大概需要10S时延!" delegate:self];
}

- (void)loginFinish:(PCLogin*)pcLogin
{
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    BOOL online = NO;
    NSArray *allDevices = [PCLogin getAllDevices];
    if (allDevices.count > 0) {
        DeviceInfo *device = allDevices[0];
        online = device.online;
    }
    if (online) {
        [PCUtilityUiOperate showOKAlert:@"泡泡云盒子激活成功" delegate:self];
        //[self activateSucceed];
    }
    else {
        [PCUtilityUiOperate showOKAlert:@"因网络的延时,绑定泡泡云盒子成功后到盒子显示在线,大概需要10S时延!" delegate:self];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self activateSucceed];
}

- (void)activateSucceed {
    [[CameraUploadManager sharedManager] startCameraUpload];
    
    PCAppDelegate *appDelegate = (PCAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSArray *arrayView = appDelegate.tabbarContent.viewControllers;
    for (UINavigationController *nav in arrayView) {
        id<PCLogoutDelegate> delegate = [nav.viewControllers objectAtIndex:0];
        if ([(NSObject *)delegate respondsToSelector:@selector(logOut)])
        {
            [delegate logOut];
        }
        
        [nav popToRootViewControllerAnimated:NO];
    }
    [self.navigationController popToRootViewControllerAnimated:NO];
    [appDelegate loadTabBarController];
}

@end
