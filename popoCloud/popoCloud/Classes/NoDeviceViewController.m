//
//  NoDeviceViewController.m
//  popoCloud
//
//  Created by public on 12-8-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//
#import "NoDeviceViewController.h"
#import "ActivateBoxViewController.h"
#import "FileFolderViewController.h"
#import "MobClick.h"
#import "PCAppDelegate.h"
@implementation NoDeviceViewController

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

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
    self.navigationItem.title = @"激活泡泡云盒子";
    
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = NSLocalizedString(@"ReturnBack", nil);
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    
    [self.buttonIgnore setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.buttonIgnore setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];
    
    [self.buttonActivate setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.buttonActivate setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self orientationDidChange:self.interfaceOrientation];
    
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"NoDeviceView"];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"NoDeviceView"];
}

- (void)viewDidUnload
{
    [self setButtonActivate:nil];
    [self setButtonIgnore:nil];
    [self setImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self orientationDidChange:interfaceOrientation];
}

- (void)orientationDidChange:(UIInterfaceOrientation)interfaceOrientation
{
    NSString *suffix;
    if (IS_IPAD) {
        if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            suffix = @"_l";
            self.buttonIgnore.frame = CGRectMake(124, 618, 380, 39);
            self.buttonActivate.frame = CGRectMake(520, 618, 380, 39);
        }
        else {
            suffix = @"";
            self.buttonIgnore.frame = CGRectMake(36, 857, 340, 39);
            self.buttonActivate.frame = CGRectMake(392, 857, 340, 39);
        }
    }
    else {
        if (IS_IPHONE5) {
            suffix = @"_phone5";
            self.buttonIgnore.frame = CGRectMake(6, 400, 140, 36);
            self.buttonActivate.frame = CGRectMake(174, 400, 140, 36);
        }
        else
            suffix = @"";
    }
    
    self.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"intro_4%@", suffix]];
}

- (void)backBtnClick:(id)sender
{
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

- (IBAction)ignoreBtnClick:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:NO];
    PCAppDelegate *app = (PCAppDelegate *)[UIApplication sharedApplication].delegate;
    [app loadTabBarController];
    [MobClick event:UM_ACTIVATE_LATER];
}

- (IBAction)activateBtnClick:(id)sender
{
    ActivateBoxViewController *vc = [[ActivateBoxViewController alloc] initWithNibName:@"ActivateBoxViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
    [MobClick event:UM_ACTIVATE_NOW];
}

@end
