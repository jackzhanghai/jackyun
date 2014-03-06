//
//  ContactBackUpViewController.m
//  popoCloud
//
//  Created by xy  on 13-5-18.
//
//
#import "PCAppDelegate.h"
#import "ContactBackUpViewController.h"
#import "PCUtility.h"
#import "PCUtilityUiOperate.h"
#import "PCUtilityStringOperate.h"
#import "FileUpload.h"
#import "PCLogin.h"
#import "NetPenetrate.h"
#import "UIDevice+IdentifierAddition.h"

#define CUSTOM_ALERT_VIEW_TAG 1
#define PICKERVIEWALERTTAG 2
//@implementation PCAppDelegate
@interface ContactBackUpViewController ()

@end

@implementation ContactBackUpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        // self.backgroundColor=[UIColor greenColor];
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title =  NSLocalizedString(@"Contacts Backup & Restore", nil);
    readButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    [readButton addTarget:self action:@selector(BackupButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:readButton];
    
    writeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    [writeButton addTarget:self action:@selector(RestoreButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:writeButton];
    self.view.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    
    
    vcardEngine = [[VcardEngine alloc] init];
    vcardEngine.delegate = self;
    // text = [[UITextField alloc]initWithFrame:CGRectMake(10, 200, 300, 30)];
    
    text = [[UITextField alloc]init];
    text.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:text];
    [text setEnabled: NO];
    
    NSInteger systemContact = [vcardEngine GetPersonCount];
    if (systemContact == -1)
    {
        isAllowAccessContact = NO;
        systemContact = 0;
    }
    else
    {
        isAllowAccessContact = YES;
    }
    if (IS_IPAD)
    {
        [text setText:[NSString stringWithFormat:@"通讯录 | 本地：%d  盒子：%d",systemContact,0]];
        if ([[UIScreen mainScreen] applicationFrame].size.height==1024)
        {
            [readButton setBackgroundImage:[UIImage imageNamed:@"daochu_l@2x~ipad.png"] forState:UIControlStateNormal];
            [writeButton setBackgroundImage:[UIImage imageNamed:@"daoru_l@2x~ipad.png"] forState:UIControlStateNormal];
            [readButton setFrame:CGRectMake(28.0, 40.0, 937, 85)];
            [writeButton setFrame:CGRectMake(28.0, 180.0, 937, 85)];
            [text setFrame:CGRectMake(28, 320, 937, 50)];
            
            [text setFont:[UIFont fontWithName:@"Courier" size:40]];
            
        }
        else
        {
            [readButton setBackgroundImage:[UIImage imageNamed:@"daochu@2x~ipad.png"] forState:UIControlStateNormal];
            [writeButton setBackgroundImage:[UIImage imageNamed:@"daoru@2x~ipad.png"] forState:UIControlStateNormal];
            [readButton setFrame:CGRectMake(28.0, 40.0, 702, 85)];
            [writeButton setFrame:CGRectMake(28.0, 180.0, 702, 85)];
            [text setFrame:CGRectMake(28, 320, 702, 50)];
            [text setFont:[UIFont fontWithName:@"Courier" size:40]];
            
        }
    }
    else
    {
        [readButton setBackgroundImage:[UIImage imageNamed:@"contactBackup.png"] forState:UIControlStateNormal];
        [writeButton setBackgroundImage:[UIImage imageNamed:@"contactRestore.png"] forState:UIControlStateNormal];
        [readButton setFrame:CGRectMake(7.0, 20.0, 306.5, 57)];
        [writeButton setFrame:CGRectMake(7.0, 91.0, 307.5, 57.5)];
        [text setFrame:CGRectMake(10, 200, 300, 25)];
        [text setText:[NSString stringWithFormat:@"通讯录|本地：%d 盒子：%d",systemContact,0]];
        [text setFont:[UIFont fontWithName:@"Courier" size:18]];
        
    }
    
    fileCache = [[FileCache alloc] init];
    uploadTask = [[FileUpload alloc] init];
    _tableFileCache = [[NSMutableDictionary alloc] init];
    data = [[NSMutableData alloc] init];
    getVcfInfo = [[NSMutableDictionary alloc]init];
    vcfName = [[NSMutableArray alloc]init];
    progressBox = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:progressBox];
    progressBox.delegate = self;
    
    if (isAllowAccessContact )
    {
        [progressBox show:YES];
        progressBox.labelText = @"获取服务器信息";
        self.tabBarController.tabBar.userInteractionEnabled = NO;
        [self geServerContactInfo:@"GetContactCount"];
    }
    else
    {
        UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"授权提示" message:@"请进入【设置】-【隐私】-【通讯录】-【泡泡云】允许后才能继续使用"delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil)  otherButtonTitles:nil];
        
        [alter show];
        [alter release];
        
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"ContactBackUpView"];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"ContactBackUpView"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) BackupButtonPressed:(id)sender
{
    
    [MobClick event:UM_CONTACTS_BACKUP];
    if(NO ==isAllowAccessContact)
    {
        UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"授权提示" message:@"请进入【设置】-【隐私】-【通讯录】-【泡泡云】允许后才能继续使用"delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil)  otherButtonTitles:nil];
        
        [alter show];
        [alter release];
        return;
    }
    if (![PCUtility isNetworkReachable:nil])
    {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"NetNotReachableError", nil) delegate:nil];
        return;
    }
    if (0 == [vcardEngine GetPersonCount])
    {
        UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"泡泡云温馨提示" message:@"你的通讯录联系人为空"delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil)  otherButtonTitles:nil];
        
        [alter show];
        [alter release];
        return;
    }
    
    progressBox = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:progressBox];
	progressBox.labelText = NSLocalizedString(@"back up", nil);
    progressBox.progress = 0;
    // Regiser for HUD callbacks so we can remove it from the window at the right time
    progressBox.delegate = self;
    progressBox.mode = MBProgressHUDModeIndeterminate;
    [progressBox show:YES];
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    NSLog(@"tabbar %@",self.tabBarController.tabBar);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString * systemContactPath = [vcardEngine loadAddressBook];
        NSData *fileData = [NSData dataWithContentsOfFile:systemContactPath];
        NSRange location = [systemContactPath rangeOfString:@"/tmp/"];
        NSString *fileName = [systemContactPath substringFromIndex:location.location+location.length];
        
        dispatch_async(dispatch_get_main_queue(), ^(void)
                       {
                           PCFileUpload *uploadRequest = [[PCFileUpload alloc] init];
                           [uploadRequest setDstPath:fileName];
                           [uploadRequest setData:fileData];
                           [uploadRequest setFileType:FILE_TYPE_CONTACT_VCF];
                           [uploadRequest setDelegate:self];
                           [uploadRequest setDeviceID:[PCLogin getResource]];
                           [uploadTask upload:uploadRequest];
                           [uploadRequest release];
                       });
    });
    
}

- (void) RestoreButtonPressed:(id)sender
{
    
    if(NO ==isAllowAccessContact)
    {
        UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"授权提示" message:@"请进入【设置】-【隐私】-【通讯录】-【泡泡云】允许后才能继续使用"delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil)  otherButtonTitles:nil];
        
        [alter show];
        [alter release];
        return;
    }
    
    if (![PCUtility isNetworkReachable:nil])
    {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"NetNotReachableError", nil) delegate:nil];
        return;
    }
    progressBox = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:progressBox];
	
    // Regiser for HUD callbacks so we can remove it from the window at the right time
    progressBox.delegate = self;
    [progressBox show:YES];
    progressBox.labelText = @"获取服务器信息";
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    //self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    [self geServerContactInfo:@"GetContactAllFileList"];
}

//
- (void) geServerContactInfo:(NSString *) urlstr
{
    if (self.currentRequest)
    {
        [self.currentRequest cancel];
        self.currentRequest = nil;
    }
    [getVcfInfo removeAllObjects];
    [vcfName removeAllObjects];
    PCURLRequest *request = [[[PCURLRequest alloc] initWithTarget:self selector:@selector(contactRequestFinish:)] autorelease];
    request.process = urlstr;
    
    if ([urlstr isEqualToString:@"GetContactCount"])
    {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setObject:[[UIDevice currentDevice] uniqueGlobalDeviceIdentifier] forKey:@"phoneId"];
        request.params = dic;
    }
    self.currentRequest = request;
    [request start];
    
    
    
}
-(void)contactRequestFinish:(PCURLRequest *)request
{
    [progressBox hide:YES];
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    if (request.error)
    {
        UIAlertView *alter = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:NSLocalizedString(@"ConnetError",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil)  otherButtonTitles:nil];
        
        [alter show];
        [alter release];
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = [[request resultString] JSONValue];
        
        if (nil != [dict objectForKey:@"data"] )
        {
            NSMutableArray * nodeArray = [dict objectForKey:@"data"];
            NSInteger count = [nodeArray count];
            if (0 == count)
            {
                UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"泡泡云温馨提示" message:@"您的联系人是空的噢！"delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil)  otherButtonTitles:nil];
                
                [alter show];
                [alter release];
                
            }
            else
            {
                NSString * phoneId =[[UIDevice currentDevice] uniqueGlobalDeviceIdentifier];
                
                for(int i = 0 ;i <count; i++)
                {
                    NSDictionary * info =  [nodeArray objectAtIndex:i];
                    NSString * localpath = [info objectForKey:@"path"];
                    NSString * name =  [PCUtilityStringOperate decodeFromPercentEscapeString:[info objectForKey:@"name"]];
                    
                    
                    if ( NSNotFound != [localpath rangeOfString:phoneId].location
                        && [name hasSuffix:@".vcf"])
                    {
                        [getVcfInfo setObject:localpath forKey:name];
                        [vcfName insertObject:name atIndex:0];
                        // [vcfName addObject:name];
                    }
                }
                NSMutableArray *phoneIdArray = [[NSMutableArray alloc]init];
                for(int i = 0 ;i <count; i++)
                {
                    NSDictionary * info =  [nodeArray objectAtIndex:i];
                    NSString * localpath = [info objectForKey:@"path"];
                    NSString * name = [info objectForKey:@"name"];
                    NSInteger typeStart = [localpath rangeOfString:@"/.popoCloud/Contact Backup/"].location + 27;
                    NSString *deviceId = [localpath substringWithRange:NSMakeRange(typeStart,localpath.length - typeStart - name.length - 1)];
                    if ([deviceId compare:phoneId] == NSOrderedSame || [phoneIdArray containsObject:deviceId] == YES) {
                    }
                    else
                    {
                        NSInteger addLocation = [vcfName count];
                        for(int j = 0 ;j <count; j++)
                        {
                            NSDictionary * info =  [nodeArray objectAtIndex:j];
                            NSString * localpath = [info objectForKey:@"path"];
                            NSString * name =  [PCUtilityStringOperate decodeFromPercentEscapeString:[info objectForKey:@"name"]];
                            
                            if ( NSNotFound !=[localpath rangeOfString:deviceId].location
                                && [name hasSuffix:@".vcf"] )
                            {
                                [getVcfInfo setObject:localpath forKey:name];
                                [vcfName insertObject:name atIndex:addLocation];
                                //[vcfName addObject:name];
                                
                            }
                            if (j == (count -1))
                            {
                                [phoneIdArray addObject:deviceId];
                            }
                        }
                    }
                }
                
                [phoneIdArray release];
                [self popupSelect];
            }
            
        }
        else if (nil != [dict objectForKey:@"count"] )
        {
            NSString *temp = [dict objectForKey:@"count"];
            serverContactNum = [temp intValue];
            NSInteger systemContact = [vcardEngine GetPersonCount];
            if(IS_IPAD)
                [text setText:[NSString stringWithFormat:@"通讯录 | 本地：%d  盒子：%d",systemContact,serverContactNum]];
            else
                [text setText:[NSString stringWithFormat:@"通讯录|本地：%d 盒子：%d",systemContact,serverContactNum]];
            
        }
        else if(nil !=[dict objectForKey:@"errMsg"] &&
                [request.process isEqualToString:@"GetContactCount"])
        {
              [self  showCustomAlert];
         }
        else if( [(NSString *)[dict objectForKey:@"errMsg"] isEqualToString:@"popoCloud.error.NotExistDisks"] &&
                ([request.process isEqualToString:@"GetContactAllFileList"]) )
        {
            
            self.tabBarController.tabBar.userInteractionEnabled = YES;
            UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"获取联系人列表失败！" message:@"请检查硬盘是否正常连接！"delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil)  otherButtonTitles:nil];
            
            [alter show];
            [alter release];
        }
        else if([request.process isEqualToString: @"GetContactAllFileList"])
        {
            int result = [[dict objectForKey:@"result"] intValue];
            if ([dict objectForKey:@"errCode"]) {
                result = [[dict objectForKey:@"errCode"]  intValue];
            }
            self.tabBarController.tabBar.userInteractionEnabled = YES;
            NSError *error2 = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
            [ErrorHandler showErrorAlert:error2];
//            UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"" message:@"泡泡云没有任何联系人，亲，赶快备份吧"delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil)  otherButtonTitles:nil];
//            
//            [alter show];
//            [alter release];
        }
        
        dict = nil;
    }
    self.currentRequest = nil;
}
- (void) geServerContactFile:(NSString *)filePath
{
    [fileCache cacheFile:filePath viewType:TYPE_CACHE_VCF_FILE viewController:self fileSize:-1 modifyGTMTime: 0 showAlert:NO];
}
- (void)dealloc
{
    if (progressBox) {
        progressBox.delegate = nil;
        [progressBox removeFromSuperview];
        [progressBox release];
    }
    if (self.currentRequest) {
        [self.currentRequest cancel];
        self.currentRequest = nil;
    }
    
    if (_tableFileCache)
    {
        for (FileCache *cacheInfo in [_tableFileCache  allValues ] ) {
            [cacheInfo cancel];
            cacheInfo.delegate = nil;
            //[cacheInfo release];
        }
        [_tableFileCache release];
    }
    vcardEngine.delegate = nil;
    [uploadTask release];
    [vcardEngine release];
    [data release];
    [getVcfInfo release];
    [vcfName release];
    [super dealloc];
    
}
-(void)lockUI
{
    readButton.userInteractionEnabled = NO;
    writeButton.userInteractionEnabled = NO;
    text.userInteractionEnabled = NO;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.tabBarController.tabBar.userInteractionEnabled = NO;
}
-(void)unLockUI
{
    readButton.userInteractionEnabled = YES;
    writeButton.userInteractionEnabled = YES;
    text.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.tabBarController.tabBar.userInteractionEnabled = YES;
}
-(void)popupSelect
{
    CustomPickerView  *popupSelectAlert = [[CustomPickerView alloc] initWithFrame:CGRectMake(0, 0, IS_IPAD ? 500 : 245, 330)];
    popupSelectAlert.delegate = self;
    popupSelectAlert.tag = PICKERVIEWALERTTAG;
    popupSelectAlert.frame = CGRectMake((self.view.frame.size.width - popupSelectAlert.frame.size.width) / 2, (self.view.frame.size.height - popupSelectAlert.frame.size.height) / 2, popupSelectAlert.frame.size.width, popupSelectAlert.frame.size.height);
    [popupSelectAlert updateContactFileName:vcfName];
    [self.view addSubview:popupSelectAlert];
    [popupSelectAlert release];
    [self lockUI];
}
#pragma mark -
#pragma mark CustomPickerViewDelegate
-(void)customPickerViewClickCancelButton:(CustomPickerView *)picker
{
    [self unLockUI];
    [picker removeFromSuperview];
}

-(void)customPickerViewClickOKButton:(CustomPickerView *)picker
{
    [self unLockUI];
    
    NSInteger fileNum = [picker getResult];
    [picker removeFromSuperview];
    
    if (![PCUtility isNetworkReachable:nil])
    {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"NetNotReachableError", nil) delegate:nil];
        return;
    }
    
    progressBox = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:progressBox];
    
    // Regiser for HUD callbacks so we can remove it from the window at the right time
    progressBox.delegate = self;
    progressBox.labelText = @"下载联系人数据";
    [progressBox show:YES];
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    //   NSString *fileName = [[getVcfInfo allKeys] objectAtIndex:fileNum];
    NSString *fileName = [vcfName objectAtIndex:fileNum];
    NSString *filepath = [getVcfInfo objectForKey:fileName];
    [self geServerContactFile:filepath];
}

#pragma -----
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            //Cancel
            break;
        case 1:
        {//Set
            if (![PCUtility isNetworkReachable:nil])
            {
                [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"NetNotReachableError", nil) delegate:nil];
                return;
            }
            progressBox = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
            [self.navigationController.view addSubview:progressBox];
            
            // Regiser for HUD callbacks so we can remove it from the window at the right time
            progressBox.delegate = self;
            progressBox.labelText = @"下载联系人数据";
            [progressBox show:YES];
            self.tabBarController.tabBar.userInteractionEnabled = NO;
            NSInteger fileNum = [(CustomPickerView *)alertView getResult];
            //   NSString *fileName = [[getVcfInfo allKeys] objectAtIndex:fileNum];
            NSString *fileName = [vcfName objectAtIndex:fileNum];
            NSString *filepath = [getVcfInfo objectForKey:fileName];
            [self geServerContactFile:filepath];
            
            break;
            
        }
        default:
            break;
    }
}

- (void) cacheFileFinish:(FileCache*)fileCache
{
    NSString *path = [fileCache.localPath copy];
    
    [self saveContactToSystem:path];
    [path release];
}

- (void) cacheFileProgress:(float)progress hostPath:(NSString *)hostPath;
{
    [self updateProgress:progress title:@"正在下载联系人数据到手机" mode:MBProgressHUDModeDeterminate];
}

-(void)saveContactToSystem:(NSString *)path
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger addContactNum = [vcardEngine addContactsToSystem:path];
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressBox hide:YES];
            self.tabBarController.tabBar.userInteractionEnabled = YES;
            // NSInteger addContactNum = [vcardEngine GetuploadContactNum];
            [MobClick event:UM_RESTORE_SUCCESS];
            if(0 == addContactNum)
            {
                UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"无更新" message:@"您的本地联系人无更新" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
                
                [alter show];
                [alter release];
            }
            else
            {
                UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"导入成功!" message:[NSString stringWithFormat:@"给力啊～成功同步通讯录到手机，共有联系人%d个！",addContactNum] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
                
                [alter show];
                [alter release];
            }
            if(IS_IPAD)
                [text setText:[NSString stringWithFormat:@"通讯录 | 本地：%d  盒子：%d",[vcardEngine GetPersonCount],serverContactNum]];
            else
                [text setText:[NSString stringWithFormat:@"通讯录|本地：%d 盒子：%d",[vcardEngine GetPersonCount],serverContactNum]];
        });
    });
    
}

- (void) uploadFileFail:(FileUpload*)fileUpload hostPath:(NSString*)path error:(NSString*)error
{
    [progressBox hide:YES];
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    if ([error isEqualToString:NSLocalizedString(@"NotExistDisksForUpload", nil)]) {
        error = NSLocalizedString(@"NotExistDisksForUploadForContact", nil);
    }

    UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"备份失败！" message:error delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil)  otherButtonTitles:nil];
    
    [alter show];
    [alter release];
}
- (void) uploadFileProgress:(FileUpload*)fileUpload currentSize:(long long)currentSize totalSize:(long long)totalSize hostPath:(NSString *)path
{
    [self updateProgress:0 title:@"正在上传数据到服务器" mode:MBProgressHUDModeIndeterminate];
}
- (void) uploadFileFinish:(FileUpload*)fileUpload hostPath:(NSString*)path fileSize:(long long)size
{
    serverContactNum =[vcardEngine GetUploadCount];
    
    [MobClick event:UM_BACKUP_SUCCESS];
    [progressBox hide:YES];
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    UIAlertView *alter = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Backup success",nil) message:[NSString stringWithFormat:@"给力啊～成功上传通讯录到泡泡云盒子，共有联系人%d个！",serverContactNum]delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
    
    [alter show];
    [alter release];
    if(IS_IPAD)
        [text setText:[NSString stringWithFormat:@"通讯录 | 本地：%d  盒子：%d",serverContactNum,serverContactNum]];
    else
        [text setText:[NSString stringWithFormat:@"通讯录|本地：%d 盒子：%d",serverContactNum,serverContactNum]];
    
    
}
- (void)cacheFileFail:(FileCache *)fileCache hostPath:(NSString *)hostPath error:(NSString *)error
{
    [progressBox hide:YES];
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    if (NSOrderedSame == [error compare:NSLocalizedString(@"NotExist", nil)])
    {
        UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"导入联系人失败" message:@"请检查硬盘是否正常连接！" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil)  otherButtonTitles:nil];
        [alter show];
        [alter release];
    }
    else
    {
        UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"导入联系人失败" message:@"网络异常或泡泡云盒子不在线，请检查连接是否正常～" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil)  otherButtonTitles:nil];
        
        [alter show];
        [alter release];
    }
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    // Remove HUD from screen when the HUD was hidded
    [progressBox removeFromSuperview];
    if (![self.view  viewWithTag:PICKERVIEWALERTTAG])
    {
        self.tabBarController.tabBar.userInteractionEnabled = YES;
    }
    
	[progressBox release];
    progressBox = nil;
}


-(void) customAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [alertView removeFromSuperview];
    [self unLockUI];
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

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duratio;
{
    if (IS_IPAD)
    {
        UIView *alertView = [self.view viewWithTag:CUSTOM_ALERT_VIEW_TAG];
        if (interfaceOrientation == UIInterfaceOrientationPortrait ||
            interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            
            [readButton setBackgroundImage:[UIImage imageNamed:@"daochu@2x~ipad.png"] forState:UIControlStateNormal];
            [writeButton setBackgroundImage:[UIImage imageNamed:@"daoru@2x~ipad.png"] forState:UIControlStateNormal];
            [readButton setFrame:CGRectMake(28.0, 40.0, 702, 85)];
            [writeButton setFrame:CGRectMake(28.0, 180.0, 702, 85)];
            [text setFrame:CGRectMake(28, 320, 702, 50)];
            
            if (alertView) {
                alertView.center = CGPointMake(384, 450);
            }
            
        }
        else if(interfaceOrientation == UIInterfaceOrientationLandscapeRight ||
                interfaceOrientation == UIInterfaceOrientationLandscapeLeft )
        {
            [readButton setBackgroundImage:[UIImage imageNamed:@"daochu_l@2x~ipad.png"] forState:UIControlStateNormal];
            [writeButton setBackgroundImage:[UIImage imageNamed:@"daoru_l@2x~ipad.png"] forState:UIControlStateNormal];
            [readButton setFrame:CGRectMake(28.0, 40.0, 937, 85)];
            [writeButton setFrame:CGRectMake(28.0, 180.0, 937, 85)];
            [text setFrame:CGRectMake(28, 320, 937, 50)];
            
            if (alertView) {
                alertView.center =  CGPointMake(512, 328);
            }
            
        }
        if ([self.view  viewWithTag:PICKERVIEWALERTTAG]) {
            CustomPickerView *view = (CustomPickerView *)[self.view  viewWithTag:PICKERVIEWALERTTAG];
            view.frame = CGRectMake((self.view.frame.size.width - view.frame.size.width) / 2, (self.view.frame.size.height - view.frame.size.height) / 2, view.frame.size.width, view.frame.size.height);
        }
    }
}

-( void )showCustomAlert
{
    if (IS_IPAD)
    {
        if ([[UIScreen mainScreen] applicationFrame].size.height==1024)
        {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [btn setImage:[UIImage imageNamed:@"popo_close@2x~ipad"] forState:UIControlStateNormal];
            [btn setFrame:CGRectMake(380, 85, 54, 54)];
            UIImage *backgroundImage = [UIImage imageNamed:@"popo@2x~ipad.png"];
            
            contactCustomAlert *alert = [[contactCustomAlert alloc] initWithImage:backgroundImage contentImage:nil];
            alert.CustomAlertdelegate = self;
            [alert addButtonWithUIButton:btn];
            [self.view addSubview:alert];
            alert.tag = CUSTOM_ALERT_VIEW_TAG;
            //[alert show];
            [alert setNeedsLayout];
            [self lockUI];
        }
        else
        {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [btn setImage:[UIImage imageNamed:@"popo_close@2x~ipad"] forState:UIControlStateNormal];
            [btn setFrame:CGRectMake(380, 85, 54, 54)];
            UIImage *backgroundImage = [UIImage imageNamed:@"popo@2x~ipad.png"];
            
            contactCustomAlert *alert = [[contactCustomAlert alloc] initWithImage:backgroundImage contentImage:nil];
            alert.CustomAlertdelegate = self;
            [alert addButtonWithUIButton:btn];
            [self.view addSubview:alert];
            alert.tag = CUSTOM_ALERT_VIEW_TAG;
            //[alert show];
            [alert setNeedsLayout];
            [self lockUI];
        }
        
    }
    else
    {
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setImage:[UIImage imageNamed:@"popo_close.png"] forState:UIControlStateNormal];
        [btn setFrame:CGRectMake(160, 55, 32, 32)];
        UIImage *backgroundImage = [UIImage imageNamed:@"popo@2x.png"];
        contactCustomAlert *alert = [[contactCustomAlert alloc] initWithImage:backgroundImage contentImage:nil];
        alert.CustomAlertdelegate = self;
        alert.tag = CUSTOM_ALERT_VIEW_TAG;
        [alert addButtonWithUIButton:btn];
        [self.view addSubview:alert];
        [self lockUI];
        
        //[alert show];
        [alert setNeedsLayout];
    }
    
    
}

- (void) networkNoReachableFail:(NSString*)error {
    [progressBox hide:YES];
    [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"NetNotReachableError", nil) delegate:self];
}



- (void) updateProgress:(float)progress title:(NSString *)promptStr mode:(MBProgressHUDMode)progressMode
{
    
    if (promptStr)
    {
        progressBox.labelText = promptStr;
    }
    progressBox.progress = progress;
    progressBox.mode = progressMode;
    
}
@end
