//
//  PCUtility.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-12.
//  Copyright 2011年 Kortide. All rights reserved.
//
#import "PCUtility.h"
#import "PCLogin.h"
#import "PCLogout.h"
#import "PCAppDelegate.h"
#import "LoginViewController.h"
#import "NetPenetrate.h"
#import "MBProgressHUD.h"
#import "FileUpload.h"
#import "FileUploadManager.h"
#import "CameraUploadManager.h"
#import "PCFileInfo.h"
#import "QLPreviewController2.h"
#import "PCUtilityShareGlobalVar.h"

#import <QuartzCore/QuartzCore.h>
#import <CommonCrypto/CommonDigest.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/UTType.h>

#include <libkern/OSAtomic.h>
#include <sys/sysctl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#import <QuickLook/QuickLook.h>
#import <AVFoundation/AVFoundation.h>
#import "PCURLRequest.h"

@implementation PCUtility

static NSDictionary* gFileTypeImage = nil;
static NSManagedObjectContext* gContext = nil;
static NSMutableString* gUrlServer = nil;
static NSMutableString* gCookie = nil;
static NSString *gPlistPath = nil;
static BOOL gIsLAN = NO;
static FileDownloadManager* gDownloadManger = nil;
static NSMutableDictionary* gCompressingImgDic = nil;

static NSMutableArray* gConnectionArray = nil;//记录请求任务,当有网络请求时添加任务,当该请求结束或者失败时移除任务

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


/*
 for (id key in node)
 {
 NSLog(@"key: %@ value: %@",key, [node objectForKey:key]);
 }
 */


+ (NSString*) checkResponseStautsCode:(NSInteger)code {
    if (code != 200 && code != 206) {
        return @"服务器异常，请稍候重试！";
    }
    return nil;
}

+ (NSDate*) formatTimeString:(NSString*)time formatString:(NSString*)formatString {
    NSDate *nd;
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [dateFormat setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]autorelease]];
    [dateFormat setDateFormat:formatString];
    nd = [dateFormat dateFromString:time];
    [dateFormat release];
    return nd;
}

+ (NSString*) formatTime:(float)time formatString:(NSString*)formatString {
    NSDate *nd = [NSDate dateWithTimeIntervalSince1970:time];
    return [PCUtility formatDate:nd formatString:formatString];
}

+ (NSString*) formatFileSize:(long long)size isNeedBlank:(BOOL)isNeedBlank {
    NSString *result = nil;
    NSString *blank = @"";
    if (isNeedBlank) blank = @" ";
    if (size >= 1073741824) {
        result = [NSString stringWithFormat:@"%.3f%@GB",  (double)size / 1073741824, blank];
    }
    else if (size >= 1048576) {
        result = [NSString stringWithFormat:@"%.2f%@MB",  (double)size / 1048576, blank];
    }
    else if (size >= 1024) {
        result = [NSString stringWithFormat:@"%.1f%@KB",  (double)size / 1024, blank];
    }
    else if (size != 1) {
        result = [NSString stringWithFormat:@"%qi%@%@", size, blank, NSLocalizedString(@"Bytes", nil)];
    }
    else {
        result = [NSString stringWithFormat:@"%qi%@%@", size, blank, NSLocalizedString(@"Byte", nil)];
    }
    
    return result;
}

+ (NSString*) urlServer
{
    @synchronized(gUrlServer)
    {
        return gUrlServer;
    }
}

+ (void) setUrlServer:(NSString*)url
{
    if (!url) return;
    
    if (!gUrlServer) {
        gUrlServer = [[NSMutableString alloc] initWithCapacity:256];
    }
    
    @synchronized(gUrlServer)
    {
        [gUrlServer setString:url];
    }
    //    NSLog(gUrlServer);
}

+ (NSString*) cookie
{
    return gCookie;
}

+ (void) setCookie:(NSArray*)cookies {
    
    if (!cookies) return;
    
    if (!gCookie) {
        gCookie = [[NSMutableString alloc] initWithCapacity:256];    }
    
    [gCookie setString:@""];
    for (NSHTTPCookie *cookie in cookies) {
        [gCookie appendFormat:@"%@=%@;", cookie.name, cookie.value];
    }
    //    NSLog(gCookie);
}


//+ (BOOL) isLAN {
//    return gIsLAN;
//}

+ (void) setIsLAN:(BOOL)isLan {
    gIsLAN = isLan;
}

+ (FileDownloadManager*) downloadManager {
    if (!gDownloadManger) {
        gDownloadManger = [[FileDownloadManager alloc] init];
    }
    
    return gDownloadManger;
}

+ (NSManagedObjectContext*) managedObjectContext {
    if (!gContext) {
        gContext = [(PCAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext] ;
    }
    
    return gContext;
}

+(void) deleteFile:(NSString*)path {
    NSFileManager *fileManage = [NSFileManager defaultManager];
    [fileManage removeItemAtPath:path error:nil];
}

+ (void) openFileAtPath:(NSString*)path WithBackTitle:(NSString*)title andFileInfo:(PCFileInfo*)fileInfo andNavigationViewControllerDelegate:(UIViewController*)delegate
{
    //add by libing 2013-6-26 fix bug bug54838  bug 55854
    BOOL result = [PCUtility itemCanOpenWithPath:path];
    if (!result) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"NoSuitableProgram", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    else
    {
        //避免null值 无  pathextention方法导致 crash
        id curPath = fileInfo.path;
        if (![curPath isKindOfClass:[NSString class]]) {
            curPath =   @"";
        }
        QLPreviewController2 *previewController = [[QLPreviewController2 alloc] init];
        previewController.currentFileInfo = fileInfo;
        
        if ([[PCUtility getImgByExt:[curPath pathExtension]] isEqualToString:@"file_video.png"] ||
            [[PCUtility getImgByExt:[curPath pathExtension]] isEqualToString:@"file_music.png"])
        {
            previewController.bHideToolbarForMusicFile = YES;
        }
        
        previewController.localPath = path;
        previewController.dataSource = previewController;
        previewController.delegate = previewController;
        previewController.backBtnTitle = title;
        previewController.currentPreviewItemIndex = 0;
        previewController.hidesBottomBarWhenPushed = YES;
        [delegate.navigationController pushViewController:previewController animated:YES];
        [previewController release];
    }
}

+ (NSString *)GetUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return [(NSString *)string autorelease];
}

+ (NSString*) SHA1:(NSString*)input
{
    
    NSData *data = [input dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, data.length, digest);
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

+ (NSString*) md5:(NSString*)str {
    const char *cStr = [str UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5( cStr, strlen(cStr), result );
    
	return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

#define CHUNK_SIZE 8192
+ (NSString *) file_md5:(NSString*)path {
    NSFileHandle* handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if(handle == nil)
        return nil;
    
    CC_MD5_CTX md5_ctx;
    CC_MD5_Init(&md5_ctx);
    
    NSData* filedata;
    do {
        filedata = [handle readDataOfLength:CHUNK_SIZE];
        CC_MD5_Update(&md5_ctx, [filedata bytes], [filedata length]);
    }
    while([filedata length]);
    
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(result, &md5_ctx);
    
    [handle closeFile];
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

+ (NSString *)encodeToPercentEscapeString: (NSString *)input
{
    //stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding
    
    // Encode all the reserved characters, per RFC 3986
    // (<http://www.ietf.org/rfc/rfc3986.txt>)
    CFStringRef str = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)input,
                                                              NULL,
                                                              (CFStringRef)@" !*'();:@&=+$,/?%#[]",
                                                              kCFStringEncodingUTF8);
    NSString *outputStr = [(NSString*)str copy];
    if (str)
    {
        CFRelease(str);
    }
    
    return [outputStr autorelease];
}

+ (NSString *)decodeFromPercentEscapeString: (NSString *) input
{
    NSMutableString *outputStr = [NSMutableString stringWithString:input];
    [outputStr replaceOccurrencesOfString:@"+"
                               withString:@" "
                                  options:NSLiteralSearch
                                    range:NSMakeRange(0, [outputStr length])];
    
    return [outputStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *) getPListPath {
    if (!gPlistPath) {
        //        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        //        NSString *plistPath = [NSString stringWithFormat:@"%@/Preferences", [paths objectAtIndex:0]];
        NSString *plistPath = [NSString stringWithFormat:@"%@/Preferences", NSTemporaryDirectory()];
        NSFileManager *fileManage = [NSFileManager defaultManager];
        
        if (![fileManage fileExistsAtPath:plistPath isDirectory:nil]) {
            if ([fileManage createDirectoryAtPath:plistPath withIntermediateDirectories:YES attributes:nil error:nil]==NO) {
                NSLog(@"创建文件夹:%@ 失败", plistPath);
            }
        }
        gPlistPath = [plistPath copy];
    }
    
    return gPlistPath;
}

+ getNSURL:(NSString*)method {
    NSString *svrUrl = nil;
    /*
     if (gIsLAN) {
     char str[1024 * 128];
     strcpy(str, [method UTF8String]);
     char *p = strchr(str, '&');
     if (p) *p = '?';
     
     svrUrl = [NSString stringWithFormat:@"%@/%@", [PCUtility urlServer], [NSString stringWithCString:str encoding:NSUTF8StringEncoding]];
     }
     else {
     svrUrl = [NSString stringWithFormat:@"%@%@%@", [PCUtility urlServer], SERVER_PROXY_PART, method];
     }
     */
    svrUrl = [NSString stringWithFormat:@"%@%@", [PCUtilityShareGlobalVar urlServer], method];
    NSLog(@"Get:%@", svrUrl);
    
    return [NSURL URLWithString:svrUrl];
}

+ (NSURLConnection *) httpGetFileDownLoadWithURL:(NSURL *)fileUrl headers:(NSArray*)headers delegate:(id)delegate {
    
    if (![PCUtility isNetworkReachable:nil]) {
        [PCUtility performSelector:@selector(networkNoReachableAlert:) withObject:delegate afterDelay:0.1];
        return nil;
    }
    /*
     NSURLConnection *ret = [PCLogin needReLogin:delegate];
     if (ret) return ret;
     */
    NSURLConnection *ret;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:fileUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:
                                    TIMEOUT_INTERVAL_DOWNLOAD];
    //TIMEOUT_INTERVAL];
    [request setValue:[PCUtility cookie] forHTTPHeaderField:@"Cookie"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    for (NSDictionary* header in headers) {
        [request setValue:[header objectForKey:@"value"] forHTTPHeaderField:[header objectForKey:@"key"]];
    }
    
    
    //    NSLog(@"%@", [request allHTTPHeaderFields]);
    ret = [NSURLConnection connectionWithRequest:request delegate:delegate];
    
    //[PCUtility addConnectionToArray:ret withDelegate:delegate withRequest:request withMethod:@""];
    [request release];
    
    return ret;
}

+ (NSURLConnection *) httpGetWithURL:(NSString *)method headers:(NSArray*)headers delegate:(id)delegate {
    
    if (![PCUtility isNetworkReachable:nil]) {
        [PCUtility performSelector:@selector(networkNoReachableAlert:) withObject:delegate afterDelay:0.1];
        return nil;
    }
    /*
     NSURLConnection *ret = [PCLogin needReLogin:delegate];
     if (ret) return ret;
     */
    NSURLConnection *ret;
    NSURL *nsUrl = [PCUtility getNSURL:method];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:nsUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:TIMEOUT_INTERVAL];
    [request setValue:[PCUtility cookie] forHTTPHeaderField:@"Cookie"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    for (NSDictionary* header in headers) {
        [request setValue:[header objectForKey:@"value"] forHTTPHeaderField:[header objectForKey:@"key"]];
    }
    
    
    //    NSLog(@"%@", [request allHTTPHeaderFields]);
    ret = [NSURLConnection connectionWithRequest:request delegate:self];
    
    [PCUtility addConnectionToArray:ret withDelegate:delegate withRequest:request withMethod:method];
    [request release];
    
    return ret;
}

+ (NSURLConnection *) httpGetFileServerInfo:(id)delegate {
    
    if (![PCUtility isNetworkReachable:nil]) {
        [PCUtility performSelector:@selector(networkNoReachableAlert:) withObject:delegate afterDelay:0.1];
        return nil;
    }
    
    NSURLConnection *ret;
    NSURL *nsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/%@", FILE_SERVER_HOST,GET_FILE_SERVER_INFO]];
    
    NSLog(@"Get:%@", nsUrl);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:nsUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:TIMEOUT_INTERVAL];
    
    ret = [NSURLConnection connectionWithRequest:request delegate:delegate];
    [request release];
    return ret;
}


+ (NSURLConnection *) postFileData:(NSData *)fileData md5:(NSString *)md5 modifyTime:(NSDate *)modifytime dstPath:(NSString *)dst replaceOldFile:(BOOL)isReplace delegate:(id)delegate whichServer:(NSString *)serverURL {
    
    if (![PCUtility isNetworkReachable:nil]) {
        [PCUtility performSelector:@selector(networkNoReachableAlert:) withObject:delegate afterDelay:0.1];
        return nil;
    }
    
    NSMutableString *url = [NSMutableString stringWithFormat:@"%@FileUpload", serverURL ? serverURL : [PCUtilityShareGlobalVar urlServer]];
    NSLog(@"Post:%@", url);

    NSURL *nsUrl = [NSURL URLWithString:url];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:nsUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:TIMEOUT_INTERVAL_UPLOAD];
    
    [request setHTTPMethod: @"POST"];
    [request setValue:@"keep-alive" forHTTPHeaderField:@"connection"];
    [request setValue:@"UTF-8" forHTTPHeaderField:@"Charsert"];
    [request setValue:[NSString stringWithFormat:@"application/octet-stream"] forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", fileData.length] forHTTPHeaderField:@"Content-Length"];
    
    if ([PCSettings sharedSettings].bSessionSupported ) {
        [request setValue:[PCLogin getToken] forHTTPHeaderField:@"token_id"];
        [request setValue:[[UIDevice currentDevice] uniqueDeviceIdentifier] forHTTPHeaderField:@"client_id"];
    }

    
    CFStringRef str = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)dst, NULL, NULL, kCFStringEncodingUTF8);
    NSString *utf8Path = [[(NSString*)str copy] autorelease];
    CFRelease(str);
    
    
    [request setValue:utf8Path forHTTPHeaderField:@"filePath"];
    [request setValue:(isReplace ? @"True" : @"False") forHTTPHeaderField:@"replaceOldFile"];
    [request setValue:@"False" forHTTPHeaderField:@"createFolder"];
    if (md5) {
        [request setValue:md5 forHTTPHeaderField:@"imageMd5"];
    }
    if (modifytime) {
        NSString *temp = [NSString stringWithFormat:@"%.0f", [modifytime timeIntervalSince1970]];
        [request setValue:temp forHTTPHeaderField:@"modifytime"];
    }
    
    if ([PCUtility cookie]) {
        [request setValue:[PCUtility cookie] forHTTPHeaderField:@"Cookie"];
    }
    
    DTLogDebug(@"PCUtility", @"file length = %d", fileData.length);
    [request setHTTPBody:fileData];
    //[request setHTTPBodyStream:[NSInputStream inputStreamWithData:fileData]];
    
    NSURLConnection *connection = nil;
    if (serverURL) {
        connection = [NSURLConnection connectionWithRequest:request delegate:delegate];
    }
    else {
        connection = [NSURLConnection connectionWithRequest:request delegate:self];
        [PCUtility addConnectionToArray:connection withDelegate:delegate withRequest:request withMethod:@""];
    }
    
    [request release];
    return connection;
}


+ (NSURLConnection *) postContactFileData:(NSData *)fileData
                                      md5:(NSString *)md5
                                  dstPath:(NSString *)dst
                           replaceOldFile:(BOOL)isReplace
                                 delegate:(id)delegate
                              whichServer:(NSString *)serverURL
{
    
    if (![PCUtility isNetworkReachable:nil])
    {
        [PCUtility performSelector:@selector(networkNoReachableAlert:)
                        withObject:delegate
                        afterDelay:0.1];
        return nil;
    }
    
    NSMutableString *url = [NSMutableString stringWithFormat:@"%@ContactFileUpload", serverURL ? serverURL : [PCUtilityShareGlobalVar urlServer]];
    NSLog(@"Post:%@", url);
    
    NSURL *nsUrl = [NSURL URLWithString:url];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:nsUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:TIMEOUT_INTERVAL_UPLOAD];
    
    [request setHTTPMethod: @"POST"];
    [request setValue:@"keep-alive" forHTTPHeaderField:@"connection"];
    [request setValue:@"UTF-8" forHTTPHeaderField:@"Charsert"];
    [request setValue:[NSString stringWithFormat:@"application/octet-stream"] forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", fileData.length] forHTTPHeaderField:@"Content-Length"];
    
    if ([PCSettings sharedSettings].bSessionSupported ) {
        [request setValue:[PCLogin getToken] forHTTPHeaderField:@"token_id"];
        [request setValue:[[UIDevice currentDevice] uniqueDeviceIdentifier] forHTTPHeaderField:@"client_id"];
    }

    NSString *globalId = [[UIDevice currentDevice] uniqueGlobalDeviceIdentifier];
    
    //[request setValue:[PCUtility encodeToPercentEscapeString:dst] forHTTPHeaderField:@"fileName"];
    //[request setValue:globalId forHTTPHeaderField:@"phoneId"];
    
    NSString *updateFileName = [NSString stringWithFormat:@"%@/%@",globalId,dst];
    
    [request setValue:[PCUtility encodeToPercentEscapeString:updateFileName] forHTTPHeaderField:@"filePath"];
    [request setValue:(isReplace ? @"True" : @"False") forHTTPHeaderField:@"replaceOldFile"];
    
    [request setValue:(isReplace ? @"True" : @"False") forHTTPHeaderField:@"replaceOldFile"];
    [request setValue:@"False" forHTTPHeaderField:@"createFolder"];
    if (md5) {
        [request setValue:md5 forHTTPHeaderField:@"imageMd5"];
    }
    
    if ([PCUtility cookie]) {
        [request setValue:[PCUtility cookie] forHTTPHeaderField:@"Cookie"];
    }
    
    DTLogDebug(@"PCUtility", @"file length = %d", fileData.length);
    [request setHTTPBody:fileData];
    //[request setHTTPBodyStream:[NSInputStream inputStreamWithData:fileData]];
    
    NSURLConnection *connection = nil;
    if (serverURL) {
        connection = [NSURLConnection connectionWithRequest:request delegate:delegate];
    }
    else {
        connection = [NSURLConnection connectionWithRequest:request delegate:self];
        [PCUtility addConnectionToArray:connection withDelegate:delegate withRequest:request withMethod:@""];
    }
    
    [request release];
    return connection;
}


#pragma ========== NSURLConnectionDelegate begin ========
+ (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response{
    id delegate = [PCUtility getConnectionDelegateByConnection:connection];
    if(delegate && [delegate respondsToSelector:@selector(pcConnection:willSendRequest:redirectResponse:)]){
        return  [delegate pcConnection:connection willSendRequest:request redirectResponse:response];
    }
    return request;
}



+ (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    id delegate = [PCUtility getConnectionDelegateByConnection:connection];
    if(delegate && [delegate respondsToSelector:@selector(pcConnection:didReceiveResponse:)]){
        [delegate pcConnection:connection didReceiveResponse:response];
    }
}

+ (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    id delegate = [PCUtility getConnectionDelegateByConnection:connection];
    if (delegate && [delegate respondsToSelector:@selector(pcConnection:didReceiveData:)]) {
        [delegate pcConnection:connection didReceiveData:data];
    }
}

+ (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    id delegate = [PCUtility getConnectionDelegateByConnection:connection];
    if(delegate && [delegate respondsToSelector:@selector(pcConnectionDidFinishLoading:)]){
        [delegate pcConnectionDidFinishLoading:connection];
    }
    [PCUtility removeConnectionFromArray:connection];
}

+ (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [PCUtility netConnectionError:connection withError:error];
    [PCUtility removeConnectionFromArray:connection];
}

+ (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
    id delegate = [PCUtility getConnectionDelegateByConnection:connection];
    if ([delegate respondsToSelector:@selector(pcConnection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
        [delegate pcConnection:connection didSendBodyData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}
#pragma ========== NSURLConnectionDelegate end ========

+ (void) netConnectionError:(NSURLConnection*)connection withError:(NSError*)error {
    id delegate = [PCUtility getConnectionDelegateByConnection:connection];
    
    NSString *host = connection.originalRequest.URL.host;
    DLogNotice(@"originalRequest.host=%@",host);
    //modified by ray
    NetPenetrate *penetrate = [NetPenetrate sharedInstance];
	
    //	if (penetrate.gCurrentNetworkState == CURRENT_NETWORK_STATE_LOCAL &&
    //		[penetrate.defaultLanUrl hasPrefix:host])
    //	{
    //		penetrate.hasRetryNat = NO;//此处需要重置hasRetryNat为NO，为了下次的局域网请求失败后可以执行NAT穿透请求
    //	}
	
	//如果当前是wifi网络并且局域网地址存在，并且当前连接不是通过局域网，则通过局域网请求
    //    if ([PCUtility isWifi] && penetrate.defaultLanUrl && !penetrate.hasRetryLan &&
    //        penetrate.gCurrentNetworkState != CURRENT_NETWORK_STATE_LOCAL)
    //    {
    //        penetrate.hasRetryLan = YES;//用以设置不再执行此段，避免循环执行
    //        [PCUtility reConnectWhenFailed:connection
    //                            connectUrl:[NSString stringWithFormat:@"http://%@/", penetrate.defaultLanUrl]];
    //    }
	//如果外网穿透地址存在，并且当前连接不是通过外网穿透
    //    if (penetrate.gCurrentNetworkState != CURRENT_NETWORK_STATE_NAT &&
    //             penetrate.defaultNatUrl && [penetrate.defaultLanUrl hasPrefix:host])
    //    {
    //        [PCUtility reConnectWhenFailed:connection connectUrl:[NSString stringWithFormat:@"http://%@/", penetrate.defaultNatUrl]];
    //    }
	//外网穿透请求也不成功，则请求默认hub网络
    if(penetrate.gCurrentNetworkState != CURRENT_NETWORK_STATE_DEFAULT &&
       ![penetrate.defaultHubUrl hasPrefix:host])
    {
        [PCUtility reConnectWhenFailed:connection connectUrl:penetrate.defaultHubUrl];
    }
    //以上都不行，不再重新连接，直接执行代理的网络请求失败逻辑
    else if(delegate && [delegate respondsToSelector:@selector(pcConnection:didFailWithError:)])
    {
        [delegate pcConnection:connection didFailWithError:error];
    }
}

+ (void)reConnectWhenFailed:(NSURLConnection*)connection connectUrl:(NSString *)urlStr
{
    for (NSArray* connectionInfo in gConnectionArray) {
        NSURLConnection* _connection = [connectionInfo objectAtIndex:0];
        if (_connection == connection) {
            id delegate = [connectionInfo objectAtIndex:1];
            NSString* method = [connectionInfo objectAtIndex:3];
            
            if ([delegate isKindOfClass:[FileCache class]])
            {
                FileCache *cache = delegate;
                NSLog(@"cache.url=%@",cache.url);
                cache.connection = [PCUtility httpGetFileServerInfo:cache];
                
                return;
            }
            else if ([delegate isKindOfClass:[FileUpload class]])
            {
                FileUpload *upload = delegate;
                if (upload.uploadStage == UploadStage_UploadData) {
                    upload.uploadStage = UploadStage_GetFileServer;
                    upload.connection = [PCUtility httpGetFileServerInfo:upload];
                    
                    return;
                }
            }
            
            NSMutableURLRequest* request = [connectionInfo objectAtIndex:2];
            NSString *svrUrl = [NSString stringWithFormat:@"http://%@%@", urlStr, method];
            NSLog(@"Get:%@", svrUrl);
            [request setURL:[NSURL URLWithString:svrUrl]];
            
            NSURLConnection* ret = [NSURLConnection connectionWithRequest:request delegate:self];
            [PCUtility addConnectionToArray:ret withDelegate:delegate withRequest:request withMethod:method];
            break;
        }
    }
}

+ (id) getConnectionDelegateByConnection:(NSURLConnection*)connection {
    id delegate = nil;
    for (NSArray* connectionInfo in gConnectionArray) {
        NSURLConnection* _connection = [connectionInfo objectAtIndex:0];
        if (_connection == connection) {
            delegate = [connectionInfo objectAtIndex:1];
            break;
        }
    }
    return delegate;
}

+ (void) addConnectionToArray:(NSURLConnection*)connection withDelegate:(id)delegate withRequest:(NSMutableURLRequest*)request withMethod:(NSString*)method {
    //按请求连接，请求代理对象，请求以及请求地址的顺序记录每次请求
    NSArray* connectionInfoArray = [NSArray arrayWithObjects:connection, delegate,request, method, nil];
    if (!gConnectionArray)
        gConnectionArray = [[NSMutableArray alloc] init];
    [gConnectionArray addObject:connectionInfoArray];
}

+ (void) removeConnectionFromArray:(NSURLConnection*)connection {
    for (NSArray* connectionInfo in gConnectionArray){
        NSURLConnection *_connection = [connectionInfo objectAtIndex:0];
        NSString *method = [[connectionInfo objectAtIndex:3] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *query = [connection.originalRequest.URL.query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSString *lastPathComponent = connection.originalRequest.URL.lastPathComponent;
        DLogInfo(@"method=%@,lastPathComponent=%@",method,lastPathComponent);
        DLogInfo(@"check equal=%d",_connection == connection);
        
        //以下判断条件有改动，当网络穿透后的请求失败时会重连默认hub，
        //这样单凭_connection == connection无法删掉某个NSURLConnection
        if(_connection == connection ||
           ([method hasPrefix:lastPathComponent] &&
            (query.length == 0 ||[method hasSuffix:query]))) {
               [_connection cancel];
               [gConnectionArray removeObject:connectionInfo];
               DLogInfo(@"remove connection success:%@",lastPathComponent);
               break;
           }
    }
}

+ (SCNetworkReachabilityFlags) getNetworkFlags {
    
    // Part 1 - Create Internet socket addr of zero
    struct sockaddr_in zeroAddr;
	bzero(&zeroAddr, sizeof(zeroAddr));
	zeroAddr.sin_len = sizeof(zeroAddr);
	zeroAddr.sin_family = AF_INET;
    
	// Part 2- Create target in format need by SCNetwork
	SCNetworkReachabilityRef target = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *) &zeroAddr);
    
	// Part 3 - Get the flags
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityGetFlags(target, &flags);
    CFRelease(target);
    
    return flags;
    
	// Part 4 - Create output
	NSString *sNetworkReachable;
	if (flags & kSCNetworkFlagsReachable)
		sNetworkReachable = @"YES";
	else
		sNetworkReachable = @"NO";
    
	NSString *sCellNetwork;
	if (flags & kSCNetworkReachabilityFlagsIsWWAN)
		sCellNetwork = @"YES";
	else
		sCellNetwork = @"NO";
    
	NSString *s = [[NSString alloc]
                   initWithFormat:
                   @"Network Reachable: %@\n"
                   @"Cell Network: %@\n",
                   sNetworkReachable,
                   sCellNetwork];
    
    //   NSLog(s);
    
	[sCellNetwork release];
	[sNetworkReachable release];
	[s release];
    
}

+ (BOOL) isNetworkReachable:(id)delegate {
    if (!([PCUtility getNetworkFlags] & kSCNetworkFlagsReachable)) {
        return NO;
    }
    return YES;
}

+ (void) networkNoReachableAlert:(id<PCNetworkDelegate>)delegate {
    [delegate networkNoReachableFail:NSLocalizedString(@"NetNotReachableError", nil)];
}

+ (BOOL) isWifi {
    //    if ([PCUtility getNetworkFlags] & kSCNetworkReachabilityFlagsIsWWAN)
    //        return NO;
    //    else
    //        return YES;
    return gIsLAN;
}

/*
 + (void) initCoreData {
 NSError *error;
 
 //Path to sqlite file.
 NSString *path = [NSHomeDirectory() stringByAppendingString:@"/Documents/fileCache.sqlite"];
 NSURL *url = [NSURL fileURLWithPath:path];
 
 //Init the model
 NSManagedObjectModel *managerObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
 
 //Establish the persistent store coordinator
 NSPersistentStoreCoordinator *persistenStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managerObjectModel];
 
 if (![persistenStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]) {
 
 }
 else {
 //Create the context and assign the coordinator
 gContext = [[[NSManagedObjectContext alloc] init] autorelease];
 [gContext setPersistentStoreCoordinator:persistenStoreCoordinator];
 }
 
 [persistenStoreCoordinator release];
 
 }
 */

+ (NSString*) getImgName:(NSString*)imgName {
    NSMutableString *getImgName = [[[NSMutableString alloc] initWithString:imgName] autorelease];
    if (IS_IPAD) {
        [getImgName appendString:@"@2x.png"];
    }
    else {
        [getImgName appendString:@".png"];
    }
    return getImgName;
}

+ (NSString*) getXibName:(NSString*)xibName {
    NSMutableString *getXibName = [[[NSMutableString alloc] initWithString:xibName] autorelease];
    if (IS_IPAD) {
        [getXibName appendString:@"_iPad"];
    }
    else {
        [getXibName appendString:@"_iPhone"];
    }
    return getXibName;
}

+ (NSString*) getImgByExt:(NSString*)ext {
    if (!gFileTypeImage) {
        gFileTypeImage = [[NSDictionary alloc] initWithObjectsAndKeys:
                          @"file_access.png", @"mdb",
                          
                          @"file_dw.png", @"swf",
                          
                          @"file_excel.png", @"xla",
                          @"file_excel.png", @"xlb",
                          @"file_excel.png", @"xlc",
                          @"file_excel.png", @"xld",
                          @"file_excel.png", @"xlk",
                          @"file_excel.png", @"xll",
                          @"file_excel.png", @"xlm",
                          @"file_excel.png", @"xls",
                          @"file_excel.png", @"xlshtml",
                          @"file_excel.png", @"xlsmhtml",
                          @"file_excel.png", @"xlt",
                          @"file_excel.png", @"xlthtml",
                          @"file_excel.png", @"xlv",
                          @"file_excel.png", @"xlsx",
                          
                          @"file_flash.png", @"fla",
                          
                          @"file_html.png", @"html",
                          @"file_html.png", @"htm",
                          
                          @"file_ai.png", @"ai",
                          
                          @"file_id.png", @"indd",
                          @"file_id.png", @"rpin",
                          @"file_id.png", @"apin",
                          
                          //                          @"file_pic.png", @"ag4",
                          //                          @"file_pic.png", @"att",
                          @"file_pic.png", @"bmp",
                          //                          @"file_pic.png", @"cal",
                          //                          @"file_pic.png", @"cit",
                          //                          @"file_pic.png", @"clp",
                          //                          @"file_pic.png", @"cmp",
                          //                          @"file_pic.png", @"cpr",
                          //                          @"file_pic.png", @"ct",
                          //                          @"file_pic.png", @"cut",
                          //                          @"file_pic.png", @"dbx",
                          //                          @"file_pic.png", @"dx",
                          //                          @"file_pic.png", @"ed6",
                          //                          @"file_pic.png", @"eps",
                          //                          @"file_pic.png", @"fax",
                          //                          @"file_pic.png", @"fmv",
                          //                          @"file_pic.png", @"ged",
                          //                          @"file_pic.png", @"gdf",
                          @"file_pic.png", @"gif",
                          //                          @"file_pic.png", @"gp4",
                          //                          @"file_pic.png", @"gx1",
                          //                          @"file_pic.png", @"gx2",
                          //                          @"file_pic.png", @"ica",
                          //                          @"file_pic.png", @"ico",
                          //                          @"file_pic.png", @"iff",
                          //                          @"file_pic.png", @"igf",
                          //                          @"file_pic.png", @"img",
                          //                          @"file_pic.png", @"jff",
                          @"file_pic.png", @"jpg",
                          @"file_pic.png", @"jpeg",
                          //                          @"file_pic.png", @"kfx",
                          //                          @"file_pic.png", @"mac",
                          //                          @"file_pic.png", @"mil",
                          //                          @"file_pic.png", @"msp",
                          //                          @"file_pic.png", @"nif",
                          //                          @"file_pic.png", @"pbm",
                          //                          @"file_pic.png", @"pcd",
                          //                          @"file_pic.png", @"pcx",
                          //                          @"file_pic.png", @"pix",
                          @"file_pic.png", @"png",
                          //                          //@"file_pic.png", @"psd",
                          //                          @"file_pic.png", @"ras",
                          //                          @"file_pic.png", @"rgb",
                          //                          @"file_pic.png", @"ria",
                          //                          @"file_pic.png", @"rlc",
                          //                          @"file_pic.png", @"rle",
                          //                          @"file_pic.png", @"rnl",
                          //                          @"file_pic.png", @"sbp",
                          //                          @"file_pic.png", @"sgi",
                          //                          @"file_pic.png", @"sun",
                          //                          @"file_pic.png", @"tga",
                          //                          @"file_pic.png", @"tif",
                          //                          @"file_pic.png", @"wpg",
                          //                          @"file_pic.png", @"xbm",
                          //                          @"file_pic.png", @"xpm",
                          //                          @"file_pic.png", @"xwd",
                          //                          @"file_pic.png", @"3ds",
                          //                          @"file_pic.png", @"906",
                          //                          @"file_pic.png", @"cal",
                          //                          @"file_pic.png", @"cdr",
                          //                          @"file_pic.png", @"cgm",
                          //                          @"file_pic.png", @"ch3",
                          //                          @"file_pic.png", @"clp",
                          //                          @"file_pic.png", @"cmx",
                          //                          @"file_pic.png", @"dg",
                          //                          @"file_pic.png", @"dgn",
                          //                          @"file_pic.png", @"drw",
                          //                          @"file_pic.png", @"ds4",
                          //                          @"file_pic.png", @"dsf",
                          //                          @"file_pic.png", @"dxf",
                          //                          @"file_pic.png", @"dwg",
                          //                          @"file_pic.png", @"emf",
                          //                          @"file_pic.png", @"esi",
                          //                          @"file_pic.png", @"fmv",
                          //                          @"file_pic.png", @"gca",
                          //                          @"file_pic.png", @"gem",
                          //                          @"file_pic.png", @"g4",
                          //                          @"file_pic.png", @"igf",
                          //                          @"file_pic.png", @"igs",
                          //                          @"file_pic.png", @"mcs",
                          //                          @"file_pic.png", @"met",
                          //                          @"file_pic.png", @"mrk",
                          //                          @"file_pic.png", @"p10",
                          //                          @"file_pic.png", @"pcl",
                          //                          @"file_pic.png", @"pdw",
                          //                          @"file_pic.png", @"pgl",
                          //                          @"file_pic.png", @"pic",
                          //                          @"file_pic.png", @"pix",
                          //                          @"file_pic.png", @"plt",
                          //                          @"file_pic.png", @"ps",
                          //                          @"file_pic.png", @"rlc",
                          //                          @"file_pic.png", @"ssk",
                          //                          @"file_pic.png", @"wmf",
                          //                          @"file_pic.png", @"wpg",
                          //                          @"file_pic.png", @"wrl",
                          //                          @"file_pic.png", @"wbmp",
                          @"file_pic.png", @"jpeg",
                          //                          @"file_pic.png", @"tiff",
                          
                          @"file_music.png", @"aac",
                          @"file_music.png", @"ac3",
                          @"file_music.png", @"amr",
                          
                          @"file_music.png", @"a2b",
                          @"file_music.png", @"ac1d",
                          @"file_music.png", @"ac-3",
                          @"file_music.png", @"aif",
                          @"file_music.png", @"aiff",
                          @"file_music.png", @"ais",
                          @"file_music.png", @"alaw",
                          @"file_music.png", @"alm",
                          @"file_music.png", @"am",
                          @"file_music.png", @"amd",
                          @"file_music.png", @"amm",
                          @"file_music.png", @"ams",
                          @"file_music.png", @"apex",
                          @"file_music.png", @"ase",
                          @"file_music.png", @"asx",
                          @"file_music.png", @"au",
                          @"file_music.png", @"aud",
                          @"file_music.png", @"avr",
                          @"file_music.png", @"bik",
                          @"file_music.png", @"bnk",
                          @"file_music.png", @"bpm",
                          @"file_music.png", @"c01",
                          @"file_music.png", @"cda",
                          @"file_music.png", @"cdr",
                          @"file_music.png", @"cmf",
                          @"file_music.png", @"d00",
                          @"file_music.png", @"dcm",
                          @"file_music.png", @"dewf",
                          @"file_music.png", @"di",
                          @"file_music.png", @"dig",
                          @"file_music.png", @"dls",
                          @"file_music.png", @"dmf",
                          @"file_music.png", @"dsf",
                          @"file_music.png", @"dsm",
                          @"file_music.png", @"dtm",
                          @"file_music.png", @"dwd",
                          @"file_music.png", @"eda",
                          @"file_music.png", @"ede",
                          @"file_music.png", @"edk",
                          @"file_music.png", @"edq",
                          @"file_music.png", @"eds",
                          @"file_music.png", @"edv",
                          @"file_music.png", @"efa",
                          @"file_music.png", @"efe",
                          @"file_music.png", @"efk",
                          @"file_music.png", @"efq",
                          @"file_music.png", @"efs",
                          @"file_music.png", @"efv",
                          @"file_music.png", @"emb",
                          @"file_music.png", @"emd",
                          @"file_music.png", @"emu",
                          @"file_music.png", @"esps",
                          @"file_music.png", @"eui",
                          @"file_music.png", @"eureka",
                          @"file_music.png", @"f2r",
                          @"file_music.png", @"f32",
                          @"file_music.png", @"f3r",
                          @"file_music.png", @"f64",
                          @"file_music.png", @"far",
                          @"file_music.png", @"fc-m",
                          @"file_music.png", @"fff",
                          @"file_music.png", @"fnk",
                          @"file_music.png", @"fpt",
                          @"file_music.png", @"fsm",
                          @"file_music.png", @"fzb",
                          @"file_music.png", @"fzf",
                          @"file_music.png", @"fzv",
                          @"file_music.png", @"g721",
                          @"file_music.png", @"g723",
                          @"file_music.png", @"g726",
                          @"file_music.png", @"gdm",
                          @"file_music.png", @"gig",
                          @"file_music.png", @"gkh",
                          @"file_music.png", @"gmc",
                          @"file_music.png", @"gsm",
                          @"file_music.png", @"gts",
                          @"file_music.png", @"hcom",
                          @"file_music.png", @"hrt",
                          @"file_music.png", @"idf",
                          @"file_music.png", @"iff",
                          @"file_music.png", @"ini",
                          @"file_music.png", @"inrs",
                          @"file_music.png", @"ins",
                          @"file_music.png", @"ist",
                          @"file_music.png", @"it",
                          @"file_music.png", @"its",
                          @"file_music.png", @"k25",
                          @"file_music.png", @"kar",
                          @"file_music.png", @"kmp",
                          @"file_music.png", @"kr1",
                          @"file_music.png", @"kris",
                          @"file_music.png", @"krZ",
                          @"file_music.png", @"ksc",
                          @"file_music.png", @"ksf",
                          @"file_music.png", @"ksm",
                          @"file_music.png", @"liq",
                          @"file_music.png", @"lqt",
                          @"file_music.png", @"lsf",
                          @"file_music.png", @"lsx",
                          @"file_music.png", @"m3u",
                          @"file_music.png", @"mat",
                          @"file_music.png", @"maud",
                          @"file_music.png", @"mav",
                          @"file_music.png", @"mdlmed",
                          @"file_music.png", @"mid",
                          @"file_music.png", @"midi",
                          @"file_music.png", @"miv",
                          @"file_music.png", @"mls",
                          @"file_music.png", @"mms",
                          @"file_music.png", @"mod",
                          @"file_music.png", @"mp",
                          @"file_music.png", @"mp1",
                          @"file_music.png", @"mp2",
                          @"file_music.png", @"mpa",
                          @"file_music.png", @"mp3",
                          @"file_music.png", @"mtm",
                          @"file_music.png", @"mtr",
                          @"file_music.png", @"mus",
                          @"file_music.png", @"mus10",
                          @"file_music.png", @"niff",
                          @"file_music.png", @"nist",
                          @"file_music.png", @"np?",
                          @"file_music.png", @"o01",
                          @"file_music.png", @"pac",
                          @"file_music.png", @"pat",
                          @"file_music.png", @"pbf",
                          @"file_music.png", @"pcm",
                          @"file_music.png", @"player",
                          @"file_music.png", @"plm",
                          @"file_music.png", @"pls",
                          @"file_music.png", @"pm",
                          @"file_music.png", @"prg",
                          @"file_music.png", @"ps16",
                          @"file_music.png", @"psb",
                          @"file_music.png", @"psion",
                          @"file_music.png", @"psm",
                          @"file_music.png", @"ptm",
                          @"file_music.png", @"ra",
                          @"file_music.png", @"rad",
                          @"file_music.png", @"raw",
                          @"file_music.png", @"rcp",
                          @"file_music.png", @"rmf",
                          @"file_music.png", @"rmi",
                          @"file_music.png", @"rol",
                          @"file_music.png", @"rtm",
                          @"file_music.png", @"s3i",
                          @"file_music.png", @"s3m",
                          @"file_music.png", @"sam",
                          @"file_music.png", @"sb",
                          @"file_music.png", @"sbk",
                          @"file_music.png", @"sc2",
                          @"file_music.png", @"sd",
                          @"file_music.png", @"sd2",
                          @"file_music.png", @"sdk",
                          @"file_music.png", @"sds",
                          @"file_music.png", @"sdw",
                          @"file_music.png", @"sdx",
                          @"file_music.png", @"sf2",
                          @"file_music.png", @"sfd",
                          @"file_music.png", @"sfi",
                          @"file_music.png", @"sfm",
                          @"file_music.png", @"sfr",
                          @"file_music.png", @"skyt",
                          @"file_music.png", @"smp",
                          @"file_music.png", @"snd",
                          @"file_music.png", @"sndr",
                          @"file_music.png", @"sndt",
                          @"file_music.png", @"sou",
                          @"file_music.png", @"spd",
                          @"file_music.png", @"spl",
                          @"file_music.png", @"spp",
                          @"file_music.png", @"sss",
                          @"file_music.png", @"stm",
                          @"file_music.png", @"svx",
                          @"file_music.png", @"sw",
                          @"file_music.png", @"syw",
                          @"file_music.png", @"tex",
                          @"file_music.png", @"tjs",
                          @"file_music.png", @"tp?",
                          @"file_music.png", @"txw",
                          @"file_music.png", @"ub",
                          @"file_music.png", @"udw",
                          @"file_music.png", @"ulaw",
                          @"file_music.png", @"ult",
                          @"file_music.png", @"uni",
                          @"file_music.png", @"unic",
                          @"file_music.png", @"uw",
                          @"file_music.png", @"uwf",
                          @"file_music.png", @"v8",
                          @"file_music.png", @"vap",
                          @"file_music.png", @"voc",
                          @"file_music.png", @"vox",
                          @"file_music.png", @"vqf",
                          @"file_music.png", @"wav",
                          @"file_music.png", @"wfb",
                          @"file_music.png", @"wfd",
                          @"file_music.png", @"wfp",
                          @"file_music.png", @"wma",
                          @"file_music.png", @"wn",
                          @"file_music.png", @"wow",
                          @"file_music.png", @"xann",
                          @"file_music.png", @"xi",
                          @"file_music.png", @"xm",
                          @"file_music.png", @"xmi",
                          @"file_music.png", @"xms",
                          @"file_music.png", @"zen",
                          @"file_music.png", @"669",
                          @"file_music.png", @"8svx",
                          @"file_music.png", @"m4a",
                          @"file_music.png", @"awb",
                          @"file_music.png", @"ogg",
                          @"file_music.png", @"oga",
                          @"file_music.png", @"mka",
                          @"file_music.png", @"xmf",
                          @"file_music.png", @"rtttl",
                          @"file_music.png", @"smf",
                          @"file_music.png", @"imy",
                          @"file_music.png", @"rtx",
                          @"file_music.png", @"ota",
                          @"file_music.png", @"flac",
                          @"file_music.png", @"ape",
                          @"file_music.png", @"aa",
                          @"file_music.png", @"aax",
                          @"file_music.png", @"f4a",
                          @"file_music.png", @"m4r",
                          @"file_music.png", @"wv",
                          
                          @"file_pdf.png", @"pdf",
                          
                          @"file_ps.png", @"psd",
                          
                          @"file_ppt.png", @"ppt",
                          @"file_ppt.png", @"pptx",
                          @"file_ppt.png", @"pptm",
                          @"file_ppt.png", @"pot",
                          @"file_ppt.png", @"potx",
                          @"file_ppt.png", @"potm",
                          
                          @"file_rar.png", @"rar",
                          @"file_rar.png", @"7z",
                          @"file_zip.png", @"zip",
                          
                          @"file_rtf.png", @"rtf",
                          
                          @"file_txt.png", @"log",
                          @"file_txt.png", @"txt",
                          
                          @"file_video.png", @"avi",
                          @"file_video.png", @"rmvb",
                          @"file_video.png", @"rm",
                          @"file_video.png", @"asf",
                          @"file_video.png", @"divx",
                          @"file_video.png", @"mpg",
                          @"file_video.png", @"mpeg",
                          @"file_video.png", @"mpe",
                          @"file_video.png", @"wmv",
                          @"file_video.png", @"mp4",
                          @"file_video.png", @"mkv",
                          @"file_video.png", @"vob",
                          @"file_video.png", @"m4v",
                          @"file_video.png", @"mov",
                          @"file_video.png", @"mp4",
                          @"file_video.png", @"asf",
                          @"file_video.png", @"3gp",
                          @"file_video.png", @"3gpp",
                          @"file_video.png", @"3g2",
                          @"file_video.png", @"3gpp2",
                          @"file_video.png", @"webm",
                          @"file_video.png", @"ts",
                          @"file_video.png", @"qt",
                          @"file_video.png", @"flv",
                          @"file_video.png", @"f4v",
                          @"file_video.png", @"ogm",
                          @"file_video.png", @"ogv",
                          @"file_video.png", @"mts",
                          @"file_video.png", @"m2ts",
                          
                          @"file_visio.png", @"vsd",
                          
                          @"file_word.png", @"doc",
                          @"file_word.png", @"docx",
                          
                          nil];
    }
    
    if (![ext  isKindOfClass:[NSString class]]) {
        return @"file_unrecognize.png";
    }
    
    NSString* imgFile = [gFileTypeImage objectForKey:[ext lowercaseString]];
    if (!imgFile) imgFile = @"file_unrecognize.png";
    return imgFile;
}

+ (long long)getFreeSpace
{
    NSFileManager *fm = [NSFileManager defaultManager];
	NSDictionary *fattributes = [fm attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    //    long long totalSize = [[fattributes objectForKey:NSFileSystemSize] longLongValue];
    long long freeSize = [[fattributes objectForKey:NSFileSystemFreeSize] longLongValue];
    NSLog(@"freeSize=%lld",freeSize);
    
    return freeSize;
}

+ (NSString*)unescapeHTML:(NSString*)inputString;
{
	NSMutableString* stringWithHttp = [NSMutableString string];
	NSMutableString* target = [[inputString mutableCopy] autorelease];
	NSCharacterSet* chs = [NSCharacterSet characterSetWithCharactersInString:@"&"];
	
	while ([target length] > 0)
    {
		NSRange r = [target rangeOfCharacterFromSet:chs];
		if (r.location == NSNotFound)
        {
			[stringWithHttp appendString:target];
			break;
		}
		
		if (r.location > 0)
        {
			[stringWithHttp appendString:[target substringToIndex:r.location]];
			[target deleteCharactersInRange:NSMakeRange(0, r.location)];
		}
		
		if ([target hasPrefix:@"&lt;"])
        {
			[stringWithHttp appendString:@"<"];
			[target deleteCharactersInRange:NSMakeRange(0, 4)];
		}
        else if ([target hasPrefix:@"&gt;"])
        {
			[stringWithHttp appendString:@">"];
			[target deleteCharactersInRange:NSMakeRange(0, 4)];
		}
        else if ([target hasPrefix:@"&quot;"])
        {
			[stringWithHttp appendString:@"\""];
			[target deleteCharactersInRange:NSMakeRange(0, 6)];
		}
        else if ([target hasPrefix:@"&ldquo;"])
        {
			[stringWithHttp appendString:@"“"];
			[target deleteCharactersInRange:NSMakeRange(0, 7)];
		}
        else if ([target hasPrefix:@"&rdquo;"])
        {
			[stringWithHttp appendString:@"”"];
			[target deleteCharactersInRange:NSMakeRange(0, 7)];
		}
        else if ([target hasPrefix:@"&lsquo;"])
        {
			[stringWithHttp appendString:@"‘"];
			[target deleteCharactersInRange:NSMakeRange(0, 7)];
		}
        else if ([target hasPrefix:@"&rsquo;"])
        {
			[stringWithHttp appendString:@"’"];
			[target deleteCharactersInRange:NSMakeRange(0, 7)];
		}
        else if ([target hasPrefix:@"&amp;"])
        {
			[stringWithHttp appendString:@"&"];
			[target deleteCharactersInRange:NSMakeRange(0, 5)];
		}
        else if ([target hasPrefix:@"&mdash;"])
        {
			[stringWithHttp appendString:@"—"];
			[target deleteCharactersInRange:NSMakeRange(0, 7)];
		}
        else
        {
			[stringWithHttp appendString:@"&"];
			[target deleteCharactersInRange:NSMakeRange(0, 1)];
		}
	}
	
	return stringWithHttp;
}

+ (NSArray *)fetchObjects:(NSString *)entityName
          sortDescriptors:(NSArray *)descriptors
                predicate:(NSPredicate *)predicate
               fetchLimit:(NSUInteger)limit
                threadMOC:(NSManagedObjectContext *)moc
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    [fetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:moc]];
    [fetchRequest setSortDescriptors:descriptors];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:limit];
    
    NSError *error = nil;
    NSArray *objects = [moc executeFetchRequest:fetchRequest error:&error];
    
    if (error)
        DLogError(@"fetch DB Objects error:%@",error.localizedDescription);
    
    //    NSFetchedResultsController *fetchResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[PCUtility managedObjectContext] sectionNameKeyPath:nil cacheName:name];
    //
    //    NSError *err = nil;
    //    if (![fetchResultsController performFetch:&err])
    //        NSLog(@"fetchObjects:%@", [err localizedDescription]);
    //
    //    NSArray* objects = fetchResultsController.fetchedObjects;
    //
    //    [fetchResultsController release];
    [fetchRequest release];
    
    return objects;
}

+ (NSArray *)fetchObjects:(NSString *)entityName
          sortDescriptors:(NSArray *)descriptors
                predicate:(NSPredicate *)predicate
               fetchLimit:(NSUInteger)limit
                cacheName:(NSString *)name
{
    return [PCUtility fetchObjects:entityName
                   sortDescriptors:descriptors
                         predicate:predicate
                        fetchLimit:limit
                         threadMOC:[PCUtility managedObjectContext]];
}

+ (void)checkDownloadFilesExist
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *cacheFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Caches"];
    NSString *downloadFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/Download"];
    NSArray *folderArr = @[cacheFolder, downloadFolder];
    
    for (int i = 0; i < folderArr.count; i++)
    {
        NSString *path = folderArr[i];
        if (![fileManager fileExistsAtPath:path])
        {
            NSString *type = i == 0 ? @"Cache" : @"Download";
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(type == %@)", type];
            
            NSArray *fetchArray = [PCUtility fetchObjects:@"FileCacheInfo"
                                          sortDescriptors:nil
                                                predicate:predicate
                                               fetchLimit:0
                                                cacheName:@"delete"];
            
            for (PCFileCacheInfo *info in fetchArray)
            {
                [[PCUtility managedObjectContext] deleteObject:info];
            }
            
            [[PCUtility managedObjectContext] save:nil];
        }
    }
}

+ (BOOL) checkPrivacyForAlbum
{
    __block BOOL accessGranted = NO;
    __block int32_t counter = 0;
    
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (*stop) {
            return;
        }
        // access granted
        *stop = TRUE;
        accessGranted = YES;
        OSAtomicDecrement32(&counter);
    } failureBlock:^(NSError *error) {
        // User denied access
        accessGranted = NO;
        OSAtomicDecrement32(&counter);
    }];
    [assetsLibrary release];
    
    while (counter >= 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    
    return accessGranted;
}

+ (UIBarButtonItem *)createRefresh:(id)target
{
    UIButton* refreshButton = [[UIButton alloc] init];
    [refreshButton setImage:[UIImage imageNamed:[PCUtility getImgName:@"navigate_refresh"]] forState:UIControlStateNormal];
    [refreshButton addTarget:target action:@selector(refreshData:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* btnRefreshBtn = [[UIBarButtonItem alloc] initWithCustomView:refreshButton];
    refreshButton.frame = CGRectMake(5, 5, 23, 23);
    [refreshButton release];
    return [btnRefreshBtn autorelease];
}

+ (BOOL)animateRefreshBtn:(UIView *)view
{
    CALayer *layer = view.layer;
    if ([layer animationForKey:@"transform"])
    {
        return NO;
    }
    
    CAKeyframeAnimation *theAnimation = [CAKeyframeAnimation animation];
    
    theAnimation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeRotation(0,0,0,1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeRotation(3.13,0,0,1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeRotation(6.26,0,0,1)]];
    theAnimation.cumulative =YES;
    theAnimation.removedOnCompletion =YES;
    theAnimation.repeatCount =HUGE_VALF;
    theAnimation.speed = 0.3f;
    
    [layer addAnimation:theAnimation forKey:@"transform"];
    return YES;
}

+ (BOOL)moveCacheFileToDownload:(NSString *)hostPath
                       fileSize:(long long)size
                      fileCache:(FileCache *)fileCache
                       fileType:(NSInteger)type
{
    NSString *downFilePath = [fileCache getCacheFilePath:hostPath withType:TYPE_DOWNLOAD_FILE];
    NSString *cacheFilePath = [fileCache getCacheFilePath:hostPath withType:type];
    //    NSString *modifyTime = [NSString stringWithFormat:@"%@",[node objectForKey:@"modifyTime"]];
    
    //更新FileCacheInfo表里对应的该缓存文件记录的path和type字段
    [fileCache updateCacheInfo:cacheFilePath newPath:downFilePath];
    
    //添加记录到FileDownloadedInfo
    if (size != 0) {
        [[PCUtility downloadManager] finishItem:hostPath
                                      localPath:downFilePath
                                     modifyTime:nil
                                       fileSize:size];
    }
    
    //把缓存文件移动到Download文件夹
    NSString *downFolder = [downFilePath stringByDeletingLastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:downFolder])
    {
        [fileManager createDirectoryAtPath:downFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSError *error = nil;
    BOOL success = [fileManager moveItemAtPath:cacheFilePath toPath:downFilePath error:&error];
    if (!success)
    {
        DLogError(@"moveCacheFileToDownload move file error:%@",error.localizedDescription);
    }
    return success;
}

+ (NSData *)getUploadImageData:(ALAssetRepresentation *)present
{
    long long size = present.size;
    uint8_t *data = malloc(size);
    
    NSError *error = nil;
    NSUInteger result = [present getBytes:data fromOffset:0 length:size error:&error];
    
    if (result == 0)
    {
        DLogError(@"get upload image data error:%@",error.localizedDescription);
    }
    
    return result ? [NSData dataWithBytesNoCopy:data length:size] : nil;
}

+ (void)saveInfos
{
    NSError *err;
    if (![[PCUtility managedObjectContext] save:&err])
        DLogError(@"save database error:%@", [err localizedDescription]);
}

+ (NSString *)formatDate:(NSDate *)date formatString:(NSString*)formatString
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:formatString];
    NSString *ret = [dateFormat stringFromDate:date];
    [dateFormat release];
    return ret;
}

+ (void)showTip:(NSString *)msg
{
    [PCUtility showTip:msg needMultiline:YES];
}

+ (void)showTip:(NSString *)msg needMultiline:(BOOL)multiline
{
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].delegate.window];
    if (!hud || (hud.mode !=MBProgressHUDModeText))
    {
        hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window
                                       text:msg
                            showImmediately:YES
                                isMultiline:multiline];
    }
    else
    {
        [hud show:YES];
        if (multiline)
        {
            hud.labelText = nil;
            hud.detailsLabelText = msg;
        }
        else
        {
            hud.detailsLabelText = nil;
            hud.labelText = msg;
        }
    }
    
    UIFont *font = [UIFont systemFontOfSize:20];
    if (multiline)
        hud.detailsLabelFont = font;
    else
        hud.labelFont = font;
    
    hud.mode = MBProgressHUDModeText;
    hud.userInteractionEnabled = NO;
    hud.margin = 5.f;
    hud.yOffset = 20.f;
    
    [hud hide:YES afterDelay:3];
}

+ (NSString *)moveDownloadFileToCache:(NSString *)hostPath
                             downPath:(NSString *)downFilePath
{
    NSString *relativePath = [FileCache getRelativePath:hostPath
                                               withType:TYPE_CACHE_FILE
                                              andDevice:[PCLogin getResource]];
    NSString *cacheFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:relativePath];
    
    //更新FileCacheInfo表里对应的该缓存文件记录的path和type字段
    PCFileCacheInfo *fileCache = [FileCache fetchCacheFile:downFilePath];
    
    if (fileCache)
    {
        fileCache.path = cacheFilePath;
        fileCache.type = @"Cache";
        [[PCUtility managedObjectContext] save:nil];
    }
    
    //把文件移动到缓存文件夹
    NSString *cacheFolder = [cacheFilePath stringByDeletingLastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:cacheFolder])
    {
        [fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSError *error = nil;
    BOOL success = [fileManager moveItemAtPath:downFilePath toPath:cacheFilePath error:&error];
    if (!success)
    {
        DLogError(@"moveDownloadFileToCache move file error:%@",error.localizedDescription);
        return nil;
    }
    else
    {
        [[PCUtility downloadManager] deleteDownloadItem:hostPath fileStatus:kStatusDownloaded];
    }
    return cacheFilePath;
}

+ (BOOL)checkValidEmail:(NSString*)emailAdderss
{
    if ((emailAdderss == nil) || ([emailAdderss length]<1))
    {
        return NO;
    }
    
    //NSString *expression = @"^([a-zA-Z0-9]+[\\-|\\.|_]?)*[a-zA-Z0-9]+@([a-zA-Z0-9]+[\\-|\\.]?)*[a-zA-Z0-9]+\\.[a-zA-Z]{2,4}$";
    NSString *expression = @"^[a-zA-Z0-9][\\w\\.\\-]*[a-zA-Z0-9]+@[a-zA-Z0-9][a-zA-Z0-9\\.\\-]*[a-zA-Z0-9]\\.[a-zA-Z][a-zA-Z\\.]*[a-zA-Z]$";
    NSError *error = NULL;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:emailAdderss options:0 range:NSMakeRange(0, [emailAdderss length])];
    
    if (match){
        return YES;
    }else{
        return NO;;
    }
}

+(NSMutableDictionary*)compressingImgDic
{
    if(gCompressingImgDic == nil)
    {
        gCompressingImgDic = [[NSMutableDictionary dictionary] retain];
    }
    return gCompressingImgDic;
}
+(void) setCompressImgDic:(NSMutableDictionary*)dic
{
    if (gCompressingImgDic == dic) {
        return;
    }
    if (gCompressingImgDic) {
        [gCompressingImgDic release];
    }
    gCompressingImgDic = [dic retain];
}

+ (BOOL) checkImages:(NSString*)ext
{
    if (ext &&  [[PCUtility getImgByExt:ext] isEqualToString:@"file_pic.png"]) {
        return YES;
    }
    return NO;
}

+ (BOOL)checkValidMobileNumber:(NSString *)mobileNum
{
    NSString *mobileRegex = @"^(\\+86)*1[3458]\\d{9}$";
    NSPredicate *regexTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", mobileRegex];
    return [regexTest evaluateWithObject:mobileNum];
}

+ (BOOL)checkValidPassword:(NSString *)password
{
    NSString *passwordRegex = @"[0-9a-zA-Z]{6,16}";
    NSPredicate *passwordTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", passwordRegex];
    return [passwordTest evaluateWithObject:password];
}

+ (BOOL)checkValidSerialNumber:(NSString *)sn
{
    NSString *snRegex = @"[0-9a-fA-F]{16}";
    NSPredicate *snTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", snRegex];
    return [snTest evaluateWithObject:sn];
}

+ (BOOL)isSameDay:(NSDate*)date1 date2:(NSDate*)date2
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date2];
    
    return [comp1 day] == [comp2 day] && [comp1 month] == [comp2 month] && [comp1 year]  == [comp2 year];
}
+ (BOOL)itemCanOpenWithPath:(NSString *)path
{
    if (!path)
    {
        return NO;
    }
    
    NSString *extension = [[path pathExtension] lowercaseString];
    NSString *type = [PCUtility getImgByExt:extension];
    if ([type isEqualToString:@"file_video.png"] ||
        [type isEqualToString:@"file_music.png"])
    {
        //本地有文件
        if([[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            if ([extension isEqualToString:@"amr"])
            {
                return NO;
            }
            else
            {
                AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
                return asset.playable;
            }
        }
        else
        {
            //取得后缀名
            if ([extension isEqualToString:@"mp4"] ||
                [extension isEqualToString:@"mov"] ||
                [extension isEqualToString:@"m4v"] ||
                [extension isEqualToString:@"avi"] ||
                [extension isEqualToString:@"3gp"] ||
                [extension isEqualToString:@"mp3"] ||
                [extension isEqualToString:@"wav"] ||
                [extension isEqualToString:@"aac"] ||
                [extension isEqualToString:@"aax"] ||
                [extension isEqualToString:@"m4a"] ||
                [extension isEqualToString:@"m4r"] ||
                [extension isEqualToString:@"aiff"])
            {
                return YES;
            }
            else
            {
                return NO;
            }
        }
        
    }

    BOOL canPlay = [QLPreviewController canPreviewItem:(id<QLPreviewItem>)[NSURL fileURLWithPath:path]];
    return canPlay;
}

+ (NSString *)deviceModel
{
    NSString *deviceModel = nil;
    
    char buffer[32];
    size_t length = sizeof(buffer);
    if (sysctlbyname("hw.machine", &buffer, &length, NULL, 0) == 0) {
        NSString *platform = [[NSString alloc] initWithCString:buffer encoding:NSASCIIStringEncoding];
        if ([platform isEqualToString:@"iPhone1,1"])        deviceModel = @"iPhone";
        else if ([platform isEqualToString:@"iPhone1,2"])   deviceModel = @"iPhone3G";
        else if ([platform isEqualToString:@"iPhone2,1"])   deviceModel = @"iPhone3GS";
        else if ([platform isEqualToString:@"iPhone3,1"])   deviceModel = @"iPhone4";          //GSM
        else if ([platform isEqualToString:@"iPhone3,2"])   deviceModel = @"iPhone4";          //GSM 8G
        else if ([platform isEqualToString:@"iPhone3,3"])   deviceModel = @"iPhone4";          //CDMA
        else if ([platform isEqualToString:@"iPhone4,1"])   deviceModel = @"iPhone4S";
        else if ([platform isEqualToString:@"iPhone5,1"])   deviceModel = @"iPhone5";          //GSM
        else if ([platform isEqualToString:@"iPhone5,2"])   deviceModel = @"iPhone5";          //Global
        else if ([platform isEqualToString:@"iPod1,1"])     deviceModel = @"iPodTouch";
        else if ([platform isEqualToString:@"iPod2,1"])     deviceModel = @"iPodTouch2";
        else if ([platform isEqualToString:@"iPod3,1"])     deviceModel = @"iPodTouch3";
        else if ([platform isEqualToString:@"iPod4,1"])     deviceModel = @"iPodTouch4";
        else if ([platform isEqualToString:@"iPod5,1"])     deviceModel = @"iPodTouch5";
        else if ([platform isEqualToString:@"iPad1,1"])     deviceModel = @"iPad";
        else if ([platform isEqualToString:@"iPad2,1"])     deviceModel = @"iPad2";            //Wi-Fi only
        else if ([platform isEqualToString:@"iPad2,2"])     deviceModel = @"iPad2";            //GSM
        else if ([platform isEqualToString:@"iPad2,3"])     deviceModel = @"iPad2";            //CDMA
        else if ([platform isEqualToString:@"iPad2,4"])     deviceModel = @"iPad2";            //Re-released Wi-Fi only
        else if ([platform isEqualToString:@"iPad2,5"])     deviceModel = @"iPadMini";         //Wi-Fi only
        else if ([platform isEqualToString:@"iPad2,6"])     deviceModel = @"iPadMini";         //GSM
        else if ([platform isEqualToString:@"iPad2,7"])     deviceModel = @"iPadMini";         //Global
        else if ([platform isEqualToString:@"iPad3,1"])     deviceModel = @"iPad3";            //Wi-Fi only
        else if ([platform isEqualToString:@"iPad3,2"])     deviceModel = @"iPad3";            //CDMA
        else if ([platform isEqualToString:@"iPad3,3"])     deviceModel = @"iPad3";            //GSM
        else if ([platform isEqualToString:@"iPad3,4"])     deviceModel = @"iPad4";            //Wi-Fi only
        else if ([platform isEqualToString:@"iPad3,5"])     deviceModel = @"iPad4";            //GSM
        else if ([platform isEqualToString:@"iPad3,6"])     deviceModel = @"iPad4";            //Global
        else if ([platform isEqualToString:@"i386"])        deviceModel = @"Simulator";
        else if ([platform isEqualToString:@"x86_64"])      deviceModel = @"Simulator";
        else deviceModel = [[platform retain] autorelease];
        [platform release];
    }
    
    return deviceModel;
}

@end
