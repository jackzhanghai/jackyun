//
//  FileUpload.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-30.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCFileUpload.h"

/**
	文件类型：图像
	@returns 1
 */
#define FILE_TYPE_IMAGE 1

/**
	文件类型：备份
	@returns 2
 */
#define FILE_TYPE_BACKUP 2

/**
	文件类型：MD5加密文件
	@returns 3
 */
#define FILE_TYPE_MD5 3

/**
	文件类型：联系人文件
	@returns 4
 */
#define FILE_TYPE_CONTACT_VCF 4

@class FileUpload;

/**
	文件上传代理
	@author LeoZhang
 */
@protocol PCFileUploadDelegate

/**
    上传文件失败
	@param fileUpload 文件上传实例
	@param path 上传路径
	@param error 错误信息
 */
- (void) uploadFileFail:(FileUpload *)fileUpload
               hostPath:(NSString *)path
                  error:(NSString *)error;

/**
	上传文件进度
	@param fileUpload 文件上传实例
	@param currentSize 已上传内容大小
	@param totalSize 总大小
	@param path 上传路径
 */
- (void) uploadFileProgress:(FileUpload *)fileUpload
                currentSize:(long long)currentSize
                  totalSize:(long long)totalSize
                   hostPath:(NSString *)path;

/**
	上传文件完毕
	@param fileUpload 文件上传实例
	@param path 上传路径
	@param size 文件大小
 */
- (void) uploadFileFinish:(FileUpload *)fileUpload
                 hostPath:(NSString *)path
                 fileSize:(long long)size;
@end

/**
	文件上传步骤
 */
typedef enum
{
	UploadStage_CheckExist,	/** 检查文件是否已经存在 */
	UploadStage_UploadData,	/** 上传数据 */
	UploadStage_GetFileServer,	/** 获得文件服务器 */
	UploadStage_UploadToFileServer	/** 上传到文件服务器 */
} UploadStage;


@class KTURLRequest;
@interface FileUpload : NSObject
{
    UploadStage uploadStage;
    NSURLConnection *connection;
}

/**
	当前网络连接
 */
@property (nonatomic, retain) NSURLConnection *connection;

/**
	错误代码
 */
@property (nonatomic, readonly) NSInteger errCode;

/**
	上传步骤
 */
@property (nonatomic) UploadStage uploadStage;

/**
	上传请求
 */
@property (nonatomic, retain) PCFileUpload *uploadRequest;

@property (strong, nonatomic)  KTURLRequest *checkDiskSpaceRequest;

@property (strong, nonatomic)  NSString *serverUrl;
/**
	上传操作
	@param request 上传请求实例
	@returns 是否上传成功
 */
- (BOOL)upload:(PCFileUpload *)request;

/**
	取消上传
 */
- (void)cancel;

@end
