//
//  SettingPhotosPermissionViewController.m
//  popoCloud
//
//  Created by Kortide on 13-3-1.
//
//

#import "SettingPhotosPermissionViewController.h"
#import "PCUtility.h"

#define  ICON_TAG   4

@interface SettingPhotosPermissionViewController ()

@end

@implementation SettingPhotosPermissionViewController
@synthesize m_tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)backBtnClick:(id)sender
{
    switch (_showType) {
        case kShowStartUp:
            [self.navigationController popViewControllerAnimated:YES];
            break;
        case kShowWhenUpload:
            [self dismissViewControllerAnimated:YES completion:NULL];
            break;
        default:
            break;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:NO];
    float vComp = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (vComp  >= 6.0) {
        bISiOS6 = YES;
    }
    
     UILabel *headView =  [[UILabel alloc] initWithFrame:  CGRectZero];
    if (bISiOS6) {
        headView.text = @"为了能够上传你的图片，泡泡云需要开启系统相册功能";
    }
    else
    {
        headView.text = @"为了能够上传你的图片，泡泡云需要开启系统定位功能";
    }
    headView.backgroundColor = [UIColor clearColor];
    headView.numberOfLines = 0;

    if (IS_IPAD) {
        headView.font = [UIFont systemFontOfSize:20];
        headView.textAlignment = UITextAlignmentCenter;
        headView.frame = CGRectMake(30, 10, self.view.frame.size.width-60, 50);
    }
    else{
        headView.font = [UIFont boldSystemFontOfSize:15];
        headView.textAlignment = UITextAlignmentLeft;
        headView.frame = CGRectMake(20, 6, self.view.frame.size.width-40, 50);
    }

    headView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UIView *headViewContent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    [headViewContent addSubview:headView];
    headViewContent.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    headViewContent.backgroundColor = [UIColor clearColor];
    self.m_tableView.tableHeaderView = headViewContent;
    [headView release];
    [headViewContent release];
    
    self.navigationItem.title =  NSLocalizedString(@"Prompt", nil);
    
    if (_showType == kShowInPopover)
    {
        return;
    }
    
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    NSString *title = [NSString stringWithFormat:@" %@",appName];
    NSString *btnTitle = _showType == kShowStartUp ? title : NSLocalizedString(@"Cancel", nil);
    
    UIBarButtonItem *loginButton = [[UIBarButtonItem alloc] initWithTitle:btnTitle style:UIBarButtonItemStyleBordered target:self action:@selector(backBtnClick:)];
    
    if (_showType == kShowStartUp)
    {
        UIImage *btnBackPortrait = [[UIImage imageNamed:@"btn_back_13x5"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 13, 0, 5)];
        UIImage *btnBackLandscape = [[UIImage imageNamed:@"btn_back_11x5_l"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 11, 0, 5)];
        [loginButton setBackgroundImage:btnBackPortrait forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [loginButton setBackgroundImage:btnBackLandscape forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    }
    
    self.navigationItem.leftBarButtonItem = loginButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"SettingPhotosView"];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"SettingPhotosView"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    //self.navItem = nil;
    self.m_tableView = nil;
    [super dealloc];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (bISiOS6) {
        return 4;
    }
    else
    {
        return 3;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UIImageView *imageV = [[UIImageView alloc] initWithFrame:CGRectMake(30, 7, 30, 30)];
        [cell.textLabel addSubview:imageV];
        imageV.tag = ICON_TAG;
        [imageV release];
    }
    
    cell.detailTextLabel.text = nil;
    UIImageView *iconView = (UIImageView*)[cell.textLabel viewWithTag:ICON_TAG];
    // Configure the cell...
    switch (indexPath.row) {
            case 0:
            {
                 cell.textLabel.text = NSLocalizedString(@"Go to Settings", nil);
                iconView.image = [UIImage imageNamed:@"settings.png"];
            }
                break;
            case 1:
            {
                if (bISiOS6) {
                    cell.textLabel.text = NSLocalizedString(@"Go to Privacy", nil);
                    iconView.image = [UIImage imageNamed:@"privacy.png"];
                }
                else
                {
                    cell.textLabel.text = NSLocalizedString(@"Go to Location Services", nil);
                    iconView.image = [UIImage imageNamed:@"location.png"];
                }
            }
                break;
            case 2:
            {
                if (bISiOS6) {
                    cell.textLabel.text = NSLocalizedString(@"Go to Photos", nil);
                    iconView.image = [UIImage imageNamed:@"photos.png"];
                }
                else
                {
                    cell.textLabel.text = NSLocalizedString(@"3Enable PopCloud", nil);
                    iconView.image = [UIImage imageNamed:@"enable.png"];
                }

            }
            break;
           case 3:
            {
                cell.textLabel.text = NSLocalizedString(@"4Enable PopCloud", nil);
                iconView.image = [UIImage imageNamed:@"enable.png"];
            }
            break;

            default:
                break;
    }
    return cell;
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

@end
