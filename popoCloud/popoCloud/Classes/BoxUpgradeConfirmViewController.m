//
//  BoxUpgradeConfirmViewController.m
//  popoCloud
//
//  Created by suleyu on 14-1-23.
//
//

#import "BoxUpgradeConfirmViewController.h"
#import "BoxUpgradeViewController.h"

@interface BoxUpgradeConfirmViewController ()

@end

@implementation BoxUpgradeConfirmViewController
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
    self.btnCancel = nil;
    self.btnUpgrade = nil;
    self.bgRemind = nil;
    self.currentSystemVersion = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = @"返回";
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    [temporaryBarButtonItem release];
    
    [self.btnCancel setBackgroundImage:[[UIImage imageNamed:@"btn_a"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateNormal];
    [self.btnCancel setBackgroundImage:[[UIImage imageNamed:@"btn_a_d"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateHighlighted];
    [self.btnUpgrade setBackgroundImage:[[UIImage imageNamed:@"btn_a"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateNormal];
    [self.btnUpgrade setBackgroundImage:[[UIImage imageNamed:@"btn_a_d"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateHighlighted];
    
    self.bgRemind.image = [[UIImage imageNamed:@"bg_warning"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
    self.btnCancel = nil;
    self.btnUpgrade = nil;
    self.bgRemind = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)btnCancelClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)btnUpgradeClicked:(id)sender
{
    BoxUpgradeViewController *view = [[BoxUpgradeViewController alloc] initWithNibName:@"BoxUpgradeViewController" bundle:nil];
    view.currentSystemVersion = self.currentSystemVersion;
    [self.navigationController pushViewController:view animated:YES];
    [view release];
}


@end
