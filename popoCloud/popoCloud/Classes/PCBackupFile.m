//
//  PCBackupFile.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-10-10.
//  Copyright 2011年 Kortide. All rights reserved.
//
#import "ZipArchive.h"
#import "PCBackupFile.h"
#import "PCLogin.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "PCUtilityUiOperate.h"
#import "PCUtilityEncryptionAlgorithm.h"
#import "PCUtilityShareGlobalVar.h"
#import "ABContact.h"
#import "ABContactsHelper.h"
#import "UIDevice+IdentifierAddition.h"

#define STATUS_GET_DOCUMENT_PATH 1
#define STATUS_GET_CONTACT_FILE_INFO 2

@implementation PCBackupFile

@synthesize delegate;
@synthesize haveGetInfo;
@synthesize filePath;
@synthesize modifyTime;
@synthesize fileSize;
@synthesize isCancel;
@synthesize md5File;
@synthesize data;

- (id)init
{
    self = [super init];
    if (self) {
        haveGetInfo = NO;
        isFinish = YES;
        isCancel = NO;
        md5File = nil;
        plistPath = [[NSString stringWithFormat:@"%@/backup.plist", [PCUtilityShareGlobalVar getPListPath]] retain];
        tmpBackupPath = [[NSString stringWithFormat:@"%@/backup.tmp", [PCUtilityShareGlobalVar getPListPath]] retain];
    }
    
    return self;
}

- (void)dealloc
{
    [documentPath release];
    [data release];
    [super dealloc];
}

+ (BOOL) checkRestoreOldData {
    NSFileManager *fileManage = [NSFileManager defaultManager];
    return [fileManage fileExistsAtPath:[NSString stringWithFormat:@"%@/backup.plist", [PCUtilityShareGlobalVar getPListPath]]] && [fileManage fileExistsAtPath:[NSString stringWithFormat:@"%@/backup.tmp", [PCUtilityShareGlobalVar getPListPath]]];
}

- (void) deleteRestoreOldData {
    NSFileManager *fileManage = [NSFileManager defaultManager];
    [fileManage removeItemAtPath:plistPath error:nil];
    [fileManage removeItemAtPath:tmpBackupPath error:nil];
}

- (void) restoreOldData:(UIProgressView*)_progressView progressScale:(float)scale {
    [self restoreContact:tmpBackupPath progressView:_progressView progressScale:scale];
}

- (void) backupOldData:(UIProgressView*)_progressView progressScale:(float)scale scaleOffset:(float)offset {
    NSInteger count = [self backupContact:tmpBackupPath progressView:_progressView progressScale:scale scaleOffset:offset];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSNumber numberWithInteger:count] forKey:@"count"];
    [dict writeToFile:plistPath atomically:YES];
}

//---------------------------------------
- (void) getBackupInfo {
    if (!haveGetInfo && isFinish) {
        isFinish = NO;
        [self getDocumentPath];
    }
    else {
        [delegate getBackupFileInfoFinish];
    }
}

- (void) getDocumentPath {
    mStatus = STATUS_GET_DOCUMENT_PATH;
    documentPath = nil;
    //    data = [[NSMutableData data] retain];
    //    [dicatorView startAnimating];
    NSString* url = @"GetSpecialFolder?folderName=document";
    [PCUtility httpGetWithURL:url headers:nil delegate:self];
}

- (void) getContactFileInfo {
    mStatus = STATUS_GET_CONTACT_FILE_INFO;
    //    data = [[NSMutableData data] retain];
    
    fileSize = 0;
    modifyTime = nil;
    
    //获取设备id号
    UIDevice *device = [UIDevice currentDevice];//创建设备对象
    NSString *deviceUID = [device uniqueGlobalDeviceIdentifier];
    NSLog(@"%@",deviceUID); // 输出设备id
    
    filePath = [NSString stringWithFormat:@"%@/iPhone%@", documentPath, [deviceUID substringFromIndex:[deviceUID length] - 3]];
    [filePath retain];
    md5File = [NSString stringWithFormat:@"%@.md5", filePath];
    [md5File retain];
    
    //    [dicatorView startAnimating];
    NSString* url = [NSString stringWithFormat: @"GetFileInfo?filePath=%@.zip", [PCUtilityStringOperate encodeToPercentEscapeString:filePath]];
    [PCUtility httpGetWithURL:url headers:nil delegate:self];
}

//---------------------------------------------------------------
- (NSInteger) backupContact:(NSString*)path progressView:(UIProgressView*)progress progressScale:(float)scale scaleOffset:(float)offset {
    
    progressView = progress;
    
    ABAddressBookRef addressBook = ABAddressBookCreate();
    NSArray *peoples = [ABContactsHelper contacts:addressBook];
    NSMutableArray *arrays = [NSMutableArray arrayWithCapacity:peoples.count];
    int index = 0;
    

	NSArray *groups1 = (NSArray *)ABAddressBookCopyArrayOfAllGroups(addressBook);
	NSMutableArray *groups = [NSMutableArray arrayWithCapacity:groups1.count];
	for (id group in groups1)
		[groups addObject:[ABGroup groupWithRecord:(ABRecordRef)group]];
	[groups1 release];


    for (ABContact *people in peoples) {
        if (isCancel) {
            isCancel = NO;
            CFRelease(addressBook);
            return index;
        }
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        //        [dict setObject:[NSNumber numberWithInt:people.recordID] forKey:@"recordID"];
        
        int recordID = -1; 
        for (ABGroup *group in groups) {
            if ([group.members containsObject:people]) {
                recordID =  group.recordID;
            }
        }

        [dict setObject:[NSNumber numberWithInt:recordID]
                 forKey:@"groupID"];
        
        if ([people firstname]) [dict setObject:[people firstname] forKey:@"firstname"];
        if ([people lastname]) [dict setObject:[people lastname] forKey:@"lastname"];
        if ([people middlename]) [dict setObject:[people middlename] forKey:@"middlename"];
        if ([people prefix]) [dict setObject:[people prefix] forKey:@"prefix"];
        if ([people suffix]) [dict setObject:[people suffix] forKey:@"suffix"];
        if ([people nickname]) [dict setObject:[people nickname] forKey:@"nickname"];
        
        if ([people firstnamephonetic]) [dict setObject:[people firstnamephonetic] forKey:@"firstnamephonetic"];
        if ([people lastnamephonetic]) [dict setObject:[people lastnamephonetic] forKey:@"lastnamephonetic"];
        if ([people middlenamephonetic]) [dict setObject:[people middlenamephonetic] forKey:@"middlenamephonetic"];
        
        if ([people organization]) [dict setObject:[people organization] forKey:@"organization"];
        if ([people jobtitle]) [dict setObject:[people jobtitle] forKey:@"jobtitle"];
        if ([people department]) [dict setObject:[people department] forKey:@"department"];
        
        if ([people note]) [dict setObject:[people note] forKey:@"note"];
        
        if ([people birthday]) [dict setObject:[people birthday] forKey:@"birthday"];
        if ([people creationDate]) [dict setObject:[people creationDate] forKey:@"creationDate"];
        if ([people modificationDate]) [dict setObject:[people modificationDate] forKey:@"modificationDate"];
        
        if ([people emailDictionaries]) [dict setObject:[people emailDictionaries] forKey:@"emailDictionaries"];
        if ([people phoneDictionaries]) [dict setObject:[people phoneDictionaries] forKey:@"phoneDictionaries"];
        if ([people relatedNameDictionaries]) [dict setObject:[people relatedNameDictionaries] forKey:@"relatedNameDictionaries"];
        if ([people urlDictionaries]) [dict setObject:[people urlDictionaries] forKey:@"urlDictionaries"];
        if ([people dateDictionaries]) [dict setObject:[people dateDictionaries] forKey:@"dateDictionaries"];
        if ([people addressDictionaries]) [dict setObject:[people addressDictionaries] forKey:@"addressDictionaries"];
        if ([people smsDictionaries]) [dict setObject:[people smsDictionaries] forKey:@"IMDictionaries"];
 
        if ([people image]) {
            [dict setObject:UIImageJPEGRepresentation([people image], 0.0) forKey:@"image"];
        }
        
        [arrays addObject:dict];
        
        index++;
        if (progressView) {
            //progressView.progress = (float)index * scale / peoples.count + offset - 0.001;
            progressValue = (float)index * scale / peoples.count + offset - 0.001;
            [self performSelectorOnMainThread:@selector(setProgressBar) withObject:nil waitUntilDone:false];
//            NSLog(@"%d:%f", index, progressView.progress);
        }
    }
    
    [arrays writeToFile:path atomically:YES];

    NSString *md5Ret = [PCUtilityEncryptionAlgorithm file_md5:path];
    NSLog(@"%@,%@", path, md5Ret);
    BOOL ok  = [md5Ret writeToFile:[NSString stringWithFormat:@"%@.md5", path] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"%d", ok);
    
    ZipArchive* zip = [[ZipArchive alloc] init];
    NSString* zipPath = [path stringByAppendingString:@".zip"] ;
    
    BOOL ret = [zip CreateZipFile2:zipPath];
    NSLog(@"CreateZipFile ret=%d",ret);
    ret = [zip addFileToZip:path newname:@"addressContent"];
    NSLog(@"addFileToZip ret=%d",ret);
    ret = [zip addFileToZip:[NSString stringWithFormat:@"%@.md5", path]  newname:@"addressMD5"];
    NSLog(@"addFileToZip2 ret=%d",ret);
    [zip CloseZipFile2];
    [zip release];
    
    CFRelease(addressBook);
    
    return index;
}

-(void) setProgressBar {
    //float progress = progressView.progress + 0.001;
    float progress = progressValue;
    [progressView setProgress:progress];
}

- (NSInteger) restoreContact:(NSString*)path progressView:(UIProgressView*)progress progressScale:(float)scale {
    
    progressView = progress;
    NSError *err = nil;
    //[ABContactsHelper removeAll:&err];
    
    
    ABAddressBookRef addressBook = ABAddressBookCreate();
    NSArray *thePeople = (NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
    //	NSMutableArray *array = [NSMutableArray arrayWithCapacity:thePeople.count];
	for (id person in thePeople) {
        if (!ABAddressBookRemoveRecord(addressBook, (ABRecordRef)person, (CFErrorRef *) err)) {
            [thePeople release];
            CFRelease(addressBook);
            return NO;
        }
    }
    
	[thePeople release];
    //BOOL ret = ABAddressBookSave(addressBook,  (CFErrorRef *) error);
    //CFRelease(addressBook);

    
    //    NSLog(@"%d", [ABContactsHelper contactsCount]);
    
    NSMutableArray *arrays = [[NSMutableArray alloc] initWithContentsOfFile:path];
    NSLog(@"%d", arrays.count);
    int index = 0;
    int indexForTenPercent = 0;
    int  tenPercentNum = arrays.count/10;
    if (tenPercentNum == 0)
    {
        tenPercentNum = 1;
    }
    //addressBook必须为contact和group共同操作的对象，否则添加联系人到群组会失败
    //ABAddressBookRef addressBook = ABAddressBookCreate();
    
    for (NSDictionary *dict in arrays) {
        if (isCancel) {
            [arrays release];
            CFRelease(addressBook);
            isCancel = NO;
            return index;
        }
        
        ABContact *people = [ABContact contact];
        NSString* string = nil;
        if ((string = [dict objectForKey:@"firstname"])) [people setFirstname:string];
        if ((string = [dict objectForKey:@"lastname"])) [people setLastname:string];
        if ((string = [dict objectForKey:@"middlename"])) [people setMiddlename:string];
        if ((string = [dict objectForKey:@"prefix"])) [people setPrefix:string];
        if ((string = [dict objectForKey:@"suffix"])) [people setSuffix:string];
        if ((string = [dict objectForKey:@"nickname"])) [people setNickname:string];
        
        if ((string = [dict objectForKey:@"firstnamephonetic"])) [people setFirstnamephonetic:string];
        if ((string = [dict objectForKey:@"lastnamephonetic"])) [people setLastnamephonetic:string];
        if ((string = [dict objectForKey:@"middlenamephonetic"])) [people setMiddlenamephonetic:string];
        
        if ((string = [dict objectForKey:@"organization"])) [people setOrganization:string];
        if ((string = [dict objectForKey:@"jobtitle"])) [people setJobtitle:string];
        if ((string = [dict objectForKey:@"department"])) [people setDepartment:string];
        
        if ((string = [dict objectForKey:@"note"])) [people setNote:string];
        
        NSDate *date = nil;
        if ((date = [dict objectForKey:@"birthday"])) [people setBirthday:date];
        if ((date = [dict objectForKey:@"creationDate"])) [people setCreationDate:date];
        if ((date = [dict objectForKey:@"modificationDate"])) [people setModificationDate:date];
        
        NSArray *dicts = nil;
        if ((dicts = [dict objectForKey:@"emailDictionaries"])) [people setEmailDictionaries:dicts];
        if ((dicts = [dict objectForKey:@"phoneDictionaries"])) [people setPhoneDictionaries:dicts];
        if ((dicts = [dict objectForKey:@"relatedNameDictionaries"])) [people setRelatedNameDictionaries:dicts];
        if ((dicts = [dict objectForKey:@"urlDictionaries"])) [people setUrlDictionaries:dicts];
        
        if ((dicts = [dict objectForKey:@"dateDictionaries"])) [people setDateDictionaries:dicts];
        if ((dicts = [dict objectForKey:@"addressDictionaries"])) [people setAddressDictionaries:dicts];
        if ((dicts = [dict objectForKey:@"IMDictionaries"])) [people setSmsDictionaries:dicts];
        
        NSData *image = nil;
        if ((image = [dict objectForKey:@"image"])) [people setImageData:image];

        //BOOL success = [ABContactsHelper addContact:people withError:&err addressbook:addressBook];
        
        BOOL success =ABAddressBookAddRecord(addressBook, people.record, (CFErrorRef *) err);
        if (success) {
            ABRecordID groupID = ((NSNumber *)[dict objectForKey:@"groupID"]).intValue;
            //            NSLog(@"groupID:%d",groupID);
            if (groupID >= 0) {
                ABRecordRef grouprec = ABAddressBookGetGroupWithRecordID(addressBook, groupID);
                ABGroup *group = [ABGroup groupWithRecord:grouprec];
                //                CFRelease(grouprec);
                //success = [group addMember:people withError:&err addressBook:addressBook];
                success =ABGroupAddMember(group.record, people.record, (CFErrorRef *) err);
            }
        }
        
        if (!success) {
            NSLog(@"RestoreFail");
        }
        index++;
        indexForTenPercent++;
        if (progressView) {
            progressValue = (float)index * scale / arrays.count + (1 - scale) - 0.001;
            [self performSelectorOnMainThread:@selector(setProgressBar) withObject:nil waitUntilDone:false];
//            NSLog(@"%d:%f", index, progressView.progress);
        }
        if(indexForTenPercent == tenPercentNum)
        {
            ABAddressBookSave(addressBook, (CFErrorRef *) err);
            indexForTenPercent = 0;
        }
    }
    
    ABAddressBookSave(addressBook, (CFErrorRef *) err);
    //此处release会导致出错，说addressBook已被release了，但前部分代码已检查过没有哪里release过，不解
    CFRelease(addressBook);
    [arrays release];
    return index;
}
//---------------------------------------------------------------

-(void)pcConnection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.data = [NSMutableData data];
    
    NSInteger rc = [(NSHTTPURLResponse*)response statusCode];
    NSLog(@"status code: %d", rc);
    
}

-(void)pcConnection:(NSURLConnection *)connection didReceiveData:(NSData *)incomingData {
    [self.data appendData:incomingData];
}

- (void)pcConnectionDidFinishLoading:(NSURLConnection *)connection {
    
    NSString *ret = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
    NSLog(@"ret%@", ret);
    NSDictionary *dict = [ret JSONValue];
 
    if (mStatus == STATUS_GET_DOCUMENT_PATH) {
        if (dict) {
           NSString * errMsg = [dict objectForKey:@"errMsg"]?[dict objectForKey:@"errMsg"]:([dict objectForKey:@"message"]?[dict objectForKey:@"message"]:NSLocalizedString(@"ConnetError", nil));

            [PCUtilityUiOperate showErrorAlert:errMsg  delegate:self];
            //zhd add
            isFinish = YES;
        }
        else {
            if ([[ret substringToIndex:2] compare:@"<!"] != NSOrderedSame) {
                documentPath = [[NSString stringWithFormat:@"%@/PopoCloud/Backup/iOS", ret] retain];
//                NSLog(documentPath);
                [self getContactFileInfo];
            }
            else{
                //zhd add
                isFinish = YES;
            }
        }
    }
    else {
        isFinish = YES;
        haveGetInfo = YES;
        fileSize = [[dict objectForKey:@"size"] floatValue];
        modifyTime = [[dict objectForKey:@"modifyTime"] copy];
        [delegate getBackupFileInfoFinish];
    }
    
    dict = nil;
    [ret release];
    self.data = nil;
}

- (void)pcConnection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    isFinish = YES;
    if(connection == nil && error == nil)//这个是网络没连接时返回的，那边已经提示过了，不希望再弹提示了。
    {
        [delegate getBackupFileInfoFail:nil];
    }
    else{
    [delegate getBackupFileInfoFail:NSLocalizedString(@"ConnetError", nil)];
    }
    //[PCUtility showErrorAlert:[error localizedDescription] delegate:self];
    self.data = nil;
}

- (NSURLRequest *)pcConnection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    if ([redirectResponse URL]) {
        [connection cancel];
        PCLogin *pcLogin = [[PCLogin alloc] init];
        [pcLogin logIn:self];  
        return nil;
    }
    return request;
}

//-----------------------------------------------------------
- (void) loginFail:(PCLogin*)pcLogin error:(NSString*)error {
    [delegate getBackupFileInfoFail:error];
    [pcLogin release];
//    [PCUtility showErrorAlert:error delegate:self];
    
}

- (void) loginFinish:(PCLogin*)pcLogin {
    [pcLogin release];
    [self getDocumentPath];
}

- (void) networkNoReachableFail:(NSString*)error {
    [delegate getBackupFileInfoFail:error];
}

//------------------------------------------------------------
- (NSString *) getModifyTime {
    if (modifyTime) {
        //        [lblModifyTime setHidden:NO];
        return [PCUtilityStringOperate formatTime:[modifyTime doubleValue]/1000 formatString:@"yyyy-MM-dd HH:mm"];
    }
    else {
        return nil;
        return NSLocalizedString(@"NoDataForBackup", nil);
        //        [lblModifyTime setHidden:YES];
    }
    
}


//http://www.open-china.net/blog/127971.html
//http://ipsw.info/trac/browser/iphone-3.0-cookbook/C18-Address%20Book/08-Unknown%20Controller/ABContact.h

@end
