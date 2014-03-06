//
//  PCAuthentication.m
//  popoCloud
//
//  Created by suleyu on 13-8-26.
//
//

#import "PCAuthentication.h"
#import "PCUserInfo.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "PCUtilityEncryptionAlgorithm.h"
#import "PCURLRequest.h"

@interface PCAuthentication () {
    NSMutableSet* requests;
}
@end

@implementation PCAuthentication
@synthesize delegate;

- (id)init {
    if (self = [super init]) {
        requests = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self cancelAllRequests];
    [requests release];
    [super dealloc];
}

- (void)cancelAllRequests {
    for (KTURLRequest* request in requests) {
        [request cancel];
    }
    [requests removeAllObjects];
}

- (void)login:(NSString *)username password:(NSString *)password
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishLogin:)];
    request.urlServer = SERVER_HOST;
    request.method = @"POST";
    request.process = @"accounts/login";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      [PCUtilityStringOperate encodeToPercentEscapeString:username], @"username",
                      [PCUtilityEncryptionAlgorithm md5:password], @"password", nil];
    [request start];
    
    [requests addObject:request];
    [request release];
}

- (void)requestDidFinishLogin:(KTURLRequest *)request
{
    if (request.error) {
        if ([delegate respondsToSelector:@selector(loginFailed:withError:)]) {
            [delegate loginFailed:self withError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                [PCUserInfo setCurrentUserWithServerInfo:[dict valueForKey:@"user"]];
                [PCUserInfo currentUser].password = [request.params valueForKey:@"password"];
                
                if ([delegate respondsToSelector:@selector(loginFinished:)]) {
                    [delegate loginFinished:self];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(loginFailed:withError:)]) {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate loginFailed:self withError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(loginFailed:withError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate loginFailed:self withError:error];
            }
        }
    }
    
    [requests removeObject:request];
}
#pragma 手机注册
- (void)registWithPhoneNum:(NSString *)phone password:(NSString *)password verifyCode:(NSString *)code
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishPhoneRegist:)];
    request.urlServer = SERVER_HOST;
    request.method = @"POST";
    request.process = @"accounts/register";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      [PCUtilityStringOperate encodeToPercentEscapeString:phone], @"username",
                      [PCUtilityEncryptionAlgorithm md5:password], @"password",code,@"verifyCode", nil];
    [request start];
    
    [requests addObject:request];
    [request release];
}
-(void)requestDidFinishPhoneRegist:(KTURLRequest *)request
{
    if (request.error) {
        if ([delegate respondsToSelector:@selector(phoneRegistFailed:withError:)]) {
            [delegate phoneRegistFailed:self withError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                [PCUserInfo setCurrentUserWithServerInfo:[dict valueForKey:@"user"]];
                [PCUserInfo currentUser].password = [request.params valueForKey:@"password"];
                
                if ([delegate respondsToSelector:@selector(phoneRegistSuccess:)]) {
                    [delegate phoneRegistSuccess:self];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(phoneRegistFailed:withError:)]) {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate phoneRegistFailed:self withError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(phoneRegistFailed:withError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate phoneRegistFailed:self withError:error];
            }
        }
    }
    
    [requests removeObject:request];
}
#pragma 邮箱注册
- (void)registWithEmail:(NSString *)email password:(NSString *)password
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishEmailRegist:)];
    request.urlServer = SERVER_HOST;
    request.method = @"POST";
    request.process = @"accounts/register";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:email, @"username",
                      [PCUtilityEncryptionAlgorithm md5:password], @"password",nil];
    [request start];
    
    [requests addObject:request];
    [request release];
}
-(void)requestDidFinishEmailRegist:(KTURLRequest *)request
{
    if (request.error) {
        if ([delegate respondsToSelector:@selector(emailRegistFailed:withError:)]) {
            [delegate emailRegistFailed:self withError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                [PCUserInfo setCurrentUserWithServerInfo:[dict valueForKey:@"user"]];
                if ([delegate respondsToSelector:@selector(emailRegistSuccess:)]) {
                    [delegate emailRegistSuccess:self];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(emailRegistFailed:withError:)]) {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate emailRegistFailed:self withError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(emailRegistFailed:withError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate emailRegistFailed:self withError:error];
            }
        }
    }
    
    [requests removeObject:request];
}

#pragma 手机重置密码
- (void)resetPasswordWithPhoneNum:(NSString *)phone password:(NSString *)password verifyCode:(NSString *)code
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishResetPasswordWithPhoneNum:)];
    request.urlServer = SERVER_HOST;
    request.method = @"POST";
    request.process = @"accounts/saveNewPassword";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      [PCUtilityStringOperate encodeToPercentEscapeString:phone], @"username",
                      [PCUtilityEncryptionAlgorithm md5:password], @"password",
                      code, @"verifyCode", nil];
    [request start];
    
    [requests addObject:request];
    [request release];
}

-(void)requestDidFinishResetPasswordWithPhoneNum:(KTURLRequest *)request
{
    if (request.error) {
        if ([delegate respondsToSelector:@selector(phoneResetPasswordFailed:withError:)]) {
            [delegate phoneResetPasswordFailed:self withError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                if ([delegate respondsToSelector:@selector(phoneResetPasswordSuccess:)]) {
                    [delegate phoneResetPasswordSuccess:self];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(phoneResetPasswordFailed:withError:)]) {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate phoneResetPasswordFailed:self withError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(phoneResetPasswordFailed:withError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate phoneResetPasswordFailed:self withError:error];
            }
        }
    }
    
    [requests removeObject:request];
}

#pragma 邮箱重置密码
- (void)resetPasswordWithEmailVerifyCode:(NSString *)code andNewPW:(NSString*)pw andEmail:(NSString*)email
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishResetPassword:)];
    request.urlServer = SERVER_HOST;
    request.method = @"POST";
    request.process = @"accounts/saveNewPassword";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:code, @"verifyCode", [PCUtilityEncryptionAlgorithm md5:pw],@"password",email,@"username",nil];
    [request start];
    
    [requests addObject:request];
    [request release];
}

#pragma 获取邮箱重置密码的验证码
- (void)getResetPasswordVerifyCodeWithEmail:(NSString *)email
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishGetResetPasswordVerifyCodeForEmail:)];
    request.urlServer = SERVER_HOST;
    request.method = @"POST";
    request.process = @"accounts/sendResetPwdVerifyCodeByEmail";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:email, @"email",nil];
    [request start];
    
    [requests addObject:request];
    [request release];
}

- (void)requestDidFinishResetPassword:(KTURLRequest *)request
{
    if (request.error) {
        if ([delegate respondsToSelector:@selector(emailResetPasswordFailed:withError:)]) {
            [delegate emailResetPasswordFailed:self withError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                if ([delegate respondsToSelector:@selector(emailResetPasswordSuccess:withInfo:)]) {
                    [delegate emailResetPasswordSuccess:self withInfo:dict];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(emailResetPasswordFailed:withError:)]) {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate emailResetPasswordFailed:self withError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(emailResetPasswordFailed:withError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate emailResetPasswordFailed:self withError:error];
            }
        }
    }
    
    [requests removeObject:request];
}

-(void)requestDidFinishGetResetPasswordVerifyCodeForEmail:(KTURLRequest *)request
{
    if (request.error) {
        if ([delegate respondsToSelector:@selector(emailGetResetPasswordVerifyCodeFailed:withError:)]) {
            [delegate emailGetResetPasswordVerifyCodeFailed:self withError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                if ([delegate respondsToSelector:@selector(emailGetResetPasswordVerifyCodeSuccess:withInfo:)]) {
                    [delegate emailGetResetPasswordVerifyCodeSuccess:self withInfo:dict];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(emailGetResetPasswordVerifyCodeFailed:withError:)]) {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate emailGetResetPasswordVerifyCodeFailed:self withError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(emailGetResetPasswordVerifyCodeFailed:withError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate emailGetResetPasswordVerifyCodeFailed:self withError:error];
            }
        }
    }
    
    [requests removeObject:request];
}

#pragma 发送激活邮件
- (void)sendVerifyEmail:(NSString *)email password:(NSString *)password
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishSendVerifyEmail:)];
    request.urlServer = SERVER_HOST;
    request.method = @"POST";
    request.process = @"accounts/sendVerifyEmail";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:email, @"email",
                      [PCUtilityEncryptionAlgorithm md5:password], @"password",nil];
    [request start];
    
    [requests addObject:request];
    [request release];
}
-(void)requestDidFinishSendVerifyEmail:(KTURLRequest *)request
{
    if (request.error) {
        if ([delegate respondsToSelector:@selector(sendVerifyEmailFailed:withError:)]) {
            [delegate sendVerifyEmailFailed:self withError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                [PCUserInfo setCurrentUserWithServerInfo:[dict valueForKey:@"user"]];
                if ([delegate respondsToSelector:@selector(sendVerifyEmailSuccess:)]) {
                    [delegate sendVerifyEmailSuccess:self];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(sendVerifyEmailFailed:withError:)]) {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate sendVerifyEmailFailed:self withError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(sendVerifyEmailFailed:withError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate sendVerifyEmailFailed:self withError:error];
            }
        }
    }
    
    [requests removeObject:request];
}

@end
