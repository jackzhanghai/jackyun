//
//  CameraUploadManager.m
//  popoCloud
//
//  Created by suleyu on 13-3-14.
//
//

#import "CameraUploadManager.h"
#import "CameraUploadInfo.h"
#import "PCUtility.h"
#import "PCUtilityGetDeviceInfo.h"
#import "PCUtilityDataManagement.h"
#import "PCUtilityEncryptionAlgorithm.h"
#import "Reachability.h"
#import "UIDevice+IdentifierAddition.h"
#import "PCLogin.h"
#define TAG @"CameraUploadManager"

/// @enum Upload Error
typedef enum {
    UPLOAD_ERROR_OK = 0,
    UPLOAD_ERROR_FILE_NOT_EXIST,
    UPLOAD_ERROR_FILE_CANNOT_OPEN,
    UPLOAD_ERROR_NETWORK_OR_SERVER
} UPLOAD_ERROR;

@implementation CameraUploadManager
@synthesize uploadTask;
@synthesize uploadStatus;
@synthesize uploadNum;

static CameraUploadManager *g_sharedManager = nil;

+ (CameraUploadManager *)sharedManager
{
    if (g_sharedManager == nil)
    {
        g_sharedManager = [[CameraUploadManager alloc] init];
    }
    
    return g_sharedManager;
}

#pragma mark - methods from super class

- (id)init
{
    self = [super init];
    if (self) {
        needUploadList = [[NSMutableArray alloc] init];
        failedUploadList = [[NSMutableArray alloc] init];
        deviceIdentifier = [[NSString stringWithFormat:@"%@_%@", [PCUtilityGetDeviceInfo deviceModel], [[UIDevice currentDevice] uniqueGlobalDeviceIdentifier]] retain];
        DTLogInfo(TAG, @"deviceIdentifier = %@", deviceIdentifier);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
	
    [self stopCameraUpload];
    
    [needUploadList release];
    [failedUploadList release];
    [deviceIdentifier release];
    [childContext release];
    [super dealloc];
}

#pragma mark - public methods
-(void)getAutoUploadImage
{
    PCURLRequest *request = [[[PCURLRequest alloc] initWithTarget:self selector:@selector(cameraUploadManagerGetSomeInfoFinished:)] autorelease];
    request.process = @"GetAutoUploadImage";
    request.params = [NSDictionary dictionaryWithObject:deviceIdentifier forKey:@"path"];
    self.currentRequest = request;
    [request start];
}
-(void)cameraUploadManagerGetSomeInfoFinished:(PCURLRequest *)request
{
    if (request.error)
    {
        DTLogError(TAG, @"pcConnection:didFailWithError: error = %@", request.error);
        self.uploadStatus = kCameraUploadStatus_NetworkError;
    }
    else
    {
        NSString *ret = [request resultString];
        NSDictionary *dict = [ret JSONValue];
        if (dict) {
            uploadFolder = [[dict valueForKey:@"path"] retain];
            if (uploadFolder) {
                DTLogDebug(TAG, @"uploadFolder: %@", uploadFolder);
                
                NSArray* serverFiles = [dict valueForKey:@"data"];
                [serverFileList release];
                serverFileList = [[NSMutableArray alloc] initWithArray:serverFiles];
                
                NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"isUploaded" ascending:YES];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user == %@ AND deviceID == %@",
                                          [[PCSettings sharedSettings] userId],
                                          [[PCSettings sharedSettings] currentDeviceIdentifier]];
                NSArray* fetchedObjects = [PCUtilityDataManagement fetchObjects:@"CameraUploadInfo"
                                                                sortDescriptors:@[sort]
                                                                      predicate:predicate
                                                                     fetchLimit:0
                                                                      cacheName:nil];
                uploadedList = [[NSMutableArray alloc] initWithArray:fetchedObjects];
                
                [needUploadList removeAllObjects];
                for (CameraUploadInfo *obj in uploadedList) {
                    if ([obj.isUploaded boolValue]) {
                        break;
                    }
                    
                    [needUploadList addObject:obj];
                }
                
                [self listAssets];
            }
            else {
                DTLogError(TAG, @"GetAutoUploadImage error: %@", ret);
                self.uploadStatus = kCameraUploadStatus_ServerError;
            }
        }
        else {
            DTLogError(TAG, @"GetAutoUploadImage error: %@", ret);
            self.uploadStatus = kCameraUploadStatus_ServerError;
        }

    }
    self.currentRequest = nil;
}
- (void)startCameraUpload
{
    if ([[PCSettings sharedSettings] autoCameraUpload] && self.uploadStatus != kCameraUploadStatus_Preparing) {
        self.uploadStatus = kCameraUploadStatus_Preparing;
        if (uploadFolder == nil) {
            [self getAutoUploadImage];
        }
        else {
            if (failedUploadList.count > 0) {
                [needUploadList addObjectsFromArray:failedUploadList];
                [failedUploadList removeAllObjects];
            }
            
            [self listAssets];
        }
    }
}

- (void) stopCameraUpload
{
    if (self.uploadStatus == kCameraUploadStatus_Stoped)
        return;
    
    DTLogInfo(TAG, @"stopCameraUpload");
    self.uploadStatus = kCameraUploadStatus_Stoped;
    self.uploadNum = 0;
    
    [failedUploadList removeAllObjects];
    
     @synchronized(needUploadList)
    {
        [needUploadList removeAllObjects];
    }
    
    [uploadedList release];
    uploadedList = nil;
    
    if (self.currentRequest)
    {
        [self.currentRequest cancel];
        self.currentRequest = nil;
    }
    if (self.uploadTask) {
        [self.uploadTask cancel];
        self.uploadTask = nil;
    }
    
    [uploadFolder release];
    uploadFolder = nil;
    
    [serverFileList release];
    serverFileList = nil;
}

- (void) setUseCellularData:(BOOL)useCellularData
{
    if ([PCUtility isNetworkReachable:nil] && [PCUtility isWifi] == NO) {
        if (useCellularData) {
            if (self.uploadTask == nil) {
                if (failedUploadList.count > 0) {
                    [needUploadList addObjectsFromArray:failedUploadList];
                    [failedUploadList removeAllObjects];
                }
                
                if (needUploadList.count > 0) {
                    self.uploadStatus = kCameraUploadStatus_Uploading;
                    [self performSelectorInBackground:@selector(uploadFilesBackground:) withObject:[needUploadList objectAtIndex:0]];
                }
            }
        } else if (self.uploadTask) {
            [self.uploadTask cancel];
            self.uploadTask = nil;
            
            self.uploadStatus = kCameraUploadStatus_Wait;
        }
    }
}

#pragma mark - private methods

- (void)saveDB:(NSManagedObjectContext *)context
{
    NSError *error = nil;
    if (![context save:&error])
    {
        DLogError(@"save child context database error:%@", error.localizedDescription);
    }
    
    NSManagedObjectContext *mainContext = [PCUtilityDataManagement managedObjectContext];
    
    [mainContext performBlock:^{
        NSError *err = nil;
        if (![mainContext save:&err])
        {
            DLogError(@"save database error:%@", err.localizedDescription);
        }
    }];
}

- (void) listAssets
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        if (childContext == nil) {
            childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [childContext setParentContext:[PCUtilityDataManagement managedObjectContext]];
        }
        
        // Group enumerator Block
        void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
        {
            if (group == nil)
            {
                return;
            }
            
            DTLogInfo(TAG, @"start listAssets");
            @synchronized(uploadedList)
            {
                NSMutableArray *tempList = [uploadedList retain];
                
                [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop)
                {
                     if (asset == nil)
                     {
                         return;
                     }
                     
                     NSString *assetUrl = [asset.defaultRepresentation.url absoluteString];
                     BOOL needUpload = YES;
                     for (CameraUploadInfo *obj in tempList) {
                         if ([assetUrl isEqualToString:obj.assetUrl]) {
                             needUpload = NO;
                             break;
                         }
                     }
                     
                     if (self.uploadStatus == kCameraUploadStatus_Stoped) {
                         *stop = YES;
                     }
                     else if (needUpload) {
                         DTLogInfo(TAG, @"needUpload assetUrl = %@",assetUrl);
                         CameraUploadInfo *obj = [NSEntityDescription insertNewObjectForEntityForName:@"CameraUploadInfo" inManagedObjectContext:childContext];
                         obj.assetUrl = assetUrl;
                         obj.fileSize = [NSNumber numberWithLongLong:asset.defaultRepresentation.size];
                         obj.isUploaded = @NO;
                         obj.user = [[PCSettings sharedSettings] userId];
                         obj.deviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
                         
                         [uploadedList addObject:obj];
                         [needUploadList addObject:obj];
                     }
                 }];
                
                [tempList release];
            }
           
            
            if (self.uploadStatus == kCameraUploadStatus_Stoped) {
                DTLogInfo(TAG, @"stop listAssets");
                return;
            }
            
            self.uploadNum = needUploadList.count + failedUploadList.count;
            DTLogInfo(TAG, @"finish listAssets, %d photos need to upload", self.uploadNum);
            
            if (self.uploadTask != nil) {
                self.uploadStatus = kCameraUploadStatus_Uploading;
            }
            else if (needUploadList.count > 0) {
                if ([PCUtility isNetworkReachable:nil] && ([PCUtility isWifi] || [[PCSettings sharedSettings] useCellularData])) {
                    self.uploadStatus = kCameraUploadStatus_Uploading;
                    [self performSelectorInBackground:@selector(uploadFilesBackground:) withObject:[needUploadList objectAtIndex:0]];
                }
                else {
                    self.uploadStatus = kCameraUploadStatus_Wait;
                }
            }
            else {
                self.uploadStatus = kCameraUploadStatus_NoUpload;
            }
            
            if (self.uploadNum)
            {
                [self saveDB:childContext];
            }
        };
        
        // Group Enumerator Failure Block
        void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
            DTLogWarn(TAG, @"listAssets failed: %@", [error localizedDescription]);
            self.uploadStatus = kCameraUploadStatus_Denied;
        };
        
        // Enumerate Albums
        [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                               usingBlock:assetGroupEnumerator
                             failureBlock:assetGroupEnumberatorFailure];
        
        [library release];
        [pool release];
    });
}

-(void) uploadFilesBackground:(CameraUploadInfo *)uploadInfo
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *asset)
    {
        if (asset == nil) {
            DTLogInfo(TAG, @"File is not exist: %@", uploadInfo.assetUrl);
            dispatch_async(dispatch_get_main_queue(), ^ {
                [self uploadComplete:UPLOAD_ERROR_FILE_NOT_EXIST];
            });
            return;
        }
        
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        NSString *dstPath = [uploadFolder stringByAppendingPathComponent:rep.filename];
        NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
        DTLogInfo(TAG, @"start upload: %@", dstPath);
        
        NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"autoUpload.tmp"];
        long long fileSize = [rep size];
        const int bufferSize = 8192;
        
        FILE *f = fopen([tempPath cStringUsingEncoding:1], "w+");
        if (f == NULL) {
            DTLogError(TAG, @"Can not create tmp file.");
            dispatch_async(dispatch_get_main_queue(), ^ {
                [self uploadComplete:UPLOAD_ERROR_FILE_CANNOT_OPEN];
            });
            return;
        }
        
        Byte *buffer = (Byte*)malloc(bufferSize);
        int read = 0, offset = 0;
        NSError *err;
        if (fileSize != 0) {
            do {
                read = [rep getBytes:buffer
                          fromOffset:offset
                              length:bufferSize
                               error:&err];
                fwrite(buffer, sizeof(char), read, f);
                offset += read;
            } while (read != 0);
        }
        free(buffer);
        fclose(f);
        
        NSString *md5 = [PCUtilityEncryptionAlgorithm file_md5:tempPath];
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            uploadInfo.md5 = md5;
            if (self.uploadStatus == kCameraUploadStatus_Stoped)
            {
                self.uploadTask = nil;
            }
            else if ([serverFileList containsObject:md5])
            {
                DTLogInfo(TAG, @"File already uploaded to server");
                [serverFileList removeObject:md5];
                [self uploadComplete:UPLOAD_ERROR_OK];
            }
            else
            {
                FileUpload *task = [[FileUpload alloc] init];
                
                //上传
                PCFileUpload *uploadRequest = [[PCFileUpload alloc] init];
                [uploadRequest setDstPath:dstPath];
                [uploadRequest setSrc:tempPath];
                [uploadRequest setMd5:md5];
                [uploadRequest setFileType:FILE_TYPE_MD5];
                [uploadRequest setDelegate:self];
                [uploadRequest setDeviceID:nil];
                [uploadRequest setModifyTime:date];
                [task upload:uploadRequest];
                
                self.uploadTask = task;
                [task release];
            }
        });
    };
    
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *error)
    {
        DTLogWarn(TAG, @"read photo library failed: %@", [error localizedDescription]);
        dispatch_async(dispatch_get_main_queue(), ^ {
            self.uploadTask = nil;
            self.uploadStatus = kCameraUploadStatus_Denied;
        });
    };
    
    NSURL *url = [NSURL URLWithString:uploadInfo.assetUrl];
    ALAssetsLibrary* assetslibrary = [[[ALAssetsLibrary alloc] init] autorelease];
    [assetslibrary assetForURL:url
                   resultBlock:resultblock
                  failureBlock:failureblock];
    
    [pool release];
}

- (void) uploadComplete:(int)error
{
    if (needUploadList.count <= 0) {
        self.uploadTask = nil;
        if (self.uploadStatus != kCameraUploadStatus_Stoped) {
            if (failedUploadList.count > 0) {
                self.uploadStatus = kCameraUploadStatus_Failed;
            }
            else {
                self.uploadStatus = kCameraUploadStatus_NoUpload;
            }
        }
        return;
    }
    
    CameraUploadInfo *obj = [needUploadList objectAtIndex:0];
    if (error == UPLOAD_ERROR_OK) {
        obj.isUploaded = @YES;
        [PCUtilityDataManagement saveInfos];
    } else if (error == UPLOAD_ERROR_FILE_NOT_EXIST) {
        [[PCUtilityDataManagement managedObjectContext] deleteObject:obj];
        [PCUtilityDataManagement saveInfos];
    }
    else {
        [failedUploadList addObject:obj];
    }
    
    [needUploadList removeObjectAtIndex:0];
    self.uploadNum = needUploadList.count + failedUploadList.count;
    
    if (needUploadList.count > 0) {
        if ([PCUtility isNetworkReachable:nil] && ([PCUtility isWifi] || [[PCSettings sharedSettings] useCellularData])) {
            [self performSelectorInBackground:@selector(uploadFilesBackground:) withObject:[needUploadList objectAtIndex:0]];
        }
        else {
            self.uploadTask = nil;
            self.uploadStatus = kCameraUploadStatus_Wait;
        }
    }
    else if (failedUploadList.count > 0) {
        self.uploadTask = nil;
        self.uploadStatus = kCameraUploadStatus_Failed;
    }
    else {
        self.uploadTask = nil;
        self.uploadStatus = kCameraUploadStatus_NoUpload;
    }
}

- (void)reachabilityChanged:(NSNotification *)note
{
    NetworkStatus ns = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    DTLogInfo(TAG, @"network status changed, new status = %d", ns);
    
    if (self.uploadStatus == kCameraUploadStatus_Wait) {
        if (ns == ReachableViaWiFi || (ns == ReachableViaWWAN && [[PCSettings sharedSettings] useCellularData])) {
            self.uploadStatus = kCameraUploadStatus_Uploading;
            [self performSelectorInBackground:@selector(uploadFilesBackground:) withObject:[needUploadList objectAtIndex:0]];
        }
    }
}

#pragma mark - methods from PCNetworkDelegate

- (void) networkNoReachableFail:(NSString*)error {
    DTLogWarn(TAG, @"networkNoReachableFail: error = %@", error);
    self.uploadStatus = kCameraUploadStatus_NetworkError;
}
#pragma mark - methods from PCFileUploadDelegate

- (void) uploadFileFail:(FileUpload*)fileUpload hostPath:(NSString*)path error:(NSString*)error
{
    DTLogError(TAG, @"uploadFileFail: error = %@", error);
    
    if (fileUpload.errCode == PC_Err_LackSpace || fileUpload.errCode == PC_Err_ReadOnly || fileUpload.errCode == PC_Err_NoDisk) {
        self.uploadTask = nil;
        self.uploadStatus = kCameraUploadStatus_NoSpace;
    }
    else {
        [self uploadComplete:UPLOAD_ERROR_NETWORK_OR_SERVER];
    }
}

- (void) uploadFileProgress:(FileUpload*)fileUpload currentSize:(long long)currentSize totalSize:(long long)totalSize hostPath:(NSString *)path
{
    //DTLogInfo(TAG, @"uploadFileProgress: currentSize = %f", currentSize / totalSize);
}

- (void) uploadFileFinish:(FileUpload*)fileUpload hostPath:(NSString*)path fileSize:(long long)size
{
    DTLogDebug(TAG, @"uploadFileFinish");
    
    [self uploadComplete:UPLOAD_ERROR_OK];
}

@end
