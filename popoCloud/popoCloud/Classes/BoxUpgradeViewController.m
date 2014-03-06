//
//  BoxUpgradeViewController.m
//  popoCloud
//
//  Created by suleyu on 14-1-23.
//
//

#import "BoxUpgradeViewController.h"
#import "PCDeviceManagement.h"
#import "PCLogin.h"
#import "PCUtilityUiOperate.h"
#import "CameraUploadManager.h"
#import "PCAppDelegate.h"

@interface BoxUpgradeViewController () <PCDeviceManagementDelegate, PCLoginDelegate>
{
    PCDeviceManagement *deviceManagement;
}
@end

@implementation BoxUpgradeViewController
@synthesize isLogin;
@synthesize isForceUpgrade;
@synthesize currentSystemVersion;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"泡泡云系统版本升级";
    }
    return self;
}

- (void)dealloc {
    self.viewUpgrading = nil;
    self.indicator = nil;
    self.bgRemind = nil;
    self.viewSuccess = nil;
    self.labelSuccess = nil;
    self.btnSuccess = nil;
    self.viewFailed = nil;
    self.currentSystemVersion = nil;
    [deviceManagement release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.hidesBackButton = YES;
    
    self.bgRemind.image = [[UIImage imageNamed:@"bg_warning"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
    
    [self.btnSuccess setBackgroundImage:[[UIImage imageNamed:@"btn_a"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateNormal];
    [self.btnSuccess setBackgroundImage:[[UIImage imageNamed:@"btn_a_d"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateHighlighted];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
    self.viewUpgrading = nil;
    self.indicator = nil;
    self.bgRemind = nil;
    self.viewSuccess = nil;
    self.labelSuccess = nil;
    self.btnSuccess = nil;
    self.viewFailed = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSArray *allDevices = [PCLogin getAllDevices];
    DeviceInfo *device = allDevices[0];
    if (device.isUpgrading == NO) {
        if (deviceManagement == nil) {
            deviceManagement = [[PCDeviceManagement alloc] init];
            deviceManagement.delegate = self;
        }
        [deviceManagement upgradeBoxSystem];
    }
    else {
        [self performSelector:@selector(checkUpgradeResult) withObject:nil afterDelay:5.0f];
        [self performSelector:@selector(upgradeFailed) withObject:nil afterDelay:60*15.0f];
    }
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

#pragma mark -

- (IBAction)btnSuccessClicked:(id)sender
{
    if (isLogin || isForceUpgrade) {
        [[CameraUploadManager sharedManager] startCameraUpload];
        
        PCAppDelegate *app = (PCAppDelegate *)[UIApplication sharedApplication].delegate;
        [app loadTabBarController];
    }
    else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)upgradeFailed
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkUpgradeResult) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(upgradeFailed) object:nil];
    
    [[PCLogin sharedManager] cancel];
    
    if (isLogin) {
        [[CameraUploadManager sharedManager] startCameraUpload];
        
        PCAppDelegate *app = (PCAppDelegate *)[UIApplication sharedApplication].delegate;
        [app loadTabBarController];
    }
    else {
        self.navigationItem.hidesBackButton = NO;
        self.viewUpgrading.hidden = YES;
        self.viewSuccess.hidden = YES;
        self.viewFailed.hidden = NO;
    }
}

- (void)checkUpgradeResult
{
    [[PCLogin sharedManager] getDevicesList:self];
}

#pragma mark - PCDeviceManagementDelegate

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement upgradeBoxSystemWithError:(NSError*)error
{
    if (error) {
        if ([error.domain isEqualToString:NSURLErrorDomain]) {
            if (error.code != NSURLErrorTimedOut) {
                [self.indicator stopAnimating];
                [ErrorHandler showErrorAlert:error];
                return;
            }
            else if (self.currentSystemVersion && ![self.currentSystemVersion isEqualToString:@"1.5.2"] && ![self.currentSystemVersion isEqualToString:@"1.5.3"]) {
                [self upgradeFailed];
                [ErrorHandler showErrorAlert:error];
                return;
            }
        }
        else {
            [self upgradeFailed];
            [ErrorHandler showErrorAlert:error];
            return;
        }
    }
    
    [[PCLogin sharedManager] setIsNeedUpgrade:NO];
    [[PCLogin sharedManager] setIsNecessaryUpgrade:NO];
    
    [self performSelector:@selector(checkUpgradeResult) withObject:nil afterDelay:5.0f];
    [self performSelector:@selector(upgradeFailed) withObject:nil afterDelay:60*15.0f];
}

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement gotBoxSystemVersion:(NSString*)version
{
    if (self.currentSystemVersion && [self.currentSystemVersion isEqualToString:version]) {
        self.navigationItem.hidesBackButton = NO;
        self.viewUpgrading.hidden = YES;
        self.viewSuccess.hidden = YES;
        self.viewFailed.hidden = NO;
    }
    else {
        self.labelSuccess.text = [NSString stringWithFormat:@"安装完成，您已升级至泡泡云系统最新版本%@", version];
        self.viewUpgrading.hidden = YES;
        self.viewFailed.hidden = YES;
        self.viewSuccess.hidden = NO;
    }
}

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement getBoxSystemVersionFailedWithError:(NSError*)error
{
    self.viewUpgrading.hidden = YES;
    self.viewFailed.hidden = YES;
    self.viewSuccess.hidden = NO;
}

#pragma mark - PCLoginDelegate

- (void) loginFail:(PCLogin*)pcLogin error:(NSString*)error
{
    if ([error isEqualToString:NSLocalizedString(@"ConnetError", nil)]) {
        [self performSelector:@selector(checkUpgradeResult) withObject:nil afterDelay:5.0f];
        return;
    }
    
    if ([error isEqualToString:NSLocalizedString(@"NetNotReachableError", nil)] ||
        [error isEqualToString:NSLocalizedString(@"PasswordChanged", nil)]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(upgradeFailed) object:nil];
        [self.indicator stopAnimating];
    }
    else {
        [self upgradeFailed];
    }
    
    [PCUtilityUiOperate showErrorAlert:error delegate:nil];
}

- (void) loginFinish:(PCLogin*)pcLogin
{
    NSArray *allDevices = [PCLogin getAllDevices];
    if (allDevices.count > 0) {
        DeviceInfo *device = allDevices[0];
        if (device.isUpgrading) {
            [self performSelector:@selector(checkUpgradeResult) withObject:nil afterDelay:5.0f];
        }
        else if (isLogin) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(upgradeFailed) object:nil];
            
            [[CameraUploadManager sharedManager] startCameraUpload];
            
            PCAppDelegate *app = (PCAppDelegate *)[UIApplication sharedApplication].delegate;
            [app loadTabBarController];
        }
        else if (device.online) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(upgradeFailed) object:nil];
            
            if (deviceManagement == nil) {
                deviceManagement = [[PCDeviceManagement alloc] init];
                deviceManagement.delegate = self;
            }
            [deviceManagement getBoxSystemVersion];
        }
        else {
            [self upgradeFailed];
        }
    }
    else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(upgradeFailed) object:nil];
        [self.navigationController popToRootViewControllerAnimated:YES];
        [ErrorHandler showAlert:PC_Err_BoxUnbind];
    }
}

@end
