//
//  RestoreViewController.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-9-5.
//  Copyright 2011年 Kortide. All rights reserved.
//
#import "ZipArchive.h"
#import "RestoreViewController.h"
#import "ABContact.h"
#import "ABContactsHelper.h"
#import "PCUtility.h"
#import "FileCache.h"
#import "FileUpload.h"
#import "PCUtility.h"
#import "PCUtilityUiOperate.h"
#import "PCLogin.h"
#import "PCAppDelegate.h"
#import "LoginViewController.h"
#import "PCUtilityEncryptionAlgorithm.h"
@implementation RestoreViewController

@synthesize backupFile;
@synthesize progressView;
@synthesize lblHint;
@synthesize btnRestore;
@synthesize imgView;
@synthesize lblModifyTime;
@synthesize toolBar;
@synthesize imgLine1;
@synthesize imgLine2;
@synthesize btnInfo;
@synthesize lblText1;
@synthesize lblInfo;
@synthesize lblContact;
@synthesize lblContactNumber;
@synthesize lblButton;
@synthesize dicatorView;
@synthesize fileCacheArr;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        fileCacheArr = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    for (FileCache *cache in fileCacheArr) {
            cache.delegate = nil;
            [cache cancel];
    }
    
    [fileCacheArr removeAllObjects];
    [fileCacheArr  release];
    fileCacheArr = nil;
    
    //xy add  还原时弹出是否继续下载。点是之后会到下载界面。要移除进度条视图
    [toolBar removeFromSuperview];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [btnRestore setEnabled:YES];
    
   [super viewWillDisappear:animated];
}

- (void)dealloc
{
    self.toolBar = nil;
    self.progressView = nil;
    self.lblText1 = nil;
    self.lblButton = nil;
    self.lblInfo = nil;
    self.lblContact = nil;
    self.lblContactNumber = nil;
    self.lblHint = nil;
    self.btnRestore = nil;
    self.btnInfo = nil;
    self.imgView = nil;
    self.imgLine1 = nil;
    self.imgLine2 = nil;
    self.lblModifyTime = nil;
    self.dicatorView = nil;

    [super  dealloc];
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
    
//    plistPath = [[NSString stringWithFormat:@"%@/contact.data", [PCUtility getPListPath]] retain];
//    NSLog(plistPath);
    
    progressView.progress = 0;
    [progressView initProgressLabel];
/*    
    dicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(140, 230, 32, 32)];
    [dicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:dicatorView];
 */   
    [imgView setHidden:NO];
    [lblHint setHidden:NO];
    //     [lblModifyTime  setHidden:YES];
    
    lblHint.lineBreakMode = UILineBreakModeWordWrap;
    lblHint.numberOfLines =0;
    [lblHint sizeToFit];
    lblHint.text = NSLocalizedString(@"NoBackupRecord", nil);
    
    [lblText1 setHidden:YES];
    [lblInfo setHidden:YES];
    lblInfo.text = NSLocalizedString(@"DataToBeRestored", nil);
    [lblModifyTime setHidden:YES];
    [lblContact setHidden:YES];
    lblContact.text = NSLocalizedString(@"Contacts", nil);
    [lblContactNumber setHidden:YES];
    [lblButton setHidden:YES];
    lblButton.text = NSLocalizedString(@"Restore", nil);
    
    [imgLine1 setHidden:YES];
    [imgLine2 setHidden:YES];
    
    [btnRestore setHidden:YES];
    [btnInfo setHidden:YES];
    
    if (backupFile.modifyTime) {
        lblHint.text = NSLocalizedString(@"ReadMessageFromPC", nil);
        [dicatorView startAnimating];
        [self downloadBackupFile];
    }
    else {

    }
    
    PCAppDelegate *appDelegate = (PCAppDelegate*)[[UIApplication sharedApplication] delegate];
    footerView = [appDelegate.tabbarContent rotatingFooterView];
    
    [footerView addSubview:toolBar];
    CGRect frame = footerView.frame;
    frame.origin.y = 0;
    toolBar.frame = frame;
    [toolBar removeFromSuperview];
    
    isCancel = NO;
//    connection = nil;
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
    [MobClick beginLogPageView:@"RestoreView"];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
   return (IS_IPAD || (interfaceOrientation == UIInterfaceOrientationPortrait));
}

//---------------------------

-(IBAction) btnCancelClicked: (id) sender {
//    if ([ModalAlert confirm:NSLocalizedString(@"CancelRestore", nil)]) {
        isCancel = YES;
        [toolBar removeFromSuperview];
        backupFile.isCancel = YES;
        self.navigationController.navigationBar.userInteractionEnabled = YES;
        [btnRestore setEnabled:YES];
    
        [PCUtilityUiOperate showOKAlert:NSLocalizedString(@"AddressBookRestoreCancelSuccessful", nil) delegate:self];

//    }
    /*
    if (connection) {
        [connection cancel];
    }
    else {
        backupFile.isCancel = YES;
    }
     */
}

-(IBAction) btnInfoClicked: (id) sender {
    [PCUtilityUiOperate showOKAlert:NSLocalizedString(@"ConfirmRestore", nil) delegate:self];
}

- (void)updateUI:(id *)content
{
    if (!isCancel) [PCUtilityUiOperate showOKAlert:NSLocalizedString(@"AddressBookRestoreSuccessful", nil) delegate:self];
    
    [toolBar removeFromSuperview];
    
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [btnRestore setEnabled:YES];
}


- (void) restoreData {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
/*
    if (!isCancel) [backupFile backupOldData:progressView progressScale:0.4 scaleOffset:0];
    if (!isCancel) {
        [backupFile restoreContact:localPath progressView:progressView progressScale:0.6]; 
    }
    else {
        [backupFile deleteRestoreOldData];
    }
   if (!isCancel) [backupFile deleteRestoreOldData];
 */
    if (!isCancel) {
        [backupFile restoreContact:localPath progressView:progressView progressScale:1.0];
    }

//    if (!isCancel) [PCUtility showOKAlert:NSLocalizedString(@"AddressBookRestoreSuccessful", nil) delegate:self];
//    
//    [toolBar removeFromSuperview];
//     
     [self performSelectorOnMainThread:@selector(updateUI:) withObject:nil waitUntilDone:YES];

    [pool release];
}


-(IBAction) btnRestoreClicked: (id) sender {
 //   if ([ModalAlert confirm:NSLocalizedString(@"ConfirmCoverAddressBook", nil)]) {
 //   }
    
    [footerView addSubview:toolBar];
    isCancel = NO;
    //    connection = nil;
    backupFile.isCancel = NO;
    progressView.progress = 0;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    [btnRestore setEnabled:NO];
    
    NSString *md5Ret = [NSString stringWithContentsOfFile:localMD5Path encoding:NSUTF8StringEncoding error:nil];
    NSString *fileMD5 = [PCUtilityEncryptionAlgorithm file_md5:localPath];
    
    if ([md5Ret compare:fileMD5] != NSOrderedSame) {
        [PCUtilityUiOperate showOKAlert:NSLocalizedString(@"BackupFileIsBad", nil) delegate:self];
        return;
    }



    [NSThread detachNewThreadSelector:@selector(restoreData) toTarget:self withObject:nil];
}

- (void) downloadMD5File {
    mStatus = FILE_TYPE_MD5;
    FileCache* fileCache = [[[FileCache alloc] init] autorelease];
    [fileCacheArr addObject:fileCache];
    [fileCache cacheFile:backupFile.md5File viewType:TYPE_CACHE_CONTACT viewController:self fileSize:-1 modifyGTMTime:0 showAlert:YES];
}

- (void) downloadBackupFile {
    mStatus = FILE_TYPE_BACKUP;
    FileCache* fileCache = [[[FileCache alloc] init] autorelease];
    fileCache.currentDeviceID = [PCLogin getResource];
    [fileCacheArr addObject:fileCache];
    [fileCache cacheFile:[NSString stringWithFormat:@"%@.zip" ,backupFile.filePath] viewType:TYPE_CACHE_CONTACT viewController:self fileSize:backupFile.fileSize modifyGTMTime:[backupFile.modifyTime longLongValue] showAlert:YES];
}

- (void) restoreContact:(NSString*)path {
    [dicatorView stopAnimating];
//    localPath = [path copy];
    if (backupFile.modifyTime) {
        [imgView setHidden:YES];
        [lblHint setHidden:YES];
        
        [lblText1 setHidden:NO];
        [lblInfo setHidden:NO];
        [lblModifyTime setHidden:NO];
        [lblContact setHidden:NO];
        [lblContactNumber setHidden:NO];
        
        [imgLine1 setHidden:NO];
        [imgLine2 setHidden:NO];
        
        [btnRestore setHidden:NO];
        [btnInfo setHidden:NO];
        [lblButton setHidden:NO];
        
        lblText1.text = NSLocalizedString(@"RestoreContactStatusTo", nil); 
        NSString *modifyTime = [backupFile getModifyTime];
        if (modifyTime) {
            lblModifyTime.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"BackupTime", nil), modifyTime]; 
        }
        
        NSArray *arrays = [NSArray arrayWithContentsOfFile:localPath];
        lblContactNumber.text = [NSString stringWithFormat:@"%d", arrays.count];
        //        [backupFile displayModifyTime:lblModifyTime];
    }
    else {
        lblHint.text = NSLocalizedString(@"NoBackupRecord", nil);
    }
}

- (void) cacheFileFinish:(FileCache*)fileCache {
    if (mStatus == FILE_TYPE_BACKUP) {
        NSString *zipPath = fileCache.localPath;
        
//        int oldSize4 = 0;
//        NSDictionary *attr4 = [[NSFileManager defaultManager] attributesOfItemAtPath:zipPath error:nil];
//        if (attr4) {
//            oldSize4 = [[attr4 objectForKey:NSFileSize] intValue];
//        }
        
        NSString *tempUnzipPath = [[zipPath stringByDeletingPathExtension] stringByAppendingString:@"tmp"];
        localPath =  [[tempUnzipPath  stringByAppendingString:@"/addressContent"] copy];
        localMD5Path =  [[tempUnzipPath  stringByAppendingString:@"/addressMD5"]  copy];
        BOOL isZipFail = YES;
        ZipArchive *zipArchive = [[ZipArchive alloc] init];
        if ([zipArchive UnzipOpenFile:zipPath]) {
            BOOL ret = [zipArchive UnzipFileTo:tempUnzipPath overWrite:YES];
            //        NSLog(@"%d", ret);
            if (ret) {
                isZipFail = NO;
            }
            [zipArchive UnzipCloseFile];
        }
        [zipArchive release];
        if(isZipFail == NO)
        {
            [self restoreContact:localPath];
        }
        else
        {
            
        }
    }
    [fileCacheArr removeObject:fileCache];
}

- (void) cacheFileFail:(FileCache*)fileCache hostPath:(NSString *)hostPath error:(NSString*)error {
    
    if (!(fileCache.errorNo == FILE_CACHE_ERROR_NO_NETWORK) && !(fileCache.errorNo == FILE_CACHE_ERROR_FILE_NO_FOUND) && fileCache.errorNo != FILE_CACHE_ERROR_LACK_OF_SPACE
        && [ModalAlert confirm:NSLocalizedString(@"DownloadBackupFileFailed", nil)]) {
        if (mStatus == FILE_TYPE_BACKUP) {
            [self downloadBackupFile];
        }
//        else {
//            [self downloadMD5File];
//        }
    }
    else {
        [dicatorView stopAnimating];
        lblHint.text = NSLocalizedString(@"GetMessageFromPCFailed", nil);
        [PCUtilityUiOperate showErrorAlert:error delegate:self];
    }
    [fileCacheArr removeObject:fileCache];
}

- (void) cacheFileProgress:(float)progress hostPath:(NSString *)hostPath {
    
}

@end
