//
//  FileUpload.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-30.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "FileUpload.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "FileListViewController.h"
#import "PCLogin.h"
#import "NetPenetrate.h"
#import "UIDevice+IdentifierAddition.h"
#import "PCUtilityUiOperate.h"

@interface FileUpload ()
{
    NSMutableData *receivedData;
}
@property (nonatomic,retain) NSMutableData *receivedData;

@end

@implementation FileUpload
@synthesize connection;
@synthesize receivedData;
@synthesize errCode;
@synthesize uploadStage;
@synthesize checkDiskSpaceRequest;
@synthesize serverUrl;

- (id)init
{
    self = [super init];
    if (self)
    {
        self.receivedData = [NSMutableData dataWithLength:1000];
    }
    return self;
}

- (void)dealloc
{
    [self cancel];
    self.serverUrl = nil;
    self.receivedData = nil;
    self.uploadRequest = nil;
    [super dealloc];
}


- (KTURLRequest*)checkDiskSpaceWithInfo:(NSString*)hostPath
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotCheckDiskSpaceResult:)];
    request.process = @"GetDiskSpace";
    request.params =     [NSDictionary dictionaryWithObjectsAndKeys:
                          [PCUtilityStringOperate encodeToPercentEscapeString:[hostPath stringByDeletingLastPathComponent]],  @"filePath",
                          nil];
    [request start];
    return [request autorelease];
}

- (void)getCheckDiskSpaceInfoErr:(NSString *)error
{
    if (self.uploadRequest.delegate)
    {
        [self.uploadRequest.delegate uploadFileFail:self
                                           hostPath:self.uploadRequest.dstPath
                                              error:error];
    }
}

- (void)requestDidGotCheckDiskSpaceResult:(KTURLRequest *)request
{
    if (request.error) {
        [self getCheckDiskSpaceInfoErr:NSLocalizedString(@"ConnetError", nil)];
    }
    else {
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        if (dict )//为0即表示已经存在了
        {
            if ( [[dict objectForKey:@"result"] intValue] == 0)//为0表示磁盘可写
            {
                //INFO 返回的   kb 为单位
                if([[dict objectForKey:@"info"] longLongValue]*1024  <= [[self.uploadRequest data] length])
                {
                    errCode = PC_Err_LackSpace;
                    NSString *errMsg;
                    if ([self.uploadRequest fileType] == FILE_TYPE_CONTACT_VCF)
                    {
                        errMsg = NSLocalizedString(@"NoSpaceForBackup", nil);
                    }
                    else
                    {
                        errMsg = NSLocalizedString(@"NoSpaceLeftForUpload", nil);
                    }
                    [self getCheckDiskSpaceInfoErr:errMsg];
                }
                else
                {
                    [self startUpload];
                }
            }
            else
            {
                NSString *errMsg = NSLocalizedString(@"ConnetError", nil);
                errCode = [[dict objectForKey:@"errCode"] intValue] ;
                switch (errCode)
                {
                    case PC_Err_ReadOnly:
                    {
                        errMsg = NSLocalizedString(@"DiskReadOnlyForUpload", nil);
                    }
                        break;
                        
                    case PC_Err_NoDisk:
                    {
                        errMsg = NSLocalizedString(@"NotExistDisksForUpload", nil);
                    }
                        break;
                        
                    default:
                        break;
                }
                
                [self getCheckDiskSpaceInfoErr:errMsg];
            }
        }
        else
        {
            [self getCheckDiskSpaceInfoErr:NSLocalizedString(@"ConnetError", nil)];
        }
    }
}

- (BOOL)upload:(PCFileUpload *)request
{
    //保留请求
    [self setUploadRequest:request];
    self.serverUrl = nil;
    
    //获得设备ID
    NSString *deviceID = [request deviceID] ? [request deviceID] : [PCLogin getResource];
    
    //获得要上传的文件类型
    int type = [request fileType];
    
    //请求主机地址
    NSString *hostPath = [request dstPath];
    
    //要发送的数据
    NSData *postData = [request data];
    
    //如果用户传的数据是为空的，则从文件里面去取
    if (postData == nil)
    {
        postData = [NSData dataWithContentsOfFile:[request src]];
        [self.uploadRequest setData:postData];
    }
    [self.uploadRequest setFileSize:[postData length]];
    
    //要上传文件的修改时间
    NSDate *modifyTime = [request modifyTime];
    
    //是否是穿透
    BOOL isPenetrate = [[NetPenetrate sharedInstance] isPenetrate];
    
    //判断设备id是否和登陆的设备id相同
    BOOL checkDevice = [deviceID isEqualToString:[PCLogin getResource]];
    
    //如果文件是图片或者Md5加密过的文件
    if (type == FILE_TYPE_IMAGE  || type == FILE_TYPE_MD5)
    {
        uploadStage = UploadStage_CheckExist;
        
        //发起连接
        self.checkDiskSpaceRequest = [self checkDiskSpaceWithInfo:hostPath];
        //self.connection = [PCUtility httpGetWithURL:url headers:nil delegate:self];
    }
    else if (isPenetrate && checkDevice)
    {
        uploadStage = UploadStage_UploadData;
        if (type == FILE_TYPE_CONTACT_VCF)
        {
            self.connection = [PCUtility postContactFileData:postData
                                                         md5:nil
                                                     dstPath:hostPath
                                              replaceOldFile:NO
                                                    delegate:self
                                                 whichServer:nil];
        }
        else
        {
            self.connection = [PCUtility postFileData:postData
                                                  md5:nil
                                           modifyTime:modifyTime
                                              dstPath:hostPath
                                       replaceOldFile:NO
                                             delegate:self
                                          whichServer:nil];
        }
    }
    else
    {
        uploadStage = UploadStage_GetFileServer;
        self.connection = [PCUtility httpGetFileServerInfo:self];
    }
    return YES;
}

- (void) cancel
{
    if (self.connection)
    {
        if (uploadStage <= UploadStage_UploadData)
        {
            [PCUtility removeConnectionFromArray:self.connection];
        }
        [connection cancel];
    }
    
    [self.receivedData setLength:0];
    self.uploadRequest.delegate = nil;
    self.connection = nil;
    
    if (self.checkDiskSpaceRequest) {
        [self.checkDiskSpaceRequest cancel];
        self.checkDiskSpaceRequest = nil;
    }
}

-(void)connection:(NSURLConnection *)_connection didReceiveResponse:(NSURLResponse *)response
{
    [self.receivedData setLength:0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)incomingData
{
    [self.receivedData appendData:incomingData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *ret = [[[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding] autorelease];
    NSString *message = NSLocalizedString(@"AccessServerError", nil);
    NSDictionary *dict = [ret JSONValue];
    if (dict)
    {
        NSString *result = dict[@"result"];
        if (result)
        {
            NSInteger value = result.integerValue;
            if (value == 0)
            {
                //参数准备
                NSString *deviceID = [self.uploadRequest deviceID] ? [self.uploadRequest deviceID] : [PCLogin getResource];
                NSString *encodedDeviceID = [PCUtilityStringOperate encodeToPercentEscapeString:deviceID];
                NSString *userId = [PCSettings sharedSettings].userId;
                NSData *postData = [self.uploadRequest data];
                NSString *md5 = [self.uploadRequest md5];
                NSString *hostPath = [self.uploadRequest dstPath];
                NSDate *modifyTime = [self.uploadRequest modifyTime];
                
                if (uploadStage == UploadStage_GetFileServer)
                {
                    uploadStage = UploadStage_UploadToFileServer;
                    NSString *fileUploadUrl = [dict objectForKey:@"fileUploadUrl"];
                    NSString *reqKey = [dict objectForKey:@"reqKey"];
                    NSString *url = [NSString stringWithFormat:@"%@/%@.%@/%@/", fileUploadUrl, encodedDeviceID, userId, reqKey];
                    
                    self.serverUrl = url;
                    if ([self.uploadRequest fileType] != FILE_TYPE_CONTACT_VCF)
                    {
                        self.connection = [PCUtility postFileData:postData
                                                              md5:md5
                                                       modifyTime:modifyTime
                                                          dstPath:hostPath
                                                   replaceOldFile:NO
                                                         delegate:self
                                                      whichServer:url];
                    }
                    else
                    {
                        self.connection = [PCUtility postContactFileData:postData
                                                                     md5:md5
                                                                 dstPath:hostPath
                                                          replaceOldFile:NO
                                                                delegate:self
                                                             whichServer:url];
                    }
                    
                    return;
                }
                
                NSDictionary *info = [dict objectForKey:@"info"];
                
                if (info && [info isKindOfClass:[NSDictionary class]])
                {
                    long long fileSize = [[info valueForKey:@"size"] longLongValue];
                    NSTimeInterval timeInterval = [[info valueForKey:@"modifyTime"] doubleValue] / 1000.0;
                    NSDate *modifyTime = [NSDate dateWithTimeIntervalSince1970:timeInterval];
                    [[self uploadRequest] setFileSize:fileSize];
                    [[self uploadRequest] setModifyTime:modifyTime];
                }
                
                if ([self.uploadRequest delegate])
                {
                    long long fileSize = [[self uploadRequest] fileSize];
                    [[self.uploadRequest delegate] uploadFileFinish:self
                                                           hostPath:hostPath
                                                           fileSize:fileSize];
                }
            }
            else
            {
                NSString *errMsg = dict[@"errMsg"];
                NSString *msg = dict[@"message"];
                if (errMsg)
                {
                    errCode = [[dict objectForKey:@"errCode"] intValue];
                    if (errCode == PC_Err_LackSpace)
                    {
                        if ([self.uploadRequest fileType] == FILE_TYPE_CONTACT_VCF)
                        {
                            message = NSLocalizedString(@"NoSpaceForBackup", nil);
                        }
                        else
                        {
                            message = NSLocalizedString(@"NoSpaceLeftForUpload", nil);
                        }
                    }
                    else if (errCode == PC_Err_ReadOnly)
                    {
                        message = NSLocalizedString(@"DiskReadOnlyForUpload", nil);
                    }
                    else if (errCode == PC_Err_NoDisk)
                    {
                        message = NSLocalizedString(@"NotExistDisksForUpload", nil);
                    }
                    else if (errCode == PC_Err_BoxUnbind)
                    {
                        message = NSLocalizedString(@"BoxUnbind", nil);
                    }
                    else if ([errMsg hasSuffix:@"NotExist"])
                    {
                        message = NSLocalizedString(@"NotExist", nil);
                    }
                    else if ([errMsg hasSuffix:@"LoginFailed"])
                    {
                        message = NSLocalizedString(@"LoginFailed", nil);
                    }
                    else if ([errMsg hasSuffix:@"AccessDenied"])
                    {
                        message = NSLocalizedString(@"AccessDenied", nil);
                    }
                    else if ([errMsg hasSuffix:@"HasExisted"])
                    {
                        message = NSLocalizedString(@"HasExisted", nil);
                    }
                    else if ([errMsg hasSuffix:@"NotSupported"])
                    {
                        message = NSLocalizedString(@"NotSupported", nil);
                    }
                    else if ([errMsg hasSuffix:@"InvalidAction"])
                    {
                        message = NSLocalizedString(@"InvalidAction", nil);
                    }
                    else if ([errMsg hasSuffix:@"LoginTooMany"])
                    {
                        message = NSLocalizedString(@"LoginTooMany", nil);
                    }
                    else if ([errMsg hasSuffix:@"CreateThumbFailed"])
                    {
                        message = NSLocalizedString(@"CreateThumbFailed", nil);
                    }
                }
                else if (msg)
                {
                    message = msg;
                }
                
                //资源当前不在线:表示盒子已断网或关机
                if (value == 20)
                {
                    errCode = NSURLErrorCannotConnectToHost;
                    if ([self.uploadRequest delegate])
                    {
                        [[self.uploadRequest delegate] uploadFileFail:self
                                                             hostPath:[[self uploadRequest] dstPath]
                                                                error:NSLocalizedString(@"DeviceOfflien", nil)];
                    }
                }
                else if(value == 1  && ([[dict valueForKey:@"errCode"] intValue] == 1028 || [[dict valueForKey:@"errCode"] intValue] == 1029))
                {
                    [PCLogin setToken:nil];
                    [[PCLogin sharedManager]  getAccessToken:self];
                }
                else if ([self.uploadRequest delegate])
                {
                    [[self.uploadRequest delegate] uploadFileFail:self hostPath:[self.uploadRequest dstPath] error:message];
                }
            }
        }
        else if ([self.uploadRequest delegate])
        {
            [[self.uploadRequest delegate] uploadFileFail:self hostPath:[self.uploadRequest dstPath] error:message];
        }
    }
    else if ([self.uploadRequest delegate])
    {
        [[self.uploadRequest delegate] uploadFileFail:self hostPath:[self.uploadRequest dstPath] error:message];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    DLogNotice(@"fileUpload didFailWithError:%@", error);
    
    NSString *errString = nil;
    errCode = error.code;
    
    if (error.code == NSURLErrorCannotConnectToHost)
    {
        errString = NSLocalizedString(@"ServerOffline", nil);
    }
    else if (error.code == NSURLErrorTimedOut)
    {
        errString = error.localizedDescription;
    }
    else
    {
        errString = NSLocalizedString(@"ConnetError", nil);
    }
    
    if ([self.uploadRequest delegate])
    {
        [[self.uploadRequest delegate] uploadFileFail:self hostPath:[self.uploadRequest dstPath] error:errString];
    }
}


- (void)gotAccessToken:(NSDictionary*)result
{
    NSString *newToken = [result objectForKey:@"token"];
    [PCLogin  setToken:newToken];
    
    NSData *postData = [self.uploadRequest data];
    NSString *md5 = [self.uploadRequest md5];
    NSString *hostPath = [self.uploadRequest dstPath];
    NSDate *modifyTime = [self.uploadRequest modifyTime];
    int type = [self.uploadRequest fileType];
    
    if (type != FILE_TYPE_CONTACT_VCF)
    {
        self.connection = [PCUtility postFileData:postData
                                              md5:md5
                                       modifyTime:modifyTime
                                          dstPath:hostPath
                                   replaceOldFile:NO
                                         delegate:self
                                      whichServer:self.serverUrl];
    }
    else
    {
        self.connection = [PCUtility postContactFileData:postData
                                                     md5:md5
                                                 dstPath:hostPath
                                          replaceOldFile:NO
                                                delegate:self
                                             whichServer:self.serverUrl];
    }
}

- (void)getAccessTokenFailedWithError:(NSError*)error2
{
    // [ErrorHandler showErrorAlert:error2];
    if ([self.uploadRequest delegate])
    {
        [[self.uploadRequest delegate] uploadFileFail:self hostPath:[self.uploadRequest dstPath] error:nil];
    }
}

- (void)requestDidGotAccessToken:(KTURLRequest *)request
{
    if (request.error) {
        [self  getAccessTokenFailedWithError:request.error];
    }
    else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                [self gotAccessToken:dict];
            }
            else {
                if ([dict objectForKey:@"errCode"]) {
                    result = [[dict objectForKey:@"errCode"] intValue];
                }
                NSError *error2 = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                [ErrorHandler showErrorAlert:error2];
                [PCUtilityUiOperate logout];
            }
        }
        else {
            NSError *error2 = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
            [self  getAccessTokenFailedWithError:error2];
        }
    }
}

- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if ([self.uploadRequest delegate])
    {
        [[self.uploadRequest delegate] uploadFileProgress:self
                                              currentSize:totalBytesWritten
                                                totalSize:totalBytesExpectedToWrite
                                                 hostPath:[self.uploadRequest dstPath]];
    }
}

- (void) networkNoReachableFail:(NSString*)error
{
    errCode = NSURLErrorNotConnectedToInternet;
    if ([self.uploadRequest delegate])
    {
        [[self.uploadRequest delegate] uploadFileFail:self
                                             hostPath:[self.uploadRequest dstPath]
                                                error:error];
    }
}

//---------------------------------------------------------------
-(void)pcConnection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.receivedData setLength:0];
}

-(void)pcConnection:(NSURLConnection *)connection didReceiveData:(NSData *)incomingData
{
    [self.receivedData appendData:incomingData];
}

- (void)startUpload
{
    //获得设备ID
    NSString *deviceID = [self.uploadRequest deviceID] ? [self.uploadRequest deviceID] : [PCLogin getResource];
    
    //是否是穿透
    BOOL isPenetrate = [[NetPenetrate sharedInstance] isPenetrate];
    
    //判断设备id是否和登陆的设备id相同
    BOOL checkDevice = [deviceID isEqualToString:[PCLogin getResource]];
    
    if (isPenetrate && checkDevice)
    {
        uploadStage = UploadStage_UploadData;
        self.connection = [PCUtility postFileData:[self.uploadRequest data]
                                              md5:[self.uploadRequest md5]
                                       modifyTime:[self.uploadRequest modifyTime]
                                          dstPath:[self.uploadRequest dstPath]
                                   replaceOldFile:NO
                                         delegate:self
                                      whichServer:nil];
    }
    else
    {
        uploadStage = UploadStage_GetFileServer;
        self.connection = [PCUtility httpGetFileServerInfo:self];
    }
}

- (void)pcConnectionDidFinishLoading:(NSURLConnection *)pcConnection
{
    if (uploadStage != UploadStage_CheckExist)
    {
        [self connectionDidFinishLoading:pcConnection];
        return;
    }
    //uploadstage_checkexist 的网络请求 独自放 kturlrequest处理
}

- (void)pcConnection:(NSURLConnection *)pcConnection didFailWithError:(NSError *)error
{
    if (uploadStage != UploadStage_CheckExist)
    {
        [self connection:pcConnection didFailWithError:error];
        return;
    }
}

- (void)pcConnection:(NSURLConnection *)connection
     didSendBodyData:(NSInteger)bytesWritten
   totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (self.uploadRequest.delegate)
    {
        [self.uploadRequest.delegate uploadFileProgress:self
                                            currentSize:totalBytesWritten
                                              totalSize:totalBytesExpectedToWrite
                                               hostPath:self.uploadRequest.dstPath];
    }
}

@end
