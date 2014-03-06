//
//  PCRestClient.h
//  popoCloud
//
//  Created by suleyu on 13-8-26.
//
//

#import <Foundation/Foundation.h>
#import "PCDiskInfo.h"

@protocol PCRestClientDelegate;
@class KTURLRequest;
@class PCFileInfo;

@interface PCRestClient : NSObject

@property (nonatomic, assign) id<PCRestClientDelegate> delegate;

- (void)cancelAllRequests;
- (void)cancelRequest:(KTURLRequest *)request;

- (KTURLRequest *)getAllDiskSpaceInfo;
- (KTURLRequest *)getAllDiskSpaceInfoWithServerAddr:(NSString*)serverUrl;
- (KTURLRequest *)getFileListInfo:(NSString *)parentDir;
- (KTURLRequest *)getFileListInfoByPage:(NSDictionary *)dic;//分页查询数据
- (KTURLRequest *)createFolder:(NSString*)path;
- (KTURLRequest *)deletePath:(NSString*)path;
- (KTURLRequest *)reNameFile:(NSString*)path  andNewName:(NSString*)name;

- (KTURLRequest *)getFileSerchIDForKey:(NSString*)key atPath:(NSString*)path;
- (KTURLRequest *)getFileSearchStatusForSearchID:(NSString*)searchID;
- (KTURLRequest *)getFileSearchResultForSearchID:(NSString*)searchID andStartIndex:(int)start andLimit:(int)limit;

- (KTURLRequest *)cancelFileSerchForSearchId:(NSString*)serchId;
/**
 * 根据信息取图片集里面的额图片
 * @param dic 里面包含接口参数  使用时传3个参数进来，groupName,start,limit
 * @return 
 */
- (KTURLRequest *)pictureListGetGroupImageByInfo:(NSDictionary *)dic;
/**
 * 取得图片的列表
 */
- (KTURLRequest *)getPictureGroupByInfo:(NSString *)sortedType andGroupType:(NSString*)groupType;
/**
 * 批量删除
 * @param path 删除路径
 * @return
 */
- (KTURLRequest *)batchDeletePath:(NSString*)path;
/**
 * 取得文件操作状态，批量删除时配合此函数使用
 * @param id  文件操作返回的id
 * @return
 */
- (KTURLRequest *)getOperateFileStatus:(NSString*)operateID;

/**
 * 取消文件操作
 * @param id  文件操作返回的id
 * @return
 */
- (KTURLRequest *)cancelOperateFile:(NSString*)operateID;

/**
 * 文件操作完成后，清除相关信息(成功之后调用)
 * @param id  文件操作返回的id
 * @return
 */
- (KTURLRequest *)clearOperateFile:(NSString*)operateID;

- (KTURLRequest *)getPictureFileList:(NSString *)dirPath;
- (KTURLRequest *)setPictureScanFolder:(NSArray *)folders exceptFolder:(NSArray *)exceptFolders;
- (KTURLRequest *)deletePictureScanFolder:(NSArray *)folders;

@end


@protocol PCRestClientDelegate <NSObject>

@optional

- (void)restClient:(PCRestClient*)client gotDiskSpace:(NSArray*)disks;   // disks: PCDiskInfo objects
- (void)restClient:(PCRestClient*)client getDiskSpaceFailedWithError:(NSError*)error;

- (void)restClient:(PCRestClient*)client gotFileListInfo:(NSArray*)fileListInfo;   // fileInfo: PCFileInfo objects
- (void)restClient:(PCRestClient*)client getFileListInfoFailedWithError:(NSError*)error;

- (void)restClient:(PCRestClient*)client gotFileSerchIDInfo:(NSString*)newId;
- (void)restClient:(PCRestClient*)client getFileSerchIDFailedWithError:(NSError*)error;

- (void)restClient:(PCRestClient*)client gotFileSerchStatusInfo:(NSDictionary*)serchStatusInfoDic;
- (void)restClient:(PCRestClient*)client getFileSearchStatusFailedWithError:(NSError*)error;

- (void)restClient:(PCRestClient*)client gotFileSerchResultInfo:(NSArray*)serchResultInfoArray;
- (void)restClient:(PCRestClient*)client getFileSearchResultFailedWithError:(NSError*)error;

- (void)restClient:(PCRestClient*)client gotCancelFileSerchResultInfo:(NSDictionary*)cancelSerchResultDic;
- (void)restClient:(PCRestClient*)client getCancelFileSearchResultFailedWithError:(NSError*)error;

- (void)restClient:(PCRestClient*)client gotCreateFolderResultInfo:(NSDictionary*)resultInfo;
- (void)restClient:(PCRestClient*)client getCreateFolderResultFailedWithError:(NSError*)error;

- (void)restClient:(PCRestClient*)client deletedPath:(NSDictionary *)resultInfo;
- (void)restClient:(PCRestClient*)client deletePathFailedWithError:(NSError*)error;     // [error userInfo] contains the path

- (void)restClient:(PCRestClient*)client reNameFile:(NSDictionary *)resultInfo;
- (void)restClient:(PCRestClient*)client reNameFileFailedWithError:(NSError*)error;     // [error userInfo] contains the path

- (void)restClient:(PCRestClient*)client pictureListGetGroupImageByInfoSuccess:(NSDictionary *)resultInfo;
- (void)restClient:(PCRestClient*)client pictureListGetGroupImageByInfoFailedWithError:(NSError*)error;

- (void)restClient:(PCRestClient*)client getPictureGroupByInfoSuccess:(NSArray *)resultInfo;
- (void)restClient:(PCRestClient*)client getPictureGroupByInfoFailedWithError:(NSError*)error;


- (void)restClient:(PCRestClient*)client batchDeletedPathSuccess:(NSString *)operateFileID;
- (void)restClient:(PCRestClient*)client batchDeletedPathFailedWithError:(NSError*)error;

- (void)restClient:(PCRestClient*)client getOperateFileStatusSuccess:(NSDictionary *)resultInfo;
- (void)restClient:(PCRestClient*)client getOperateFileStatusFailedWithError:(NSError*)error;

- (void)restClient:(PCRestClient*)client cancelOperateFileSuccess:(NSDictionary *)resultInfo;
- (void)restClient:(PCRestClient*)client cancelOperateFileFailedWithError:(NSError*)error;

- (void)restClient:(PCRestClient*)client clearOperateFileSuccess:(NSDictionary *)resultInfo;
- (void)restClient:(PCRestClient*)client clearOperateFileFailedWithError:(NSError*)error;

- (void)restClient:(PCRestClient*)client gotPictureFileList:(NSArray*)fileListInfo;   // fileListInfo: PCFileInfo objects
- (void)restClient:(PCRestClient*)client getPictureFileListFailedWithError:(NSError*)error;

- (void)restClient:(PCRestClient*)client setPictureScanFolderSuccess:(NSDictionary *)resultInfo;
- (void)restClient:(PCRestClient*)client setPictureScanFolderFailedWithError:(NSError*)error;

- (void)restClient:(PCRestClient*)client deletePictureScanFolderSuccess:(NSDictionary *)resultInfo;
- (void)restClient:(PCRestClient*)client deletePictureScanFolderFailedWithError:(NSError*)error;

@end
