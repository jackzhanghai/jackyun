//
//  PCAccountManagement.h
//  popoCloud
//
//  Created by leijun on 13-8-27.
//
//

#import <Foundation/Foundation.h>
#import "KTURLRequest.h"
#import "PCUserInfo.h"
#import "PCUtility.h"
@class PCAccountManagement;

@protocol PCAccountManagementDelegate <NSObject>
@optional
/**
 * 取得用户信息相关回调
 */
-(void)getUserInfoSuccess:(PCAccountManagement*)pcAccountManagement;
-(void)getUserInfoFailed:(PCAccountManagement *)pcAccountManagement withError:(NSError *)error;

/**
 * 绑定邮箱与解除绑定
 */
-(void)bindEmailSuccess:(PCAccountManagement*)pcAccountManagement;
-(void)bindEmailFailed:(PCAccountManagement *)pcAccountManagement withError:(NSError *)error;
-(void)unbindEmailSuccess:(PCAccountManagement*)pcAccountManagement;
-(void)unbindEmailFailed:(PCAccountManagement *)pcAccountManagement withError:(NSError *)error;

/**
 * 绑定手机与解除绑定
 */
-(void)bindPhoneSuccess:(PCAccountManagement*)pcAccountManagement;
-(void)bindPhoneFailed:(PCAccountManagement *)pcAccountManagement withError:(NSError *)error;
-(void)unbindPhoneSuccess:(PCAccountManagement*)pcAccountManagement;
-(void)unbindPhoneFailed:(PCAccountManagement *)pcAccountManagement withError:(NSError *)error;

/**
 * 取得安全问题
 */
-(void)getSecurityQuestionsSuccess:(PCAccountManagement*)pcAccountManagement withQuestions:(NSArray *)questionsArray;
-(void)getSecurityQuestionsFailed:(PCAccountManagement *)pcAccountManagement withError:(NSError *)error;

/**
 * 提交安全问题
 */
-(void)submitSecurityQuestionsSuccess:(PCAccountManagement*)pcAccountManagement;
-(void)submitSecurityQuestionsFailed:(PCAccountManagement *)pcAccountManagement withError:(NSError *)error;
/**
 * 销毁帐号
 */
-(void)destroyAccountSuccess:(PCAccountManagement*)pcAccountManagement;
-(void)destroyAccountFailed:(PCAccountManagement *)pcAccountManagement withError:(NSError *)error;

@end


@interface PCAccountManagement : NSObject

@property (nonatomic, assign) id<PCAccountManagementDelegate> delegate;
/**
 * 取消所有请求
 */
- (void)cancelAllRequests;
/**
 * 取得用户信息
 * 成功之后就把获得数据设置为当前用户信息
 */
-(void)getUserInfo;
/**
 * 绑定邮箱
 */
-(void)bindEmail:(NSString *)email;
/**
 * 解除邮箱绑定
 */
-(void)unbindEmailWithPassword:(NSString *)password;
/**
 * 绑定手机
 */
-(void)bindPhone:(NSString *)phone  verifyCode:(NSString *)code;
/**
 * 解除手机绑定
 */
-(void)unbindPhoneWithPassword:(NSString *)password;
/**
 * 取得安全问题
 */
-(void)getSecurityQuestions;
/**
 * 提交安全问题和答案
 */
-(void)submitSecurityQuestionsAndAnswer:(NSDictionary *)info;
/**
 * 销毁帐号
 */
-(void)destroyAccountWithPassword:(NSString *)password;
@end
