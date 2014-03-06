//
//  FileUploadManager.m
//  popoCloud
//
//  Created by leijun on 13-3-14.
//
//

#import "FileUploadManager.h"
#import "FileUploadInfo.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityDataManagement.h"
#import "PCUtilityUiOperate.h"
#import "PCUtilityStringOperate.h"
#import "PCLogin.h"
#import "NetPenetrate.h"

#import <AssetsLibrary/AssetsLibrary.h>

#define  MORETHAN2MB  202
@interface FileUploadManager ()

///上传文件类实例
@property (nonatomic, retain) FileUpload *fileUpload;

///包括暂停上传文件FileUploadInfo的集合
@property (nonatomic, retain) NSMutableSet *pauseUploadSet;

///检查新添加的上传文件是否在云端已存在的http调用接口的连接
@property (nonatomic, retain) NSURLConnection *connection;

//网络连接返回的数据
@property (nonatomic, retain) NSMutableData *receivedData;

//当前上传数据模型
@property (nonatomic, retain) FileUploadInfo *currentFileUploadInfo;

@end

@implementation FileUploadManager

+ (FileUploadManager *)sharedManager
{
    static FileUploadManager *_sharedSingleton = nil;
    if (_sharedSingleton == nil)
    {
        _sharedSingleton = [[FileUploadManager alloc] init];
    }
    return _sharedSingleton;
}

#pragma mark - methods from super class

- (id)init
{
    if (self = [super init])
    {
        //存储设备的字典
        _deviceDic = [[NSMutableDictionary alloc] init];
        
        _uploadFileArr = [[NSMutableArray alloc] init];
        
        _totalUploadArr = [[NSMutableArray alloc] init];
        
        //暂停的数据集合
        _pauseUploadSet = [[NSMutableSet alloc] init];
        
        //收到的网络请求数据
        NSMutableData *tReceivedData = [[NSMutableData alloc] initWithLength:1000];
        [self setReceivedData:tReceivedData];
        [tReceivedData release];
    }
    return self;
}

- (void)dealloc
{
    [self cancelUpload];
    
    self.deviceDic = nil;
    self.uploadFileArr = nil;
    self.totalUploadArr = nil;
    self.pauseUploadSet = nil;
    self.receivedData = nil;
	
    [super dealloc];
}

#pragma mark - public methods

//从数据库恢复数据
- (void)resumeFileUploadInfos
{
    //如果当前上传数据大于0个
    if (self.totalUploadArr.count || self.pauseUploadSet.count)
    {
        NSLog(@"不用从数据库获取数据...");
    }
    else
    {
        //获得用户ID
        NSString *userID = [[PCSettings sharedSettings] userId];
        
        //从数据库取回所有上传数据
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"uploadTime" ascending:YES];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(user == %@)", userID];
        NSArray *fetchArray = [PCUtilityDataManagement fetchObjects:@"FileUploadInfo"
                                                    sortDescriptors:@[sort]
                                                          predicate:predicate
                                                         fetchLimit:0
                                                          cacheName:@"Root"];
        
        BOOL isChange = NO;
        for (FileUploadInfo *info in fetchArray)
        {
            isChange = info.status.intValue != pauseUploadStatus;
            info.status = @(pauseUploadStatus);
            [self.pauseUploadSet addObject:info];
            [self addInfoToContainer:info];
        }
        
        if (isChange)
        {
            [PCUtilityDataManagement saveInfos];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:EVENT_UPLOAD_FILE_NUM object:nil];
    }
}

- (void)deleteAllUpload
{
    //删除数据库所有数据
    NSString *userID = [[PCSettings sharedSettings] userId];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(user == %@)", userID];
    NSArray *fetchArray = [PCUtilityDataManagement fetchObjects:@"FileUploadInfo"
                                                sortDescriptors:nil
                                                      predicate:predicate
                                                     fetchLimit:0
                                                      cacheName:@"delete"];
    
    if (fetchArray.count > 0)
    {
        for (FileUploadInfo *uploadInfo in fetchArray)
        {
            [[PCUtilityDataManagement managedObjectContext] deleteObject:uploadInfo];
        }
        [PCUtilityDataManagement saveInfos];
    }
}

//暂停所有上传数据
- (void)pauseAllUpload:(BOOL)needToClear
{
    [self cancelUpload];
    
    for (FileUploadInfo *uploadInfo in self.totalUploadArr)
    {
        uploadInfo.status = @(pauseUploadStatus);
        if (!needToClear)
        {
            [self.pauseUploadSet addObject:uploadInfo];
        }
    }
    
    if (self.totalUploadArr.count)
    {
        [PCUtilityDataManagement saveInfos];
    }
    
    [self.totalUploadArr removeAllObjects];
    
    if (needToClear)
    {
        [self.deviceDic removeAllObjects];
        [self.uploadFileArr removeAllObjects];
        [self.pauseUploadSet removeAllObjects];
    }
    
    if (self.delegate)
    {
        [self.delegate uploadFinish:_uploadSectionIndex
                           rowIndex:_uploadRowIndex
                           isCancel:YES
                          hasDelete:NO];
    }
}

- (NSUInteger)uploadTotalNum
{
    return self.totalUploadArr.count + self.pauseUploadSet.count;
}

- (BOOL)addUploadFile:(FileUploadInfo *)info
{
    __block BOOL alreadyInUpload = NO;
    NSNumber *arrayIndex = self.deviceDic[[info deviceID]];
    if (arrayIndex)
    {
        [self.uploadFileArr[arrayIndex.integerValue] enumerateObjectsUsingBlock:^(FileUploadInfo *tInfo, NSUInteger idx, BOOL *stop)
         {
             BOOL checkHostPath = [info.hostPath isEqualToString:[tInfo hostPath]];
             BOOL checkAssetUrl = [info.assetUrl isEqualToString:tInfo.assetUrl];
             if (checkAssetUrl && checkHostPath)
             {
                 alreadyInUpload = YES;
                 *stop = YES;
             }
         }];
    }
    
    if (alreadyInUpload == NO)
    {
        [self.totalUploadArr addObject:info];
        [self addInfoToContainer:info];
    }
    
    return alreadyInUpload;
}

- (BOOL)pauseUploadFile:(NSInteger)section rowIndex:(NSInteger)row
{
    DLogNotice(@"pauseUploadFile sectionIndex=%d,rowIndex=%d",section,row);
    DLogNotice(@"self.uploadFileArr.count=%d",self.uploadFileArr.count);
    DLogNotice(@"self.uploadFileArr[section].count=%d",[self.uploadFileArr[section] count]);
    DLogNotice(@"self.totalUploadArr.count=%d",self.totalUploadArr.count);
    
    FileUploadInfo *uploadInfo = self.uploadFileArr[section][row];
    
    BOOL hasNextUpload = NO;
    
    //若是取消的正在上传的文件，则要启动下一个文件上传
    if (self.totalUploadArr.count && [uploadInfo isEqual:self.totalUploadArr[0]])
    {
		[self cancelUpload];
        hasNextUpload = [self uploadNext:NO];
    }
    else
    {
        [self.pauseUploadSet addObject:uploadInfo];
        [self.totalUploadArr removeObject:uploadInfo];
        
        uploadInfo.status = @(pauseUploadStatus);
        [PCUtilityDataManagement saveInfos];
    }
    
    return hasNextUpload;
}

- (void)resumeUploadFile:(NSInteger)section rowIndex:(NSInteger)row
{
    DLogNotice(@"resumeUploadFile sectionIndex=%d,rowIndex=%d",section,row);
    if (![PCUtility isNetworkReachable:nil])
    {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"NetNotReachableError", nil) delegate:nil];
        return;
    }
    FileUploadInfo *uploadInfo = self.uploadFileArr[section][row];
    
    [self.pauseUploadSet removeObject:uploadInfo];
    
    //插入到totalUploadArr
    __block NSInteger insertIndex = self.totalUploadArr.count;
    [self.totalUploadArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSComparisonResult result = [uploadInfo.uploadTime compare:((FileUploadInfo *)obj).uploadTime];
        if (result == NSOrderedAscending)
        {
            insertIndex = idx;
            *stop = YES;
        }
    }];
    
    if (self.totalUploadArr.count && insertIndex == 0)
    {
        insertIndex = 1;//若恢复上传的文件上传时间先于目前正在上传的文件，则要排在正在上传的后面
    }
    
    DLogNotice(@"resumeUploadFile insertIndex=%d",insertIndex);
    
    [self.totalUploadArr insertObject:uploadInfo atIndex:insertIndex];
    
    BOOL hasOnlyOne = self.totalUploadArr.count == 1;
    
    uploadInfo.status = @(hasOnlyOne ? uploadingStatus : waitUploadStatus);
    [PCUtilityDataManagement saveInfos];
    
    if (hasOnlyOne)
    {
        _uploadSectionIndex = section;
        _uploadRowIndex = row;
        _progressValue = 0;
        
        [self uploadFile:uploadInfo];
    }
}

- (void)cancelUploadAndProcessNext:(NSInteger)sectionIndex
                          whichRow:(NSInteger)rowIndex
                           isPause:(BOOL)pause
                          isCancel:(BOOL)cancel
                      deleteDBInfo:(BOOL)isDelete
{
	DLogNotice(@"cancelUploadAndProcessNext sectionIndex=%d,rowIndex=%d",sectionIndex,rowIndex);
    if (sectionIndex>= self.uploadFileArr.count) {
        DLogNotice(@"Upload Error sectionIndex=%d,uploadFileArr count=%d",sectionIndex,self.uploadFileArr.count);
        return;
    }
    NSMutableArray *tempArr = self.uploadFileArr[sectionIndex];
    DLogNotice(@"tempArr.count=%d",tempArr.count);
    if (rowIndex>= tempArr.count) {
        DLogNotice(@"Upload Error rowIndex=%d,sectionIndex Array count=%d",rowIndex,tempArr.count);
        return;
    }
    
    FileUploadInfo *uploadInfo = [tempArr[rowIndex] retain];
    
    if (isDelete)
    {
        [tempArr removeObjectAtIndex:rowIndex];
        if (tempArr.count == 0)
        {
            NSInteger removeIndex = [self.deviceDic[uploadInfo.deviceID] integerValue];
            DLogInfo(@"removeIndex=%d",removeIndex);
            
            if (uploadInfo.deviceID)
            {
                [self.deviceDic removeObjectForKey:uploadInfo.deviceID];
            }
            
            [self.uploadFileArr removeObjectAtIndex:sectionIndex];
            
            if (self.deviceDic.count)
            {
                [self.deviceDic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    NSInteger index = [obj integerValue];
                    if (index > removeIndex)
                        self.deviceDic[key] = @(index - 1);
                }];
            }
        }
    }
    
    //若是取消的正在上传的文件，则要启动下一个文件上传
    if (self.totalUploadArr.count && [uploadInfo isEqual:self.totalUploadArr[0]])
    {
		[self cancelUpload];
        [self uploadNext:isDelete];
    }
    else
    {
        if (pause)
            [self.pauseUploadSet removeObject:uploadInfo];
        else
            [self.totalUploadArr removeObject:uploadInfo];
        [self deleteUploadFile:uploadInfo];//删除数据库记录
        
        [self setCurrentUploadIndex];//fix bug:54326,必须添加这句，以前没有
    }
    
    [uploadInfo release];
    
    DLogNotice(@"self.delegate=%@",self.delegate);
    if (self.delegate)
    {
        [self.delegate uploadFinish:sectionIndex
                           rowIndex:rowIndex
                           isCancel:cancel
                          hasDelete:isDelete];
    }
}

- (void)uploadFile:(FileUploadInfo *)info
{
    if ([PCUtility isNetworkReachable:nil])
    {
        ALAssetsLibrary *library = [[[ALAssetsLibrary alloc] init] autorelease];
        [library assetForURL:[NSURL URLWithString:info.assetUrl] resultBlock:^(ALAsset *asset)
         {
             if (info)
             {
                 if (asset)
                 {
                     ALAssetRepresentation *present = asset.defaultRepresentation;
                     NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
                     NSData *imageData = [PCUtilityFileOperate getUploadImageData:present];
                     if (imageData)
                     {
                         //是否穿透
                         BOOL isPenetrate = [[NetPenetrate sharedInstance] isPenetrate];
                         BOOL checkLength = imageData.length >= SIZE_2M * 15;
                         if (!isPenetrate && checkLength)
                         {
                             if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
                             {
                                 UIAlertView *alert = [[UIAlertView alloc]
                                                       initWithTitle:NSLocalizedString(@"FileSizeMoreThan30MB", nil)
                                                       message:nil
                                                       delegate:nil
                                                       cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                       otherButtonTitles:nil];
                                 [alert show];
                                 [alert release];
                             }
                             
                             [self cancelUploadAndProcessNext:_uploadSectionIndex
                                                     whichRow:_uploadRowIndex
                                                      isPause:NO
                                                     isCancel:YES
                                                 deleteDBInfo:NO];
                             return;
                         }
                         
                         if (![PCUtility isWifi] && imageData.length >= SIZE_2M)
                         {
                             if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
                             {
                                 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UploadFileSizeMoreThan2MB", nil)
                                                                                     message:nil
                                                                                    delegate:self
                                                                           cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                                           otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                                 alertView.tag = MORETHAN2MB;
                                 [alertView show];
                                 [alertView release];
                                 
                                 //保存当前上传信息
                                 [self setCurrentFileUploadInfo:info];
                             }
                             else
                             {
                                 [self cancelUploadAndProcessNext:_uploadSectionIndex
                                                         whichRow:_uploadRowIndex
                                                          isPause:NO
                                                         isCancel:YES
                                                     deleteDBInfo:NO];
                             }
                             
                             return;
                         }
                         
                         _progressValue = 0;
                         
                         FileUpload *upload = [[FileUpload alloc] init];
                         self.fileUpload = upload;
                         [upload release];
                         
                         //上传
                         PCFileUpload *uploadRequest = [[PCFileUpload alloc] init];
                         [uploadRequest setDstPath:info.hostPath];
                         [uploadRequest setData:imageData];
                         [uploadRequest setFileType:FILE_TYPE_IMAGE];
                         [uploadRequest setDelegate:self];
                         [uploadRequest setDeviceID:info.deviceID];
                         [uploadRequest setModifyTime:date];
                         [self.fileUpload upload:uploadRequest];
                         [uploadRequest release];
                     }
                 }
                 else
                 {
                     [self cancelUploadAndProcessNext:_uploadSectionIndex
                                             whichRow:_uploadRowIndex
                                              isPause:NO
                                             isCancel:YES
                                         deleteDBInfo:YES];
                 }
             }
         }
                failureBlock:^(NSError *error)
         {
             [self pauseAllUpload:NO];
             if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
             {
                 [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"UploadAccessDeny", nil) delegate:nil];
             }
             DLogError(@"access upload picture fail:%@",error.localizedDescription);
         }];
    }
    else
    {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"NetNotReachableError", nil) delegate:nil];
        [[FileUploadManager sharedManager] pauseAllUpload:NO];
    }
}

- (void)setCurrentUploadIndex
{
    if (self.totalUploadArr.count)
    {
        FileUploadInfo *uploadInfo = self.totalUploadArr[0];
        [self.uploadFileArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            __block BOOL hasFound = NO;
            
            [obj enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([uploadInfo isEqual:obj])
                {
                    _uploadRowIndex = idx;
                    hasFound = YES;
                    *stop = YES;
                }
            }];
            
            if (hasFound)
            {
                _uploadSectionIndex = idx;
                *stop = YES;
            }
        }];
    }
    else
    {
        _uploadRowIndex = NSNotFound;
        _uploadSectionIndex = NSNotFound;
    }
    
    DLogNotice(@"setCurrentUploadIndex uploadSectionIndex=%d,uploadRowIndex=%d",_uploadSectionIndex,_uploadRowIndex);
}

- (void)addNewFileUploadInfos:(NSArray *)addFileArr;
{
    if (addFileArr.count)
    {
        FileUploadInfo *info = addFileArr[0];
        if (self.totalUploadArr.count == 0)
        {
            info.status = @(uploadingStatus);
        }
        
        for (FileUploadInfo *tInfo in addFileArr)
        {
            [self addUploadFile:tInfo];
        }
        
        NSNumber *status = [info status];
        if (status.intValue == uploadingStatus)
        {
            [self setCurrentUploadIndex];
            [self uploadFile:info];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:EVENT_UPLOAD_FILE_NUM object:nil];
    }
}

#pragma mark - private methods
- (void)addInfoToContainer:(FileUploadInfo *)uploadInfo
{
    NSString *deviceID = uploadInfo.deviceID;
    NSString *deviceName = uploadInfo.deviceName;
    
    __block NSInteger index = NSNotFound;
    
    if (self.deviceDic.count)
    {
        [self.deviceDic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
         {
             if ([key isEqualToString:deviceID])
             {
                 index = [obj integerValue];
                 *stop = YES;
             }
         }];
    }
    DLogNotice(@"addUploadFile index=%d",index);
    
    if (index == NSNotFound)//新的盒子的上传文件
    {
        NSInteger length = self.uploadFileArr.count;
        __block NSInteger sectionIndex = length;
        
        if (sectionIndex)
        {
            __block BOOL needToChangeSection = NO;
            
            [self.uploadFileArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                FileUploadInfo *info = obj[0];
                NSString *otherDeviceName = info.deviceName;
                DLogNotice(@"deviceName=%@",deviceName);
                NSComparisonResult result = [otherDeviceName localizedCompare:deviceName];
                DLogNotice(@"result=%d",result);
                
                if (sectionIndex == length && result == NSOrderedDescending)
                {
                    sectionIndex = idx;
                }
                
                if (sectionIndex != length)
                {
                    self.deviceDic[info.deviceID] = @(idx + 1);
                    if (_uploadSectionIndex == idx)
                        needToChangeSection = YES;
                }
            }];
            
            if (needToChangeSection)//fix bug:54960
                _uploadSectionIndex++;
        }
        else
        {
            _uploadSectionIndex = 0;
            _uploadRowIndex = 0;
        }
        
        self.deviceDic[deviceID] = @(sectionIndex);
        
        NSMutableArray *tempArr = [NSMutableArray array];
        [tempArr addObject:uploadInfo];
        [self.uploadFileArr insertObject:tempArr atIndex:sectionIndex];
        
        DLogNotice(@"self.deviceDic=%@",self.deviceDic);
    }
    else
    {
        [self.uploadFileArr[index] addObject:uploadInfo];
    }
}

- (BOOL)uploadNext:(BOOL)needRemoveFromDB
{
    _progressValue = 0;
    
    if (self.totalUploadArr.count)
    {
        FileUploadInfo *oldInfo = [self.totalUploadArr[0] retain];
        
        [self.totalUploadArr removeObjectAtIndex:0];
        
        if (needRemoveFromDB)
        {
            [self deleteUploadFile:oldInfo];
        }
        else//上传失败的文件状态改为暂停，并添加到pauseUploadSet数组中
        {
            oldInfo.status = @(pauseUploadStatus);
            [PCUtilityDataManagement saveInfos];
            
            [self.pauseUploadSet addObject:oldInfo];
        }
        
        [oldInfo release];
        
        if (self.totalUploadArr.count)
        {
            [self setCurrentUploadIndex];
            
            FileUploadInfo *uploadInfo = self.totalUploadArr[0];
            uploadInfo.status = @(uploadingStatus);
            [PCUtilityDataManagement saveInfos];//更新数据库
            [self uploadFile:uploadInfo];
            
            return YES;
        }
    }
    
    return NO;
}

- (void)cancelUpload
{
    if (self.fileUpload)
    {
        [self.fileUpload cancel];
        self.fileUpload = nil;
    }
}

- (void)deleteUploadFile:(FileUploadInfo *)info
{
    [[NSNotificationCenter defaultCenter] postNotificationName:EVENT_UPLOAD_FILE_NUM object:nil];
    
    [[PCUtilityDataManagement managedObjectContext] deleteObject:info];
    [PCUtilityDataManagement saveInfos];
}

#pragma mark - PCFileUploadDelegate methods

- (void) uploadFileFinish:(FileUpload*)fileUpload hostPath:(NSString*)path fileSize:(long long)size
{
    [self cancelUploadAndProcessNext:_uploadSectionIndex
                            whichRow:_uploadRowIndex
                             isPause:NO
                            isCancel:path == nil
                        deleteDBInfo:YES];
}

- (void) uploadFileFail:(FileUpload*)fileUpload hostPath:(NSString*)path error:(NSString*)error
{
    DLogNotice(@"uploadFileFail path=%@,error=%@",path,error);
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
    {
        if (fileUpload.errCode == PC_Err_LackSpace || fileUpload.errCode == PC_Err_ReadOnly || fileUpload.errCode == PC_Err_NoDisk)
        {
            [PCUtilityUiOperate showTip:error];
        }
    }
    
    if (fileUpload.errCode == NSURLErrorNotConnectedToInternet || fileUpload.errCode == PC_Err_ReadOnly || fileUpload.errCode == PC_Err_NoDisk || fileUpload.errCode == 1028 || fileUpload.errCode == 1029
        || fileUpload.errCode == PC_Err_LackSpace)
    {
        [self pauseAllUpload:NO];
    }
    else
    {
        [self cancelUploadAndProcessNext:_uploadSectionIndex
                                whichRow:_uploadRowIndex
                                 isPause:NO
                                isCancel:YES
                            deleteDBInfo:NO];
    }
}

- (void) uploadFileProgress:(FileUpload*)fileUpload
                currentSize:(long long)currentSize
                  totalSize:(long long)totalSize hostPath:(NSString *)path
{
    _progressValue = (double)currentSize / totalSize;
    if (self.delegate)
    {
        [self.delegate uploadProgress:_progressValue];
    }
}

#pragma mark - UIAlertViewDelegate methods

//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//	[self cancelUploadAndProcessNext:_uploadSectionIndex
//                            whichRow:_uploadRowIndex
//                             isPause:NO
//                            isCancel:YES
//                        deleteDBInfo:(buttonIndex == 1)];
//    [self setCurrentFileUploadInfo:nil];
//}

-(void)goOnUploadFile
{
    FileUploadInfo *info = self.currentFileUploadInfo;
    if ([PCUtility isNetworkReachable:nil])
    {
        ALAssetsLibrary *library = [[[ALAssetsLibrary alloc] init] autorelease];
        [library assetForURL:[NSURL URLWithString:info.assetUrl] resultBlock:^(ALAsset *asset)
         {
             if (info)
             {
                 if (asset)
                 {
                     ALAssetRepresentation *present = asset.defaultRepresentation;
                     NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
                     NSData *imageData = [PCUtilityFileOperate getUploadImageData:present];
                     if (imageData)
                     {
                         _progressValue = 0;
                         
                         FileUpload *upload = [[FileUpload alloc] init];
                         self.fileUpload = upload;
                         [upload release];
                         
                         //上传
                         PCFileUpload *uploadRequest = [[PCFileUpload alloc] init];
                         [uploadRequest setDstPath:info.hostPath];
                         [uploadRequest setData:imageData];
                         [uploadRequest setFileType:FILE_TYPE_IMAGE];
                         [uploadRequest setDelegate:self];
                         [uploadRequest setDeviceID:info.deviceID];
                         [uploadRequest setModifyTime:date];
                         [self.fileUpload upload:uploadRequest];
                         [uploadRequest release];
                     }
                 }
                 else
                 {
                     [self cancelUploadAndProcessNext:_uploadSectionIndex
                                             whichRow:_uploadRowIndex
                                              isPause:NO
                                             isCancel:YES
                                         deleteDBInfo:YES];
                 }
             }
         }
                failureBlock:^(NSError *error)
         {
             [self pauseAllUpload:NO];
             if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
             {
                 [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"UploadAccessDeny", nil) delegate:nil];
             }
             DLogError(@"access upload picture fail:%@",error.localizedDescription);
         }];
    }
    else
    {
        [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"NetNotReachableError", nil) delegate:nil];
        [[FileUploadManager sharedManager] pauseAllUpload:NO];
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == MORETHAN2MB)
    {
        if (buttonIndex == 0)
        {
            [self cancelUploadAndProcessNext:_uploadSectionIndex
                                    whichRow:_uploadRowIndex
                                     isPause:NO
                                    isCancel:YES
                                deleteDBInfo:YES];
            [self setCurrentFileUploadInfo:nil];
        }
        else
        {
            [self goOnUploadFile];
        }
        
    }
}

@end
