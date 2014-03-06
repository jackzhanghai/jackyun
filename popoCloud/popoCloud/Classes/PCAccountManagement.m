//
//  PCAccountManagement.m
//  popoCloud
//
//  Created by leijun on 13-8-27.
//
//

#import "PCAccountManagement.h"
#import "PCUtilityStringOperate.h"
#import "PCUtilityEncryptionAlgorithm.h"

@interface PCAccountManagement () {
    NSMutableSet* requests;
}
@end
@implementation PCAccountManagement
@synthesize delegate;
- (id)init {
    if (self = [super init])
    {
        requests = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self cancelAllRequests];
    [requests release];
    [super dealloc];
}

- (void)cancelAllRequests
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    for (KTURLRequest* request in requests) {
        [request cancel];
    }
    [requests removeAllObjects];
}
#pragma 取得用户信息
-(void)getUserInfo
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishGetUserInfo:)];
    request.urlServer = SERVER_HOST;
    request.process = @"accounts/getUserInfo";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:[[PCUserInfo currentUser] userId], @"username",
                      [[PCUserInfo currentUser] password], @"password", nil];
    [request start];
    [requests addObject:request];
    [request release];
}
- (void)requestDidFinishGetUserInfo:(KTURLRequest *)request
{
    if (request.error)
    {
        if ([delegate respondsToSelector:@selector(getUserInfoFailed:withError:)])
        {
            [delegate getUserInfoFailed:self withError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict)
        {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                [PCUserInfo setCurrentUserWithServerInfo:[dict valueForKey:@"user"]];
                if ([delegate respondsToSelector:@selector(getUserInfoSuccess:)])
                {
                    [delegate getUserInfoSuccess:self];
                }
            }
            else
            {
                if ([delegate respondsToSelector:@selector(getUserInfoFailed:withError:)])
                {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate getUserInfoFailed:self withError:error];
                }
            }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(getUserInfoFailed:withError:)])
            {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate getUserInfoFailed:self withError:error];
            }
        }
    }
    [requests removeObject:request];
}
#pragma 绑定邮箱
-(void)bindEmail:(NSString *)email
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishBindEmail:)];
    request.urlServer = SERVER_HOST;
    request.process = @"accounts/bindingEmail";
    request.method = @"POST";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:[[PCUserInfo currentUser] userId], @"username",
                                                                [[PCUserInfo currentUser] password], @"password",
                                                                email,@"email", nil];
    [request start];
    [requests addObject:request];
    [request release];
}
- (void)requestDidFinishBindEmail:(KTURLRequest *)request
{
    if (request.error)
    {
        if ([delegate respondsToSelector:@selector(bindEmailFailed:withError:)])
        {
            [delegate bindEmailFailed:self withError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict)
        {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                if ([delegate respondsToSelector:@selector(bindEmailSuccess:)])
                {
                    [delegate bindEmailSuccess:self];
                }
            }
            else
            {
                if ([delegate respondsToSelector:@selector(bindEmailFailed:withError:)])
                {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate bindEmailFailed:self withError:error];
                }
            }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(bindEmailFailed:withError:)])
            {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate bindEmailFailed:self withError:error];
            }
        }
    }
    [requests removeObject:request];
}
#pragma 解绑邮箱
-(void)unbindEmailWithPassword:(NSString *)password
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishUnbindEmail:)];
    request.urlServer = SERVER_HOST;
    request.process = @"accounts/unbindingEmail";
    request.method = @"POST";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:[[PCUserInfo currentUser] userId], @"username",
                      [PCUtilityEncryptionAlgorithm md5:password], @"password",
                      [[PCUserInfo currentUser] email],@"email", nil];
    [request start];
    [requests addObject:request];
    [request release];

}
- (void)requestDidFinishUnbindEmail:(KTURLRequest *)request
{
    if (request.error)
    {
        if ([delegate respondsToSelector:@selector(unbindEmailFailed:withError:)])
        {
            [delegate unbindEmailFailed:self withError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict)
        {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                if ([delegate respondsToSelector:@selector(unbindEmailSuccess:)])
                {
                    [delegate unbindEmailSuccess:self];
                }
            }
            else
            {
                if ([delegate respondsToSelector:@selector(unbindEmailFailed:withError:)])
                {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate unbindEmailFailed:self withError:error];
                }
            }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(unbindEmailFailed:withError:)])
            {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate unbindEmailFailed:self withError:error];
            }
        }
    }
    [requests removeObject:request];
}
#pragma 绑定手机
-(void)bindPhone:(NSString *)phone verifyCode:(NSString *)code
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishBindPhone:)];
    request.urlServer = SERVER_HOST;
    request.process = @"accounts/bindingMobile";
    request.method = @"POST";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      [[PCUserInfo currentUser] userId], @"username",
                      [[PCUserInfo currentUser] password], @"password",
                      [PCUtilityStringOperate encodeToPercentEscapeString:phone], @"mobile",
                      code, @"verifyCode",nil];
    [request start];
    [requests addObject:request];
    [request release];
}
- (void)requestDidFinishBindPhone:(KTURLRequest *)request
{
    if (request.error)
    {
        if ([delegate respondsToSelector:@selector(bindPhoneFailed:withError:)])
        {
            [delegate bindPhoneFailed:self withError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict)
        {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                if ([delegate respondsToSelector:@selector(bindPhoneSuccess:)])
                {
                    [delegate bindPhoneSuccess:self];
                }
            }
            else
            {
                if ([delegate respondsToSelector:@selector(bindPhoneFailed:withError:)])
                {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate bindPhoneFailed:self withError:error];
                }
            }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(bindPhoneFailed:withError:)])
            {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate bindPhoneFailed:self withError:error];
            }
        }
    }
    [requests removeObject:request];
}
#pragma 解绑手机
-(void)unbindPhoneWithPassword:(NSString *)password
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishUnbindPhone:)];
    request.urlServer = SERVER_HOST;
    request.process = @"accounts/unbindingMobile";
    request.method = @"POST";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:[[PCUserInfo currentUser] userId], @"username",
                      [PCUtilityEncryptionAlgorithm md5:password], @"password",
                      [[PCUserInfo currentUser] phone],@"mobile",nil];
    [request start];
    [requests addObject:request];
    [request release];
}
- (void)requestDidFinishUnbindPhone:(KTURLRequest *)request
{
    if (request.error)
    {
        if ([delegate respondsToSelector:@selector(unbindPhoneFailed:withError:)])
        {
            [delegate unbindPhoneFailed:self withError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict)
        {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                if ([delegate respondsToSelector:@selector(unbindPhoneSuccess:)])
                {
                    [delegate unbindPhoneSuccess:self];
                }
            }
            else
            {
                if ([delegate respondsToSelector:@selector(unbindPhoneFailed:withError:)])
                {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate unbindPhoneFailed:self withError:error];
                }
            }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(unbindPhoneFailed:withError:)])
            {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate unbindPhoneFailed:self withError:error];
            }
        }
    }
    [requests removeObject:request];
}
#pragma 取得安全问题
-(void)getSecurityQuestions
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishGetSecurityQuestions:)];
    request.urlServer = SERVER_HOST;
    request.process = @"accounts/getSecurityQuestions";
    [request start];
    [requests addObject:request];
    [request release];
}
- (void)requestDidFinishGetSecurityQuestions:(KTURLRequest *)request
{
    if (request.error)
    {
        if ([delegate respondsToSelector:@selector(getSecurityQuestionsFailed:withError:)])
        {
            [delegate getSecurityQuestionsFailed:self withError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict)
        {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                if ([delegate respondsToSelector:@selector(getSecurityQuestionsSuccess:withQuestions:)])
                {
                    [delegate getSecurityQuestionsSuccess:self withQuestions:[dict valueForKey:@"securityQuestions"]];
                }
            }
            else
            {
                if ([delegate respondsToSelector:@selector(getSecurityQuestionsFailed:withError:)])
                {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate getSecurityQuestionsFailed:self withError:error];
                }
            }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(getSecurityQuestionsFailed:withError:)])
            {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate getSecurityQuestionsFailed:self withError:error];
            }
        }
    }
    [requests removeObject:request];
}
#pragma 提交安全问题和答案
-(void)submitSecurityQuestionsAndAnswer:(NSDictionary *)info
{
    NSMutableString *answers = [NSMutableString string];
    NSEnumerator *enumerator = [info keyEnumerator];
    id key;
    if (key = [enumerator nextObject]) {
        while (YES) {
            [answers appendFormat:@"%@,%@", key, info[key]];
            
            key = [enumerator nextObject];
            if (key == nil) {
                break;
            }
            
            [answers appendString:@"&answers="];
        }
    }

    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishSubmitSecurityQuestionsAndAnswer:)];
    request.urlServer = SERVER_HOST;
    request.process = @"accounts/saveUserSecurityQuestions";
    request.method = @"POST";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:[[PCUserInfo currentUser] userId], @"username",
                      [[PCUserInfo currentUser] password], @"password",
                      answers, @"answers",nil];
    [request start];
    [requests addObject:request];
    [request release];
}
- (void)requestDidFinishSubmitSecurityQuestionsAndAnswer:(KTURLRequest *)request
{
    if (request.error)
    {
        if ([delegate respondsToSelector:@selector(submitSecurityQuestionsFailed:withError:)])
        {
            [delegate submitSecurityQuestionsFailed:self withError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict)
        {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                if ([delegate respondsToSelector:@selector(submitSecurityQuestionsSuccess:)])
                {
                    [delegate submitSecurityQuestionsSuccess:self];
                }
            }
            else
            {
                if ([delegate respondsToSelector:@selector(submitSecurityQuestionsFailed:withError:)])
                {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate submitSecurityQuestionsFailed:self withError:error];
                }
            }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(submitSecurityQuestionsFailed:withError:)])
            {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate submitSecurityQuestionsFailed:self withError:error];
            }
        }
    }
    [requests removeObject:request];
}

#pragma 销毁帐号
-(void)destroyAccountWithPassword:(NSString *)password
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishDestroyAccount:)];
    request.urlServer = SERVER_HOST;
    request.method = @"POST";
    request.process = @"accounts/destroyAccount";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:[[PCUserInfo currentUser] userId], @"username",
                      [PCUtilityEncryptionAlgorithm md5:password], @"password", nil];
    [request start];
    [requests addObject:request];
    [request release];
}

- (void)requestDidFinishDestroyAccount:(KTURLRequest *)request
{
    if (request.error)
    {
        if ([delegate respondsToSelector:@selector(destroyAccountFailed:withError:)])
        {
            [delegate destroyAccountFailed:self withError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict)
        {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                if ([delegate respondsToSelector:@selector(destroyAccountSuccess:)])
                {
                    [delegate destroyAccountSuccess:self];
                }
            }
            else
            {
                if ([delegate respondsToSelector:@selector(destroyAccountFailed:withError:)])
                {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate destroyAccountFailed:self withError:error];
                }
            }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(destroyAccountFailed:withError:)])
            {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate destroyAccountFailed:self withError:error];
            }
        }
    }
    [requests removeObject:request];
}

@end
