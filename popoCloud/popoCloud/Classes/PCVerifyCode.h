//
//  PCVerifyCode.h
//  popoCloud
//
//  Created by leijun on 13-8-28.
//
//

#import <Foundation/Foundation.h>
#import "KTURLRequest.h"
#import "PCUserInfo.h"
@class PCVerifyCode;

@protocol PCVerifyCodeDelegate <NSObject>
@optional
-(void)generateVerifyCodeSuccess:(PCVerifyCode*)pcVerifyCode verifyCode:(NSString *)verifyCode;
-(void)generateVerifyCodeFailed:(PCVerifyCode*)pcVerifyCode withError:(NSError *)error;
@end

@interface PCVerifyCode : NSObject
@property (nonatomic,assign) id<PCVerifyCodeDelegate> delegate;
/**
 * 用指定手机号生成验证码
 * @param phone =  手机号
 */
-(void)generateVerifyCodeWithPhoneNum:(NSString *)phone;
/**
 * 修改密码时的验证码
 */
-(void)resetPasswordVerifyCodeWithPhoneNum:(NSString *)phone;
/**
 * 解绑盒子时的验证码
 */
-(void)generateUnbindBoxVerifyCode:(NSString *)username;
@end
