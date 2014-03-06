//
//  SettingViewController.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-27.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "SettingViewController.h"
#import "PCAppDelegate.h"
#import "LoginViewController.h"
#import "AboutViewController.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "PCLogin.h"
#import "PCLogout.h"
#import "FileFolderViewController.h"
#import "ShareManagerViewController.h"
#import "CameraUploadSettingViewController.h"
#import "CameraUploadManager.h"
#import "AccountSettingViewController.h"
#import "ActivateBoxViewController.h"
#import "DeviceManageViewController.h"
#import "SettingPhotosPermissionViewController.h"
#import "FeedbackViewController.h"
#import "ContactBackUpViewController.h"
#import "UserHelpViewController.h"
#import "KKPasscodeViewController.h"
#import "ScreenLockViewController.h"

@implementation SettingViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super init];
    if (self) {
        // Custom initialization
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

- (void)dealloc
{
    [_tableView release];
    [super dealloc];
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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = @"返回";
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    [temporaryBarButtonItem release];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"SettingView"];
    [MobClick event:UM_SETTING];
    
    [self.tableView reloadData];
    
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [[PCLogin sharedManager] getDevicesList:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [[PCLogin sharedManager] cancel];
    
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"SettingView"];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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
    NSInteger result = 0;
    
    switch (section) {
        case 0:
        {
            //            NSInteger deviceCount = [[PCLogin getAllDevices] count];
            //            result = deviceCount > 1 ? deviceCount + 2 : 3;
            result = 3;
        }
            break;
            
        case 1:
            result = 3;
            break;
            
        case 2:
            result = 3;
            break;
            
        default:
            break;
    }
    
    return result;
}
/*
 - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
 NSString *title = nil;
 
 switch (section) {
 case 0:
 title = NSLocalizedString(@"Account",nil);
 break;
 
 case 1:
 title = NSLocalizedString(@"Devices",nil);
 break;
 
 case 2:
 title = NSLocalizedString(@"Contacts",nil);
 break;
 
 case 3:
 title = NSLocalizedString(@"Settings",nil);
 break;
 
 case 4:
 title = NSLocalizedString(@"About",nil);
 break;
 
 default:
 break;
 }
 
 return title;
 }
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1)
    {
        if (indexPath.row == 0)
        {
            static NSString *CellIdentifier = @"CellCameraUpload";
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil)
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
                cell.imageView.image = [UIImage imageNamed:@"icon_4"];
                cell.textLabel.text = NSLocalizedString(@"Camera Upload", nil);
                cell.detailTextLabel.text = NSLocalizedString(@"Auto upload photos to PopoBox using WiFi", nil);
                cell.detailTextLabel.font = [UIFont systemFontOfSize:10.0f];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                if (IS_IPAD) {
                    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                    [switchView addTarget:self action:@selector(cameraUploadSwitchStateChanged:) forControlEvents:UIControlEventValueChanged];
                    [switchView setOn:[[PCSettings sharedSettings] autoCameraUpload] animated:NO];
                    switchView.tag = 100;
                    cell.accessoryView = switchView;
                    [switchView release];
                }
                else {
                    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                    button.frame = CGRectMake(232, 4, 59, 21);
                    [button addTarget:self action:@selector(cameraUploadSwitchStateChanged:) forControlEvents:UIControlEventTouchUpInside];
                    [button setImage:[UIImage imageNamed:@"switch_on"] forState:UIControlStateSelected];
                    [button setImage:[UIImage imageNamed:@"switch_off"] forState:UIControlStateNormal];
                    button.selected = [[PCSettings sharedSettings] autoCameraUpload];
                    button.tag = 100;
                    [cell.contentView addSubview:button];
                }
            }
            else {
                UIView * switchView = [cell.contentView viewWithTag:100];
                if (IS_IPAD)
                    [(UISwitch *)switchView setOn:[[PCSettings sharedSettings] autoCameraUpload] animated:NO];
                else
                    [(UIButton *)switchView setSelected:[[PCSettings sharedSettings] autoCameraUpload]];
            }
            return cell;
        }
        else if (indexPath.row == 2)
        {
            UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
            cell.imageView.image = [UIImage imageNamed:@"lock_icon"];
            cell.textLabel.text = @"应用锁屏密码设置";
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (IS_IPAD)
            {
                UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                [switchView addTarget:self action:@selector(kkPasscodeSetting:) forControlEvents:UIControlEventValueChanged];
                [switchView setOn:[[PCSettings sharedSettings] screenLock] animated:NO];
                cell.accessoryView = switchView;
                [switchView release];
            }
            else
            {
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = CGRectMake(232, 2, 59, 40);
                [button addTarget:self action:@selector(kkPasscodeSetting:) forControlEvents:UIControlEventTouchUpInside];
                [button setImage:[UIImage imageNamed:@"switch_on"] forState:UIControlStateSelected];
                [button setImage:[UIImage imageNamed:@"switch_off"] forState:UIControlStateNormal];
                button.selected = [[PCSettings sharedSettings] screenLock];
                [cell.contentView addSubview:button];
            }
            return cell;
        }


    }
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
    }
    else
    {
        cell.textLabel.text = nil;
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.text = nil;
        cell.accessoryView = nil;
        UIView * subView = [cell.contentView viewWithTag:101];
        if (subView) [subView removeFromSuperview];
    }
    
    // Configure the cell...
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                cell.imageView.image = [UIImage imageNamed:@"icon_1"];
                cell.textLabel.text = NSLocalizedString(@"Account Management",nil);
                //cell.detailTextLabel.text = [[PCSettings sharedSettings] username];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                break;
                
            case 1:
                cell.imageView.image = [UIImage imageNamed:@"icon_2"];
                cell.textLabel.text = NSLocalizedString(@"Contacts Backup & Restore", nil);
                if ([PCLogin getResource]) {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                }
                else {
                    cell.textLabel.textColor = [UIColor grayColor];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
                break;
                
            case 2:
            {
                cell.imageView.image = [UIImage imageNamed:@"icon_3"];
                NSArray *allDevices = [PCLogin getAllDevices];
                if (allDevices == nil) {
                    cell.textLabel.text = @"加载设备失败！";
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    UIButton *reloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
                    reloadButton.frame = CGRectMake(0, 0, 40, 40);
                    [reloadButton setImage:[UIImage imageNamed:@"navigate_refresh"] forState:UIControlStateNormal];
                    [reloadButton addTarget:self action:@selector(reloadDevices:) forControlEvents:UIControlEventTouchUpInside];
                    cell.accessoryView = reloadButton;
                }
                else if (allDevices.count == 0) {
                    cell.textLabel.text = @"＋激活泡泡云盒子";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                }
                else {
                    DeviceInfo *device = allDevices[0];
                    cell.textLabel.text = device.nickName;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    
                    if (device.online) {
                        cell.detailTextLabel.text = @"在线";
                        cell.detailTextLabel.textColor = [UIColor greenColor];
                        if (cell.textLabel.frame.origin.x > 0 && [[PCLogin sharedManager] isNeedUpgrade])
                        {
                            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"new"]];
                            CGFloat x = cell.textLabel.frame.origin.x + [device.nickName sizeWithFont:cell.textLabel.font].width + 6;
                            imageView.frame = CGRectMake(x, cell.textLabel.frame.origin.y, imageView.frame.size.width, imageView.frame.size.height);
                            imageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
                            imageView.tag = 101;
                            [cell.contentView addSubview:imageView];
                            [imageView release];
                        }
                    }
                    else {
                        cell.detailTextLabel.text = @"离线";
                        cell.detailTextLabel.textColor = [UIColor grayColor];
                    }
                }
            }
                break;
                
            default:
            {
                NSArray *allDevices = [PCLogin getAllDevices];
                if (allDevices.count > indexPath.row - 2) {
                    DeviceInfo *device = allDevices[indexPath.row - 2];
                    cell.textLabel.text = device.nickName;
                    cell.imageView.image = [UIImage imageNamed:@"icon_3"];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    
                    if (device.online) {
                        cell.detailTextLabel.text = @"在线";
                        cell.detailTextLabel.textColor = [UIColor greenColor];
                    }
                    else {
                        cell.detailTextLabel.text = @"离线";
                        cell.detailTextLabel.textColor = [UIColor grayColor];
                    }
                }
            }
                break;
        }
    }
    else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 1:
                cell.imageView.image = [UIImage imageNamed:@"delete.png"];
                cell.textLabel.text = NSLocalizedString(@"MemeryClear", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                break;
                
            default:
                break;
        }
    }
    else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0:
                cell.imageView.image = [UIImage imageNamed:@"icon_5"];
                cell.textLabel.text = NSLocalizedString(@"Feedback", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                break;
                
            case 1:
                cell.imageView.image = [UIImage imageNamed:@"icon_6"];
                cell.textLabel.text = NSLocalizedString(@"Check new version", nil);
                cell.detailTextLabel.text = [NSString stringWithFormat:@"V%@",
                                             [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
                cell.detailTextLabel.textColor = [UIColor grayColor];
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                break;
                
            case 2:
                cell.imageView.image = [UIImage imageNamed:@"icon_7"];
                cell.textLabel.text = NSLocalizedString(@"UserHelp", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                break;
                
            default:
                break;
        }
    }
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark -

- (void)reloadDevices:(id)sender
{
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[PCLogin sharedManager] getDevicesList:self];
}

- (void) loginFail:(PCLogin*)pcLogin error:(NSString*)error
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [PCUtilityUiOperate showErrorAlert:error delegate:nil];
}

- (void) loginFinish:(PCLogin*)pcLogin
{
    [self.tableView reloadData];
    
    if ([PCLogin getResource]) {
        NSArray *allDevices = [PCLogin getAllDevices];
        DeviceInfo *device = allDevices[0];
        if (device.online) {
            [[CameraUploadManager sharedManager] startCameraUpload];
            
            float hardVersion = ceilf([device.hardwareVersion floatValue]);
            if (hardVersion >= 2) {
                [pcLogin getBoxNeedUpgrade:self];
                return;
            }
        }
    }
    
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)gotBoxNeedUpgrade:(BOOL)isNeed necessary:(BOOL)isNecessary
{
    [self.tableView reloadData];
    
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)getBoxNeedUpgradeFailedWithError:(NSError*)error
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [ErrorHandler showErrorAlert:error];
}

-(void)kkPasscodeSetting:(UISwitch *)switchControl
{
    if (![[PCSettings sharedSettings] screenLock])
    {
        if (IS_IPAD) {
            switchControl.on = NO;
        }
        else
        {
            ((UIButton *)switchControl).selected = NO;
        }
        ScreenLockViewController *code = [[ScreenLockViewController alloc] initWithNibName:@"ScreenLockViewController" bundle:nil];
        [self.navigationController pushViewController:code animated:YES];
        [code release];
    }
    else
    {
        DLogInfo(@"关闭应用锁屏密码");
        BOOL on;
        if (IS_IPAD) {
            on = ((UISwitch *)switchControl).on;
        }
        else {
            on = !((UIButton *)switchControl).selected;
            ((UIButton *)switchControl).selected = on;
        }

        [[PCSettings sharedSettings] setScreenLock:NO];
        [[PCSettings sharedSettings] setScreenLockValue:@""];
        [PCUtilityUiOperate showTip:@"应用锁屏密码已关闭"];
    }

}
- (void)cameraUploadSwitchStateChanged:(id)switchControl
{
    BOOL on;
    if (IS_IPAD) {
        on = ((UISwitch *)switchControl).on;
    }
    else {
        on = !((UIButton *)switchControl).selected;
        ((UIButton *)switchControl).selected = on;
    }
    
    if (on && [PCUtilityFileOperate  checkPrivacyForAlbum] == NO)
    {
        if (IS_IPAD) {
            [(UISwitch *)switchControl setOn:NO animated:NO];
        }
        else {
            ((UIButton *)switchControl).selected = NO;
        }
        
        SettingPhotosPermissionViewController *setPhotoPermission = [[SettingPhotosPermissionViewController alloc]
                                                                     initWithNibName:[PCUtilityFileOperate getXibName:@"SettingPhotosPermissionViewController"] bundle:nil];
        setPhotoPermission.showType = kShowWhenUpload;
        UINavigationController *navController = [[UINavigationController2 alloc] initWithRootViewController:setPhotoPermission];
        [self.navigationController presentViewController:navController animated:YES completion:NULL];
        [setPhotoPermission release];
        [navController release];
        return;
    }
    
    [[PCSettings sharedSettings] setAutoCameraUpload:on];
    
    if (on) {
        [MobClick event:UM_AUTO_UPLOAD_OPEN];
        [[CameraUploadManager sharedManager] setUseCellularData:NO];
        [[CameraUploadManager sharedManager] startCameraUpload];
    } else {
        [MobClick event:UM_AUTO_UPLOAD_CLOSE];
        [[CameraUploadManager sharedManager] stopCameraUpload];
    }
}

- (void)cleanCache
{
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //    NSString *documentsDirectory = [paths objectAtIndex:0];
    //    NSString *documentsDirectory = NSTemporaryDirectory();
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
    NSString *myDirectory = [NSString stringWithString:documentsDirectory];
    NSString *cacheDir = [myDirectory stringByAppendingPathComponent:@"/Caches"];
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:cacheDir error:&error];
    if (!success || error) {
        NSLog(@"Fail:removeCacheDirectory");
    }
    //数据库文件删除之后会引起crash
    //    PCAppDelegate *delegate = (PCAppDelegate *)[UIApplication sharedApplication].delegate;
    //    NSPersistentStoreCoordinator *coordinator = [delegate persistentStoreCoordinator];
    //    if (coordinator != nil)
    //    {
    //        NSArray *stores = [coordinator persistentStores];
    //
    //        for(NSPersistentStore *store in stores) {
    //            //[coordinator removePersistentStore:store error:nil];
    //            [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
    //        }
    //
    //    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            AccountSettingViewController *vc = [[AccountSettingViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:vc animated:YES];
            [vc release];
            [MobClick event:UM_ACCOUNT_SETTING];
        }
        else if (indexPath.row == 1) {
            if ([PCLogin getResource]) {
                ContactBackUpViewController *vc = [[[ContactBackUpViewController alloc] init] autorelease];
                [self.navigationController pushViewController:vc animated:YES];
            }
        }
        else if (indexPath.row == 2) {
            NSArray *allDevices = [PCLogin getAllDevices];
            if (allDevices == nil) {
            }
            else if (allDevices.count == 0) {
                [MobClick event:UM_SETTING_ACTIVATE];
                ActivateBoxViewController *vc = [[ActivateBoxViewController alloc] initWithNibName:@"ActivateBoxViewController" bundle:nil];
                [self.navigationController pushViewController:vc animated:YES];
                [vc release];
            }
            else {
                DeviceManageViewController *vc = [[DeviceManageViewController alloc] initWithStyle:UITableViewStyleGrouped];
                vc.device = allDevices[0];
                [self.navigationController pushViewController:vc animated:YES];
                [vc release];
            }
        }
        else {
            NSArray *allDevices = [PCLogin getAllDevices];
            if (allDevices.count > indexPath.row - 2) {
                DeviceManageViewController *vc = [[DeviceManageViewController alloc] initWithStyle:UITableViewStyleGrouped];
                vc.device = allDevices[indexPath.row - 2];
                [self.navigationController pushViewController:vc animated:YES];
                [vc release];
            }
        }
    }
    else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            FeedbackViewController *vc = [[[FeedbackViewController alloc] initWithNibName:@"FeedbackViewController" bundle:nil] autorelease];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if (indexPath.row == 1) {
            self.tabBarController.tabBar.userInteractionEnabled = NO;
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [[PCCheckUpdate sharedInstance] checkUpdate:self];
            [MobClick event:UM_CHECK_NEW_VERSION];
        }
        else if (indexPath.row == 2) {
            [MobClick event:UM_USER_HELP];
            UserHelpViewController *vc = [[[UserHelpViewController alloc] init] autorelease];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    else if (indexPath.section == 1)
    {
        if (indexPath.row == 1)
        {
            [MobClick event:UM_CACHE_CLEAR];
            if (IS_IPAD)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"确定删除缓存?" message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil)  otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                [alert show];
                [alert release];
            }
            else
            {
                UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"确定删除缓存?"
                                                                         delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
                actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
                [actionSheet showFromTabBar:self.tabBarController.tabBar];
                [actionSheet release];
            }
        }
        if (indexPath.row == 2)
        {
            NSLog(@"应用锁屏密码");
        }

    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) checkUpadteFinish:(PCCheckUpdate*)pcCheckUpdate isUpdate:(BOOL)isUpdate
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    
    if (!isUpdate) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"泡泡云版本"
                                                            message:@"您使用的是最新版本噢～"
                                                           delegate:nil
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    }
}

- (void) checkUpadteFailed:(PCCheckUpdate*)pcCheckUpdate withError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"NetNotReachableError", nil)
                                                       delegate:nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
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

#pragma mark -
#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// the user clicked one of the OK/Cancel buttons
	if (buttonIndex == 0)
	{
        FileCache* fileCache = [[FileCache alloc] init];
        [fileCache deleteCacheObjectsWithLimit:0];//
        [fileCache release];
        [self cleanCache];//删除本地的文件
        
        [PCUtilityUiOperate showTip:NSLocalizedString(@"清理成功!", nil)];
	}
}

#pragma mark -
#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex ==1)
    {
        FileCache* fileCache = [[FileCache alloc] init];
        [fileCache deleteCacheObjectsWithLimit:0];//
        [fileCache release];
        [self cleanCache];//删除本地的文件
        
        [PCUtilityUiOperate showTip:NSLocalizedString(@"清理成功!", nil)];
    }
}
@end
