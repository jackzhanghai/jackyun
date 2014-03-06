//
//  BackupRestoreViewController.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-27.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "BackupRestoreViewController.h"

#import "BackupViewController.h"
#import "RestoreViewController.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "PCLogin.h"
#import "ABContact.h"
#import "ABContactsHelper.h"

#define STATUS_BACKUP 1
#define STATUS_RESTORE 2

@implementation BackupRestoreViewController

@synthesize tableView;
@synthesize lblRestoreInfo;
@synthesize progressView;
@synthesize dicatorView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
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
    // Do any additional setup after loading the view from its nib.
    
    tableData = [[NSMutableArray alloc] init];
    
        [tableData addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                              NSLocalizedString(@"BackupPhoneData", nil), @"name", [PCUtilityFileOperate getImgName:@"file_folder"], @"image", nil]];
        [tableData addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                              NSLocalizedString(@"RestorePhoneData", nil), @"name", [PCUtilityFileOperate getImgName:@"file_folder"], @"image", nil]];
/*    
    dicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(144, 196, 32, 32)];
    [dicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:dicatorView];
 */
    
//    UIBarButtonItem *btnListDevice = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Devices", nil) style:UIBarButtonItemStylePlain target:self action:@selector(listDevices)];
//    self.navigationItem.leftBarButtonItem = btnListDevice;
//    [btnListDevice release];
    
    backupFile = [[PCBackupFile alloc] init];
    backupFile.delegate = self;
    
    isFinish = NO;
    
//    if (_refreshHeaderView == nil) {
//    
//    EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
//    view.delegate = self;
//    [self.tableView addSubview:view];
//    _refreshHeaderView = view;
//    [_refreshHeaderView refreshLastUpdatedDate];
//    }
    


/*

    */
//    [dicatorView startAnimating];
//    [backupFile getBackupInfo];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
//    [tableView reloadData];
//    [dicatorView startAnimating];
//    [backupFile getBackupInfo];
    
/*
    if ([PCBackupFile checkRestoreOldData]) {
        [progressView setHidden:NO];
        [lblRestoreInfo setHidden:NO];
        
        [backupFile restoreOldData:progressView progressScale:1.0];
        [backupFile deleteRestoreOldData];
//        [PCUtility showOKAlert:NSLocalizedString(@"RestoreSuccessful", nil) delegate:self];
    }
 */
        
    [progressView setHidden:YES];
    [lblRestoreInfo setHidden:YES];


//    if (!isFinish) {
//        [dicatorView startAnimating];
//        [self getDocumentPath];
//        isFinish = NO;
//    }
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"BackupRestore"];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (![PCLogin getResource]) {
        //[tableData removeAllObjects];
        [tableView reloadData];
        [self listDevices];
    }
    else {
        [tableView reloadData];
        [dicatorView startAnimating];
        [backupFile getBackupInfo];
    }
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (IS_IPAD || (interfaceOrientation == UIInterfaceOrientationPortrait));
}

- (void)dealloc
{
    _refreshHeaderView=nil;
}

//-----------------------------------------------------
- (void) listDevices {
    [PCUtilityUiOperate listDevices:self resource:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if    ((![PCLogin getResource])||(!isFinish || !backupFile.haveGetInfo))
    {
        return 0;
    }

    return 2;//tableData.count;
}


-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return TABLE_CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    if (indexPath.row < tableData.count) {
        NSDictionary *node = (NSDictionary *)[tableData objectAtIndex:indexPath.row];
        cell.textLabel.text = [node objectForKey:@"name"];
//        cell.imageView.image = [UIImage imageNamed:[node objectForKey:@"image"]];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.row == 0) {
        NSString *modifyTime = [backupFile getModifyTime];
        if (modifyTime) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"LastBackupDate", nil), modifyTime]; 
        }
        else if(isFinish){
            cell.detailTextLabel.text = NSLocalizedString(@"NoBackupDate", nil);
        }
        else{
            cell.detailTextLabel.text = @"";
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    if (!isFinish || !backupFile.haveGetInfo)
    if    ((![PCLogin getResource])||(!isFinish || !backupFile.haveGetInfo))
    {
          [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"ConnetError", nil) delegate:self];
        return;
    }
    
    
//    [dicatorView startAnimating];
    if (indexPath.row == 0) {
        mStatus = STATUS_BACKUP;
        [self loadContacts];
        //[self backup];
    } 
    else if (indexPath.row == 1) {
        mStatus = STATUS_RESTORE;
        [self restoreContacts];
        //[self restore];
    }
//    [dicatorView startAnimating];
//    [backupFile getBackupInfo];
}

-(void)loadContacts {
    __block BOOL accessGranted = NO;
    if (ABAddressBookRequestAccessWithCompletion != NULL)
    {
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
            CFErrorRef error = nil;
            ABAddressBookRef addressBook  = ABAddressBookCreateWithOptions(NULL,&error);
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                accessGranted = granted;
                dispatch_semaphore_signal(sema);
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            dispatch_release(sema);
            CFRelease(addressBook);
        }
        else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
            // The user has previously given access, add the contact
            accessGranted = YES;
        }
        else {
            // The user has previously denied access
            // Send an alert telling user to change privacy setting in settings app
            [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"PermissionDenied", nil) delegate:self];
        }
    }
    else { // we're on iOS 5 or older
        accessGranted = YES;
    }
    
    
    if (accessGranted) {
        // Do whatever you want here.
        [self backup];
    }
}

//-----------------------------------------------
-(void) backup {
    BackupViewController *backupView = [[BackupViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"BackupView"] bundle:nil];
    backupView.navigationItem.title = NSLocalizedString(@"Backup", nil);
    backupView.backupFile = backupFile;
//    [backupView setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:backupView animated:YES];   
}

-(void) restore {
    RestoreViewController *restoreView = [[RestoreViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"RestoreView"] bundle:nil]; 
    restoreView.navigationItem.title = NSLocalizedString(@"Restore", nil);
    restoreView.backupFile = backupFile;
    [self.navigationController pushViewController:restoreView animated:YES];   
}

-(void)restoreContacts {
    __block BOOL accessGranted = NO;
    if (ABAddressBookRequestAccessWithCompletion != NULL)
    {
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
            CFErrorRef error = nil;
            ABAddressBookRef addressBook  = ABAddressBookCreateWithOptions(NULL,&error);
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                accessGranted = granted;
                dispatch_semaphore_signal(sema);
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            dispatch_release(sema);
            CFRelease(addressBook);
        }
        else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
            // The user has previously given access, add the contact
            accessGranted = YES;
        }
        else {
            // The user has previously denied access
            // Send an alert telling user to change privacy setting in settings app
            [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"PermissionDenied", nil) delegate:self];
        }
    }
    else { // we're on iOS 5 or older
        accessGranted = YES;
    }
    
    
    if (accessGranted) {
        // Do whatever you want here.
        [self restore];
    }
}
//------------------------------------------------------
- (void) getBackupFileInfoFail:(NSString*)error {
    [dicatorView stopAnimating];
    
    isFinish = YES;
    [self doneLoadingTableViewData];
    if (error) {
            [PCUtilityUiOperate showErrorAlert:error delegate:self];
    }
}

- (void) getBackupFileInfoFinish {
    [dicatorView stopAnimating];
    isFinish = YES;
    [self.tableView reloadData];
    [self doneLoadingTableViewData];
    /*
    if (mStatus == STATUS_BACKUP) {
        [self backup];
    } 
    else if (mStatus == STATUS_RESTORE) {
        [self restore];
    }
     */
}

//----------------------------------------------------------

- (void) logOut {
    backupFile.haveGetInfo = NO;
    backupFile.modifyTime = nil;
}

//----------------------------------------------------------
#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
	_reloading = YES;
    [backupFile getBackupInfo];
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
	
}


#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{	
	if (isFinish)
        [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	if (isFinish)
        [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];	
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	
	[self reloadTableViewDataSource];
    //	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
	
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	
	return _reloading; // should return if data source model is reloading
	
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	
	return [NSDate date]; // should return date data source was last changed
	
}



@end

