//
//  AccountSettingViewController.m
//  popoCloud
//
//  Created by suleyu on 13-5-29.
//
//

#import "AccountSettingViewController.h"
#import "DestroyAccountViewController.h"
#import "BindPhoneViewController.h"
#import "BindEmailViewController.h"
#import "UnbindPhoneViewController.h"
#import "UnbindEmailViewController.h"
#import "SecurityProtectionViewController.h"
#import "BindingReasonViewController.h"
#import "AboutViewController.h"
#import "RegisterProtocolViewController.h"
#import "SettingViewController.h"
#import "UIUnderlinedButton.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "PCUserInfo.h"
#import "ChangePasswordViewController.h"
#define  UNBIAND_EMAIL_ALERT_TAG      1
#define  UNBIAND_PHONE_ALERT_TAG    2
#define  QUIT_ALERT_TAG    3



@interface AccountSettingViewController ()
@property  (nonatomic, retain) UIAlertView *alert;
@end

@implementation AccountSettingViewController
@synthesize alert;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    self.title = @"泡泡云帐号设置";
    
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = @"返回";
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    [temporaryBarButtonItem release];
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    if (accountManagement == nil)
    {
        accountManagement = [[PCAccountManagement alloc] init];
        accountManagement.delegate = self;
    }
     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    //取得用户信息
    [accountManagement getUserInfo];
   
    [MobClick beginLogPageView:@"AccountSettingView"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [accountManagement cancelAllRequests];    
    [MobClick endLogPageView:@"AccountSettingView"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)dealloc
{
    [accountManagement release];
    [alert release];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSInteger number = 0;
    switch (section) {
        case 0:
            number = 5;
            break;
            
        case 1:
            number = 2;
            break;
            
        case 2:
            number = 1;
            break;
            
        default:
            break;
    }
    return number;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2) {
        static NSString *CellIdentifier = @"CellLogout";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            cell.backgroundView = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"btn_exit_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)]] autorelease];
            cell.selectedBackgroundView = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"btn_exit_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)]] autorelease];
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.textLabel.text = NSLocalizedString(@"Logout",nil);
        }
        return cell;
    }

    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UILabel *label;
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(90, 11, IS_IPAD ? 500 : 150, 20)];
        label.tag = 100;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:15.0];
        label.textColor = [UIColor colorWithRed:50.0/255.0 green:79.0/255.0 blue:133.0/255.0 alpha:1.0];
        [cell.contentView addSubview:label];
        [label release];
    }
    else {
        label = (UILabel *)[cell.contentView viewWithTag:100];
        cell.accessoryView = nil;
        cell.detailTextLabel.text = nil;
    }
    
    // Configure the cell...
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"泡泡云ID:";
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                label.text = [[PCUserInfo currentUser] userId];
                label.hidden = NO;
                
                if ([[PCLogin getAllDevices] count] == 0) {
                    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                    button.frame = IS_IPAD ? CGRectMake(200, 4, 70, 39) : CGRectMake(200, 4, 63, 36);
                    button.titleLabel.font = [UIFont systemFontOfSize:15.0];
                    [button setBackgroundImage:[[UIImage imageNamed:@"btn_a"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateNormal];
                    [button setBackgroundImage:[[UIImage imageNamed:@"btn_a_d"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateHighlighted];
                    
                    [button setTitle:@"清除帐号" forState:UIControlStateNormal];
                    [button addTarget:self action:@selector(destroyAccount:) forControlEvents:UIControlEventTouchUpInside];
                    cell.accessoryView = button;
                }
                break;
                
            case 1:
            {
                cell.textLabel.text = @"手　　机:";
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                label.hidden = NO;
                
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = IS_IPAD ? CGRectMake(200, 4, 70, 39) : CGRectMake(200, 4, 63, 36);
                button.titleLabel.font = [UIFont systemFontOfSize:15.0];
                [button setBackgroundImage:[[UIImage imageNamed:@"btn_a"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateNormal];
                [button setBackgroundImage:[[UIImage imageNamed:@"btn_a_d"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateHighlighted];
                
                if ([[[PCUserInfo currentUser] phone] length] > 0) {
                    label.text = [[PCUserInfo currentUser] phone];
                    [button setTitle:@"解除" forState:UIControlStateNormal];
                    [button addTarget:self action:@selector(unbindPhone) forControlEvents:UIControlEventTouchUpInside];
                }
                else {
                    label.text = @"未绑定";
                    [button setTitle:@"去绑定" forState:UIControlStateNormal];
                    [button addTarget:self action:@selector(bindPhone) forControlEvents:UIControlEventTouchUpInside];
                }
                
                cell.accessoryView = button;
            }
                break;
                
            case 2:
            {
                cell.textLabel.text = @"绑定邮箱:";
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                label.text = @"未绑定";
                label.hidden = NO;
                
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = IS_IPAD ? CGRectMake(200, 4, 70, 39) : CGRectMake(200, 4, 63, 36);
                button.titleLabel.font = [UIFont systemFontOfSize:15.0];
                [button setBackgroundImage:[[UIImage imageNamed:@"btn_a"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateNormal];
                [button setBackgroundImage:[[UIImage imageNamed:@"btn_a_d"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateHighlighted];
                
                if ([[[PCUserInfo currentUser] email] length] > 0) {
                    label.text = [[PCUserInfo currentUser] email];
                    
                    if ([[PCUserInfo currentUser] emailVerified]) {
                        [button setTitle:@"解除" forState:UIControlStateNormal];
                        [button addTarget:self action:@selector(unbindEmail) forControlEvents:UIControlEventTouchUpInside];
                    }
                    else {
                        [button setTitle:@"未验证" forState:UIControlStateNormal];
                        [button addTarget:self action:@selector(bindEmail) forControlEvents:UIControlEventTouchUpInside];
                    }
                }
                else {
                    label.text = @"未绑定";
                    [button setTitle:@"去绑定" forState:UIControlStateNormal];
                    [button addTarget:self action:@selector(bindEmail) forControlEvents:UIControlEventTouchUpInside];
                }
                
                cell.accessoryView = button;
            }
                break;
            
            case 3:
                cell.textLabel.text = @"修改密码";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                label.hidden = YES;
                break;
            case 4:
                cell.textLabel.text = @"安全问题设置";
                if ([[PCUserInfo currentUser] setSecurityQuestion]) {
                    cell.detailTextLabel.text = @"已提交";
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                }
                label.hidden = YES;
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == 1) {
        
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = NSLocalizedString(@"About", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                label.hidden = YES;
                break;
                
            case 1:
                cell.textLabel.text = NSLocalizedString(@"RegisterProtocol", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                label.hidden = YES;
                break;
                
            default:
                break;
        }
    }
    
    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == 0 ? @"(为什么要绑定邮箱/手机号？)" : nil;
}


#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 2 ? (IS_IPAD ? 37 : 34) : 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForFooterInSection:section];
    if (sectionTitle == nil) {
        return 0;
    }
    
    UIFont *font = [UIFont systemFontOfSize:15.0];
    CGSize labelSize = [sectionTitle sizeWithFont:font constrainedToSize:CGSizeMake(280, 480) lineBreakMode:NSLineBreakByWordWrapping];
    
    return labelSize.height + 15;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForFooterInSection:section];
    if (sectionTitle == nil) {
        return nil;
    }
    
    UIFont *font = [UIFont systemFontOfSize:15.0];
    CGSize labelSize = [sectionTitle sizeWithFont:font constrainedToSize:CGSizeMake(280, 480) lineBreakMode:NSLineBreakByWordWrapping];
    
    UIButton *button = [UIUnderlinedButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake((IS_IPAD ? 712 : 302) - labelSize.width - 10, 4, labelSize.width + 10, labelSize.height);
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    button.backgroundColor = [UIColor clearColor];
    button.titleLabel.font = font;
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button setTitle:sectionTitle forState:UIControlStateNormal];
    [button addTarget:self action:@selector(whyBind) forControlEvents:UIControlEventTouchUpInside];
    
    CGRect footerFrame = CGRectMake(0, 0, IS_IPAD ? 768 : 320, labelSize.height + 15);
    UIView * sectionView = [[[UIView alloc] initWithFrame:footerFrame] autorelease];
    sectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [sectionView addSubview:button];
    
    return sectionView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (indexPath.row == 3)
        {
            NSLog(@"修改密码");
            ChangePasswordViewController *change = [[ChangePasswordViewController alloc] initWithNibName:@"ChangePasswordViewController" bundle:nil];
            [self.navigationController pushViewController:change animated:YES];
            [change release];
        }
        if (indexPath.row == 4) {
            if ([[PCUserInfo currentUser] setSecurityQuestion] == NO) {
                [MobClick event:UM_SAFE_QUESTION];
                SecurityProtectionViewController *vc = [[SecurityProtectionViewController alloc] init];
                [self.navigationController pushViewController:vc animated:YES];
                [vc release];
            }
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            AboutViewController *aboutView = [[[AboutViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"AboutView"] bundle:nil] autorelease];
            [self.navigationController pushViewController:aboutView animated:YES];
        }
        else if (indexPath.row == 1) {
            RegisterProtocolViewController *licenseView = [[[RegisterProtocolViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"RegisterProtocolView"] bundle:nil] autorelease];
            [self.navigationController pushViewController:licenseView animated:YES];
        }
    }
    else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            UIAlertView *quitAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConfirmLogout", nil)
                                                                  message:nil
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                        otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
            quitAlert.tag = QUIT_ALERT_TAG;
            [quitAlert show];
            self.alert = quitAlert;
            [quitAlert release];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -

- (void)bindPhone
{
    [MobClick event:UM_BIND_PHONE];
    BindPhoneViewController *vc = [[BindPhoneViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

- (void)unbindPhone
{
    if ([[[PCUserInfo currentUser] email] length] == 0 || [[PCUserInfo currentUser] emailVerified] == NO) {
        [ErrorHandler showAlert:PC_Err_Unknown description:@"邮箱和手机号码至少保留一个"];
        return;
    }
    
    UIAlertView *unBindAlert = [[UIAlertView alloc] initWithTitle:@"确认要解绑该帐号吗？"
                                                        message:@"绑定是为了预防出现数据不安全时，即时通知您。如果解绑后，出现特殊情况时无法即时通知，泡泡云概不负责！"
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    unBindAlert.tag = UNBIAND_PHONE_ALERT_TAG;
    [unBindAlert show];
    self.alert = unBindAlert;
    [unBindAlert release];
}

- (void)bindEmail
{
    [MobClick event:UM_BIND_MAIL];
    BindEmailViewController *vc = [[BindEmailViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

- (void)unbindEmail
{
    if ([[[PCUserInfo currentUser] phone] length] == 0) {
        [ErrorHandler showAlert:PC_Err_Unknown description:@"邮箱和手机号码至少保留一个"];
        return;
    }
    UIAlertView *unBindAlert = [[UIAlertView alloc] initWithTitle:@"确认要解绑该帐号吗？"
                                                          message:@"绑定是为了预防出现数据不安全时，即时通知您。如果解绑后，出现特殊情况时无法即时通知，泡泡云概不负责！"
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    unBindAlert.tag = UNBIAND_EMAIL_ALERT_TAG;
    [unBindAlert show];
    self.alert = unBindAlert;
    [unBindAlert release];
}

- (void)whyBind
{
    BindingReasonViewController *vc = [[BindingReasonViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

- (void)destroyAccount:(UIButton *)sender
{
    DestroyAccountViewController *vc = [[DestroyAccountViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}
#pragma mark - PCAccountManagementDelegate
-(void)getUserInfoSuccess:(PCAccountManagement *)pcAccountManagement
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    //重新加载数据
    [self.tableView reloadData];
}
-(void)getUserInfoFailed:(PCAccountManagement *)pcAccountManagement withError:(NSError *)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    [ErrorHandler showErrorAlert:error];
    
    if (self.alert && [error.domain isEqualToString:KTServerErrorDomain] && error.code == 9) {
        [self.alert dismissWithClickedButtonIndex:self.alert.cancelButtonIndex animated:YES];
    }
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    self.alert = nil;
    if (buttonIndex == [alertView firstOtherButtonIndex]) {
        if (alertView.tag == QUIT_ALERT_TAG) {
            //fix bug 56118
            if (IS_IOS5)
            {
                [self.navigationController popViewControllerAnimated:YES];
            }
            [PCUtilityUiOperate logout];
        }
        else if(alertView.tag == UNBIAND_PHONE_ALERT_TAG)
        {
            UnbindPhoneViewController *vc = [[UnbindPhoneViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            [vc release];
            [MobClick event:UM_UNBIND_PHONE];
        }
        else if(alertView.tag == UNBIAND_EMAIL_ALERT_TAG)
        {
            UnbindEmailViewController *vc = [[UnbindEmailViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            [vc release];
            [MobClick event:UM_UNBIND_MAIL];
        }
    }
}

@end
