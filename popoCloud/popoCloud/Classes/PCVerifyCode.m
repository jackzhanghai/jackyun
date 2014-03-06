//
//  PCVerifyCode.m
//  popoCloud
//
//  Created by leijun on 13-8-28.
//
//

#import "PCVerifyCode.h"
#import "PCUtilityStringOperate.h"

@interface PCVerifyCode ()
{
     NSMutableSet* requests;
}
@end

@implementation PCVerifyCode
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
-(void)generateVerifyCodeWithPhoneNum:(NSString *)phone
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishGenerateVerifyCode:)];
    request.urlServer = SERVER_HOST;
    request.method = @"POST";
    request.process = @"accounts/sendVerifyCode";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:[PCUtilityStringOperate encodeToPercentEscapeString:phone], @"mobile",nil];
    [request start];
    
    [requests addObject:request];
    [request release];
}
-(void)requestDidFinishGenerateVerifyCode:(KTURLRequest *)request
{
    if (request.error)
    {
        if ([delegate respondsToSelector:@selector(generateVerifyCodeFailed:withError:)])
        {
            [delegate generateVerifyCodeFailed:self withError:request.error];
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
                if ([delegate respondsToSelector:@selector(generateVerifyCodeSuccess:verifyCode:)])
                {
                    NSString *verifyCode = [dict valueForKey:@"verifyCode"];
                    [delegate generateVerifyCodeSuccess:self verifyCode:verifyCode];
                }
            }
            else
            {
                if ([delegate respondsToSelector:@selector(generateVerifyCodeFailed:withError:)])
                {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate generateVerifyCodeFailed:self withError:error];
                }
            }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(generateVerifyCodeFailed:withError:)])
            {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate generateVerifyCodeFailed:self withError:error];
            }
        }
    }
    [requests removeObject:request];
}

-(void)resetPasswordVerifyCodeWithPhoneNum:(NSString *)phone
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishGenerateVerifyCode:)];
    request.urlServer = SERVER_HOST;
    request.method = @"POST";
    request.process = @"accounts/sendResetPasswordVerifyCode";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:[PCUtilityStringOperate encodeToPercentEscapeString:phone], @"mobile",nil];
    [request start];
    
    [requests addObject:request];
    [request release];
}

-(void)generateUnbindBoxVerifyCode:(NSString *)username
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishGenerateVerifyCode:)];
    request.urlServer = SERVER_HOST;
    request.method = @"POST";
    request.process = @"accounts/sendUnbindBoxVerifyCode";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:username, @"username",
                      [[PCUserInfo currentUser] password], @"password", nil];
    [request start];
    
    [requests addObject:request];
    [request release];
}
@end
