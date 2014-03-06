//
//  DeviceManageViewController.m
//  popoCloud
//
//  Created by suleyu on 13-5-30.
//
//

#import "DeviceManageViewController.h"
#import "UnbindBoxViewController.h"
#import "CameraUploadManager.h"
#import "PCUtility.h"
#import "PCUtilityUiOperate.h"
#import "BoxUpgradeConfirmViewController.h"
#import "NetPenetrate.h"

#define RENAME_TAG 123

#define TABLE_FOOT_BTN_TAG1 1
#define TABLE_FOOT_BTN_TAG2 2
#define TABLE_FOOT_BTN_TAG3 3
#define TABLE_FOOT_BTN_TAG4 4

#define POP_USB_ALERT_TAG  5
#define RESTART_ALERT_TAG  6


@interface DeviceManageViewController ()
@property (copy, nonatomic) NSString *systemVersion;
@end

@implementation DeviceManageViewController
@synthesize device;
@synthesize systemVersion;
@synthesize currentRequest;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.title = @"设备管理";
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}


//获取磁盘空间
- (void) getFolderSize
{
    if (restClient == nil) {
        restClient = [[PCRestClient alloc] init];
        restClient.delegate = self;
    }

    self.currentRequest = [restClient getAllDiskSpaceInfoWithServerAddr: [[NetPenetrate sharedInstance] defaultHubUrl]];
}

- (void)timerAction:(NSTimer*)time
{
//    //获取设备列表
//    if (deviceManagement == nil) {
//        deviceManagement = [[PCDeviceManagement alloc] init];
//        deviceManagement.delegate = self;
//    }
//   [deviceManagement getDeviceList];
    bRestarting = YES;
    [self getFolderSize];
}

- (void)requestDidGotShutdownDisk:(KTURLRequest *)request
{
    [self removeLoadingView];
    if (request.error) {
        if ([request.error.domain isEqualToString:NSURLErrorDomain] ) {
            [ErrorHandler showErrorAlert:request.error];
        }
        else {
            [PCUtilityUiOperate showOKAlert:@"弹出硬盘失败!" delegate:nil];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                [PCUtilityUiOperate showOKAlert:@"弹出硬盘成功!" delegate:nil];
                [self popUsbEnable:NO];
            }
            else {
//                if ([dict objectForKey:@"errCode"]) {
//                    result = [[dict objectForKey:@"errCode"] intValue];
//                }
//                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
//                [ErrorHandler showErrorAlert:error];
                
                [PCUtilityUiOperate showOKAlert:@"弹出硬盘失败!" delegate:nil];
            }
        }
        else {
//            NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
//            [ErrorHandler showErrorAlert:error];
            
            [PCUtilityUiOperate showOKAlert:@"弹出硬盘失败!" delegate:nil];
        }
    }
}

- (void)requestDidGotRestart:(KTURLRequest *)request
{
    if (request.error) {
        if ([request.error.domain isEqualToString:NSURLErrorDomain] && request.error.code == NSURLErrorTimedOut) {
            restartTime = [[NSDate date]  timeIntervalSince1970];
            [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerAction:) userInfo:nil repeats:NO];
        }
        else{
            [ErrorHandler showErrorAlert:request.error];
            [self removeLoadingView];
        }
    } else {
        [self removeLoadingView];
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
            }
            else {
                if ([dict objectForKey:@"errCode"]) {
                    result = [[dict objectForKey:@"errCode"] intValue];
                }
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                [ErrorHandler showErrorAlert:error];
                if(result ==20)
                {
                    [self RestartEnable:NO];
                    [self popUsbEnable:NO];
                }
            }
        }
        else {
            NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
             [ErrorHandler showErrorAlert:error];
        }
    }
}

- (void)reStartButtonClick:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:@"确定要立即重启泡泡云盒子?"
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    alert.tag = RESTART_ALERT_TAG;
    [alert show];
    [alert release];
}

- (void)popUSBButtonClick:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:@"确定弹出盒子连接的硬盘?"
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    alert.tag = POP_USB_ALERT_TAG;
    [alert show];
    [alert release];
}

- (void)createTableFooter
{
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 10, 0, 10);
    UIImage  *image = [[UIImage imageNamed:@"btn_n.png"] resizableImageWithCapInsets:insets];
    
    UIImage  *disAbleImage = [[UIImage imageNamed:@"btn_dis.png"] resizableImageWithCapInsets:insets];
    
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 60)];
    bgView.backgroundColor = [UIColor clearColor];
    UIButton *reStartButton1 = [[[UIButton alloc] initWithFrame:CGRectMake(10, 15, 145,45)] autorelease];
    [reStartButton1 setTitle:@"一键重启盒子" forState:UIControlStateNormal];
    reStartButton1.tag =  TABLE_FOOT_BTN_TAG1;
    [reStartButton1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [reStartButton1.titleLabel setFont:[UIFont systemFontOfSize:12]];
    
    [reStartButton1 setTitleEdgeInsets:UIEdgeInsetsMake(0,32,0.0,0.0)];
    [reStartButton1 setBackgroundImage:image forState:UIControlStateNormal];
    [reStartButton1 setBackgroundImage:disAbleImage forState:UIControlStateDisabled];

    
    [reStartButton1 addTarget:self action:@selector(reStartButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    //
    
    UIButton *reStartButton2 = [[[UIButton alloc] initWithFrame:CGRectMake(10, 8, 32,32)] autorelease];
    
    [reStartButton2 setBackgroundImage:[UIImage imageNamed:@"chongqi.png"] forState:UIControlStateNormal];
    
    [reStartButton2 addTarget:self action:@selector(reStartButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    reStartButton2.autoresizingMask =  UIViewAutoresizingFlexibleRightMargin;
    reStartButton2.tag =  TABLE_FOOT_BTN_TAG2;
    [reStartButton1 addSubview:reStartButton2];

    [bgView addSubview: reStartButton1];
    
    
    UIButton *popButton1 = [[[UIButton alloc] initWithFrame:CGRectMake(164, 15, 145,45)] autorelease];
    popButton1.tag =  TABLE_FOOT_BTN_TAG3;
    popButton1.enabled = NO;
    [popButton1 setBackgroundImage:disAbleImage forState:UIControlStateDisabled];
    [popButton1 setBackgroundImage:image forState:UIControlStateNormal];
    [popButton1 setTitle:@"弹出硬盘（U盘）" forState:UIControlStateNormal];
    [popButton1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [popButton1 addTarget:self action:@selector(popUSBButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [popButton1.titleLabel setFont:[UIFont systemFontOfSize:12]];
    [popButton1 setTitleEdgeInsets:UIEdgeInsetsMake(0,45,0.0,0.0)];
    UIButton *popButton2 = [[[UIButton alloc] initWithFrame:CGRectMake(10, 8, 32,32)] autorelease];
    popButton2.tag = TABLE_FOOT_BTN_TAG4;
    popButton2.enabled = NO;
    [popButton2 setBackgroundImage:[UIImage imageNamed:@"usb.png"] forState:UIControlStateNormal];
    
    [popButton2 addTarget:self action:@selector(popUSBButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    popButton2.autoresizingMask =  UIViewAutoresizingFlexibleRightMargin;
    [popButton1 addSubview:popButton2];
    
    [bgView addSubview: popButton1];
    
    self.tableView.tableFooterView =  bgView;
    [bgView release];
}


#pragma mark -  OrientationChange
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self  resizeTableFooter:interfaceOrientation];
}


- (void)resizeTableFooter:(UIInterfaceOrientation)interfaceOrientation
{
    UIInterfaceOrientation to = interfaceOrientation;
    UIButton *bt1 = (UIButton*)[self.tableView.tableFooterView viewWithTag: TABLE_FOOT_BTN_TAG1];
    UIButton *bt2 = (UIButton*)[self.tableView.tableFooterView viewWithTag: TABLE_FOOT_BTN_TAG2];
    UIButton *bt3 = (UIButton*)[self.tableView.tableFooterView viewWithTag: TABLE_FOOT_BTN_TAG3];
    UIButton *bt4 = (UIButton*)[self.tableView.tableFooterView viewWithTag: TABLE_FOOT_BTN_TAG4];
    
    if (IS_IPAD) {
        if (to == UIInterfaceOrientationPortrait || to == UIInterfaceOrientationPortraitUpsideDown) {
            bt1.frame = CGRectMake(45, 15, 329, 45);
            bt2.frame = CGRectMake(108, 6, 32, 32);
            bt3.frame = CGRectMake(393, 15, 329, 45);
            bt4.frame = CGRectMake(105, 6, 32, 32);
        }
        else{
            bt1.frame = CGRectMake(45, 15, 452, 45);
            bt2.frame = CGRectMake(160, 6, 32, 32);
            bt3.frame = CGRectMake(527, 15, 452, 45);
            bt4.frame = CGRectMake(163, 6, 32, 32);
        }
    }
}

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
    
    self.tableView.backgroundColor = [UIColor colorWithRed:228.0/255.0 green:236.0/255.0 blue:244.0/255.0 alpha:1.0];
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    [self createTableFooter];
}

- (void)dealloc {
    if (self.currentRequest) {
        [restClient cancelRequest:self.currentRequest];
        self.currentRequest = nil;
    }
    [restClient release];

    if (deviceManagement)
    {
        [deviceManagement release];
    }
    if (newName) {
        [newName release];
    }
    [device release];
    [systemVersion release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self resizeTableFooter:self.interfaceOrientation];
    
    if (systemVersion == nil && device.online)
    {
        self.view.userInteractionEnabled = NO;
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        if (deviceManagement == nil)
        {
            deviceManagement = [[PCDeviceManagement alloc] init];
            deviceManagement.delegate = self;
        }
        [deviceManagement getBoxSystemVersion];
    }
    if (!device.online) {
        [self RestartEnable:NO];
        [self popUsbEnable:NO];
    }
}

-(void)editPopoBoxName:(UIButton *)btn
{
    UIAlertView * inputAnswerAlert = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"请输入新名称"
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                      otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    inputAnswerAlert.tag = RENAME_TAG;
    inputAnswerAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [inputAnswerAlert textFieldAtIndex:0];
    
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.clearsOnBeginEditing = YES;
    [inputAnswerAlert show];
    [inputAnswerAlert release];
    
}

-(void)showLoadingView:(NSString *)str
{
    self.view.userInteractionEnabled = NO;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    if (str) {
        [MBProgressHUD showHUDAddedTo:self.view text:str showImmediately:YES isMultiline:NO];
    }
    else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
}

-(void)removeLoadingView
{
    self.view.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
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

#pragma mark - alert delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex)
        return;
    
    if (alertView.tag == RENAME_TAG)//请求名字
    {
        if (deviceManagement == nil) {
            deviceManagement = [[PCDeviceManagement alloc] init];
            deviceManagement.delegate = self;
        }
        UITextField *textField = [alertView textFieldAtIndex:0];
        if (newName) {
            [newName release];
        }
        newName = [[NSString alloc] initWithString:textField.text];
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:textField.text,@"nickName",device.serNum,@"resourceId", nil];
        [self showLoadingView:nil];
        [deviceManagement renameBox:dic];
    }
    else if (alertView.tag == POP_USB_ALERT_TAG) {
        [self showLoadingView:@"正在弹出硬盘，请稍候..."];
        
        self.currentRequest =  [[[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotShutdownDisk:)] autorelease];
        self.currentRequest.process = @"ShutdownDisk";
        [self.currentRequest start];
    }
    else if (alertView.tag == RESTART_ALERT_TAG) {
        [self showLoadingView:@"正在重启，请稍候..."];
        
        self.currentRequest =  [[[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotRestart:)] autorelease];
        self.currentRequest.process = @"RestartBox";
        self.currentRequest.urlServer = [[NetPenetrate sharedInstance] defaultHubUrl];
        [self.currentRequest start];
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    if (alertView.alertViewStyle != UIAlertViewStylePlainTextInput) {
        return YES;
    }
    UITextField *textField = [alertView textFieldAtIndex:0];
    if (textField)
    {
        NSString *name = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        NSUInteger length = [name length];
        NSRange range = [name rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/[\\/:*\"<>?|]"]];
        
        if (length == 0 )
        {
            return NO;
        }
        else if(range.location!=NSNotFound)
        {
            [PCUtilityUiOperate showTip :NSLocalizedString(@"InvalidName", nil)];
            return NO;
        }
        else if (name.length > 20)
        {
            if (alertView.tag == RENAME_TAG)
            {
                if (alertView.visible)
                {
                    alertView.delegate = nil;
                    [PCUtilityUiOperate showErrorAlert:@"名称过长,请重新输入" delegate:nil];
                    textField.text = @"";
                    alertView.delegate = self;
                    return NO;
                }
            }
            
        }
    }
    
    
    return YES;
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return section == 0 ? 2 : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
    
    // Configure the cell...
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0)
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            //            cell.backgroundView = nil;
            //            cell.imageView.image = [UIImage imageNamed:@"icon_3"];
            //            cell.textLabel.backgroundColor = [UIColor clearColor];
            //            cell.textLabel.textColor = [UIColor blackColor];
            //            cell.textLabel.textAlignment = UITextAlignmentLeft;
            //            cell.textLabel.text = [device objectForKey:@"nickname"];
                
                for (UIView *view in [cell.contentView subviews])
                {
                    [view removeFromSuperview];
                }
                
                CGFloat x = 15.0f;
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, 10, 30, 30)];
                imageView.image = [UIImage imageNamed:@"icon_3"];
                [cell.contentView addSubview:imageView];
                [imageView release];
                
                UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.origin.x+30+5, imageView.frame.origin.y+5, 170, 20)];
                nameLabel.text = nil;
                nameLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
                [nameLabel setBackgroundColor:[UIColor clearColor]];
                nameLabel.textColor = [UIColor blackColor];
                nameLabel.text = device.nickName;
                nameLabel.font = [UIFont boldSystemFontOfSize:14];
                [cell.contentView addSubview:nameLabel];
                [nameLabel release];
                
                UIButton *editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                editBtn.frame = CGRectMake(230, 12, 57, 22);
                [editBtn setBackgroundImage:[UIImage imageNamed:@"editname"] forState:UIControlStateNormal];
                editBtn.titleLabel.font = [UIFont systemFontOfSize:12];
                [editBtn setTitle:@"编辑名称" forState:UIControlStateNormal];
                [editBtn addTarget:self action:@selector(editPopoBoxName:) forControlEvents:UIControlEventTouchUpInside];
                [cell.contentView addSubview:editBtn];
                
                CGFloat y = imageView.frame.origin.y + imageView.frame.size.height + 15;
                UILabel *hardWare = [[UILabel alloc] initWithFrame:CGRectMake(x, y, 300, 14)];
                float hardVersion = ceilf([device.hardwareVersion floatValue]);
                hardWare.text = [NSString stringWithFormat:@"泡泡云盒子型号 : PopoBox %.0f 代", ceilf(hardVersion)];
                [hardWare setBackgroundColor:[UIColor clearColor]];
                [hardWare setTextColor:[UIColor grayColor]];
                [cell.contentView addSubview:hardWare];
                [hardWare setFont:[UIFont systemFontOfSize:12]];
                
                y = hardWare.frame.origin.y + hardWare.frame.size.height + 10;
                UILabel *softWare = [[UILabel alloc] initWithFrame:CGRectMake(x, y, 300, 14)];
                [softWare setBackgroundColor:[UIColor clearColor]];
                [softWare setTextColor:[UIColor grayColor]];
                [cell.contentView addSubview:softWare];
                [softWare setFont:[UIFont systemFontOfSize:12]];
                softWare.text = [NSString stringWithFormat:@"泡泡云盒子软件版本 : V%@", device.versionCode];
                
                [softWare release];
                [hardWare release];
            }
            else if (indexPath.row == 1)
            {
                float hardVersion = ceilf([device.hardwareVersion floatValue]);
                if (hardVersion >= 2 && device.online) {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
                
                if (device.online) {
                    NSString *text = @"泡泡云盒子系统版本 : ";
                    if (systemVersion) {
                        text = [text stringByAppendingFormat:@"V%@", systemVersion];
                    }
                    cell.textLabel.text = text;
                    
                    if ([[PCLogin sharedManager] isNeedUpgrade])
                    {
                        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"new"]];
                        CGFloat x = cell.textLabel.frame.origin.x + [text sizeWithFont:cell.textLabel.font].width + 18;
                        imageView.frame = CGRectMake(x, 14, imageView.frame.size.width, imageView.frame.size.height);
                        imageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
                        [cell.contentView addSubview:imageView];
                        [imageView release];
                    }
                }
                else {
                    cell.textLabel.text = @"泡泡云盒子系统版本 : 盒子不在线！";
                }
            }
            break;
            
        case 1:
            //            if ([[device objectForKey:@"name"] isEqualToString:[[PCSettings sharedSettings] currentDeviceIdentifier]]) {
            //                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            //                cell.backgroundView = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"btn_green_disable_3x4"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 4)]] autorelease];
            //            }
            //            else {
            //                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            //                cell.backgroundView = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)]] autorelease];
            //                cell.selectedBackgroundView = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)]] autorelease];
            //            }
            //            cell.imageView.image = nil;
            //            cell.textLabel.backgroundColor = [UIColor clearColor];
            //            cell.textLabel.textColor = [UIColor whiteColor];
            //            cell.textLabel.textAlignment = UITextAlignmentCenter;
            //            cell.textLabel.text = @"设为当前盒子";
            //            break;
            //
            //        case 2:
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.imageView.image = [UIImage imageNamed:@"jiebang"];
            cell.textLabel.text = @"解除盒子绑定";
            
            break;
            
        default:
            break;
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
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 0 && indexPath.row == 0)? 106 : 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
            float hardVersion = ceilf([device.hardwareVersion floatValue]);
            if (hardVersion >= 2 && device.online) {
                if ([[PCLogin sharedManager] isNeedUpgrade]) {
                    BoxUpgradeConfirmViewController *view = [[BoxUpgradeConfirmViewController alloc] initWithNibName:@"BoxUpgradeConfirmViewController" bundle:nil];
                    view.currentSystemVersion = self.systemVersion;
                    [self.navigationController pushViewController:view animated:YES];
                    [view release];
                }
                else {
                    [PCUtilityUiOperate showOKAlert:@"当前已是最新的系统版本！" delegate:nil];
                }
            }
        }
    }
    else if (indexPath.section == 1) {
        //        if ([[device objectForKey:@"name"] isEqualToString:[[PCSettings sharedSettings] currentDeviceIdentifier]] == NO) {
        //            if ([[device objectForKey:@"online"] isEqualToString:@"false"]) {
        //                [PCUtility showTip:NSLocalizedString(@"DeviceOfflien", nil)];
        //            }
        //            else {
        //                PCLogin *pcLogin = [[PCLogin alloc] init];
        //                [pcLogin logIn:self node:device];
        //                [pcLogin release];
        //            }
        //        }
        //    }
        //    else if (indexPath.section == 2) {
        UnbindBoxViewController *unbindBoxViewController = [[UnbindBoxViewController alloc] initWithNibName:@"UnbindBoxViewController" bundle:nil];
        unbindBoxViewController.deviceIdentifier = device.serNum;
        [self.navigationController pushViewController:unbindBoxViewController animated:YES];
        [unbindBoxViewController release];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) loginFail:(PCLogin*)pcLogin error:(NSString*)error
{
    [PCUtilityUiOperate showErrorAlert:error delegate:nil];
}

- (void) loginFinish:(PCLogin*)pcLogin
{
    [[CameraUploadManager sharedManager] stopCameraUpload];
    [[CameraUploadManager sharedManager] startCameraUpload];
    
    [PCUtilityUiOperate logoutPop];
}

- (void)gotBoxNeedUpgrade:(BOOL)isNeed necessary:(BOOL)isNecessary
{
    //[self removeLoadingView];
    [self.tableView reloadData];
    
    [self getFolderSize];
}

- (void)getBoxNeedUpgradeFailedWithError:(NSError*)error
{
    [self removeLoadingView];
    [ErrorHandler showErrorAlert:error];
}

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement renameBoxSuccess:(NSString*)unused
{
    device.nickName = newName;
    if ([[PCLogin getAllDevices] count])
    {
        DeviceInfo *deviceInfo = [[PCLogin getAllDevices] objectAtIndex:0];
        deviceInfo.nickName = newName;
    }
    [[PCSettings sharedSettings] setCurrentDeviceName:newName];
    
    [self removeLoadingView];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"修改盒子名称成功" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
    [alert show];
    [alert release];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}
- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement renameBoxFailedWithError:(NSError*)error
{
    [self removeLoadingView];
    [ErrorHandler showErrorAlert:error];
}

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement gotBoxSystemVersion:(NSString*)version
{
    self.systemVersion = version;
    [self.tableView reloadData];
    
    float hardVersion = ceilf([device.hardwareVersion floatValue]);
    if (hardVersion >= 2) {
        [[PCLogin sharedManager] getBoxNeedUpgrade:self];
    }
    else {
        [self getFolderSize];
    }
}

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement getBoxSystemVersionFailedWithError:(NSError*)error
{
    [self removeLoadingView];
    [ErrorHandler showErrorAlert:error];
    if (error.code == 20) {
        [self RestartEnable:NO];
        [self popUsbEnable:NO];
    }
}

- (void)RestartEnable:(BOOL)enalbe
{
    UIButton *bt1 = (UIButton*)[self.tableView.tableFooterView viewWithTag: TABLE_FOOT_BTN_TAG1];
    UIButton *bt2 = (UIButton*)[self.tableView.tableFooterView viewWithTag: TABLE_FOOT_BTN_TAG2];
    
    if (enalbe) {
        bt1.enabled = YES;
        bt2.enabled = YES;
    }
    else{
        bt1.enabled = NO;
        bt2.enabled = NO;
    }
}

- (void)popUsbEnable:(BOOL)enalbe
{
    UIButton *bt3 = (UIButton*)[self.tableView.tableFooterView viewWithTag: TABLE_FOOT_BTN_TAG3];
    UIButton *bt4 = (UIButton*)[self.tableView.tableFooterView viewWithTag: TABLE_FOOT_BTN_TAG4];

    
    if (enalbe) {
        bt3.enabled = YES;
        bt4.enabled = YES;
    }
    else{
        bt3.enabled = NO;
        bt4.enabled = NO;
    }
}


#pragma mark - PCRestClientDelegate

- (void)restClient:(PCRestClient*)client gotDiskSpace:(NSArray*)disks
{
    [self removeLoadingView];
    if (disks && [disks count]>0) {
        [self popUsbEnable:YES];
    }
    else{
        [self popUsbEnable:NO];
    }
    if (bRestarting) {
            [PCUtilityUiOperate showTip :NSLocalizedString(@"泡泡云盒子已重新启动成功!", nil)];
        bRestarting = NO;
    }
    self.currentRequest = nil;
}

- (void)restClient:(PCRestClient*)client getDiskSpaceFailedWithError:(NSError*)error
{
    [self popUsbEnable:NO];

    if (bRestarting) {
        if (error.code == -1001 || error.code ==20) {
            NSTimeInterval newTime = [[NSDate date]  timeIntervalSince1970];
            if ( (newTime-restartTime)<120) {
                [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerAction:) userInfo:nil repeats:NO];
            }
            else
            {
                [PCUtilityUiOperate showErrorAlert:@"泡泡云盒子重启失败!" delegate:nil];
                [self removeLoadingView];
                bRestarting = NO;
            }
        }
        else{
            bRestarting = NO;
            if([error.domain isEqualToString: KTServerErrorDomain] &&error.code >1000)
            {
                [self removeLoadingView];
                [PCUtilityUiOperate showTip :NSLocalizedString(@"泡泡云盒子已重新启动成功!", nil)];
            }
            else{
                [PCUtilityUiOperate showErrorAlert:@"泡泡云盒子重启失败!" delegate:nil];
                [self removeLoadingView];
            }
        }
    }
    else{
        if(error.code ==20)
        {
            [self RestartEnable:NO];
        }
        [self removeLoadingView];
    }
    
    self.currentRequest = nil;
}
@end
