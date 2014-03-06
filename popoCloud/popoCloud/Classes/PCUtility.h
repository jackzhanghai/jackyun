//
//  PCUtility.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-12.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileDownloadManager.h"
#import "ModalAlert.h"
#import <CoreData/CoreData.h>
#import "JSON.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "MobClick.h"
#import "umengEventStr.h"
#import <QuickLook/QuickLook.h>

@protocol PCNetworkDelegate
- (void) networkNoReachableFail:(NSString*)error;

@optional
- (NSURLRequest *)pcConnection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response;
- (void)pcConnection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)pcConnection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)pcConnectionDidFinishLoading:(NSURLConnection *)connection;
- (void)pcConnection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)pcConnection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

@end

@interface PCUtility : NSObject

+ (NSString*) formatFileSize:(long long)size isNeedBlank:(BOOL)isNeedBlank;
+ (NSDate*) formatTimeString:(NSString*)time formatString:(NSString*)formatString;
+ (NSString*) formatTime:(float)time formatString:(NSString*)formatString;
+ (NSString*) checkResponseStautsCode:(NSInteger)code;

+ (NSString*) urlServer;
+ (void) setUrlServer:(NSString*)url;
+ (NSString*) cookie;
+ (void) setCookie: (NSArray*)cookies;
//+ (BOOL) isLAN;
+ (void) setIsLAN:(BOOL)isLan;

+ (FileDownloadManager*) downloadManager;
+ (NSManagedObjectContext*) managedObjectContext;

+ (void) deleteFile:(NSString*)path;
+ (void) openFileAtPath:(NSString*)path WithBackTitle:(NSString*)title andFileInfo:(PCFileInfo*)fileInfo andNavigationViewControllerDelegate:(UIViewController*)delegate;

+ (NSString*) GetUUID;
+ (NSString*) SHA1:(NSString*)input; 
+ (NSString*) md5:(NSString*)str;
+ (NSString*) file_md5:(NSString*)path;
+ (NSString *) encodeToPercentEscapeString: (NSString *) input;
+ (NSString *) decodeFromPercentEscapeString: (NSString *) input;

+ (NSString *) getPListPath;
+ getNSURL:(NSString*)method;

+ (NSURLConnection *) httpGetFileServerInfo:(id)delegate;

+ (NSURLConnection *) httpGetWithURL:(NSString *)url headers:(NSArray*)headers delegate:(id)delegate;

+ (NSURLConnection *) postFileData:(NSData *)fileData
                               md5:(NSString *)md5
                        modifyTime:(NSDate *)modifytime
                           dstPath:(NSString *)dst
                    replaceOldFile:(BOOL)isReplace
                          delegate:(id)delegate
                       whichServer:(NSString *)serverURL;

+ (NSURLConnection *) postContactFileData:(NSData *)fileData
                                      md5:(NSString *)md5
                                  dstPath:(NSString *)dst
                           replaceOldFile:(BOOL)isReplace
                                 delegate:(id)delegate
                              whichServer:(NSString *)serverURL;

+ (SCNetworkReachabilityFlags) getNetworkFlags;
+ (BOOL) isNetworkReachable:(id)delegate;
+ (BOOL) isWifi;
+ (void) networkNoReachableAlert:(id)delegate;

+ (NSString*) getImgName:(NSString*)imgName;
+ (NSString*) getXibName:(NSString*)xibName;
+ (NSString*) getImgByExt:(NSString*)ext;

//网络不通时的处理逻辑
+ (void) netConnectionError:(NSURLConnection*)connection withError:(NSError*)error;
+ (void)reConnectWhenFailed:(NSURLConnection*)connection connectUrl:(NSString *)urlStr;

//网络请求队列处理
+ (id) getConnectionDelegateByConnection:(NSURLConnection*)connection;
+ (void) addConnectionToArray:(NSURLConnection*)connection withDelegate:(id)delegate withRequest:(NSMutableURLRequest*)request withMethod:(NSString*)method;
+ (void) removeConnectionFromArray:(NSURLConnection*)connection;

/**
 * 获取当前设备的磁盘可用容量
 * @return 可用容量大小
 */
+ (long long)getFreeSpace;

//http特殊符号转换
+ (NSString*)unescapeHTML:(NSString*)inputString;

/**
 * 查询数据库返回想要的数据，从指定的NSManagedObjectContext获取（可能是子线程的MOC）
 * @param entityName 数据库表名
 * @param descriptors 排序的NSSortDescriptor对象数组
 * @param predicate 查询条件判断，过滤数据
 * @param limit 限制查询返回的数据的最大数量，传0表示没限制
 * @param moc 指定的NSManagedObjectContext
 * @return 查询到的符合条件的项组成的数组
 */
+ (NSArray *)fetchObjects:(NSString *)entityName
          sortDescriptors:(NSArray *)descriptors
                predicate:(NSPredicate *)predicate
               fetchLimit:(NSUInteger)limit
                threadMOC:(NSManagedObjectContext *)moc;
/**
 * 查询数据库返回想要的数据，从主线程的NSManagedObjectContext获取
 * @param entityName 数据库表名
 * @param descriptors 排序的NSSortDescriptor对象数组
 * @param predicate 查询条件判断，过滤数据
 * @param limit 限制查询返回的数据的最大数量，传0表示没限制
 * @param name 查询缓存名
 * @return 查询到的符合条件的项组成的数组
 */
+ (NSArray *)fetchObjects:(NSString *)entityName
          sortDescriptors:(NSArray *)descriptors
                predicate:(NSPredicate *)predicate
               fetchLimit:(NSUInteger)limit
                cacheName:(NSString *)name;

/**
 * 登陆成功后检查缓存和收藏文件是否还在沙盒里存在（可能会被系统清除），若不存在则删除数据库里的记录
 */
+ (void)checkDownloadFilesExist;

+ (BOOL) checkPrivacyForAlbum;

/**
 * 创建导航栏右侧刷新按钮
 * @param target 刷新按钮点击后执行的回调函数所在的类对象
 * @return UIBarButtonItem实例
 */
+ (UIBarButtonItem *)createRefresh:(id)target;

/**
 * 动画旋转刷新按钮
 * @param view 刷新按钮的customView：UIButton
 * @return 旋转动画启动返回YES，若正在进行旋转动画则返回NO
 */
+ (BOOL)animateRefreshBtn:(UIView *)view;

/**
 * 移动缓存的文件到收藏（下载）目录
 * @param hostPath 文件在云端的目录地址
 * @param size 文件大小
 * @param fileCache FileCache实例
 * @param type 缓存文件类型
 * @return 移动成功返回YES，否则NO
 */
+ (BOOL)moveCacheFileToDownload:(NSString *)hostPath
                       fileSize:(long long)size
                      fileCache:(FileCache *)fileCache
                       fileType:(NSInteger)type;

/**
 * 获取上传图片文件的二进制数据
 * @param present ALAssetRepresentation实例
 * @return 上传文件的数据
 */
+ (NSData *)getUploadImageData:(ALAssetRepresentation *)present;

/**
 * 数据库内容改变后，存储更新
 */
+ (void)saveInfos;

/**
 * 格式化时间为指定字符串格式
 * @param date 要格式化的时间NSDate实例
 * @param formatString 格式化样式字符串
 * @return 时间格式化后的字符串
 */
+ (NSString *)formatDate:(NSDate *)date formatString:(NSString*)formatString;

/**
 * 在屏幕上显示自动消失的提示信息,若一行显示不全会多行显示
 * @param msg 信息内容
 */
+ (void)showTip:(NSString *)msg;

/**
 * 在屏幕上显示自动消失的提示信息
 * @param msg 信息内容
 * @param multiline 是否需要多行显示
 */
+ (void)showTip:(NSString *)msg needMultiline:(BOOL)multiline;

/**
 * 移动收藏下载的文件到缓存目录
 * @param hostPath 文件在云端的目录地址
 * @param downFilePath 收藏的文件的路径
 * @return 移动成功返回缓存文件路径，否则nil
 */
+ (NSString *)moveDownloadFileToCache:(NSString *)hostPath
                             downPath:(NSString *)downFilePath;

+ (NSURLConnection *) httpGetFileDownLoadWithURL:(NSURL *)fileUrl headers:(NSArray*)headers delegate:(id)delegate;

+ (BOOL)checkValidEmail:(NSString*)emailAdderss;
+ (NSMutableDictionary*)compressingImgDic;
+ (void)setCompressImgDic:(NSMutableDictionary*)dic;
+ (BOOL)checkImages:(NSString*)ext;
+ (BOOL)checkValidMobileNumber:(NSString *)mobileNum;
+ (BOOL)checkValidPassword:(NSString *)password;
+ (BOOL)checkValidSerialNumber:(NSString *)sn;
+ (BOOL)isSameDay:(NSDate*)date1 date2:(NSDate*)date2;
/**
    用QLPreviewControler和后缀名结合判断是否能够打开指定路径的文件
    add by libing 2013-6-26  for fix bugID55854，58438
 */
+ (BOOL)itemCanOpenWithPath:(NSString *)path;

+ (NSString *)deviceModel;
@end
