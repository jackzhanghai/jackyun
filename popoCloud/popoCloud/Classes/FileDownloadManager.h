//
//  FileDownloadManager.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-30.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileCache.h"
#import "PCFileDownloadedInfo.h"
#import "PCFileDownloadingInfo.h"

#define STATUS_RUN 0
#define STATUS_PAUSE 1
#define STATUS_STOP 2

@interface FileDownloadManager : NSObject <PCFileCacheDelegate>

@property (nonatomic, retain, readonly) NSMutableDictionary* tableProgressView;
@property (nonatomic, retain, readonly) NSMutableDictionary* tableFileCache;
@property (nonatomic, retain, readonly) NSArray* tableDownloading;
@property (nonatomic, retain, readonly) NSArray* tableDownloaded;
@property (nonatomic, retain, readonly) NSArray* tableDownloadingStoped;

- (id)fetchObject:(NSString *)entityName
         hostPath:(NSString *)hostPath
       modifyTime:(NSString *)modifyTime;

-(BOOL)addItem:(NSString *)hostPath fileSize:(long long)size modifyGTMTime:(long long)modifyGTMTime;

//删除正在下载，暂停下载，已经下载的文件
-(void)deleteDownloadingItem:(NSInteger)index;
-(void)deleteDownloadingStopedItem:(NSInteger)index;
-(void)deleteDownloadedItem:(NSInteger)index;
- (void)deleteFileWithPath:(NSString*)filePath;

-(void)downloadingPause:(PCFileDownloadingInfo *)info;
-(void)downloadingStop:(PCFileDownloadingInfo *)info;
-(void)downloadingStopedToRun:(PCFileDownloadingInfo *)info;

-(void)itemChangeStatus:(NSInteger)index;

- (NSArray *)fetchObjects:(NSString *)entityName withState:(int)stateCode;

//- (void)saveInfos;

- (void)backgroundDownload;

- (void)reloadData;

- (void)finishItem:(NSString *)hostPath localPath:(NSString *)localPath modifyTime:(NSString *)modifyTime fileSize:(long long)size;

/**
 * 获取文件下载状态
 * @param hostPath 文件在服务器端的路径
 * @return 下载状态枚举，有5种状态
 */
- (DownloadStatus)getFileStatus:(NSString *)hostPath andModifyTime:(NSString *)modifyTime;

/**
 * 取消收藏时调用，删除正在下载或已经下载的文件及数据库中保存信息
 * @param hostPath 文件的相对路径
 * @param status 文件的当前状态
 */
- (void)deleteDownloadItem:(NSString *)hostPath fileStatus:(DownloadStatus)status;

/**
 * 登陆时候发现和之前账号不一样时候调用。删除之前账号的所有下载信息
 */
- (void)deleteDownloadItem;
- (BOOL)checkDownLoadingStatus;
- (void)startNewDownLoad;
- (void)stopDownLoading;
- (void)loadOnlyDownloadedData;
@end
