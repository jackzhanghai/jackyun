//
//  PCAuthentication.h
//  popoCloud
//
//  Created by suleyu on 13-8-26.
//
//

#import <Foundation/Foundation.h>
#import "KTURLRequest.h"

@protocol PCAuthenticationDelegate;
@class PCUserInfo;

@interface PCAuthentication : NSObject

@property (nonatomic, assign) id<PCAuthenticationDelegate> delegate;

- (void)login:(NSString *)username password:(NSString *)password;
/**
 * 手机注册
 * @param phone=手机号  password=密码    code=验证码
 */
- (void)registWithPhoneNum:(NSString *)phone password:(NSString *)password verifyCode:(NSString *)code;
/**
 * 邮箱注册
 * @param email=邮箱  password=密码
 */
- (void)registWithEmail:(NSString *)email password:(NSString *)password;
/**
 * 手机重置密码
 * @param phone=手机号  password=密码    code=验证码
 */
- (void)resetPasswordWithPhoneNum:(NSString *)phone password:(NSString *)password verifyCode:(NSString *)code;
/**
 * 邮箱重置密码
 * @param email=邮箱
 */
- (void)getResetPasswordVerifyCodeWithEmail:(NSString *)email;
- (void)resetPasswordWithEmailVerifyCode:(NSString *)code andNewPW:(NSString*)pw andEmail:(NSString*)email;
/**
 * 发送激活邮件
 * @param email=邮箱  password=密码
 */
- (void)sendVerifyEmail:(NSString *)email password:(NSString *)password;
@end


@protocol PCAuthenticationDelegate <NSObject>

@optional

- (void)loginFinished:(PCAuthentication *)pcAuthentication;
- (void)loginFailed:(PCAuthentication *)pcAuthentication withError:(NSError *)error;
/**
 * 手机注册回调
 */
- (void)phoneRegistSuccess:(PCAuthentication *)pcAuthentication;
- (void)phoneRegistFailed:(PCAuthentication *)pcAuthentication withError:(NSError *)error;
/**
 * 邮箱注册回调
 */
- (void)emailRegistSuccess:(PCAuthentication *)pcAuthentication;
- (void)emailRegistFailed:(PCAuthentication *)pcAuthentication withError:(NSError *)error;
/**
 * 手机重置密码回调
 */
- (void)phoneResetPasswordSuccess:(PCAuthentication *)pcAuthentication;
- (void)phoneResetPasswordFailed:(PCAuthentication *)pcAuthentication withError:(NSError *)error;
/**
 * 邮箱获取 验证码 和   重置密码回调
 */
- (void)emailGetResetPasswordVerifyCodeSuccess:(PCAuthentication *)pcAuthentication withInfo:(NSDictionary *)dict;
- (void)emailGetResetPasswordVerifyCodeFailed:(PCAuthentication *)pcAuthentication withError:(NSError *)error;

- (void)emailResetPasswordSuccess:(PCAuthentication *)pcAuthentication withInfo:(NSDictionary *)dict;
- (void)emailResetPasswordFailed:(PCAuthentication *)pcAuthentication withError:(NSError *)error;
/**
 * 发送激活邮件回调
 */
- (void)sendVerifyEmailSuccess:(PCAuthentication *)pcAuthentication;
- (void)sendVerifyEmailFailed:(PCAuthentication *)pcAuthentication withError:(NSError *)error;
@end
