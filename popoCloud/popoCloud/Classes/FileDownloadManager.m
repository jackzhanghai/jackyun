//
//  FileDownloadManager.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-30.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "FileDownloadManager.h"
#import "FileCache.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityDataManagement.h"
#import "PCUtilityUiOperate.h"
#import "PCLogin.h"
#import "FileDownloadManagerViewController.h"
#import "NetPenetrate.h"
#import "PCAppDelegate.h"
#import "LoginViewController.h"

@implementation FileDownloadManager

@synthesize tableProgressView;
@synthesize tableFileCache;
@synthesize tableDownloading;
@synthesize tableDownloaded;
@synthesize tableDownloadingStoped;

- (id)init
{
    self = [super init];
    if (self) {
        tableProgressView = [[NSMutableDictionary alloc] init];
        tableFileCache = [[NSMutableDictionary alloc] init];
        
        tableDownloaded = nil;
        tableDownloading = nil;
        tableDownloadingStoped = nil;
    }
    
    return self;
}

- (void)dealloc
{
    if (tableFileCache)
    {
        for (FileCache *cacheInfo in [tableFileCache  allValues ] ) {
            [cacheInfo cancel];
            cacheInfo.delegate = nil;
            //[cacheInfo release];
        }
        [tableFileCache release];
    }
    
    if (tableProgressView) [tableProgressView release];
    if (tableDownloaded) [tableDownloaded release];
    if (tableDownloading) [tableDownloading release];
    if (tableDownloadingStoped) {
        [tableDownloadingStoped release];
    }
    
    [super dealloc];
}

#pragma mark - private methods

- (void) fetchDownloadedInfoObjects {
    if (tableDownloaded) [tableDownloaded release];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"recordTime" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(user == %@)", [[PCSettings sharedSettings] userId]];
    
    tableDownloaded = [[PCUtilityDataManagement fetchObjects:@"FileDownloadedInfo"
                                             sortDescriptors:@[sort]
                                                   predicate:predicate
                                                  fetchLimit:0
                                                   cacheName:@"Root"] retain];
    //    NSLog(@"%@", tableDownloaded);
}

- (void) fetchDownloadingInfoObjects {
    if (tableDownloading) [tableDownloading release];
    tableDownloading = [[self fetchObjects:@"FileDownloadingInfo" withState:0] retain];
    //    NSLog(@"%@", tableDownloading);
}

- (void) fetchDownloadingStopedInfoObjects {
    if (tableDownloadingStoped) [tableDownloadingStoped release];
    tableDownloadingStoped = [[self fetchObjects:@"FileDownloadingInfo" withState:2] retain];
    //    NSLog(@"%@", tableDownloading);
}

- (void) addTableItem:(PCFileDownloadingInfo*)info {
    PCProgressView *progressView = [[[PCProgressView alloc] init] autorelease];
    if (IS_IPAD) {
        [progressView setFrame:CGRectMake(62, 40, 650, 12)];
    }
    else
    {
        [progressView setFrame:CGRectMake(62, 40, 250, 12)];
    }
    
    [progressView initProgressLabel];
    progressView.progress = [info.progress floatValue];
    NSLog(@"%f", progressView.progress);
    //    NSString *name = [info.hostPath lastPathComponent];
    
    FileCache* fileCache = [[[FileCache alloc] init] autorelease];
    fileCache.currentDeviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
    [fileCache setProgressView:progressView progressScale:1.0];
    
    [tableProgressView setObject:progressView forKey:info.hostPath];
    [tableFileCache setObject:fileCache forKey:info.hostPath];
    
    //    NSLog(info.localPath);
    if ([info.status shortValue] == STATUS_RUN) {
        NSString *localPath = [fileCache cacheFile:info.hostPath viewType:TYPE_DOWNLOAD_FILE viewController:self fileSize:[info.size longLongValue] modifyGTMTime:[info.modifyGTMTime longLongValue] showAlert:YES];
        if (localPath) {
            info.localPath = localPath;
        }
        else if (fileCache.errorNo != FILE_CACHE_ERROR_LACK_OF_SPACE) {
            info.status = [NSNumber numberWithShort:STATUS_PAUSE];
        }
    }
}

- (void)restoreInfo
{
    NSUInteger downloadingLength = tableDownloading.count;
    NSUInteger downloadingStopedLength = tableDownloadingStoped.count;
    
    for (int i = 0; i < downloadingLength; i++) {
        PCFileDownloadingInfo *info = [tableDownloading objectAtIndex:i];
        if ([tableFileCache objectForKey:info.hostPath] == nil) {
            PCProgressView *progressView = [[[PCProgressView alloc] init] autorelease];
            if (IS_IPAD) {
                [progressView setFrame:CGRectMake(62, 40, 650, 12)];
            }
            else
            {
                [progressView setFrame:CGRectMake(62, 40, 250, 12)];
            }
            
            [progressView initProgressLabel];
            progressView.progress = [info.progress floatValue];
            NSLog(@"%f", progressView.progress);
            //    NSString *name = [info.hostPath lastPathComponent];
            
            FileCache* fileCache = [[[FileCache alloc] init] autorelease];
            [fileCache setProgressView:progressView progressScale:1.0];
            
            [tableProgressView setObject:progressView forKey:info.hostPath];
            [tableFileCache setObject:fileCache forKey:info.hostPath];
        }
    }
    
    for (int i = 0; i < downloadingStopedLength; i++) {
        PCFileDownloadingInfo *info = [tableDownloadingStoped objectAtIndex:i];
        if ([tableFileCache objectForKey:info.hostPath] == nil) {
            PCProgressView *progressView = [[[PCProgressView alloc] init] autorelease];
            if (IS_IPAD) {
                [progressView setFrame:CGRectMake(62, 40, 650, 12)];
            }
            else
            {
                [progressView setFrame:CGRectMake(62, 40, 250, 12)];
            }
            
            [progressView initProgressLabel];
            progressView.progress = [info.progress floatValue];
            NSLog(@"%f", progressView.progress);
            //    NSString *name = [info.hostPath lastPathComponent];
            
            FileCache* fileCache = [[[FileCache alloc] init] autorelease];
            [fileCache setProgressView:progressView progressScale:1.0];
            
            [tableProgressView setObject:progressView forKey:info.hostPath];
            [tableFileCache setObject:fileCache forKey:info.hostPath];
        }
    }
}

//-------------------------------------------------------------------------------

- (void) deleteDownloadingInfo:(PCFileDownloadingInfo*)downloadingInfo {
    NSString *path = downloadingInfo.localPath;
    if (path) {
        [PCUtilityFileOperate deleteFile:path];
    }
    
    if (downloadingInfo.hostPath != nil)
    {
        [tableProgressView removeObjectForKey:downloadingInfo.hostPath];
        [(FileCache*)[tableFileCache objectForKey:downloadingInfo.hostPath] cancel];
        [tableFileCache removeObjectForKey:downloadingInfo.hostPath];
        
    }
    
    [FileCache deleteDownloadFile:downloadingInfo.localPath];
    [[PCUtilityDataManagement managedObjectContext] deleteObject:downloadingInfo];
}

-(void) deleteDownloadedInfo:(PCFileDownloadedInfo*)downloadedInfo {
    if (downloadedInfo) {
        NSString *path = downloadedInfo.localPath;
        if (path)
        {
            if (![path hasPrefix:NSHomeDirectory()]) {
                path = [NSHomeDirectory() stringByAppendingPathComponent:path];
            }
            [PCUtilityFileOperate deleteFile:path];
        }
        [FileCache deleteDownloadFile:downloadedInfo.localPath];
        [[PCUtilityDataManagement managedObjectContext] deleteObject:downloadedInfo];
    }
}

//暂停下载后再次点击继续下载时，或弹出提示框用户确认重新下载时调用
-(void) downloadingRun:(PCFileDownloadingInfo*)info {
    if (info  && ([info.status shortValue] == STATUS_PAUSE))
    {
        //如果在后台。大于2m且非wifi
        if (![UIApplication sharedApplication].applicationState == UIApplicationStateActive)
        {
            if (![PCUtility isWifi] && [info.size integerValue] >= SIZE_2M )
            {
                [self downloadingStop:info];
                return;
            }
        }
        
        FileCache * cache = [tableFileCache objectForKey:info.hostPath];
        cache.currentDeviceID = info.deviceName;
        NSString *localPath = [cache cacheFile:info.hostPath viewType:TYPE_DOWNLOAD_FILE viewController:self fileSize:[info.size longLongValue] modifyGTMTime:[info.modifyGTMTime longLongValue] showAlert:YES];
        if (localPath) {
            info.localPath = localPath;
            info.status = [NSNumber numberWithShort:STATUS_RUN];
            [PCUtilityDataManagement saveInfos];
        }
    }
}

- (void)sendRefreshTableNotification:(NSString *)key userInfo:(NSDictionary *)info
{
    //    RefreshTableView
    [[NSNotificationCenter defaultCenter] postNotificationName:key object:nil userInfo:info];
}

#pragma mark - public methods

- (id)fetchObject:(NSString *)entityName
         hostPath:(NSString *)hostPath
       modifyTime:(NSString *)modifyTime
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"hostPath" ascending:YES];
    NSPredicate *predicate = nil;
    
    if (modifyTime)
    {
        if ([entityName isEqualToString:@"FileDownloadedInfo"])
        {
            predicate = [NSPredicate predicateWithFormat:@"(hostPath == %@ and user == %@ and modifyTime == %@)", hostPath, [[PCSettings sharedSettings] userId], modifyTime];
        }
        else
        {
            predicate = [NSPredicate predicateWithFormat:@"(hostPath == %@ and user == %@ and modifyGTMTime == %@)", hostPath, [[PCSettings sharedSettings] userId], modifyTime];
        }
    }
    else
    {
        predicate = [NSPredicate predicateWithFormat:@"(hostPath == %@ and user == %@)", hostPath, [[PCSettings sharedSettings] userId]];
    }
    
    NSArray *fetchArray = [PCUtilityDataManagement fetchObjects:entityName
                                                sortDescriptors:@[sort]
                                                      predicate:predicate
                                                     fetchLimit:0
                                                      cacheName:@"Root"];
    
    return fetchArray.count ? fetchArray[0] : nil;
}

//文件集里长按某个文件弹出的actionsheet，点击下载文件时调用该函数
- (BOOL)addItem:(NSString *)hostPath fileSize:(long long)size modifyGTMTime:(long long)modifyGTMTime
{
    if (!hostPath)
        return NO;
    
    if (size == 0) {
        [PCUtilityUiOperate showOKAlert:NSLocalizedString(@"DownloadFileSizeZero", nil) delegate:nil];
        return NO;
    }
    
    PCFileDownloadedInfo *downloadedInfo = [self fetchObject:@"FileDownloadedInfo"
                                                    hostPath:hostPath
                                                  modifyTime:nil];
    if (downloadedInfo)
    {
        //xy add 有记录 表明曾经下载过同名文件 现在下载的是更改后的文件。弹出对话框询问是否重新下载
        //        if ([ModalAlert confirm:@"下载过同名文件,继续下载的话将会覆盖原有文件,是否继续?"])
        //        {
        //选覆盖的话，删除以前的
        [self deleteDownloadedInfo:downloadedInfo];
        [PCUtilityDataManagement saveInfos];
        [self fetchDownloadedInfoObjects];
        [self sendRefreshTableNotification:@"RefreshTableView" userInfo:nil];
        //        }
        //        else
        //        {
        //             return NO;
        //        }
    }
    
    PCFileDownloadingInfo *info = [self fetchObject:@"FileDownloadingInfo"
                                           hostPath:hostPath
                                         modifyTime:nil];
    if (info) {
        return NO;
    }
    else {
        info = (PCFileDownloadingInfo*)[NSEntityDescription insertNewObjectForEntityForName:@"FileDownloadingInfo" inManagedObjectContext:[PCUtilityDataManagement managedObjectContext]];
        info.hostPath = hostPath;
        info.progress = [NSNumber numberWithFloat:0.0];
        info.recordTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
        info.user = [[PCSettings sharedSettings] userId];
    }
    info.size = [NSNumber numberWithLongLong:size];
    info.modifyGTMTime = [NSNumber numberWithLongLong:modifyGTMTime];
    info.status = [NSNumber numberWithShort:STATUS_RUN];
    
    //xy add  切换盒子后正在下载的文件不能继续下载
    //保存能成功下载的huburl和盒子名称
    //info.downhostPath = [NSString stringWithFormat:@"http://%@%@", [NetPenetrate sharedInstance].defaultHubUrl,[NSString stringWithFormat:@"DownloadFile?filePath=%@", [PCUtility encodeToPercentEscapeString:info.hostPath]]] ;
    info.deviceName = [[PCSettings sharedSettings] currentDeviceIdentifier];
    int downLoadingNum = 0;//record current downloading number
    for(PCFileDownloadingInfo *pcFDI in tableDownloading) {
        if(0 == [pcFDI.status intValue]) {
            downLoadingNum++;
            if(downLoadingNum >= MAX_DOWNLOADING) {
                info.status = [NSNumber numberWithShort:STATUS_PAUSE];
            }
        }
    }
    
    [PCUtilityDataManagement saveInfos];
    
    [self addTableItem:info];
    [self fetchDownloadedInfoObjects];
    [self fetchDownloadingInfoObjects];
    
    [self sendRefreshTableNotification:@"RefreshTableView" userInfo:nil];
    
    return YES;
}

- (void)deleteDownloadingItem:(NSInteger)index
{
    PCFileDownloadingInfo *downloadingInfo = [tableDownloading objectAtIndex:index];
    if (downloadingInfo) {
        [self deleteDownloadingInfo:downloadingInfo];
    }
    
    [PCUtilityDataManagement saveInfos];
    [self fetchDownloadingInfoObjects];
    [self sendRefreshTableNotification:@"RefreshTableView" userInfo:nil];
    
}

- (void)deleteDownloadingStopedItem:(NSInteger)index
{
    PCFileDownloadingInfo *downloadingInfo = [tableDownloadingStoped objectAtIndex:index];
    if (downloadingInfo)
    {
        [self deleteDownloadingInfo:downloadingInfo];
    }
    
    [PCUtilityDataManagement saveInfos];
    [self fetchDownloadingStopedInfoObjects];
    [self sendRefreshTableNotification:@"RefreshTableView" userInfo:nil];
    
}

- (void)deleteFileWithPath:(NSString*)filePath
{
    for (PCFileDownloadedInfo *downloadedInfo in tableDownloaded) {
        if ([downloadedInfo.hostPath isEqualToString:filePath]) {
            [self deleteDownloadedInfo:downloadedInfo];
            [PCUtilityDataManagement saveInfos];
            [self fetchDownloadedInfoObjects];
            [self sendRefreshTableNotification:@"RefreshTableView" userInfo:nil];
            break;
        }
    }
}

- (void)deleteDownloadedItem:(NSInteger)index
{
    PCFileDownloadedInfo *downloadedInfo = [tableDownloaded objectAtIndex:index];
    
    [self deleteDownloadedInfo:downloadedInfo];
    [PCUtilityDataManagement saveInfos];
    [self fetchDownloadedInfoObjects];
    [self sendRefreshTableNotification:@"RefreshTableView" userInfo:nil];
    
}

- (void)downloadingPause:(PCFileDownloadingInfo*)info
{
    if (info && ([info.status shortValue] == STATUS_RUN)) {
        [(FileCache*)[tableFileCache objectForKey:info.hostPath] cancel];
        info.status = [NSNumber numberWithShort:STATUS_PAUSE];
        [PCUtilityDataManagement saveInfos];
    }
}

- (void)downloadingStop:(PCFileDownloadingInfo*)info
{
    if (info ) {
        [(FileCache*)[tableFileCache objectForKey:info.hostPath] cancel];
        if (info.status == [NSNumber numberWithShort:STATUS_RUN]) {
            NSUInteger length = tableDownloading.count;
            for (int i = 0; i < length; i++) {
                PCFileDownloadingInfo *info = [tableDownloading objectAtIndex:i];
                if (info.status.shortValue == STATUS_PAUSE) {
                    [self itemChangeStatus:i];
                    break;
                }
            }
            
        }
        
        info.status = [NSNumber numberWithShort:STATUS_STOP];
        [PCUtilityDataManagement saveInfos];
        
        [self fetchDownloadedInfoObjects];
        [self fetchDownloadingInfoObjects];
        [self fetchDownloadingStopedInfoObjects];
        [self sendRefreshTableNotification:@"RefreshTableView" userInfo:nil];
        
    }
}

- (void)downloadingStopedToRun:(PCFileDownloadingInfo *)info
{
    if (info  && ([info.status shortValue] == STATUS_STOP)) {
        //        NSString *localPath = [[tableFileCache objectForKey:info.hostPath] cacheFile:info.hostPath viewType:TYPE_DOWNLOAD_FILE viewController:self fileSize:[info.size floatValue] modifyGTMTime:[info.modifyGTMTime longLongValue] showAlert:YES];
        //        if (localPath) {
        if (1) {
            // info.localPath = localPath;
            int downLoadingNum = 0;//record current downloading number
            info.status = [NSNumber numberWithShort:STATUS_RUN];
            for(PCFileDownloadingInfo *pcFDI in tableDownloading) {
                if(0 == [pcFDI.status intValue]) {
                    downLoadingNum++;
                    if(MAX_DOWNLOADING <= downLoadingNum) {
                        info.status = [NSNumber numberWithShort:STATUS_PAUSE];
                    }
                }
            }
            
            if (info.status == [NSNumber numberWithShort:STATUS_RUN]) {
                FileCache * cache = [tableFileCache objectForKey:info.hostPath];
                if (cache == nil) {
                    return;
                }
                cache.currentDeviceID = info.deviceName;
                NSString *localPath = [cache cacheFile:info.hostPath viewType:TYPE_DOWNLOAD_FILE viewController:self fileSize:[info.size longLongValue] modifyGTMTime:[info.modifyGTMTime longLongValue] showAlert:YES];
                if (localPath) {
                    info.localPath = localPath;
                }
                
            }
            
            [self fetchDownloadedInfoObjects];
            [self fetchDownloadingInfoObjects];
            [self fetchDownloadingStopedInfoObjects];
            [PCUtilityDataManagement saveInfos];
            
            [self sendRefreshTableNotification:@"RefreshTableView" userInfo:nil];
        }
    }
}

- (void)itemChangeStatus:(NSInteger)index
{
    PCFileDownloadingInfo *info = [tableDownloading objectAtIndex:index];
    
    if (info) {
        if ([info.status shortValue] == STATUS_RUN) {
            [self downloadingPause:info];
        }
        else {
            [self downloadingRun:info];
        }
        
        [self sendRefreshTableNotification:@"RefreshTableView" userInfo:nil];
    }
}

- (NSArray *)fetchObjects:(NSString *)entityName withState:(int)stateCode
{
    NSString *userName = [[PCSettings sharedSettings] userId];
    NSPredicate *predicate = stateCode == 0 ?
    [NSPredicate predicateWithFormat:@"(status < 2 and user == %@)", userName] :
    [NSPredicate predicateWithFormat:@"(status == %d and user == %@)", stateCode, userName];
    
    NSSortDescriptor *sort = stateCode == 0 ?[NSSortDescriptor sortDescriptorWithKey:@"status" ascending:YES]:[NSSortDescriptor sortDescriptorWithKey:@"recordTime" ascending:YES];
    
    return [PCUtilityDataManagement fetchObjects:entityName
                                 sortDescriptors:@[sort]
                                       predicate:predicate
                                      fetchLimit:0
                                       cacheName:@"Root"];
}
/*
 - (void)saveInfos
 {
 NSError *err;
 if (![[PCUtility managedObjectContext] save:&err])
 NSLog(@"Error %@", [err localizedDescription]);
 }*/

- (void)backgroundDownload
{
    //切到后台后。遍历正在下载的数据。如果当前网络不是wifi并且文件大于2m。为了避免弹出提示框。直接将该下载任务暂停。其他任务继续下载
    for (int i=0;i < [[PCUtilityFileOperate downloadManager].tableDownloading count];i++)
    {
        PCFileDownloadingInfo * info = [[PCUtilityFileOperate downloadManager].tableDownloading objectAtIndex:i];
        if (![PCUtility isWifi] && [info.size integerValue] >= SIZE_2M )
        {
            [(FileCache*)[[PCUtilityFileOperate downloadManager].tableFileCache objectForKey:info.hostPath] cancel];
            info.status = [NSNumber numberWithShort:STATUS_STOP];
        }
    }
    [PCUtilityDataManagement saveInfos];
    [self reloadData];
    
}

//在DevicesViewController里登陆成功以后会调用该函数
- (void)reloadData
{
    [self fetchDownloadingInfoObjects];
    
    for (PCFileDownloadingInfo *info in tableDownloading)
    {
        if (info.status.shortValue != STATUS_STOP)
        {
            info.status = [NSNumber numberWithShort:STATUS_STOP];
        }
    }
    [PCUtilityDataManagement saveInfos];
    
    [self fetchDownloadedInfoObjects];
    [self fetchDownloadingInfoObjects];
    [self fetchDownloadingStopedInfoObjects];
    
    [self restoreInfo];
    [self sendRefreshTableNotification:@"RefreshTableView" userInfo:nil];
    
//    //遍历保存正在下载对象的数据库 有状态为run的继续下载
//    NSUInteger length = MIN(tableDownloading.count,MAX_DOWNLOADING);
//    for (int i = 0; i < length; i++)
//    {
//        PCFileDownloadingInfo *info = [tableDownloading objectAtIndex:i];
//        if (info.status.shortValue != STATUS_STOP)
//        {
////            [self performSelector:@selector(showAlert) withObject:nil afterDelay:0.1];
//            FileCache * cache = [tableFileCache objectForKey:info.hostPath];
//            cache.currentDeviceID = info.deviceName;
//            NSString *localPath = [cache cacheFile:info.hostPath viewType:TYPE_DOWNLOAD_FILE viewController:self fileSize:[info.size longLongValue] modifyGTMTime:[info.modifyGTMTime longLongValue] showAlert:YES];
//            
//            if (localPath)
//            {
//                info.localPath = localPath;
//                info.status = [NSNumber numberWithShort:STATUS_RUN];
//                [PCUtilityDataManagement saveInfos];
//            }
//            
//            [self sendRefreshTableNotification:@"RefreshTableView" userInfo:nil];
//            break;
//        }
//    }
}

- (DownloadStatus)getFileStatus:(NSString *)hostPath andModifyTime:(NSString *)modifyTime
{
    PCFileDownloadedInfo *downloadedInfo = [self fetchObject:@"FileDownloadedInfo"
                                                    hostPath:hostPath modifyTime:nil];
    if (downloadedInfo) {
        return kStatusDownloaded;
    }
    
    PCFileDownloadingInfo *downloadingInfo = [self fetchObject:@"FileDownloadingInfo"
                                                      hostPath:hostPath modifyTime:modifyTime];
    if (downloadingInfo) {
        return downloadingInfo.status.shortValue + 1;
    }
    
    return kStatusNoDownload;
}

- (void)deleteDownloadItem:(NSString *)hostPath fileStatus:(DownloadStatus)status
{
    //    NSString *localPath = [FileCache getRelativePath:hostPath
    //                                            withType:TYPE_DOWNLOAD_FILE
    //                                           andDevice:[[PCSettings sharedSettings] currentDeviceIdentifier]];
    NSArray *tempArray = nil;
    
    if (status == kStatusDownloading||status == kStatusDownloadPause)
        tempArray = tableDownloading;
    else if (status == kStatusDownloaded)
        tempArray = tableDownloaded;
    else
        tempArray = tableDownloadingStoped;
    
    __block NSUInteger index = NSNotFound;
    [tempArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         if ([(NSString *)[obj valueForKey:@"localPath"] isEqualToString:hostPath]) {
             index = idx;
             *stop = YES;
         }
         if ([(NSString *)[obj valueForKey:@"hostPath"] isEqualToString:hostPath]) {
             index = idx;
             *stop = YES;
         }
         
     }];
    
    
    DLogNotice(@"deleteDownloadItem index=%d",index);
    if (index != NSNotFound) {
        if (status == kStatusDownloading||status == kStatusDownloadPause)
        {
            [self deleteDownloadingItem:index];
            //删除正在下载的文件。后面排队的会下载
            NSUInteger length = [PCUtilityFileOperate downloadManager].tableDownloading.count;
            for (int i = 0; i < length; i++) {
                PCFileDownloadingInfo *info = [[PCUtilityFileOperate downloadManager].tableDownloading objectAtIndex:i];
                if (info.status.shortValue == STATUS_PAUSE&& i==0) {
                    [[PCUtilityFileOperate downloadManager] itemChangeStatus:i];
                }
            }
            
        }
        else if (status == kStatusDownloaded)
            [self deleteDownloadedItem:index];
        else
            [self deleteDownloadingStopedItem:index];
    }
    else
    {
        [self sendRefreshTableNotification:@"RefreshTableView" userInfo:nil];
    }
}

- (void)deleteDownloadItem
{
    [self fetchDownloadedInfoObjects];
    [self fetchDownloadingInfoObjects];
    [self fetchDownloadingStopedInfoObjects];
    
    for (int i = 0; i < [tableDownloading count]; i++)
    {
        PCFileDownloadingInfo *downloadingInfo = [tableDownloading objectAtIndex:i];
        if (downloadingInfo)
        {
            [self deleteDownloadingInfo:downloadingInfo];
        }
        [PCUtilityDataManagement saveInfos];
    }
    
    for (int i = 0; i< [tableDownloadingStoped count]; i++) {
        //        [self deleteDownloadingStopedItem:i];直接调这个函数数组会被重新获取。导致少删
        PCFileDownloadingInfo *downloadingInfo = [tableDownloadingStoped objectAtIndex:i];
        if (downloadingInfo)
        {
            [self deleteDownloadingInfo:downloadingInfo];
        }
        [PCUtilityDataManagement saveInfos];
    }
    
    for  (int i = 0; i< [tableDownloaded count]; i++) {
        PCFileDownloadedInfo *downloadedInfo = [tableDownloaded objectAtIndex:i];
        
        [self deleteDownloadedInfo:downloadedInfo];
        [PCUtilityDataManagement saveInfos];
    }
    
}

- (void)finishItem:(NSString *)hostPath localPath:(NSString *)localPath modifyTime:(NSString *)modifyTime fileSize:(long long)size
{
    PCFileDownloadedInfo *downloadedInfo = [self fetchObject:@"FileDownloadedInfo"
                                                    hostPath:hostPath
                                                  modifyTime:nil];
    if (!downloadedInfo) {
        downloadedInfo = (PCFileDownloadedInfo*)[NSEntityDescription insertNewObjectForEntityForName:@"FileDownloadedInfo" inManagedObjectContext:[PCUtilityDataManagement managedObjectContext]];
    }
    
    downloadedInfo.hostPath = hostPath;
    if ([localPath hasPrefix:NSHomeDirectory()]) {
        localPath = [localPath substringFromIndex:[NSHomeDirectory() length]];
    }
    downloadedInfo.localPath = localPath;
    downloadedInfo.modifyTime = modifyTime;
    downloadedInfo.user = [[PCSettings sharedSettings] userId];
    downloadedInfo.recordTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    downloadedInfo.size = [NSNumber numberWithLongLong:size];
    //    NSLog(@"recordTime: %ld", [downloadedInfo.recordTime longValue]);
    
    PCFileDownloadingInfo *downloadingInfo = [self fetchObject:@"FileDownloadingInfo"
                                                      hostPath:hostPath
                                                    modifyTime:nil];
    if (downloadingInfo) {
        [[tableProgressView objectForKey:downloadingInfo.hostPath] removeFromSuperview];
        [tableProgressView removeObjectForKey:downloadingInfo.hostPath];
        [tableFileCache removeObjectForKey:downloadingInfo.hostPath];
        [[PCUtilityDataManagement managedObjectContext] deleteObject:downloadingInfo];
    }
    
    [PCUtilityDataManagement saveInfos];
    [self fetchDownloadedInfoObjects];
    [self fetchDownloadingInfoObjects];
    
    NSUInteger length = tableDownloading.count;
    BOOL bDownLoading =  [self checkDownLoadingStatus];
    //当前没有下载文件，则开始下载。（收藏那边通过把cache文件移到收藏目录也会调用这个方法）
    if (!bDownLoading) {
        for (int i = 0; i < length; i++) {
            PCFileDownloadingInfo *info = [tableDownloading objectAtIndex:i];
            if (info.status.shortValue == STATUS_PAUSE) {
                [self itemChangeStatus:i];
                [self sendRefreshTableNotification:@"RefreshTableView" userInfo:@{@"success": @(YES)}];
                return;
            }
        }
    }
    NSLog(@"下载结束");
    [self sendRefreshTableNotification:@"RefreshTableView" userInfo:@{@"success": @(YES)}];
}

#pragma mark - PCFileCacheDelegate methods

- (void) cacheFileProgress:(float)progress hostPath:(NSString *)hostPath {
    PCFileDownloadingInfo *downloadingInfo = [self fetchObject:@"FileDownloadingInfo"
                                                      hostPath:hostPath
                                                    modifyTime:nil];
    NSNumber *proValue = @(progress);
    if (downloadingInfo) {
        downloadingInfo.progress = proValue;
    }
    [self sendRefreshTableNotification:@"RefreshProgress" userInfo:@{@"progress": proValue}];
    //[self saveInfos];
}

- (void) cacheFileFinish:(FileCache*)fileCache {
    
    PCFileDownloadingInfo *downloadingInfo = [self fetchObject:@"FileDownloadingInfo"
                                                      hostPath:fileCache.hostPath
                                                    modifyTime:nil];
    if (downloadingInfo)
    {
        //NSLog(@"fileCache.fileSize = %f, [downloadingInfo.size floatValue] = %f", fileCache.fileSize, [downloadingInfo.size floatValue]);
        //NSLog(@"[downloadingInfo.progress integerValue] = %f", [downloadingInfo.progress floatValue]);
        if ( [downloadingInfo.progress integerValue] < 1)
        {
            fileCache.errorNo = FILE_CACHE_ERROR_FILE_REPLACE;
            [self cacheFileFail:fileCache hostPath:fileCache.hostPath error:@"文件已经被替换,请去文件集重新下载。"];
            return;
        }
        
        
    }
    
    if (fileCache.viewType == TYPE_DOWNLOAD_FILE)
    {
        [PCUtilityUiOperate showHasCollectTip:fileCache.hostPath.lastPathComponent];
    }
    
    NSString *modifyTime = [NSString stringWithFormat:@"%lld",fileCache.modifyGTMTime];
    [self finishItem:fileCache.hostPath localPath:fileCache.localPath modifyTime: modifyTime fileSize:fileCache.fileSize];
}

- (void) cacheFileFail:(FileCache*)cache hostPath:(NSString *)hostPath error:(NSString*)error {
    PCFileDownloadingInfo *downloadingInfo = [self fetchObject:@"FileDownloadingInfo"
                                                      hostPath:cache.hostPath
                                                    modifyTime:nil];
    
    
    if (downloadingInfo == nil)
    {
        return;
    }
    
    FileCache *fileCache = [cache retain];
    
    if (fileCache.errorNo == FILE_CACHE_ERROR_LACK_OF_SPACE ||
        fileCache.errorNo == FILE_CACHE_ERROR_NO_NETWORK ||
        fileCache.errorNo == FILE_CACHE_ERROR_CONNECTION_ERROR||
        fileCache.errorNo == FILE_CACHE_ERROR_SERVER_COMMON)
    {
        //盒子断电，网络请求会超时;或者resultType为20表示资源当前不在线，包括：盒子已断网,注销或关机，fix bug54760
        if (fileCache.isTimeout)
        {
            //超时后，停止当前的下载，开始新的下载
            downloadingInfo.status = [NSNumber numberWithShort:STATUS_STOP];
            [PCUtilityDataManagement saveInfos];
            [self sendRefreshTableNotification:@"RefreshTableView" userInfo:nil];
            
            [self startNewDownLoad];
        }
        else
        {
            [self stopDownLoading];
            
            if (fileCache.resultType != 20)
            {
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
                {
                    if (cache.errorNo == FILE_CACHE_ERROR_LACK_OF_SPACE)
                    {
                        error = NSLocalizedString(@"LackOfSpaceForDownload", nil);
                    }
                    [PCUtilityUiOperate showErrorAlert:error delegate:nil];
                }
            }
        }
    }
    else if (fileCache.errorNo == FILE_CACHE_ERROR_FILE_NO_FOUND ||
             fileCache.errorNo == FILE_CACHE_ERROR_FILE_REPLACE)
    {
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
        {
            [PCUtilityUiOperate showTip:error];
        }
        
        [self deleteDownloadingInfo:downloadingInfo];
        [PCUtilityDataManagement saveInfos];
        
        [self fetchDownloadingInfoObjects];
        [self sendRefreshTableNotification:@"RefreshTableView" userInfo:nil];
        
        [self startNewDownLoad];
    }
    else
    {
        [self stopDownLoading];
    }
    
    [fileCache release];
}

- (BOOL)checkDownLoadingStatus
{
    NSUInteger length = tableDownloading.count;
    for (int i = 0; i < length; i++) {
        PCFileDownloadingInfo *info = [tableDownloading objectAtIndex:i];
        if (info.status.shortValue == STATUS_RUN) {
            return   YES;
        }
    }
    
    return NO;
}

- (void)startNewDownLoad
{
    NSUInteger length = tableDownloading.count;
    BOOL bDownLoading =  [self checkDownLoadingStatus];
    //当前没有下载文件，则开始下载。（收藏那边通过把cache文件移到收藏目录也会调用这个方法）
    if (!bDownLoading) {
        for (int i = 0; i < length; i++) {
            PCFileDownloadingInfo *info = [tableDownloading objectAtIndex:i];
            if (info.status.shortValue == STATUS_PAUSE) {
                [self itemChangeStatus:i];
                [self sendRefreshTableNotification:@"RefreshTableView" userInfo:@{@"success": @(YES)}];
                return;
            }
        }
    }
}

- (void)stopDownLoading {
    
    for (int i=0; i < [self.tableDownloading count]; i++)
    {
        PCFileDownloadingInfo * info = [self.tableDownloading objectAtIndex:i];
        [(FileCache*)[self.tableFileCache objectForKey:info.hostPath] cancel];
        info.status = [NSNumber numberWithShort:STATUS_STOP];
        [PCUtilityDataManagement saveInfos];
    }
    
    [self fetchDownloadedInfoObjects];
    [self fetchDownloadingInfoObjects];
    [self fetchDownloadingStopedInfoObjects];
    [self sendRefreshTableNotification:@"RefreshTableView" userInfo:nil];
}

- (void)loadOnlyDownloadedData
{
    if (tableDownloading)
    {
        [tableDownloading release];
        tableDownloading = nil;
    }
    
    if (tableDownloadingStoped)
    {
        [tableDownloadingStoped release];
        tableDownloadingStoped = nil;
    }
    
    [self fetchDownloadedInfoObjects];
}

@end
