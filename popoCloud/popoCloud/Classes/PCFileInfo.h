//
//  PCFileInfo.h
//  popoCloud
//
//  Created by Kortide on 13-8-26.
//
//

#import <Foundation/Foundation.h>
#import "PCFileDownloadedInfo.h"

typedef enum {
	PC_FILE_VEDIO,
	PC_FILE_AUDIO,
	PC_FILE_IMAGE,
    PC_FILE_OTHER,
} PCFILEType;

@interface PCFileInfo : NSObject
@property(nonatomic)  PCFILEType              mFileType;
@property(nonatomic,retain) NSString         *createTime;
@property(nonatomic,retain) NSString         *modifyTime;
@property(nonatomic,retain) NSString         *visitTime;
@property(nonatomic,retain) NSNumber   *size;

@property(nonatomic,retain) NSString  *dir;
@property(nonatomic,retain) NSString  *ext;
@property(nonatomic,retain) NSString  *name;
@property(nonatomic,retain) NSString  *path;
@property(nonatomic,retain) NSString  *identify;
@property(nonatomic,retain) NSString  *hash;

@property(nonatomic) BOOL bFileFoldType;
@property(nonatomic) BOOL bIsUploading;
@property(nonatomic) BOOL bIsAdded;

@property(nonatomic,retain) NSString  *publicAccess;

- (id)initWithFileInfoDic:(NSDictionary*)dic;//文件集
- (void) checkFileType;
- (id)initWithPCFileDownloadedInfo:(PCFileDownloadedInfo*)downLoadInfo;//下载
- (id)initWithFileShareInfo:(NSDictionary*)dic;//分享
- (id)initWithImageFileInfo:(NSDictionary*)dic;//图片集
@end
