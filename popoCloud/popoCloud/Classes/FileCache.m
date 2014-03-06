//
//  FileCache.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-17.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "FileCache.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "PCUtilityDataManagement.h"
#import "PCLogin.h"
#import "PCAppDelegate.h"
#import "NetPenetrate.h"
#import "PCFileInfo.h"
#import "PCUtilityUiOperate.h"
#import "UIDevice+IdentifierAddition.h"

#define K_RANGE_SIZE 512 * 1024 - 1
#define K_DELETE_CACHE_SIZE 20                //到达1G后删除老记录的数量
#define K_MAX_CACHE_SIZE (1024 * 1024 * 1024)   //缓存阀值

#define DELETE_CACHE_ALERT_TAG    1
#define LARGE_FILE_ALERT_TAG          2

@implementation FileCache

@synthesize delegate;
@synthesize connection;
@synthesize viewType;
@synthesize index;
@synthesize errorNo;
@synthesize fileSize;
@synthesize url;
@synthesize hostPath;
@synthesize localPath;
@synthesize modifyTime;
@synthesize modifyGTMTime;
@synthesize currentDeviceID;
@synthesize currentTimeZone;
@synthesize data;
@synthesize isRemoveWhenCancel;
@synthesize fileDownLoadUrl;
- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        //        data = [[NSMutableData alloc] init];
        data = [[NSMutableData alloc] init];
        progressView = nil;
        progressScale = 1.0;
        delegate = nil;
        index = 0;
        fileTotalSize = 0;
        isRemoveWhenCancel = NO;
    }
    
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
    [self cancel];
    
    self.fileCacheObjID = nil;
    self.currentDeviceID = nil;
    self.currentTimeZone = nil;
    self.hostPath = nil;
    if (url) [url release];
    if (localPath) [localPath release];
    if (headers) [headers release];
    //if (delegate) [(NSObject*)delegate release];
    [data release];
    self.fileDownLoadUrl = nil;
    [super dealloc];
}

#pragma mark - private methods

-(void)deleteCacheObjectsWithLimit:(NSUInteger)limit
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(type == %@)", @"Cache"];
    
    NSArray *fetchArray = [PCUtilityDataManagement fetchObjects:@"FileCacheInfo"
                                                sortDescriptors:nil
                                                      predicate:predicate
                                                     fetchLimit:limit
                                                      cacheName:@"delete"];
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    for (PCFileCacheInfo *info in fetchArray)
    {
        NSString *filePath = info.path;
        if (![filePath hasPrefix:NSHomeDirectory()]) {
            filePath = [NSHomeDirectory() stringByAppendingPathComponent:filePath];
        }
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        [[PCUtilityDataManagement managedObjectContext] deleteObject:info];
    }
    [pool release];
    [[PCUtilityDataManagement managedObjectContext] save:nil];
    if (limit!=0) { //0 表示 不限制limit，一次删光，不需要循环删除（用来删除一半的控制）
        [self fetchCacheObjects:NO];
    }
}

- (PCFileCacheInfo *)fetchObjects:(NSString*)type
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES];
    NSString *pathStr = localPath;
    if ([pathStr hasPrefix:NSHomeDirectory()])
    {
        pathStr = [pathStr substringFromIndex:[NSHomeDirectory() length]];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(path == %@)", pathStr];
    
    NSArray *fetchArray = [PCUtilityDataManagement fetchObjects:@"FileCacheInfo"
                                                sortDescriptors:@[sort]
                                                      predicate:predicate
                                                     fetchLimit:0
                                                      cacheName:@"Root"];
    
    //    for (PCFileCacheInfo *info in fetchArray)
    //        NSLog(@"%@, %@", info.path, info.modifyTime);
    PCFileCacheInfo *fileCacheInfo = nil;
    
    if (fetchArray.count) {
        fileCacheInfo = [fetchArray objectAtIndex:0];
        if (modifyTime) [modifyTime release];
        modifyTime = [fileCacheInfo.modifyTime retain];
        NSLog(@"database modifyTime:%@", modifyTime);
        
        BOOL isChange = NO;
        for (int i = 1; i < fetchArray.count; i++) {
            isChange = YES;
            [[PCUtilityDataManagement managedObjectContext] deleteObject:[fetchArray objectAtIndex:i]];
        }
        
        if (isChange)
            [PCUtilityDataManagement saveInfos];
    }
    else {
        fileCacheInfo = (PCFileCacheInfo*)[NSEntityDescription insertNewObjectForEntityForName:@"FileCacheInfo" inManagedObjectContext:[PCUtilityDataManagement managedObjectContext]];
        fileCacheInfo.path = pathStr;
        fileCacheInfo.type = type;
        fileCacheInfo.modifyGTMTime = 0;
        fileCacheInfo.size = [NSNumber numberWithLongLong:-1];
        fileCacheInfo.timeZone = currentTimeZone;
        
        [PCUtilityDataManagement saveInfos];
    }
    
    self.fileCacheObjID = fileCacheInfo.objectID;
    
    return fileCacheInfo;
}
/*
 - (void) saveInfos {
 NSError *err;
 if (![[PCUtility managedObjectContext] save:&err])
 NSLog(@"Error %@", [err localizedDescription]);
 }
 */
-(void) sendCacheFailError:(NSString*)error {
    if (delegate&& delegate!=nil && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)])
    {
        [delegate cacheFileFail:self hostPath:hostPath error:error];
    }
}

- (void) connectFileDownLoadWithURL:(NSURL*)downLoadURL {
    
    if (headers) [headers release];
    headers = [[NSMutableArray alloc] init];
    if (modifyTime && offsetPos > 0) {
        //        [headers addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        //                              modifyTime, @"value", @"If-Modified-Since", @"key", nil]];
    }
    long long pos = offsetPos;
    
    //[headers addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"keep-alive", @"value", @"connection", @"key", nil]];
    BOOL bNeedRange =     (viewType != TYPE_CACHE_THUMBIMAGE_ZIP)
    && (viewType != TYPE_CACHE_THUMBIMAGE)
    && (viewType != TYPE_CACHE_SLIDEIMAGE)
    && (viewType != TYPE_CACHE_VCF_FILE);
    if(pos >0 || bNeedRange){
        [headers addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSString stringWithFormat: @"bytes=%lld-%lld", pos,pos + K_RANGE_SIZE], @"value", @"Range", @"key", nil]];
        
    }
    
    NSLog(@"downLoadURL = %@, pos = %lld", downLoadURL, pos);
    [headers retain];
    self.connection = [PCUtility httpGetFileDownLoadWithURL:downLoadURL headers:headers delegate:self];
    [headers release];
}

- (void) connectURL {
    
    if (headers) [headers release];
    headers = [[NSMutableArray alloc] init];
    //    if (modifyTime && offsetPos > 0) {
    //        //[headers addObject:[NSDictionary dictionaryWithObjectsAndKeys:modifyTime, @"value", @"If-Modified-Since", @"key", nil]];
    //    }
    
    //[headers addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"keep-alive", @"value", @"connection", @"key", nil]];
    NetPenetrate *netPenetrate = [NetPenetrate sharedInstance];
    
    //图片TYPE_CACHE_SLIDEIMAGE 不分段。
    if (viewType != TYPE_CACHE_THUMBIMAGE_ZIP
        && viewType != TYPE_CACHE_THUMBIMAGE
        && viewType != TYPE_CACHE_SLIDEIMAGE
        && viewType != TYPE_CACHE_VCF_FILE) {
        long long pos = offsetPos;
        
        if (netPenetrate.gCurrentNetworkState == CURRENT_NETWORK_STATE_LOCAL) {
            if (pos > 0) {
                [headers addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSString stringWithFormat: @"bytes=%lld-%lld", pos,pos + 10240* 1024], @"value", @"Range", @"key", nil]];
                
            }
        }
        else if ((netPenetrate.gCurrentNetworkState == CURRENT_NETWORK_STATE_NAT && pos > 0) ||
                 netPenetrate.gCurrentNetworkState == CURRENT_NETWORK_STATE_DEFAULT)
        {
            [headers addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                [NSString stringWithFormat: @"bytes=%lld-%lld", pos,pos + K_RANGE_SIZE], @"value", @"Range", @"key", nil]];
        }
    }
    
    [headers retain];
    
    //    NSLog(@"%@", headers);
    //文件下载 的请求流程 改变了
    if (currentDeviceID && ![currentDeviceID isEqualToString:[[PCSettings sharedSettings] currentDeviceIdentifier]])
    {
        self.connection = [PCUtility httpGetFileServerInfo:self];
    }
    else if (netPenetrate.gCurrentNetworkState == CURRENT_NETWORK_STATE_DEFAULT)
    {
        self.connection = [PCUtility httpGetFileServerInfo:self];
    }
    else
    {
        NSString *urlStr;
        if ([PCSettings sharedSettings].bSessionSupported)
        {
            urlStr = [self.url stringByAppendingFormat:@"&token_id=%@&client_id=%@", [PCLogin getToken], [[UIDevice currentDevice] uniqueDeviceIdentifier]];
        }
        else
        {
            urlStr = self.url;
        }
        self.connection = [PCUtility httpGetWithURL:urlStr headers:headers delegate:self];
    }
    [headers release];
}

- (void)finishCache
{
    if (progressView) {
        progressView.progress = progressScale;
    }
    if (delegate && [delegate respondsToSelector:@selector(cacheFileProgress:hostPath:)])
        [delegate cacheFileProgress:1.0 hostPath:hostPath];
    
    NSError *err;
    NSFileManager *fileManage = [NSFileManager defaultManager];
    NSDictionary *attr = [fileManage attributesOfItemAtPath:localPath error:&err];
    fileSize = [[attr objectForKey:NSFileSize] longLongValue];
    
    if (self.fileCacheObjID)
    {
        PCFileCacheInfo *fileCacheInfo = (PCFileCacheInfo *)[[PCUtilityDataManagement managedObjectContext] existingObjectWithID:self.fileCacheObjID error:nil];
        if (fileCacheInfo)
        {
            fileCacheInfo.size = [NSNumber numberWithLongLong:fileSize];
            [PCUtilityDataManagement saveInfos];
        }
    }
    self.isRemoveWhenCancel = NO;
    [self cancel];
    //移到 下面了，为了长度为0,filehandle为空的情况
    
    if (delegate && [delegate respondsToSelector:@selector(cacheFileFinish:)])
        [delegate cacheFileFinish:self];
}

- (BOOL) isCacheFileExit:(NSString*)filePath withType:(NSInteger)type {
    NSFileManager *fileManage = [NSFileManager defaultManager];
    BOOL fileExit = [fileManage fileExistsAtPath:filePath];
    
    return fileExit;
}

#pragma mark - public methods

- (void) setProgressView:(PCProgressView *)progress progressScale:(float)scale {
    progressView = progress;
    progressScale = scale;
}

- (void) setIndex:(NSInteger)_index {
    index = _index;
}


- (NSString *)cacheFile:(NSString *)path viewType:(NSInteger)type viewController:(id)controller fileSize:(long long)filesize modifyGTMTime:(long long)_modifyGTMTime showAlert:(BOOL)showAlert
{
    if (controller) {
        //[controller retain];
        delegate = (id)controller;
    }
    fileTotalSize = filesize;
    self.hostPath = path;
    DLogInfo(@"fileCache.hostPath=%@",self.hostPath);
    if (![PCUtility isNetworkReachable:self])
    {
        errorNo = FILE_CACHE_ERROR_NO_NETWORK;
        //        [self performSelector:@selector(sendCacheFailError:) withObject:NSLocalizedString(@"OpenNetwork", nil) afterDelay:0.1];
        if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)])
        {
            [delegate cacheFileFail:self hostPath:hostPath error:NSLocalizedString(@"OpenNetwork", nil)];
        }
        
        return nil;
    }
    
    NSString *saveType = nil;
    NSString *documentsDirectory = nil;
    if (type == TYPE_DOWNLOAD_FILE)
    {
        saveType = @"Download";
        documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
    }
    else
    {
        saveType = @"Cache";
        //        documentsDirectory = NSTemporaryDirectory();
        documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
    }
    
    if (showAlert) {
        switch (type) {
            case TYPE_DOWNLOAD_FILE:
            case TYPE_CACHE_FILE:
            case TYPE_CACHE_IMAGE:
                if (![PCUtility isWifi] &&  (filesize >= SIZE_2M)) {
                    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
                    {
                        UIAlertView *Alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FileSizeMoreThan2MB", nil)
                                                                        message:nil
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                              otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                        Alert.tag = LARGE_FILE_ALERT_TAG;
                        [Alert show];
                        [Alert release];
                    }
                    //如果在后台。大于2m且非wifi
                    else {
                        errorNo = FILE_CACHE_FILE_MORE_THAN_2M;
                        if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)]) [delegate cacheFileFail:self hostPath:hostPath error:nil];
                    }
                }
                break;
            case TYPE_CACHE_THUMBIMAGE:
            case TYPE_CACHE_THUMBIMAGE_ZIP:
            case TYPE_CACHE_SLIDEIMAGE:
            case TYPE_CACHE_NEXT_SLIDEIMAGE:
            case TYPE_CACHE_CONTACT:
            default:
                break;
        }
    }
    
    errorNo = FILE_CACHE_NO_ERROR;
    isCancel = NO;
    viewType = type;
    modifyGTMTime = _modifyGTMTime;
    
    //    NSLog(path);
    NSString *filePath = [FileCache getRelativePath:path withType:type andDevice:self.currentDeviceID];
    
    NSFileManager *fileManage = [NSFileManager defaultManager];
    NSArray* dirs = [filePath pathComponents];
    
    NSString *myDirectory = [NSString stringWithString:documentsDirectory];
    //    NSString *cacheDir = [myDirectory stringByAppendingPathComponent:@"/Caches/"];
    //    [self fetchCacheObjects:cacheDir];//执行当缓存文件总存储大小大于1024M时删除Caches文件夹及其所有文件
    
    
    int i = 0;
    BOOL isDirectory;
    for (; i < dirs.count - 1; i++) {
        myDirectory = [myDirectory stringByAppendingPathComponent:[dirs objectAtIndex:i]];
        BOOL isExist = [fileManage fileExistsAtPath:myDirectory isDirectory:&isDirectory];
        if (!isDirectory)
        {
            //此处加上showAlert判断是为了：当为YES时，后面的函数不被执行，added by ray
            if (showAlert && ![fileManage removeItemAtPath:myDirectory error:nil])
            {
                
                //xuyang修改。ios4系统。貌似不支持NSTemporaryDirectory？第一次目录会找不到。会弹出异常。导致第一次下载文件的时候。会触发cacheFileFail。导致弹出对话框。
                //                if(type != TYPE_DOWNLOAD_FILE || )
                //                {
                //                    if (delegate) [delegate cacheFileFail:self hostPath:path error:NSLocalizedString(@"DeleteFileFailed", nil)];
                //                    return nil;
                //
                //                }
            }
            isExist = NO;
        }
        if (!isExist) {
            NSError *err = nil;
            if ([fileManage createDirectoryAtPath:myDirectory withIntermediateDirectories:YES attributes:nil error:&err]==NO) {
                NSLog(@"Create directory failed, %@", err);
                errorNo = FILE_CACHE_ERROR_LACK_OF_SPACE;
                if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)])
                {
                    [delegate cacheFileFail:self hostPath:path error:NSLocalizedString(@"CreateFileFailed", nil)];
                }
                return nil;
            }
        }
    }
    
    localPath = [[NSString alloc] initWithString:[myDirectory stringByAppendingPathComponent:[dirs objectAtIndex:i]]];
    //    NSLog(localPath);
    
    if (filesize == 0) {
        [self performSelector:@selector(finishCache) withObject:nil afterDelay:0.1];
        return localPath;
    }
    
    offsetPos = 0;
    long long freeSize = [PCUtilityDataManagement getFreeSpace];
    NSString *errorStr = nil;
    
    if ([fileManage fileExistsAtPath:localPath]) {
        NSDictionary *attr = [fileManage attributesOfItemAtPath:localPath error:nil];
        if (attr) {
            offsetPos = [[attr objectForKey:NSFileSize] longLongValue];
            //            NSLog(@"%f", offsetPos);
        }
        
        long long remainSize = filesize - offsetPos;
        if (remainSize > freeSize) {
            errorNo = FILE_CACHE_ERROR_LACK_OF_SPACE;
            errorStr = NSLocalizedString(@"LackOfSpace", nil);
        }
    }
    else {
        if (filesize > freeSize) {
            errorNo = FILE_CACHE_ERROR_LACK_OF_SPACE;
            errorStr = NSLocalizedString(@"LackOfSpace", nil);
        }
        else if (![fileManage createFileAtPath:localPath contents:nil attributes:nil]) {
            NSLog(@"Create file failed, error code: %d - message: %s", errno, strerror(errno));
            errorNo = FILE_CACHE_ERROR_LACK_OF_SPACE;
            errorStr = NSLocalizedString(@"CreateFileFailed", nil);
        }
    }
    
    if (errorStr) {
        if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)])
        {
            [delegate cacheFileFail:self hostPath:path error:errorStr];
        }
        return nil;
    }
    
    modifyTime = nil;
    headers = nil;
    
	PCFileCacheInfo *fileCacheInfo = nil;
	if (viewType != TYPE_CACHE_THUMBIMAGE_ZIP)
	{
		fileCacheInfo = [self fetchObjects:saveType];
		fileSize = [fileCacheInfo.size longLongValue];
	}
    else
		fileSize = -1;
    
    if (fileSize < 0 || (fileSize != filesize) || offsetPos >= fileSize || modifyGTMTime == 0 || modifyGTMTime != [fileCacheInfo.modifyGTMTime longLongValue]) {
        
        //下载暂时->重新下载。。fileSize不等于filesize,所以加一个判断。否则每次重新下载 进度又从0开始了
        if (type != TYPE_DOWNLOAD_FILE) {
            modifyTime = nil;
            offsetPos = 0;
        }
        else
        {
            if(modifyGTMTime != [fileCacheInfo.modifyGTMTime longLongValue])
            {
                modifyTime = nil;
                offsetPos = 0;
            }
        }
    }
    
    fileHandle = [[NSFileHandle fileHandleForWritingAtPath:localPath] retain];
    
    path = [PCUtilityStringOperate encodeToPercentEscapeString:path];
    if (type == TYPE_CACHE_THUMBIMAGE) {
        url = [[NSString stringWithFormat:@"GetThumbImage?path=%@&width=82&height=82", path] retain];
    }
    else if (type == TYPE_CACHE_THUMBIMAGE_ZIP) {
        //        url = [NSString stringWithFormat:@"GetThumbImageZip&paths=%@&width=82&height=82", paths];
    }
    else if (type == TYPE_CACHE_SLIDEIMAGE || type == TYPE_CACHE_NEXT_SLIDEIMAGE ) {
        //        CGRect frame = [[UIScreen mainScreen] bounds];
        //        int width = frame.size.width;
        //        int height = frame.size.height;
        int width = 1080;
        int height = 600;//服务器总是返回1080*600，所以这里直接参数写死，modified by ray
        url = [[NSString stringWithFormat:@"GetThumbImage?path=%@&width=%d&height=%d", path, width, height] retain];
    }
    else {
        url = [[NSString stringWithFormat:@"DownloadFile?filePath=%@", path] retain];
    }
    
    if (progressView && (filesize > 1)) {
        progressView.progress = offsetPos * progressScale / filesize;
    }
    
    [fileHandle truncateFileAtOffset:offsetPos];
    [fileHandle seekToFileOffset:offsetPos];
    
    [self connectURL];
    return localPath;
}

- (NSInteger) cancel {
    isCancel = YES;
    if (connection) {
        [PCUtility  removeConnectionFromArray:connection];
        [self.connection cancel];
        self.connection = nil;
    }
    
    if (fileHandle) {
        [fileHandle closeFile];
        [fileHandle release];
        fileHandle = nil;
    }
    //删除没有下载完的缩略图
    if (isRemoveWhenCancel && progressView.progress<1.0 && viewType == TYPE_CACHE_THUMBIMAGE)
    {
        if (self.localPath.length)
        {
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.localPath])
            {
                [[NSFileManager defaultManager]removeItemAtPath:self.localPath error:nil];
            }
        }
        
    }
    return downloadSize;
}


//- (BOOL) GetFuLLSizeFileFromCacheWithNoModifyTime:(NSDictionary*)node withType:(NSInteger)type {
//    BOOL readFileFromCache = NO;
//    NSString* filePath = [node valueForKey:@"path"];
//    NSString* localFilePath = [self getCacheFilePath:filePath withType:type];
//    if (!localFilePath || [localFilePath isEqualToString:@""]) return NO;
//
//    PCFileCacheInfo *fileCache = [FileCache fetchCacheFile:localFilePath];
//
//    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:localFilePath error:nil];
//    if (attr) {
//        long long oldSize = [[attr objectForKey:NSFileSize] longLongValue];
//        readFileFromCache = ([fileCache.size longLongValue]  == oldSize);
//    }
//
//    return readFileFromCache;
//}

- (BOOL) GetFuLLSizeFileFromCacheWithFileInfo:(PCFileInfo*)fileInfo withType:(NSInteger)type {
    BOOL readFileFromCache = NO;
    NSString* filePath = fileInfo.path;
    long long listModifyTime = [fileInfo.modifyTime longLongValue];
    
    NSString* localFilePath = [self getCacheFilePath:filePath withType:type];
    if (!localFilePath || [localFilePath isEqualToString:@""]) return NO;
    
    PCFileCacheInfo *fileCache = [FileCache fetchCacheFile:localFilePath];
    if (!fileCache.modifyTime)
    {
        return NO;
    }
    
    NSString* cacheModifyTimeGMT = fileCache ? [NSString stringWithString:fileCache.modifyTime] :
    nil;//缓存的是格林尼治时间
    if (!cacheModifyTimeGMT || [cacheModifyTimeGMT isEqualToString:@""]) return NO;
    
    NSDate* cacheModifyTimeDate = [PCUtilityStringOperate formatTimeString:[cacheModifyTimeGMT substringToIndex:([cacheModifyTimeGMT length]-4)] formatString:@"EEE, dd MMM yyyy HH:mm:ss"];
    if (!cacheModifyTimeDate) return NO;
    NSDate* listModifyTimeDate = [NSDate dateWithTimeIntervalSince1970:(listModifyTime/1000.0)];
    
    int cacheModifyTimeInterval = (int)[cacheModifyTimeDate timeIntervalSinceReferenceDate];
    int listModifyTimeInterval = (int)[listModifyTimeDate timeIntervalSinceReferenceDate];
    
    if ((cacheModifyTimeInterval < listModifyTimeInterval) || ![self isCacheFileExit:localFilePath withType:type])
    {
        
        return NO;
    }
    
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:localFilePath error:nil];
    if (attr) {
        long long oldSize = [[attr objectForKey:NSFileSize] longLongValue];
        readFileFromCache = ([fileCache.size longLongValue]  == oldSize);
    }
    
    return readFileFromCache;
}

- (BOOL) readFileFromCacheWithFileInfo:(PCFileInfo*)fileInfo withType:(NSInteger)type {
    BOOL readFileFromCache = NO;
    NSString* filePath = fileInfo.path;
    long long listModifyTime = [fileInfo.modifyTime longLongValue];
    
    NSString* localFilePath = [self getCacheFilePath:filePath withType:type];
    if (!localFilePath || [localFilePath isEqualToString:@""]) return NO;
    
    PCFileCacheInfo *fileCache = [FileCache fetchCacheFile:localFilePath];
    if (!fileCache.modifyTime)
    {
        return NO;
    }
    
    NSString* cacheModifyTimeGMT = fileCache ? [NSString stringWithString:fileCache.modifyTime] :
    nil;//缓存的是格林尼治时间
    if (!cacheModifyTimeGMT || [cacheModifyTimeGMT isEqualToString:@""]) return NO;
    
    NSDate* cacheModifyTimeDate = [PCUtilityStringOperate formatTimeString:[cacheModifyTimeGMT substringToIndex:([cacheModifyTimeGMT length]-4)] formatString:@"EEE, dd MMM yyyy HH:mm:ss"];
    if (!cacheModifyTimeDate) return NO;
    NSDate* listModifyTimeDate = [NSDate dateWithTimeIntervalSince1970:(listModifyTime/1000.0)];
    
    int cacheModifyTimeInterval = (int)[cacheModifyTimeDate timeIntervalSinceReferenceDate];
    int listModifyTimeInterval = (int)[listModifyTimeDate timeIntervalSinceReferenceDate];
    
    if ((cacheModifyTimeInterval >= listModifyTimeInterval) && [self isCacheFileExit:localFilePath withType:type])
    {
        readFileFromCache = YES;
    }
    //bugid：53417  点击图片查看 加载过程中返回  再进入查看  只显示一部分
    //这是缓存文件存在。但是大小不完整。需要做判断
    if(type == TYPE_CACHE_SLIDEIMAGE)
    {
        NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:localFilePath error:nil];
        if (attr) {
            long long oldSize = [[attr objectForKey:NSFileSize] longLongValue];
            readFileFromCache = fileCache.size.intValue == oldSize;
        }
    }
    
    return readFileFromCache;
}

- (NSString*) getCacheFilePath:(NSString*)nodeFilePath withType:(NSInteger)type
{
    NSString *relativePath = [FileCache getRelativePath:nodeFilePath
                                               withType:type
                                              andDevice:self.currentDeviceID];
    
    //    NSString *documentsDirectory = type == TYPE_DOWNLOAD_FILE ? [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] : NSTemporaryDirectory();
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
    
    return [documentsDirectory stringByAppendingPathComponent:relativePath];
}

- (void)fetchCacheObjects:(BOOL)needAsk
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(type == %@)", @"Cache"];
    
    NSArray *fetchArray = [PCUtilityDataManagement fetchObjects:@"FileCacheInfo"
                                                sortDescriptors:@[sort]
                                                      predicate:predicate
                                                     fetchLimit:0
                                                      cacheName:@"Root"];
    
    long long totalSize = 0, size = 0;
    for (PCFileCacheInfo *info in fetchArray) {
        size = [info.size longLongValue];
        //        NSLog(@"当前cache：%@,%@",info.path,info.timeZone);
        if (size > 0) totalSize += size;
    }
    
    //    NSLog(@"totalSize = %f",  totalSize);
    //modified by ray，询问用户是否大于1G，最终会删除到小于500m的总容量
    long long maxSize = needAsk ? K_MAX_CACHE_SIZE : K_MAX_CACHE_SIZE / 2;
    
    if (totalSize > maxSize)
    {
        if (!needAsk) {
            [self deleteCacheObjectsWithLimit:K_DELETE_CACHE_SIZE];
        }
        else{
            UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"AskDeleteCache", nil)
                                                                  message:nil
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                        otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
            deleteAlert.tag = DELETE_CACHE_ALERT_TAG;
            [deleteAlert show];
            [deleteAlert release];
        }
    }
}

- (void)updateCacheInfo:(NSString *)path newPath:(NSString *)newPath
{
    PCFileCacheInfo *fileCache = [FileCache fetchCacheFile:path];
    
    if (fileCache)
    {
        fileCache.path = newPath;
        fileCache.type = @"Download";
        [[PCUtilityDataManagement managedObjectContext] save:nil];
    }
}

#pragma mark - static methods

+ (void)deleteDownloadFile:(NSString *)path
{
    PCFileCacheInfo *fileCache = [FileCache fetchCacheFile:path];
    
    if (fileCache)
    {
        [[PCUtilityDataManagement managedObjectContext] deleteObject:fileCache];
        [[PCUtilityDataManagement managedObjectContext] save:nil];
    }
}

+ (NSString *)getRelativePath:(NSString *)path withType:(NSInteger)type andDevice:(NSString *)device
{
    NSMutableString* filePath = [[[NSMutableString alloc] initWithCapacity:256]  autorelease];
    [filePath setString:[path stringByReplacingOccurrencesOfString:@"\\" withString:@"/"]];
    //修改but 1551 判断长度，我喜欢文件的path 可能是一个字符
    if ([filePath length]>1 && [filePath characterAtIndex:1] == ':')
        [filePath deleteCharactersInRange:NSMakeRange(1, 1)];
    else if ([filePath characterAtIndex:0] == '/')
        [filePath deleteCharactersInRange:NSMakeRange(0, 1)];
    
    switch (type) {
        case TYPE_DOWNLOAD_FILE:
        case TYPE_CACHE_VCF_FILE:
        {
            NSString *subPath = device ? [NSString stringWithFormat:@"Download/%@/",device] :
            @"Download/";
            [filePath insertString:subPath atIndex:0];
            break;
        }
        case TYPE_CACHE_THUMBIMAGE:
        case TYPE_CACHE_THUMBIMAGE_ZIP:
        {
            NSString *subPath = device ? [NSString stringWithFormat:@"Caches/%@/ThumbImage/",device] :
            @"Caches/ThumbImage/";
            [filePath insertString:subPath atIndex:0];
            break;
        }
        case TYPE_CACHE_SLIDEIMAGE:
        case TYPE_CACHE_NEXT_SLIDEIMAGE:
        {
            NSString *subPath = device ? [NSString stringWithFormat:@"Caches/%@/SlideImage/",device] :
            @"Caches/SlideImage/";
            [filePath insertString:subPath atIndex:0];
            break;
        }
        case TYPE_CACHE_FILE:
        case TYPE_CACHE_IMAGE:
        case TYPE_CACHE_CONTACT:
        default:
        {
            NSString *subPath = device ? [NSString stringWithFormat:@"Caches/%@/",device] : @"Caches/";
            [filePath insertString:subPath atIndex:0];
            break;
        }
    }
    return filePath;
}

+ (PCFileCacheInfo *)fetchCacheFile:(NSString *)path
{
    if ([path hasPrefix:NSHomeDirectory()])
    {
        path = [path substringFromIndex:[NSHomeDirectory() length]];
    }
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(path == %@)", path];
    
    NSArray *fetchArray = [PCUtilityDataManagement fetchObjects:@"FileCacheInfo"
                                                sortDescriptors:@[sort]
                                                      predicate:predicate
                                                     fetchLimit:0
                                                      cacheName:@"Root"];
    
    return fetchArray.count ? fetchArray[0] : nil;
}

- (void)continueDownLoad
{
    if (self.fileDownLoadUrl)
    {
        [self connectFileDownLoadWithURL:self.fileDownLoadUrl];
    }
    else
    {
        [self connectURL];
    }
}

#pragma mark - PCNetworkDelegate methods

-(void)pcConnection:(NSURLConnection *)_connection didReceiveResponse:(NSURLResponse *)response {
    [data setLength:0];
    if (isCancel) return;
    
    //   [data setLength:0];
    
    NSInteger rc = [(NSHTTPURLResponse*)response statusCode];
    //    NSLog(@"status code: %d", rc);
    
    //connection = _connection;
    //self.connection = _connection;
    
    //此处判断viewType，是因为TYPE_CACHE_THUMBIMAGE_ZIP类型传入赋值的fileTotalSize为-1，
    //导致原来offsetPos >= fileTotalSize的判断条件（0 > -1）立马执行而没有正常下载成功
    BOOL isImage = viewType == TYPE_CACHE_THUMBIMAGE_ZIP || viewType == TYPE_CACHE_SLIDEIMAGE || viewType == TYPE_CACHE_NEXT_SLIDEIMAGE  ||viewType ==TYPE_CACHE_VCF_FILE||viewType == TYPE_CACHE_THUMBIMAGE;
    if ( rc == 416 || rc == 304  ||
        (isImage && offsetPos == fileTotalSize) ||
        (!isImage && offsetPos >= fileTotalSize))
    {
        [self finishCache];
        return;
    }
    
    NSString *error;
    
    error = [PCUtility checkResponseStautsCode:rc];
    if (error) {
        [self cancel];
        if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)])
        {
            [delegate cacheFileFail:self hostPath:hostPath error:error];
        }
        return;
    }
    
    NSDictionary *dict = [(NSHTTPURLResponse*)response allHeaderFields];
    
    if (offsetPos == 0) {
        //如果是分段下载，这个长度可能是分段长度，而不是文件长度
        if ([dict objectForKey:@"Content-Length"]) {
            long long bagSize = [[dict objectForKey:@"Content-Length"] longLongValue];
            // 文件集看图片，图片的大小来自服务器返回，文件集传的是原始图大小，不能用(下面3类下载不分段)
            if (viewType == TYPE_CACHE_THUMBIMAGE_ZIP
                || viewType == TYPE_CACHE_THUMBIMAGE
                || viewType == TYPE_CACHE_SLIDEIMAGE
                || viewType == TYPE_CACHE_VCF_FILE ) {
                fileSize  = fileTotalSize =  bagSize;
            }
            else
            {
                fileSize =  MAX(fileTotalSize,   MAX(fileSize, bagSize));
            }
            
            long long freeSize = [PCUtilityDataManagement getFreeSpace];
            DLogNotice(@"bagSize=%lld,freeSize=%lld",bagSize,freeSize);
            if (bagSize > freeSize)
            {
                [self cancel];
                errorNo = FILE_CACHE_ERROR_LACK_OF_SPACE;
                if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)])
                {
                    [delegate cacheFileFail:self hostPath:hostPath error:NSLocalizedString(@"LackOfSpace", nil)];
                }
                return;
            }
            else if (self.fileCacheObjID)
            {
                PCFileCacheInfo *fileCacheInfo = (PCFileCacheInfo *)[[PCUtilityDataManagement managedObjectContext] existingObjectWithID:self.fileCacheObjID error:nil];
                if (fileCacheInfo)
                {
                    fileCacheInfo.size = [NSNumber numberWithLongLong:fileSize];
                    [PCUtilityDataManagement saveInfos];
                }
            }
        }
    }
    
    if (fileSize ==  0) {
        [self finishCache];
        return;
    }
    
    NSString *lastModified = [dict objectForKey:@"Last-Modified"];
    /*
     if (!lastModified) {
     [self cancel];
     errorNo = FILE_CACHE_ERROR_FILE_NO_FOUND;
     NSString *date = [dict objectForKey:@"Date"];
     NSLog(@"date=%@", date);
     if (delegate) {
     if (!date)
     [delegate cacheFileFail:self hostPath:hostPath error:NSLocalizedString(@"ServerOffline", nil)];
     else
     [delegate cacheFileFail:self hostPath:hostPath error:NSLocalizedString(@"FileNotFound", nil)];
     }
     return;
     }*/
    //�规����缁������������翠�涓�����灏����敞���
    
    //    if (modifyTime && (offsetPos == fileSize) &&  ([modifyTime compare:lastModified] == NSOrderedSame)) {
    ////        NSLog(@"FILE SAME");
    //        [self finishCache];
    //        return;
    //    }
    
    if (progressView && (fileSize > 1)) {
        progressView.progress = offsetPos * progressScale / fileSize;
    }
    
    if (self.fileCacheObjID && (lastModified || modifyGTMTime))
    {
        PCFileCacheInfo *fileCacheInfo = (PCFileCacheInfo *)[[PCUtilityDataManagement managedObjectContext] existingObjectWithID:self.fileCacheObjID error:nil];
        if (fileCacheInfo)
        {
            if (lastModified)
                fileCacheInfo.modifyTime = lastModified;
            
            if (modifyGTMTime)
                fileCacheInfo.modifyGTMTime = [NSNumber numberWithLongLong:modifyGTMTime];
            
            [PCUtilityDataManagement saveInfos];
        }
    }
}

-(void)pcConnection:(NSURLConnection *)cur_connection didReceiveData:(NSData *)incomingData {
    if (isCancel) return;
    
    NSString *nsFileUrl =  [NSString stringWithFormat:@"http://%@/%@", FILE_SERVER_HOST, GET_FILE_SERVER_INFO];
    
    
    //保存data用来获取服务器给的错误信息，但是估计下载
    //文件之类也这么做会消耗cpu和内存，如果返回错误信息的话
    //返回的应该是很小的数据。
    BOOL  bErrorInfoData = NO;
    //判断返回的是 错误信息 还是  文件数据
    
    if (incomingData.length<10240 && data.length<10240)
    {
        [data appendData:incomingData];
        NSString *ret = [[[NSString alloc] initWithData:incomingData encoding:NSUTF8StringEncoding] autorelease];
        if ([ret isKindOfClass:[NSString class]] )
        {
            NSDictionary *dict = [ret JSONValue];
            if ([dict isKindOfClass:[NSDictionary class]])
            {
                int result = [[dict objectForKey:@"result"] intValue];
                if (result !=0) {
                    bErrorInfoData = YES;
                }
            }
        }
        
    }
    
    if ([[[[cur_connection originalRequest] URL] absoluteString] isEqualToString:nsFileUrl] )
    {
        return;
    }
    
    if (incomingData.length && fileHandle && (bErrorInfoData == NO)) {
        [fileHandle writeData:incomingData];
        //        [fileHandle synchronizeFile];
        offsetPos += incomingData.length;
        
        float progress = offsetPos * progressScale / fileTotalSize;
        progress = MIN(progress,0.99);
        if (delegate && [delegate respondsToSelector:@selector(cacheFileProgress:hostPath:)])
        {
            [delegate cacheFileProgress:progress hostPath:hostPath];
        }
        
        if (progressView) {
            progressView.progress = progress;
            //            NSLog(@"%f", progress);
            
        }
    }
}

- (void)pcConnectionDidFinishLoading:(NSURLConnection *)cur_connection {
    if (isCancel)
    {
        [data setLength:0];
        return;
    }
    
    NSString *ret = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    [data setLength:0];
    self.connection = nil;
    
    if ([ret isKindOfClass:[NSString class]] )
    {
        NSDictionary *dict = [ret JSONValue];
        if ([dict isKindOfClass:[NSDictionary class]])
        {
            int result = [[dict objectForKey:@"result"] intValue];
            DLogNotice(@"cache ret : %@",ret);
            
            errorNo = FILE_CACHE_ERROR_SERVER_COMMON;
            
            NSString *errMsg = nil;
            if (result == 98) {
                errMsg = NSLocalizedString(@"ConnetError", nil);
            }
            else if ((result == 1) && ([[dict valueForKey:@"errCode"] intValue] == 1028 || [[dict valueForKey:@"errCode"] intValue] == 1029)){
                [PCLogin setToken:nil];
                [[PCLogin sharedManager]  getAccessToken:self];
                return;
            }
            else if ([dict objectForKey:@"errCode"])
            {
                int errCode = [[dict objectForKey:@"errCode"] intValue];
                if (errCode == PC_Err_FileNotExist)
                    errorNo = FILE_CACHE_ERROR_FILE_NO_FOUND;
                
                NSString *msg = [ErrorHandler messageForError:errCode];
                if (msg)
                    errMsg = msg;
                else
                    errMsg = NSLocalizedString(@"AccessServerError", nil);            }
            else {
                errMsg = ([dict objectForKey:@"message"]?[dict objectForKey:@"message"]:NSLocalizedString(@"AccessServerError", nil));
            }
            NSLog(@"errMsg:%@",errMsg);
            
            if (result == 20)//资源当前不在线:表示盒子已断网,注销或关机
            {
                _resultType = result;//供FileDownloadManager使用
                if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)])
                {
                    [delegate cacheFileFail:self hostPath:hostPath error:NSLocalizedString(@"DeviceOfflien", nil)];
                }
                return;
            }
            else
            {
                if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)])
                {
                    [delegate cacheFileFail:self hostPath:hostPath error:errMsg];
                }
                return;
            }
        }
    }
    
    if (viewType == TYPE_CACHE_THUMBIMAGE_ZIP
        || viewType == TYPE_CACHE_THUMBIMAGE
        || viewType == TYPE_CACHE_SLIDEIMAGE) {
        [self finishCache];
        return;
    }
    //fix bug 55252	【Cherry-IOS】【Box1.0/1.5】【Hub1.5】使用kt-qa的WiFi网络下载upnp穿透的盒子的内容始终提示‘响应超时’
    if (fileTotalSize > 0 && offsetPos == fileTotalSize) {
        [self finishCache];
        return;
    }
    //
    //如果在下载过程中，继续下载
    //如果有fileDownLoadUrl，就直接用这个地址去下载，不走下面connectURL。
    
    [self  continueDownLoad];
}

- (void)pcConnection:(NSURLConnection *)_connection didFailWithError:(NSError *)error {
    [data setLength:0];
    if (isCancel) return;
    //    if (isReLogin) return;
    [self cancel];
    
    //单独设置一个isTimeout属性，避免设置errorNo为kCFURLErrorTimedOut后影响FileDownloadManager对errorNo的判断
    _isTimeout = error.code == kCFURLErrorTimedOut;
    errorNo = FILE_CACHE_ERROR_CONNECTION_ERROR;
    
    if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)])
    {
        @try {
            [delegate cacheFileFail:self hostPath:hostPath error:NSLocalizedString(@"ConnetError", nil)];
        }
        @catch (NSException *exception) {
            DLogError(@"FileCache didFailWithError exception=%@",exception);
        }
    }
    self.connection = nil;
}

- (void) networkNoReachableFail:(NSString*)error {
    if (isCancel) return;
    
    if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)])
    {
        [delegate cacheFileFail:self hostPath:hostPath error:error];
    }
    self.connection = nil;
}


#pragma mark - URLConnectionDelegate method
- (void)connection:(NSURLConnection *)cur_connection didReceiveResponse:(NSURLResponse *)response{
    NSString *nsFileUrl =  [NSString stringWithFormat:@"http://%@/%@", FILE_SERVER_HOST, GET_FILE_SERVER_INFO];
    if (![[[[cur_connection originalRequest] URL] absoluteString] isEqualToString:nsFileUrl] )
    {
        [self pcConnection:cur_connection didReceiveResponse:response];
        return;
    }
    
    [data setLength:0];
    if (isCancel)
        return;
    
    NSInteger rc = [(NSHTTPURLResponse*)response statusCode];
    NSString *error = [PCUtility checkResponseStautsCode:rc];
    if (error) {
        [self cancel];
        if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)])
        {
            [delegate cacheFileFail:self hostPath:hostPath error:error];
        }
    }
}

- (void)connection:(NSURLConnection *)cur_connection didReceiveData:(NSData *)cur_data{
    [self pcConnection:cur_connection didReceiveData:cur_data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)cur_connection{
    if (isCancel)
    {
        [data setLength:0];
        return;
    }
    
    NSString *nsFileUrl =  [NSString stringWithFormat:@"http://%@/%@", FILE_SERVER_HOST, GET_FILE_SERVER_INFO];
    if (![[[[cur_connection originalRequest] URL] absoluteString] isEqualToString:nsFileUrl] )
    {
        [self pcConnectionDidFinishLoading:cur_connection];
        return;
    }
    
    NSString *ret = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    [data setLength:0];
    if ([ret isKindOfClass:[NSString class]] )
    {
        NSDictionary *dict = [ret JSONValue];
        if ([dict isKindOfClass:[NSDictionary class]])
        {
            id result = [dict objectForKey:@"result"];
            if ( result && ([result intValue]  == 0)) {
                NSLog(@"上传下载地址  的dic : %@",dict);
                NSString *newDownLoadUrl = [NSString stringWithFormat:@"%@/%@.%@/%@/%@",
                                            [dict objectForKey:@"fileDownloadUrl"],
                                            [PCUtilityStringOperate encodeToPercentEscapeString:([currentDeviceID length] > 0 ? currentDeviceID : [PCSettings sharedSettings].currentDeviceIdentifier)],
                                            [PCSettings sharedSettings].userId,
                                            [dict objectForKey:@"reqKey"],
                                            self.url];
                if ([PCSettings sharedSettings].bSessionSupported)
                {
                    newDownLoadUrl = [newDownLoadUrl stringByAppendingFormat:@"&token_id=%@&client_id=%@", [PCLogin getToken], [[UIDevice currentDevice] uniqueDeviceIdentifier]];
                }
                self.fileDownLoadUrl = [NSURL URLWithString:newDownLoadUrl];
                [self connectFileDownLoadWithURL:self.fileDownLoadUrl];
                return;
            }
            else
            {
                NSString *errMsg = ([dict objectForKey:@"message"]?[dict objectForKey:@"message"]:NSLocalizedString(@"ServerError", nil));
                NSLog(@"errMsg:%@",errMsg);
                if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)])
                {
                    [delegate cacheFileFail:self hostPath:hostPath error:NSLocalizedString(errMsg, nil)];
                }
                return;
            }
        }
        else
        {
            if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)])
            {
                [delegate cacheFileFail:self hostPath:hostPath error:NSLocalizedString(@"ServerError", nil)];
            }
        }
    }
    else
    {
        if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)])
        {
            [delegate cacheFileFail:self hostPath:hostPath error:NSLocalizedString(@"ServerError", nil)];
        }
    }
}

- (void)connection:(NSURLConnection *)cur_connection didFailWithError:(NSError *)error{
    
    [self pcConnection:cur_connection didFailWithError:error];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == [alertView firstOtherButtonIndex]) {
        if (alertView.tag == DELETE_CACHE_ALERT_TAG) {
            [self deleteCacheObjectsWithLimit:K_DELETE_CACHE_SIZE];
        }
    }
    else if(alertView.tag == LARGE_FILE_ALERT_TAG)
    {
        errorNo = FILE_CACHE_FILE_MORE_THAN_2M;
        if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)]) [delegate cacheFileFail:self hostPath:hostPath error:nil];
        self.connection = nil;
    }
}

- (NSString*)refreshURLToken:(NSString*)target
{
    NSRange startRange = [target rangeOfString:@"token_id="];
    NSRange endRange = [target rangeOfString:@"&client_id="];
    if (startRange.length >0) {
        int startIndex = startRange.location+startRange.length;
        int endIndex  = endRange.location;
        if (endIndex > startIndex) {
            NSRange tokenRange =  NSMakeRange(startIndex,endIndex-startIndex);
            NSString  *tempURL = [target  stringByReplacingCharactersInRange:tokenRange withString:[PCLogin getToken]];
            NSLog(@"new url  %@",tempURL);
            return tempURL;
        }
    }
    return  nil;
}

- (void)refreshURLToken
{
    NSString * tempFileDownLoadUrl = [self refreshURLToken:[self.fileDownLoadUrl  absoluteString] ];
    
    if (tempFileDownLoadUrl) {
        self.fileDownLoadUrl = [NSURL URLWithString:tempFileDownLoadUrl];
    }
}

- (void)gotAccessToken:(NSDictionary*)result
{
    NSString *newToken = [result objectForKey:@"token"];
    [PCLogin  setToken:newToken];
    [self refreshURLToken];
    [self continueDownLoad];
}


#pragma mark - reGetToken
- (void)getAccessTokenFailedWithError:(NSError*)error2
{
    // 可能导致重复的错误提示
    // [ErrorHandler showErrorAlert:error2];
    DLogWarn(@"connection error: %d, %@", error2.code, error2.localizedDescription);
    
    if (delegate && [delegate respondsToSelector:@selector(cacheFileFail:hostPath:error:)])
    {
        [delegate cacheFileFail:self hostPath:hostPath error:error2.localizedDescription];
    }
}

- (void)requestDidGotAccessToken:(KTURLRequest *)request
{
    if (isCancel)
        return;
    
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

@end
