//
//  PCShareServices.h
//  popoCloud
//
//  Created by leijun on 13-9-2.
//
//

#import <Foundation/Foundation.h>
#import "PCURLRequest.h"
@class PCShareServices;
@protocol PCShareServicesDelegate <NSObject>
@optional
/**
 * 用指定路径取得分享url 回调
 */
-(void)getShareURLWithPathSuccess:(PCShareServices *)pcShareServices withUrl:(NSString *)shareUrl accessCode:(NSString *)accessCode;
-(void)getShareURLWithPathFailed:(PCShareServices *)pcShareServices withError:(NSError *)error;
/**
 * 取得所有分享文件 回调
 */
-(void)getAllShareFilesSuccess:(PCShareServices *)pcShareServices withFileArray:(NSArray *)fileArray;
-(void)getAllShareFilesFailed:(PCShareServices *)pcShareServices withError:(NSError *)error;

/**
 * 删除分享文件
 */
-(void)deleteShareFileWithIDSuccess:(PCShareServices *)pcShareServices;
-(void)deleteShareFileWithIDFailed:(PCShareServices *)pcShareServices withError:(NSError *)error;
@end

@interface PCShareServices : NSObject
@property (nonatomic,assign) id<PCShareServicesDelegate> delegate;
- (void)cancelAllRequests;
/**
 * 用指定路径取得分享url
 * @param path 分享的路径
 * @return 
 */
-(void)getShareURLForFile:(NSString *)path withPublic:(BOOL)bPublic;

/**
 * 取得所有分享文件
 * @param
 * @return 
 */
-(void)getAllShareFiles;

/**
 * 删除分享文件 
 * @param shareID 分享的id
 * @return 
 */
-(void)deleteShareFileWithID:(NSString *)shareID;
@end