//
//  FileCache.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-17.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCFileCacheInfo.h"
#import "PCProgressView.h"
//#import <UIKit/UIKit.h>

//#define TYPE_CACHE_FILE 0
//#define TYPE_CACHE_IMAGE 1
//#define TYPE_CACHE_THUMBIMAGE 2
//#define TYPE_CACHE_THUMBIMAGE_ZIP 3
//#define TYPE_CACHE_SLIDEIMAGE 4
//#define TYPE_CACHE_NEXT_SLIDEIMAGE 5
//#define TYPE_CACHE_CONTACT 6
//#define TYPE_CACHE_SHARE_DETAIL_FILE 7
//#define TYPE_DOWNLOAD_FILE 8
//#define TYPE_CACHE_VCF_FILE 9

typedef enum
{
    TYPE_CACHE_FILE,
    TYPE_CACHE_IMAGE,
    TYPE_CACHE_THUMBIMAGE,
    TYPE_CACHE_THUMBIMAGE_ZIP,
    TYPE_CACHE_SLIDEIMAGE,
    TYPE_CACHE_NEXT_SLIDEIMAGE,
    TYPE_CACHE_CONTACT,
    TYPE_DOWNLOAD_FILE,
    TYPE_CACHE_VCF_FILE
}CacheFileType;

#define FILE_CACHE_NO_ERROR 0
#define FILE_CACHE_ERROR_FILE_NO_FOUND 1
#define FILE_CACHE_ERROR_CONNECTION_ERROR 2
#define FILE_CACHE_ERROR_NO_NETWORK 3
#define FILE_CACHE_FILE_MORE_THAN_2M 4
#define FILE_CACHE_ERROR_LACK_OF_SPACE 5
#define FILE_CACHE_ERROR_SERVER_COMMON 6
#define FILE_CACHE_ERROR_FILE_REPLACE 7

@class FileCache;

@protocol PCFileCacheDelegate <NSObject>

- (void) cacheFileFail:(FileCache*)fileCache hostPath:(NSString *)hostPath error:(NSString*)error;
- (void) cacheFileFinish:(FileCache*)fileCache;

@optional
- (void) cacheFileProgress:(float)progress hostPath:(NSString *)hostPath;
@end

@class  PCFileInfo;
@interface FileCache : NSObject {
//    NSMutableData* data;
//    NSString *localPath;
//    NSString *hostPath;

    NSFileHandle *fileHandle;
    long long offsetPos;
    
    PCProgressView * progressView;
    float progressScale;
//    float fileSize;
    long long downloadSize;
    
    BOOL isCancel;
    NSURLConnection *connection;
    
    NSString *url;
    NSMutableArray *headers;
    
    NSString *currentDeviceID;
    NSString *currentTimeZone;
    long long fileTotalSize;
    NSMutableData* data;
}

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic) NSInteger viewType;
@property (nonatomic) NSInteger index;
@property (nonatomic) NSInteger errorNo;
@property (nonatomic) long long fileSize;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *hostPath;
@property (nonatomic, readonly) NSString *localPath;
@property (nonatomic, readonly) NSString *modifyTime;
@property (nonatomic, readonly) long long modifyGTMTime;
@property (nonatomic, copy) NSString *currentDeviceID;
@property (nonatomic, copy) NSString *currentTimeZone;
@property (assign) id<PCFileCacheDelegate> delegate;
@property (nonatomic,retain) NSMutableData* data;
@property (nonatomic) BOOL isEnshrine;
@property (nonatomic,retain)  NSURL *fileDownLoadUrl;
@property (nonatomic, retain) NSManagedObjectID *fileCacheObjID;
@property (nonatomic, readonly) BOOL isTimeout;
@property (nonatomic, readonly) NSInteger resultType;
@property (nonatomic,assign) BOOL isRemoveWhenCancel;//取消时，（当没有下载完缩略图的时候）是否删除本地文件

- (NSString *)cacheFile:(NSString *)path viewType:(NSInteger)type viewController:(id)controller fileSize:(long long)filesize modifyGTMTime:(long long)modifyGTMTime showAlert:(BOOL)showAlert;

- (void)setProgressView:(PCProgressView *)progress progressScale:(float)scale;

- (void)setIndex:(NSInteger)_index;

- (NSInteger)cancel;

- (BOOL) readFileFromCacheWithFileInfo:(PCFileInfo*)fileInfo withType:(NSInteger)type;

- (NSString *)getCacheFilePath:(NSString *)nodeFilePath withType:(NSInteger)type;

- (void)fetchCacheObjects:(BOOL)needAsk;

- (void)updateCacheInfo:(NSString *)path newPath:(NSString *)newPath;

+ (void)deleteDownloadFile:(NSString *)path;

+ (NSString *)getRelativePath:(NSString *)path withType:(NSInteger)type andDevice:(NSString *)device;

+ (PCFileCacheInfo *)fetchCacheFile:(NSString *)path;
- (BOOL) GetFuLLSizeFileFromCacheWithFileInfo:(PCFileInfo*)fileInfo withType:(NSInteger)type;
- (void)deleteCacheObjectsWithLimit:(NSUInteger)limit;
@end
