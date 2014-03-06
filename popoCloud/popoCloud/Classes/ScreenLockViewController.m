//
//  ScreenLockViewController.m
//  popoCloud
//
//  Created by ice on 13-11-18.
//
//

#import "ScreenLockViewController.h"
#import "LoginViewController.h"
#import "PCAppDelegate.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "ELCImagePickerController.h"
#import "ELCAssetTablePicker.h"
#import <MediaPlayer/MediaPlayer.h>
#import "FileDownloadManagerViewController.h"
#import "LoginViewController.h"
#import "FileListViewController.h"

#define NAVTAG 11111
#define MAXTEXTLENGHT 14
#define DelayTime   0.05
@interface ScreenLockViewController ()

@end

@implementation ScreenLockViewController
@synthesize num1,num2,num3,num4;
@synthesize lockType;
@synthesize desLabel1,desLabel2,titleLabel;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"应用锁屏密码设置";
        isShow = NO;
    }
    return self;
}
-(BOOL)hasAlertWindow
{
    UIWindow *window = nil;
    if ([self isOnScreen] && IS_IPAD)
    {
        for (UIWindow *content in [UIApplication sharedApplication].windows)
        {
            if ([NSStringFromClass([content class]) isEqualToString:@"_UIAlertNormalizingOverlayWindow"])
            {
                window = content;
                break;
            }
        }
        if (window)
        {
            return YES;
        }
    }
    
    return NO;
}
-(void)resetNavFrame
{
    if ([self isOnScreen])
    {
        if ([self.view viewWithTag:NAVTAG])
        {
            UINavigationBar *nav = (UINavigationBar *)[self.view viewWithTag:NAVTAG];
            CGRect rect = nav.frame;
            if (!IS_IPAD) {
                if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                    rect.size.height = 32;
                }
                else
                {
                    rect.size.height = 44;
                }
                
            }
            rect.size.width = self.view.bounds.size.width;
            nav.frame = rect;
        }
    }
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
    screenLockField = [[UITextField alloc] initWithFrame:CGRectZero];
    [self.view addSubview:screenLockField];
    screenLockField.delegate = self;
    [screenLockField becomeFirstResponder];
    screenLockField.keyboardType = UIKeyboardTypeNumberPad;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenLockDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
    
    [self resetNumImage];
    numArray = [[NSMutableArray alloc] initWithObjects:num1,num2,num3,num4, nil];
    if (lockType == ScreenLockTypeReStore)
    {
        CGRect titleRect = self.titleLabel.frame;
        titleRect.origin.y+=44;
        self.titleLabel.frame = titleRect;
        for (int i=0; i<4; i++)
        {
            UITextField *filed =(UITextField *)[numArray objectAtIndex:i];
            CGRect rect = filed.frame;
            rect.origin.y+=44;
            filed.frame = rect;
            
        }
    }
}
-(void)clearInput
{
    screenLockField.text = @"";
    num1.text = @"";
    num2.text = @"";
    num3.text = @"";
    num4.text = @"";
    [screenLockField becomeFirstResponder];
}
-(void)resetNumImage
{
    screenLockField.text = @"";
    num1.text = @"";
    num2.text = @"";
    num3.text = @"";
    num4.text = @"";
}
-(void)showTip:(NSString *)msg
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if ([self isOnScreen] && IS_IPAD)
    {
        for (UIWindow *content in [UIApplication sharedApplication].windows)
        {
            if ([NSStringFromClass([content class]) isEqualToString:@"_UIAlertNormalizingOverlayWindow"])
            {
                window = content;
            }
        }
    }
    BOOL multi = NO;
    if (!IS_IPAD)
    {
        if (msg.length > MAXTEXTLENGHT)
        {
            multi = YES;
        }
    }
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    if (!hud || (hud.mode !=MBProgressHUDModeText))
    {
        hud = [MBProgressHUD showHUDAddedTo:self.view
                                       text:msg
                            showImmediately:YES
                                isMultiline:multi];
    }
    else
    {
        [hud show:YES];
        hud.labelText = msg;
        
    }
    UIFont *font = [UIFont systemFontOfSize:20];
    hud.labelFont = font;
    if (self.navigationController) {
        if (IS_IPAD && UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            [hud setYOffset:-44];
        }
    }
    if (!IS_IPAD)
    {
        [hud setYOffset:-44];
    }
    hud.mode = MBProgressHUDModeText;
    hud.userInteractionEnabled = NO;
    hud.margin = 5.f;
    [hud hide:YES afterDelay:1];
}
- (BOOL)CheckInput:(NSString *)string {
    
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
    
}
-(void)showLoginView
{
    if ([screenLockField.text isEqualToString:[[PCSettings sharedSettings] screenLockValue]])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ScreenLockCorrect" object:nil];
        
        LoginViewController * loginVC = [[[LoginViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"LoginView"] bundle:nil] autorelease];
        UINavigationController2 *loginNav = [[[UINavigationController2 alloc] initWithRootViewController:loginVC] autorelease];
        PCAppDelegate *app = (PCAppDelegate *)[[UIApplication sharedApplication] delegate];
        app.window.rootViewController = loginNav;
        screenLockField.text = @"";
    }
    else
    {
        [self showTip:@"输入不正确，请重新输入。"];
        [self resetNumImage];
    }
}
-(void)showInputAgainView
{
    screenLockStr = [[NSString alloc] initWithString:screenLockField.text];
    titleLabel.text = @"再次输入4位数字密码";
    [self resetNumImage];
    [self showTip:@"请再次输入锁屏密码"];
}
-(void)showSetScreenLockView
{
    if ([screenLockField.text isEqualToString:screenLockStr])
    {
        [[PCSettings sharedSettings] setScreenLock:YES];
        [[PCSettings sharedSettings] setScreenLockValue:screenLockStr];
        DLogInfo(@"开启应用锁屏密码");
        [PCUtilityUiOperate showTip:@"应用锁屏密码设置完成"];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        [self showTip:@"首次输入密码和再次输入密码不一致，请重新输入。"];
        if (screenLockStr)
        {
            [screenLockStr release];
            screenLockStr = nil;
        }
        titleLabel.text = @"输入4位数字密码";
        [self resetNumImage];
    }
}
-(void)layOutController
{
    PCAppDelegate *app = (PCAppDelegate *)[UIApplication sharedApplication].delegate;
    UINavigationController2 *nav = nil;
    if ([app.window.rootViewController isKindOfClass:[UITabBarController2 class]])
    {
        nav = (UINavigationController2 *)((UITabBarController2 *)app.window.rootViewController).selectedViewController;
    }
    else
    {
        nav = (UINavigationController2 *)app.window.rootViewController;
    }
    // 修改bug 1705
//    if (![nav.topViewController isKindOfClass:[LoginViewController class]])//为了使页面重新布局一下
//    {
//        [nav.topViewController.navigationController setNavigationBarHidden:YES];
//        [nav.topViewController.navigationController setNavigationBarHidden:NO];
//    }
}
-(void)showEnterAppView
{
    if ([screenLockField.text isEqualToString:[[PCSettings sharedSettings] screenLockValue]])
    {
        isShow = NO;
        if (shouldRotate) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldSetNavFrame" object:nil];
        }
        shouldRotate = NO;
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ScreenLockCorrect" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                                        name: UIApplicationDidChangeStatusBarOrientationNotification
                                                      object: nil];
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                                        name: UIApplicationDidChangeStatusBarFrameNotification
                                                      object: nil];
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                                        name: UIApplicationDidBecomeActiveNotification
                                                      object: nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPMoviePlayerPlaybackDidFinishNotification
                                                      object:nil];
        self.view.transform = CGAffineTransformIdentity;
        [self.view removeFromSuperview];
        if (self.navigationController)
        {
            if ([self.navigationController.topViewController isKindOfClass:[self class]])
            {
                [self.navigationController popViewControllerAnimated:NO];
            }
        }
        [self removeFromParentViewController];
        screenLockField.text = @"";
        [self layOutController];
    }
    else
    {
        [self showTip:@"输入不正确，请重新输入。"];
        [self resetNumImage];
    }
}
-(void)screenLockDidChange:(NSNotification *)noti
{
    if (!screenLockField.text) {
        return;
    }
    if (screenLockField.text.length == 0)
    {
        num1.text = @"";
        num2.text = @"";
        num3.text = @"";
        num4.text = @"";
        return;
    }
    if (![self CheckInput:screenLockField.text])
    {
        [self showTip:@"输入不正确，请输入4位数字。"];
        [self resetNumImage];
        return;
    }
    if (screenLockField.text.length > 4)
    {
        screenLockField.text = [screenLockField.text substringToIndex:4];
        return;
    }
    
    for (NSInteger i = 0; i < screenLockField.text.length; i++)
    {
        UITextField *textField = [numArray objectAtIndex:i];
        textField.text = [screenLockField.text substringWithRange:NSMakeRange(i,1)];
    }
    for (NSInteger i = screenLockField.text.length; i < 4; i++)
    {
        UITextField *textField = [numArray objectAtIndex:i];
        textField.text = @"";
    }
    
    if (lockType == ScreenLockTypeEnter)
    {
        if (screenLockField.text.length == 4)
        {
            [self performSelector:@selector(showLoginView) withObject:nil afterDelay:DelayTime];
        }
        return;
    }
    if (lockType == ScreenLockTypeReStore)
    {
        if (screenLockField.text.length == 4)
        {
            [self performSelector:@selector(showEnterAppView) withObject:nil afterDelay:DelayTime];
        }
        
        return;
    }
    if (screenLockField.text.length == 4 && !screenLockStr)
    {
        [self performSelector:@selector(showInputAgainView) withObject:nil afterDelay:DelayTime];
    }
    if (screenLockStr && screenLockField.text.length == 4)
    {
        [self performSelector:@selector(showSetScreenLockView) withObject:nil afterDelay:DelayTime];
    }
}
-(void)hideDesLabel
{
    self.desLabel1.hidden = YES;
    self.desLabel2.hidden = YES;
}
-(void)viewWillDisappear:(BOOL)animated
{
    screenLockField.delegate = nil;
    [super viewWillDisappear:animated];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (IS_IPAD) {
        UIEdgeInsets inset = UIEdgeInsetsMake(10, 10, 10, 10);
        UIImage *image = [[UIImage imageNamed:@"screenlock_input_bg"] resizableImageWithCapInsets:inset];
        self.num1.background = image;
        self.num2.background = image;
        self.num3.background = image;
        self.num4.background = image;
    }
    [self resetNumImage];
    [screenLockField becomeFirstResponder];
    screenLockField.delegate = self;
    if (lockType == ScreenLockTypeEnter)
    {
        self.title = @"输入泡泡云锁屏密码";
        [self hideDesLabel];
    }
    if (lockType == ScreenLockTypeReStore)
    {
        [self hideDesLabel];
        CGRect windowRect = [UIScreen mainScreen].bounds;
        windowRect.origin.y = 20;
        self.view.frame = windowRect;
        CGFloat w = [UIScreen mainScreen].bounds.size.width;
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
        {
            w = [UIScreen mainScreen].bounds.size.height;
        }
        if ([self.view viewWithTag:NAVTAG])
        {
            UINavigationBar *nav = (UINavigationBar *)[self.view viewWithTag:NAVTAG];
            CGRect rect = nav.frame;
            if (rect.size.width != w)
            {
                rect.size.width = w;
                nav.frame = rect;
            }
            
        }
        else
        {
            UINavigationBar *nav = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, w, 44)];
            if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && !IS_IPAD)
            {
                CGRect re = nav.frame;
                re.size.height = 32;
            }
            nav.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            nav.translucent = NO;
            if (IS_IOS7)
            {
                nav.barTintColor = [UIColor colorWithRed:0 green:144 / 255.0 blue:211 / 255.0 alpha:1];
                nav.tintColor = [UIColor whiteColor];
                nav.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor];
            }
            nav.tag = NAVTAG;
            UINavigationItem *titlte = [[UINavigationItem alloc] initWithTitle:@"输入泡泡云锁屏密码"];
            [nav setItems:[NSArray arrayWithObject:titlte]];
            [self.view addSubview:nav];
            [titlte release];
            [nav release];
        }
        
    }
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self isOnScreen])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    }
    if (IS_IPAD) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    }
    [self hasAlertWindow];
    [self resetNavFrame];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    self.num1 = nil;
    self.num2 = nil;
    self.num3 = nil;
    self.num4 = nil;
    self.desLabel1 = nil;
    self.desLabel2 = nil;
    self.titleLabel = nil;
}
-(void)dealloc
{
    if (screenLockStr)
    {
        [screenLockStr release];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [numArray removeAllObjects];
    [numArray release];
    self.num1 = nil;
    self.num2 = nil;
    self.num3 = nil;
    self.num4 = nil;
    self.desLabel1 = nil;
    self.desLabel2 = nil;
    self.titleLabel = nil;
    [screenLockField release];
    [super dealloc];
}
+(ScreenLockViewController *)sharedLock
{
    __strong static ScreenLockViewController *sharedObject = nil;
	
	if (sharedObject != nil) {
		return sharedObject;
	}
	
	static dispatch_once_t pred;
	dispatch_once(&pred, ^{
		sharedObject = [[ScreenLockViewController alloc] initWithNibName:@"ScreenLockViewController" bundle:nil]; // or some other init method
	});
	
	return sharedObject;
}
- (BOOL)shouldAutorotate
{
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations
{
	if (IS_IPAD)
        return UIInterfaceOrientationMaskAll;
    else
    {
        if (shouldRotate)
        {
            return UIInterfaceOrientationMaskAll;
        }
    }
	return UIInterfaceOrientationPortraitUpsideDown;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (!IS_IPAD)
    {
        if (shouldRotate)
        {
            return YES;
        }
    }
    return (IS_IPAD || (interfaceOrientation == UIInterfaceOrientationPortrait));
}
-(BOOL)isOnScreen
{
    return isShow;
}
+(void)show
{
    PCAppDelegate *app = (PCAppDelegate *)[UIApplication sharedApplication].delegate;
    if ([app.window.rootViewController isKindOfClass:[UINavigationController2 class]])
    {
        if ([((UINavigationController2*)app.window.rootViewController).topViewController isKindOfClass:[ScreenLockViewController class]]) {
            return;
        }
    }
    ScreenLockViewController *con = [ScreenLockViewController sharedLock];
    if ([con isOnScreen])
    {
        [con clearInput];
        return;
    }
    con.lockType = ScreenLockTypeReStore;
    [con show];
}

-(void)show
{
    isShow = YES;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    for (UIWindow *content in [UIApplication sharedApplication].windows)
    {
        if ([NSStringFromClass([content class]) isEqualToString:@"_UIAlertNormalizingOverlayWindow"])
        {
            window = content;
        }
    }
    [window addSubview:self.view];
    [window.rootViewController addChildViewController:self];
    PCAppDelegate *app = (PCAppDelegate *)[UIApplication sharedApplication].delegate;
    UINavigationController2 *nav = nil;
    if ([app.window.rootViewController isKindOfClass:[UITabBarController2 class]])
    {
        nav = (UINavigationController2*)((UITabBarController2*)app.window.rootViewController).selectedViewController;
    }
    else
    {
        nav = (UINavigationController2*)app.window.rootViewController;
    }
    if (nav.topViewController.modalViewController && !IS_IPAD) {
        if (![nav.topViewController.modalViewController isKindOfClass:[ELCImagePickerController class]])
        {
            shouldRotate = YES;
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
        }
        
    }
    if ([[nav topViewController] isKindOfClass:[KTPhotoScrollViewController class]] && !IS_IPAD)
    {
        shouldRotate = YES;
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarFrameOrOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarFrameOrOrientationChanged:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}
-(void)reShowScreenLock
{
    [screenLockField resignFirstResponder];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    [ScreenLockViewController show];
}
- (void) playerPlaybackDidFinish:(NSNotification*) aNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:nil];
    if (isShow)
    {
        isShow = NO;
        [self performSelector:@selector(reShowScreenLock) withObject:nil afterDelay:.05];
    }
}

-(void)appActive
{
    if ([self isOnScreen] && IS_IPAD)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    }
    [self hasAlertWindow];
    [self resetNavFrame];
    [self resetNumImage];
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.text.length>=1 && string) {
        return YES;
    }
    if (string) {
        if (string.length > 0) {
            return YES;
        }
        else
            return NO;
    }
    else
        return NO;
}
-(BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return !isShow;
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![screenLockField isFirstResponder]) {
        [screenLockField becomeFirstResponder];
    }
}



// All of the rotation handling is thanks to Håvard Fossli's ( https://github.com/hfossli )
// answer: http://stackoverflow.com/a/4960988/793916
#pragma mark - Handling rotation
- (void)statusBarFrameOrOrientationChanged:(NSNotification *)notification
{
    [self resetNavFrame];
    [self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
}
// And to his AGWindowView ( https://github.com/hfossli/AGWindowView )
// Without the 'desiredOrientation' method, using showLockscreen in one orientation,
// then presenting it inside a modal in another orientation would display the view in the first orientation.
- (UIInterfaceOrientation)desiredOrientation {
    UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    UIInterfaceOrientationMask statusBarOrientationAsMask = UIInterfaceOrientationMaskFromOrientation(statusBarOrientation);
    if(self.supportedInterfaceOrientations & statusBarOrientationAsMask) {
        return statusBarOrientation;
    }
    else {
        if(self.supportedInterfaceOrientations & UIInterfaceOrientationMaskPortrait) {
            return UIInterfaceOrientationPortrait;
        }
        else if(self.supportedInterfaceOrientations & UIInterfaceOrientationMaskLandscapeLeft) {
            return UIInterfaceOrientationLandscapeLeft;
        }
        else if(self.supportedInterfaceOrientations & UIInterfaceOrientationMaskLandscapeRight) {
            return UIInterfaceOrientationLandscapeRight;
        }
        else {
            return UIInterfaceOrientationPortraitUpsideDown;
        }
    }
}


- (void)rotateAccordingToStatusBarOrientationAndSupportedOrientations {
	UIInterfaceOrientation orientation = [self desiredOrientation];
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    CGFloat angle = UIInterfaceOrientationAngleOfOrientation(orientation);
    CGFloat statusBarHeight = [[self class] getStatusBarHeight];
	
    CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGRect frame = [[self class] rectInWindowBounds: bounds
							   statusBarOrientation: statusBarOrientation
									statusBarHeight: statusBarHeight];
	
    [self setIfNotEqualTransform:transform frame:frame];
}


- (void)setIfNotEqualTransform:(CGAffineTransform)transform frame:(CGRect)frame
{
    if ([self hasAlertWindow]) {
        return;
    }
    if(!CGAffineTransformEqualToTransform(self.view.transform, transform))
    {
        self.view.transform = transform;
    }
    if(!CGRectEqualToRect(self.view.frame, frame))
    {
        self.view.frame = frame;
    }
}


+ (CGFloat)getStatusBarHeight {
    if (IS_IPAD) {
        return 20;
    }
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if(UIInterfaceOrientationIsLandscape(orientation)) {
        return [UIApplication sharedApplication].statusBarFrame.size.width;
    }
    else {
        return [UIApplication sharedApplication].statusBarFrame.size.height;
    }
}


+ (CGRect)rectInWindowBounds:(CGRect)windowBounds statusBarOrientation:(UIInterfaceOrientation)statusBarOrientation statusBarHeight:(CGFloat)statusBarHeight {
    CGRect frame = windowBounds;
    frame.origin.x += statusBarOrientation == UIInterfaceOrientationLandscapeLeft ? statusBarHeight : 0;
    frame.origin.y += statusBarOrientation == UIInterfaceOrientationPortrait ? statusBarHeight : 0;
    frame.size.width -= UIInterfaceOrientationIsLandscape(statusBarOrientation) ? statusBarHeight : 0;
    frame.size.height -= UIInterfaceOrientationIsPortrait(statusBarOrientation) ? statusBarHeight : 0;
    return frame;
}

CGFloat UIInterfaceOrientationAngleOfOrientation(UIInterfaceOrientation orientation);
UIInterfaceOrientationMask UIInterfaceOrientationMaskFromOrientation(UIInterfaceOrientation orientation);

CGFloat UIInterfaceOrientationAngleOfOrientation(UIInterfaceOrientation orientation)
{
    CGFloat angle;
    
    switch (orientation)
    {
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = -M_PI_2;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI_2;
            break;
        default:
            angle = 0.0;
            break;
    }
    
    return angle;
}

UIInterfaceOrientationMask UIInterfaceOrientationMaskFromOrientation(UIInterfaceOrientation orientation)
{
    return 1 << orientation;
}
@end
