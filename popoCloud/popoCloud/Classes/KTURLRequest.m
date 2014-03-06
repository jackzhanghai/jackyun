//
//  KTURLRequest.m
//  popoCloud
//
//  Created by suleyu on 13-8-26.
//
//

#import "KTURLRequest.h"
#import "JSON.h"
#import "PCUtility.h"
#import "PCLogin.h"
#import "PCUtilityStringOperate.h"

NSString* KTNetworkErrorDomain = @"KTNetworkErrorDomain";
NSString* KTServerErrorDomain = @"KTServerErrorDomain";

@implementation KTURLRequest

@synthesize resultData;
@synthesize statusCode;
@synthesize error;

- (void) dealloc {
    [urlConnection cancel];
    [urlConnection release];
    [resultData release];
    [error release];
    
    [_protocol release];
    [_method release];
    [_urlServer release];
    [_process release];
    [_params release];
    [_headers release];
    [_body release];
    [super dealloc];
}

- (id)initWithTarget:(id)aTarget selector:(SEL)aSelector {
    if (self = [super init]) {
        target = aTarget;
        selector = aSelector;
        self.timeoutSeconds = TIMEOUT_INTERVAL;
    }
    return self;
}

- (BOOL)bNeedAppendToken
{
    return     ![self.process hasPrefix:@"accounts/"]&&
    ![self.process isEqualToString:@"Login"]&&
    [PCSettings sharedSettings].bSessionSupported;
}

- (void)start {
    if (urlConnection) {
        [urlConnection cancel];
        [urlConnection release];
        urlConnection = nil;
    }
    
    NSMutableURLRequest *urlRequest = nil;
    
    //组合的基本URL字符串
    NSMutableString *urlString = [[NSMutableString alloc] initWithFormat:@"%@://%@/%@",
                                  self.protocol ? self.protocol : @"http",
                                  self.urlServer,
                                  self.process];
    
    //组合参数字符串
    NSMutableString *mParamsString = [[NSMutableString alloc] init];
    NSEnumerator *enumerator = [self.params keyEnumerator];
    id key;
    if (key = [enumerator nextObject]) {
        while (YES) {
            NSString *value = [self.params objectForKey:key];
            [mParamsString appendFormat:@"%@=%@", key, value];
            
            key = [enumerator nextObject];
            if (key == nil) {
                break;
            }
            
            [mParamsString appendString:@"&"];
        }
        //添加token
        if ([self bNeedAppendToken]) {
            [mParamsString appendString:@"&"];
            [mParamsString appendFormat:@"%@=%@", @"token_id",[PCLogin getToken] ];
            [mParamsString appendString:@"&"];
            [mParamsString appendFormat:@"%@=%@", @"client_id",[[UIDevice currentDevice] uniqueDeviceIdentifier] ];
        }
    }
    else{
        if ([self bNeedAppendToken]){
            //添加token
            [mParamsString appendFormat:@"%@=%@", @"token_id",[PCLogin getToken] ];
            [mParamsString appendString:@"&"];
            [mParamsString appendFormat:@"%@=%@", @"client_id",[[UIDevice currentDevice] uniqueDeviceIdentifier] ];
        }
    }

    //根据请求方法，讲参数字符串设置到对应的位置
    if (self.method == nil || [self.method isEqualToString:@"GET"])
    {
        if (mParamsString.length > 0)
        {
            [urlString appendFormat:@"?%@", mParamsString];
        }
        
        NSURL *url = [NSURL URLWithString:urlString];
        urlRequest = [[NSMutableURLRequest alloc] initWithURL:url
                                                  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                              timeoutInterval:self.timeoutSeconds];
        [urlRequest setHTTPMethod:@"GET"];
        DLogInfo(@"GET: %@", urlString);
    }
    else
    {
        NSURL *url = [NSURL URLWithString:urlString];
        urlRequest = [[NSMutableURLRequest alloc] initWithURL:url
                                                  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                              timeoutInterval:self.timeoutSeconds];
        
        if (mParamsString.length > 0)
        {
            NSData *bodyData = [mParamsString dataUsingEncoding:NSUTF8StringEncoding];
            [urlRequest setHTTPBody:bodyData];
            [urlRequest setValue:[NSString stringWithFormat:@"%d", bodyData.length] forHTTPHeaderField:@"Content-Length"];
            [urlRequest setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=UTF-8"] forHTTPHeaderField:@"Content-Type"];
        }
        else if (self.body) {
            [urlRequest setHTTPBody:self.body];
            [urlRequest setValue:[NSString stringWithFormat:@"%d", self.body.length] forHTTPHeaderField:@"Content-Length"];
            [urlRequest setValue:[NSString stringWithFormat:@"application/octet-stream"] forHTTPHeaderField:@"Content-Type"];
        }
        
        [urlRequest setHTTPMethod: @"POST"];
        DLogInfo(@"POST: %@, data: %@", urlString, mParamsString);
    }
    
    for (NSString *key in [self.headers allKeys])
    {
        NSString * value = [self.headers objectForKey:key];
        [urlRequest setValue:value forHTTPHeaderField:key];
    }
    
    urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    [urlRequest release];
    [urlString release];
    [mParamsString release];
}

- (void)cancel {
    if (urlConnection) {
        [urlConnection cancel];
        [urlConnection release];
        urlConnection = nil;
    }
}

- (NSString*)resultString {
    return [[[NSString alloc]
             initWithData:resultData encoding:NSUTF8StringEncoding]
            autorelease];
}

- (NSObject*)resultJSON {
    return [[self resultString] JSONValue];
}

#pragma mark NSURLConnectionDataDelegate methods

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    statusCode = [(NSHTTPURLResponse*)response statusCode];
    if (resultData) {
        [resultData setLength:0];
    }
    else {
        resultData = [NSMutableData new];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)incomingData {
    [resultData appendData:incomingData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (statusCode != 200) {
        DLogError(@"statusCode: %d", statusCode);
        NSString* resultString = [self resultString];
        error = [[NSError alloc] initWithDomain:KTNetworkErrorDomain
                                           code:statusCode
                                       userInfo:[NSDictionary dictionaryWithObject:resultString forKey:@"errorMessage"]];
    }
    
    if ([self.process isEqualToString:@"accounts/getAccessToken"]) {
        for (id  tmpTarget in [[PCLogin sharedManager] getTargets]) {
            if ([tmpTarget respondsToSelector:@selector(requestDidGotAccessToken:)]) {
                [tmpTarget performSelector:selector withObject:self];
            }
         }
        [[PCLogin sharedManager] clearTargets];
        [[PCLogin sharedManager] setGetTokenState:NO];
    }
    else{
        [target performSelector:selector withObject:self];
    }
    
    //[target performSelector:selector withObject:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)conError {
    DLogWarn(@"connection error: %d, %@", conError.code, conError.localizedDescription);
    error = [conError retain];
    
    if ([self.process isEqualToString:@"accounts/getAccessToken"]) {
        for (id  tmpTarget in [[PCLogin sharedManager] getTargets]) {
            if ([tmpTarget respondsToSelector:@selector(requestDidGotAccessToken:)]) {
                [tmpTarget performSelector:selector withObject:self];
            }
        }
        [[PCLogin sharedManager] clearTargets];
        [[PCLogin sharedManager] setGetTokenState:NO];
    }
    else{
        [target performSelector:selector withObject:self];
    }

    //[target performSelector:selector withObject:self];
}

- (void)connection:(NSURLConnection*)connection didSendBodyData:(NSInteger)bytesWritten {
}

@end
