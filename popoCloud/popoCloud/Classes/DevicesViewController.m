//
//  DevicesViewController.m
//  popoCloud
//
//  Created by Chen Dongxiao on 12-2-2.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//
#import "PCUserInfo.h"
#import "DevicesViewController.h"
#import "PCLogin.h"
#import "NoDeviceViewController.h"
#import "LoginViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import "PCAppDelegate.h"
#import "CameraUploadManager.h"
#import "FileFolderViewController.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "PCUtilityStringOperate.h"

@implementation DevicesViewController

@synthesize dicatorView, tableView, lblTip;
@synthesize resource;
@synthesize bPushedByTabViewController;
@synthesize bNeedShowNodevice;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"Devices", nil);
         tableData = [[NSMutableArray alloc] init];
        data = [[NSMutableData data] retain];
        deviceListConnectionArray = [[NSMutableArray alloc] init];
        bViewWillDisappear = NO;
        _reloading = NO;
        isFinish = YES;
        bNeedShowNodevice = YES;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)stopRefresh
{
    UIButton *refreshImg = (UIButton *)self.navigationItem.rightBarButtonItem.customView;
    refreshImg.enabled = YES;
    [refreshImg.layer removeAnimationForKey:@"transform"];
    [dicatorView stopAnimating];
}

- (void)setNavigationItemByRefresh:(id)sender
{
    UIButton *refreshImg = (UIButton *)self.navigationItem.rightBarButtonItem.customView;
    refreshImg.enabled = NO;
    CAKeyframeAnimation *theAnimation = [CAKeyframeAnimation animation];
    
    theAnimation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeRotation(0,0,0,1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeRotation(3.13,0,0,1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeRotation(6.26,0,0,1)]];
    theAnimation.cumulative =YES;
    theAnimation.removedOnCompletion =YES;
    theAnimation.repeatCount =HUGE_VALF;
    theAnimation.speed = 0.3f;
    
    [refreshImg.layer addAnimation:theAnimation forKey:@"transform"];
    [dicatorView startAnimating];
   [self reloadTableViewDataSource];
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO];
//    UIImage *refreshImage = [UIImage imageNamed:[PCUtility getImgName:@"navigate_refresh"]];
//    
//    UIImageView *refreshImageView = [[UIImageView alloc]initWithImage:refreshImage ];
//    
//    refreshImageView.frame = CGRectMake(5, 5, 23, 23);
//    
//    refreshImageView.backgroundColor = [UIColor clearColor];
//    
//    refreshImageView.center =self.view.center;
//    
//    UITapGestureRecognizer * refreshTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(setNavigationItemByRefresh:)];
//    refreshTapRecognizer.numberOfTapsRequired = 1;
//    [refreshImageView addGestureRecognizer:refreshTapRecognizer];
//    [refreshTapRecognizer release];
//    
//    UIBarButtonItem *btnRefreshBtn = [[UIBarButtonItem alloc] initWithCustomView:refreshImageView];
//    
//    btnRefreshBtn.target = refreshImageView;
//    [refreshImageView release];
//    
//    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects: btnRefreshBtn,nil]];
//    [btnRefreshBtn release];
//    
    
    
    UIButton* refreshButton = [[UIButton alloc] init];
    [refreshButton setImage:[UIImage imageNamed:[PCUtilityFileOperate getImgName:@"navigate_refresh"]] forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(setNavigationItemByRefresh:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* btnRefreshBtn = [[[UIBarButtonItem alloc] initWithCustomView:refreshButton] autorelease];
     refreshButton.frame = CGRectMake(5, 5, 23, 23);
    self.navigationItem.rightBarButtonItem = btnRefreshBtn;
    [refreshButton release];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.dicatorView = nil;
    self.lblTip = nil;
    tableView.delegate = nil;
    [tableView release];
    tableView = nil;
}

- (void)dealloc
{
    self.dicatorView = nil;
    self.lblTip = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    for(NSURLConnection  *cn  in      deviceListConnectionArray)
    {
        [cn cancel];
    }
    [deviceListConnectionArray removeAllObjects];
    [tableData release];
    [data release];
    [deviceListConnectionArray release];
    [resource release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.title = NSLocalizedString(@"Devices", nil);
    bViewWillDisappear = NO;
     dicatorView.center = self.view.center;
     if (([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0))
     {
         dicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
         dicatorView.color = [UIColor grayColor];
     }
     else{
         dicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
     }
    
     [MobClick beginLogPageView:@"DevicesView"];
    //[self getDevicesList];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self  setNavigationItemByRefresh:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"DevicesView"];
    bViewWillDisappear = YES;
    for(NSURLConnection  *cn  in      deviceListConnectionArray)
    {
        [cn cancel];
    }
    [deviceListConnectionArray removeAllObjects];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (IS_IPAD || (interfaceOrientation == UIInterfaceOrientationPortrait));
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    dicatorView.center = self.view.center;
}

- (void) hideTip {
    [lblTip setHidden:YES];
}

- (void) showTip:(NSString*)tip {
    lblTip.text = tip;
    [lblTip setHidden:NO];
    [self performSelector:@selector(hideTip) withObject:nil afterDelay:2.0];
}

- (void) getDevicesList {
 /*   
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:TIMEOUT_INTERVAL];

    NSError *error;
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];  
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@", ret);
  */  

    if (!isFinish) {
        return;
    }
    isFinish = NO;
    
    for(NSURLConnection  *cn  in      deviceListConnectionArray)
    {
        [cn cancel];
    }
    [deviceListConnectionArray removeAllObjects];

    
    _reloading = YES;
    
    NSString* url = [NSString stringWithFormat:@"list?username=%@&password=%@", [PCUtilityStringOperate encodeToPercentEscapeString:[[PCUserInfo currentUser] userId]], [PCUtilityStringOperate encodeToPercentEscapeString:[[PCUserInfo currentUser] password]]];
    NSURLConnection  *deviceListConnection = [PCUtility httpGetWithAccountURL:url headers:nil delegate:self];
    if (deviceListConnection) {
        [deviceListConnectionArray addObject:deviceListConnection];
    }
}

//--------------------------------------------------------------------


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return tableData.count;
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return TABLE_CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [[self tableView] dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    // Configure the cell...
    if (indexPath.row < tableData.count) {
        NSDictionary *node = (NSDictionary *)[tableData objectAtIndex:indexPath.row];
        cell.textLabel.text = [node objectForKey:@"nickname"];
        NSString *online = node[@"online"];
        
        if ([[node valueForKey:@"type"] shortValue] == 1) {
            if ([online isEqualToString:@"true"])
            {
                cell.imageView.image = [UIImage imageNamed:@"dev_computer_online.png"];
                cell.textLabel.textColor = [UIColor blackColor];
            }
            else
            {
                cell.imageView.image = [UIImage imageNamed:@"dev_computer_offline.png"];
                cell.textLabel.textColor = [UIColor grayColor];
            }
        }
        else {
            if ([online isEqualToString:@"true"])
            {
                cell.imageView.image = [UIImage imageNamed:@"dev_equipment_online.png"];
                cell.textLabel.textColor = [UIColor blackColor];
            }
            else
            {
                cell.imageView.image = [UIImage imageNamed:@"dev_equipment_offline.png"];
                cell.textLabel.textColor = [UIColor grayColor];
            }
        }
        
        NSString *currentDeviceIdentifier = [[PCSettings sharedSettings] currentDeviceIdentifier];
        if (currentDeviceIdentifier && ([currentDeviceIdentifier compare:[node objectForKey:@"name"]] == NSOrderedSame)) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
//            if ([[node objectForKey:@"online"] compare:@"false"] == NSOrderedSame) 
                //[self showTip:NSLocalizedString(@"DefauteDeviceOffline", nil)];
//                [PCUtility showErrorAlert:NSLocalizedString(@"DefauteDeviceOffline", nil) delegate:self];
                
        }    
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
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

- (void)logIn:(NSDictionary *)node {
    [dicatorView startAnimating];
    UIButton *refreshImg = (UIButton *)self.navigationItem.rightBarButtonItem.customView;
    refreshImg.enabled = NO;
    [PCUtilityUiOperate animateRefreshBtn:refreshImg];
    isFinish = NO;
    deviceType = [[node valueForKey:@"type"] intValue];
    
    PCLogin *pcLogin = [[PCLogin alloc] init];
    [pcLogin logIn:self node:node];
}

- (NSInteger) selectResource:(NSDictionary *)node resource:(NSString*)_resource {
    if (([_resource isEqualToString:[node objectForKey:@"name"]])) {
//        if ([[node objectForKey:@"online"] isEqualToString:@"false"]) {
//            [PCUtility showTip:NSLocalizedString(@"DeviceOfflien", nil)];
//            return 1;
//        }
//        else {
            //resource = [node objectForKey:@"name"];
            [self logIn:node];
            return 2;
//        }
    }
    else {
        return 0;
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (!isFinish) {
        return;
    }
    
    if (indexPath.row >= tableData.count) return;
    
    NSDictionary *node = (NSDictionary *)[tableData objectAtIndex:indexPath.row];

//    if ([[node objectForKey:@"online"] isEqualToString:@"false"]) 
//        [PCUtility showTip:NSLocalizedString(@"DeviceOfflien", nil)];
//    else {
        self.resource = [node objectForKey:@"name"];
        [self logIn:node];
//    }
}

//---------------------------------------------------------------

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [data setLength:0];
    
    NSInteger rc = [(NSHTTPURLResponse*)response statusCode];
    NSLog(@"status code: %d", rc);
    NSString *error;
    
    error = [PCUtility checkResponseStautsCode:rc];
    if (error) {
        /*
         isNetworkError = YES;
         isFinish = YES;
         [dicatorView stopAnimating];
         [self doneLoadingTableViewData];
         [PCUtility showErrorAlert:error delegate:self];
         */
    }
    
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)incomingData {
    [data appendData:incomingData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    _reloading = NO;
    isFinish = YES;
    [self stopRefresh];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@", ret);
    NSDictionary *dict = [ret JSONValue];
    [ret release];
   
    if (dict) {
        
        if ([[dict valueForKey:@"result"] shortValue] == 0) {
            [tableData removeAllObjects];
            NSLog(@"wwwww   %@",[dict valueForKey:@"data"]);
            if ([dict valueForKey:@"data"]) {
                [tableData addObjectsFromArray:[dict valueForKey:@"data"]];
            }
            
           for (NSDictionary *node in tableData) {
                NSString *nickname = [node objectForKey:@"nickName"];
                [node setValue:[PCUtility unescapeHTML:nickname] forKey:@"nickname"];
            }
            
            BOOL bFoundLastDevice = NO;
            if (resource) {
                for (int i = 0; i < tableData.count; i++) {
                    NSDictionary *node = (NSDictionary *)[tableData objectAtIndex:i];
                    if ([self selectResource:node resource:resource]) {
//                         [[PCUtility downloadManager] reloadData];
                        bFoundLastDevice = YES;
                        break;
                    }
                }
            
            }
            //bPushedByTabViewController 表示是切换盒子那边的。
            if ((!bPushedByTabViewController)&&(!bFoundLastDevice)  && (tableData.count == 1) ) {
                NSDictionary *node = (NSDictionary *)[tableData objectAtIndex:0];
//                id nsOnlineStatus = [node objectForKey:@"online"];
//                if ([nsOnlineStatus isKindOfClass:[NSString class]] &&  ([(NSString*)nsOnlineStatus compare:@"true"] == NSOrderedSame))
//                {
                    [self logIn:node];
//                }
            }
            if(0 == [tableData count]) {
                //[PCUtility showErrorAlert:@"请检查该帐号是否绑定泡泡云设备。" title:@"未检测到泡泡云设备"  delegate:self];
                
                NoDeviceViewController* noDeviceViewController = [[NoDeviceViewController alloc] initWithNibName:@"NoDeviceView" bundle:nil];
                [self.navigationController pushViewController:noDeviceViewController animated:YES];
                [noDeviceViewController release];
            }
            [tableView reloadData];
        }
        else if ([[dict valueForKey:@"result"] shortValue] == 9) //用户名密码错误
        {
            [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"PasswordChanged", nil)  delegate:nil];
        }
        else {
            NSString * errMsg = [dict objectForKey:@"errMsg"]?[dict objectForKey:@"errMsg"]:([dict objectForKey:@"message"]?[dict objectForKey:@"message"]:NSLocalizedString(@"ConnetError", nil));
            [PCUtilityUiOperate showErrorAlert:errMsg  delegate:nil];
        }
        dict = nil;
    }
}

- (void)pushNoDeviceVC:(id)sender {
    [NSThread sleepForTimeInterval:0.5];
    NoDeviceViewController* noDeviceViewController = [[NoDeviceViewController alloc] initWithNibName:@"NoDeviceView" bundle:nil];
    [self.navigationController pushViewController:noDeviceViewController animated:YES];
    [noDeviceViewController release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    _reloading = NO;
    isFinish = YES;
    [self stopRefresh];
     [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"ConnetError", nil) delegate:nil];
}

//-----------------------------------------------------------
- (void) loginFail:(PCLogin*)pcLogin error:(NSString*)error {
    isFinish = YES;
    [dicatorView stopAnimating];
    [self stopRefresh];

    [PCUtilityUiOperate showErrorAlert:error delegate:nil];
    [pcLogin release];
}

- (void) loginFinish:(PCLogin*)_pcLogin {
    isFinish = YES;
    [dicatorView stopAnimating];
      [self stopRefresh];
    
    [PCUtilityUiOperate logoutPop];
    //xy add  选择盒子之后刷新下载列表
    
    if (resource)
    {
        [[PCUtilityFileOperate downloadManager] reloadData];
    }
    
    [[CameraUploadManager sharedManager] stopCameraUpload];
    [[CameraUploadManager sharedManager] startCameraUpload];
    
    [_pcLogin release];
}


#pragma mark - PCNetworkDelegate methods

- (void) networkNoReachableFail:(NSString*)error
{
    isFinish = YES;
    [dicatorView stopAnimating];
    [self stopRefresh];
    [PCUtilityUiOperate showErrorAlert:error delegate:nil];
}

//----------------------------------------------------------
#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
	
    [self getDevicesList];
}

#pragma mark - UIAlertViewDelegate method

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (bNeedShowNodevice) {
          [NSThread detachNewThreadSelector:@selector(pushNoDeviceVC:) toTarget:self withObject:nil];
    }  
}


@end
