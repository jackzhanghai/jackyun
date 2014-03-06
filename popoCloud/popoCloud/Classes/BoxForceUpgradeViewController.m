//
//  BoxForceUpgradeViewController.m
//  popoCloud
//
//  Created by suleyu on 14-1-24.
//
//

#import "BoxForceUpgradeViewController.h"
#import "BoxUpgradeViewController.h"
#import "FileDownloadManagerViewController.h"
#import "PCUtilityFileOperate.h"
#import "PCAppDelegate.h"

@interface BoxForceUpgradeViewController ()

@end

@implementation BoxForceUpgradeViewController

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
    self.btnUpgrade = nil;
    self.bgRemind = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = @"返回";
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    [temporaryBarButtonItem release];
    
    [self.btnUpgrade setBackgroundImage:[[UIImage imageNamed:@"btn_a"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateNormal];
    [self.btnUpgrade setBackgroundImage:[[UIImage imageNamed:@"btn_a_d"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateHighlighted];
    
    self.bgRemind.image = [[UIImage imageNamed:@"bg_warning"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
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

- (IBAction)upgrade:(id)sender
{
    BoxUpgradeViewController *vc = [[BoxUpgradeViewController alloc] initWithNibName:@"BoxUpgradeViewController" bundle:nil];
    vc.isForceUpgrade = YES;
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

- (IBAction)viewDownloaded:(id)sender
{
    [[PCUtilityFileOperate downloadManager] loadOnlyDownloadedData];
    
    ((PCAppDelegate*)[[UIApplication sharedApplication] delegate]).bNetOffline = YES;
    
    FileDownloadManagerViewController *vc = [[FileDownloadManagerViewController alloc] initWithNibName:
                                             [PCUtilityFileOperate getXibName:@"FileDownloadManagerView"] bundle:nil];
    vc.title = NSLocalizedString(@"Collect", nil);
    NSMutableArray *array = [NSMutableArray arrayWithArray:[self.navigationController viewControllers]];
    [array replaceObjectAtIndex:array.count-1 withObject:vc];
    [self.navigationController setViewControllers:array animated:YES];
    [vc release];
}

@end
