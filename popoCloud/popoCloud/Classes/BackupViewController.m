//
//  BackupViewController.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-27.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "BackupViewController.h"
#import "ABContact.h"
#import "ABContactsHelper.h"
#import "PCUtility.h"
#import "PCUtilityUiOperate.h"
#import "PCUtilityShareGlobalVar.h"
#import "ModalAlert.h"
#import "PCLogin.h"

#import "PCAppDelegate.h"
#import "LoginViewController.h"
#import "PCFileUpload.h"

//#define STATUS_GET_DOCUMENT_PATH 1
//#define STATUS_UPLOAD_FILE 2

@implementation BackupViewController

@synthesize btnStart, progressView;
@synthesize dicatorView;
@synthesize backupFile;
@synthesize lblResult;
@synthesize lblCount;
@synthesize toolBar;
@synthesize lblBackupTip;
@synthesize lblButtonTitle;
@synthesize lblContacts;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
            fileUploadCacheArr = [[NSMutableArray alloc] init];
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
    
    plistPath = [NSString stringWithFormat:@"%@/%@", [PCUtilityShareGlobalVar getPListPath], [backupFile.filePath lastPathComponent]];
//    NSLog(plistPath);
    
    contactsCount = [ABContactsHelper contactsCount];
 
    progressView.progress = 0;
    [progressView initProgressLabel];
    [lblResult setHidden:YES];
    
    lblBackupTip.text = NSLocalizedString(@"BackupData", nil);
    lblButtonTitle.text = NSLocalizedString(@"Backup", nil);
    lblContacts.text = NSLocalizedString(@"Contacts", nil);
    
    [dicatorView setHidesWhenStopped:YES];
    lblCount.text = [NSString stringWithFormat:@"%d", contactsCount];
    
//    NSArray *arrayView = [(PCAppDelegate*)[[UIApplication sharedApplication] delegate] viewController].viewControllers;
//    LoginViewController *loginViewController= [arrayView objectAtIndex:0];
    footerView = [((PCAppDelegate*)[[UIApplication sharedApplication] delegate]).tabbarContent rotatingFooterView];
    
    [footerView addSubview:toolBar];
    CGRect frame = footerView.frame;
    frame.origin.y = 0;
    toolBar.frame = frame;
    [toolBar removeFromSuperview];
    
    isCancel = NO;
    isBackuping = NO;
    connection = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"BackupView"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [toolBar removeFromSuperview];
    for (FileUpload *fileUpload  in fileUploadCacheArr)
    {
        [fileUpload cancel];
    }
    [fileUploadCacheArr removeAllObjects];
    
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"BackupView"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (IS_IPAD || (interfaceOrientation == UIInterfaceOrientationPortrait));
}

//---------------------------

-(IBAction) btnCancelClicked: (id) sender
{
        if (!isBackuping) return;
        
        isCancel = YES;
        [self finishBackup:NSLocalizedString(@"BackupBeCancel", nil)];
    
        for (FileUpload *fileUpload  in fileUploadCacheArr)
        {
            [fileUpload cancel];
        }
        [fileUploadCacheArr removeAllObjects];

        if (connection)
        {
            [connection cancel];
        }
        else
        {
            backupFile.isCancel = YES;
        }
}

//-------------------------------------------
- (void) backupContact {
    [backupFile backupContact:plistPath progressView:progressView progressScale:1 scaleOffset:0];
//   [backupFile backupContact:plistPath progressView:progressView progressScale:0.4 scaleOffset:0];
}

- (void) backupData {
    @autoreleasepool {
        if (!isCancel) [self backupContact];
        if (!isCancel) {
            [self performSelectorOnMainThread:@selector(uploadBackupFile) withObject:nil waitUntilDone:false];
        }  
    }
}

-(IBAction) btnBackupClicked: (id) sender {
    if (![PCUtility isNetworkReachable:self]) {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"OpenNetwork", nil) delegate:self];
        return;
    }
    
    if (!contactsCount) {
        [PCUtilityUiOperate showOKAlert:NSLocalizedString(@"NoDataForBackup", nil) delegate:self];
        return;
    }
    
    [footerView addSubview:toolBar];
    isCancel = NO;
    isBackuping = YES;
    connection = nil;
    backupFile.isCancel = NO;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    [btnStart setEnabled:NO];
//    if (!backupFile.modifyTime || [ModalAlert confirm:NSLocalizedString(@"ConfirmToCoverLastRecord", nil)]) {
    progressView.progress = 0.0;
    [NSThread detachNewThreadSelector:@selector(backupData) toTarget:self withObject:nil];

//    }
}

- (void) uploadBackupFile
{
    mStatus = FILE_TYPE_BACKUP;
    FileUpload *fileUpload = [[FileUpload alloc] init];
    
    //构造参数
    NSString *filePath = [NSString stringWithFormat:@"%@.zip", backupFile.filePath];
    NSString *srcPath = [NSString stringWithFormat:@"%@.zip", plistPath];
    int fileType = FILE_TYPE_BACKUP;
    id<PCFileUploadDelegate> delegate = self;
    NSString *deviceID = nil;
    
    PCFileUpload *uploadRequest = [[PCFileUpload alloc] init];
    [uploadRequest setDstPath:filePath];
    [uploadRequest setSrc:srcPath];
    [uploadRequest setFileType:fileType];
    [uploadRequest setDelegate:delegate];
    [uploadRequest setDeviceID:deviceID];
    
    [fileUpload upload:uploadRequest];
    
    [fileUploadCacheArr addObject:fileUpload];
}

//---------------------------------------------------------------


- (void) finishBackup:(NSString*)resultText {
    if (isBackuping) {
        isBackuping = NO;
        [toolBar removeFromSuperview];
        self.navigationController.navigationBar.userInteractionEnabled = YES;
        [btnStart setEnabled:YES];
//        [lblResult setHidden:NO];
//        lblResult.text = resultText; 
        [PCUtilityUiOperate showOKAlert:resultText delegate:self];
    }
}


//-----------------------------------------------------------

- (void) uploadFileFinish:(FileUpload *)fileUpload hostPath:(NSString *)path fileSize:(long long)size
{
    [fileUploadCacheArr removeAllObjects];
    
    if (fileUpload.uploadRequest.fileType == FILE_TYPE_BACKUP)
    {
        backupFile.modifyTime = fileUpload.uploadRequest.modifyTime;
        backupFile.fileSize = fileUpload.uploadRequest.fileSize;
        [self finishBackup:NSLocalizedString(@"BackupSuccessful", nil)];        
    }
}

- (void) uploadFileFail:(FileUpload*)fileUpload hostPath:(NSString*)path error:(NSString*)error
{
    [fileUploadCacheArr removeAllObjects];
    
    if (fileUpload.errCode == NSURLErrorCannotConnectToHost ||
        fileUpload.errCode == NSURLErrorTimedOut ||
        fileUpload.errCode == PC_Err_LackSpace)
    {
        [self finishBackup:[NSString stringWithFormat:@"%@: %@",
                            NSLocalizedString(@"BackupFailed", nil), error]];
    }
    else if (fileUpload.errCode == NSURLErrorNotConnectedToInternet)//fixed bug 53863 by ray
    {
        [self finishBackup:error];
    }
    else
    {
        if ([ModalAlert confirm:NSLocalizedString(@"ConfirmToRebackup", nil)])
        {
            if (fileUpload.uploadRequest.fileType == FILE_TYPE_BACKUP)
            {
                [self uploadBackupFile];
            }
        }
        else
        {
            [self finishBackup:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"BackupFailed", nil), error]];
        }
    }
}

- (void) uploadFileProgress:(FileUpload*)fileUpload
                currentSize:(long long)currentSize
                  totalSize:(long long)totalSize
                   hostPath:(NSString *)path
{

    if (fileUpload.uploadRequest.fileType == FILE_TYPE_MD5)
    {
        [progressView setTip:@"正在备份"];
    }
    else
    {
         [progressView setTip:@"正在上传备份"];
    }
}

- (void) loginFail:(PCLogin*)pcLogin error:(NSString*)error {
    [self finishBackup:NSLocalizedString(@"ReLoginFailed", nil)];
    [PCUtilityUiOperate showErrorAlert:error delegate:self];
}

- (void) loginFinish:(PCLogin*)pcLogin {
    [fileUploadCacheArr removeAllObjects];
    
    if (mStatus == FILE_TYPE_BACKUP) {
        [self uploadBackupFile];
    }  
}

- (void) networkNoReachableFail:(NSString*)error {
    [self finishBackup:NSLocalizedString(@"NetworkFailed", nil)];
    [PCUtilityUiOperate showErrorAlert:error delegate:self];
}


//-----------------------------------------------------------
- (void) getBackupFileInfoFail:(NSString*)error {
    [PCUtilityUiOperate showErrorAlert:error delegate:self];
}

- (void) getBackupFileInfoFinish {
    
}

- (void)dealloc
{
    self.backupFile = nil;
    
    self.toolBar = nil;
    self.lblResult = nil;
    self.lblCount = nil;
    self.lblBackupTip = nil;
    self.lblButtonTitle = nil;
    self.lblContacts = nil;
    self.btnStart = nil;
    self.progressView = nil;
    self.dicatorView = nil;
}
@end
