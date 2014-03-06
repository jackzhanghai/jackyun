//
//  FileUploadManager.h
//  popoCloud
//
//  Created by leijun on 13-3-14.
//
//

#import <Foundation/Foundation.h>
#import "FileUpload.h"
#import "FileUploadInfo.h"

@protocol UploadDelegate;
@class KTURLRequest;
@interface FileUploadManager : NSObject <PCFileUploadDelegate, UIAlertViewDelegate>

///key为deviceID，value为对应device的上传文件的数组在uploadFileArr里的索引
@property (nonatomic, retain) NSMutableDictionary *deviceDic;

///二维数组，第二维包括上传文件FileUploadInfo对象，按上传时间先后排序；一维按盒子名首字母排序；对应显示到视图列表中
@property (nonatomic, retain) NSMutableArray *uploadFileArr;

///包括正在上传文件FileUploadInfo的一维数组
@property (nonatomic, retain) NSMutableArray *totalUploadArr;

///UploadDelegate代理协议，其值目前仅为FileUploadController对象
@property (atomic, assign) id<UploadDelegate> delegate;

///上传进度值，取值0-1
@property (nonatomic, readonly) CGFloat progressValue;

///当前正在上传文件的section索引（属于哪个设备）
@property (nonatomic, readonly) NSInteger uploadSectionIndex;

///当前正在上传文件的row索引
@property (nonatomic, readonly) NSInteger uploadRowIndex;

/**
 * 单例模式
 * @return 该类的唯一实例
 */
+ (FileUploadManager *)sharedManager;

/**
 * 从数据库查询初始化数据
 */
- (void)resumeFileUploadInfos;

/**
 * 添加一批上传任务
 * @param files 要上传的文件，FileUploadInfo数组
 */
- (void)addNewFileUploadInfos:(NSArray *)addFileArr;

/**
 * 删除当前帐户所有的上传任务
 */
- (void)deleteAllUpload;

/**
 * 暂停所有正在和等待上传的文件
 * @param needToClear 是否清空所有集合容器的数据；切换为其他账号登录处调用需传YES，退出app和网络断开处调用需传NO
 */
- (void)pauseAllUpload:(BOOL)needToClear;

/**
 * 正在，等待，暂停上传的文件总数
 * @return 上传的文件总数
 */
- (NSUInteger)uploadTotalNum;

/**
 * 添加上传项到集合中
 * @param node 包括FileUploadInfo属性值的字典
 * @return 若上传文件已经处于上传队列中，则返回YES，否则NO
 */
- (BOOL)addUploadFile:(FileUploadInfo *)node;

/**
 * 暂停上传文件，列表视图中展开的操作栏暂停按钮点击时调用
 * @param section section索引
 * @param row row索引
 * @return 若是暂停的正在上传的文件，则要启动下一个文件上传；启动了下个文件返回YES；否则NO
 */
- (BOOL)pauseUploadFile:(NSInteger)section rowIndex:(NSInteger)row;

/**
 * 恢复继续上传文件，列表视图中展开的操作栏恢复按钮点击时调用
 * @param section section索引
 * @param row row索引
 */
- (void)resumeUploadFile:(NSInteger)section rowIndex:(NSInteger)row;

/**
 * 取消上传并且启动下一个上传文件
 * @param sectionIndex section索引
 * @param rowIndex row索引
 * @param pause 取消上传的文件是否已经处于暂停状态
 * @param cancel 是否是取消文件上传（正常上传完成也会调用该函数，那就应该传NO）
 * @param isDelete 是否删除数据库中该项
 */
- (void)cancelUploadAndProcessNext:(NSInteger)sectionIndex
                          whichRow:(NSInteger)rowIndex
                           isPause:(BOOL)pause
                          isCancel:(BOOL)cancel
                      deleteDBInfo:(BOOL)isDelete;

/**
 * 设置当前正在上传的文件的索引，即uploadSectionIndex和uploadRowIndex
 */
- (void)setCurrentUploadIndex;

@end

@protocol UploadDelegate

/**
 * 上传完成，取消上传，暂停所有上传时调用；更新UI
 * @param sectionIndex section索引
 * @param rowIndex row索引
 * @param cancel 是否是取消上传文件
 * @param hasDelete 是否删除了该上传文件
 */
- (void)uploadFinish:(NSInteger)sectionIndex
            rowIndex:(NSInteger)rowIndex
            isCancel:(BOOL)cancel
           hasDelete:(BOOL)hasDelete;

/**
 * 上传正在进行的回调函数
 * @param progress 当前上传的进度
 */
- (void)uploadProgress:(CGFloat)progress;
@end
