//
//  NetPenetrate.m
//  popoCloud
//
//  Created by leijun on 13-2-5.
//
//

#import "NetPenetrate.h"
#import "JSON.h"
#import "PCUtility.h"
#import "PCUtilityShareGlobalVar.h"
#import "PCLogin.h"
#import "PCURLRequest.h"
#import "PCUserInfo.h"

@implementation NetPenetrate
@synthesize currentRequest;

static NetPenetrate *_sharedSingleton = nil;

+ (NetPenetrate *)sharedInstance
{
    if (_sharedSingleton == nil)
    {
        _sharedSingleton = [NSAllocateObject([self class], 0, NULL) init];
    }
    
    return _sharedSingleton;
}

#pragma mark - methods from super class

+ (id)allocWithZone:(NSZone *)zone
{
    return [[NetPenetrate sharedInstance] retain];
}

- (id)copyWithZone:(NSZone*)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax; // denotes an object that cannot be released
}

- (oneway void)release {}

- (id)autorelease
{
    return self;
}

- (void)dealloc
{
    [self cancel];
    self.defaultLanUrl = nil;
    self.defaultNatUrl = nil;
    self.defaultHubUrl = nil;
    
    [super dealloc];
}

#pragma mark - public methods

- (BOOL)isPenetrate
{
    return self.gCurrentNetworkState != CURRENT_NETWORK_STATE_DEFAULT;
}

- (void)changePenetrate:(CURRENT_NETWORK_STATE)state
{
    self.gCurrentNetworkState = state;
    switch (state) {
        case CURRENT_NETWORK_STATE_DEFAULT:
            DLogNotice(@"默认hub连接");
            [PCUtilityShareGlobalVar setUrlServer:[NSString stringWithFormat:@"http://%@/", _defaultHubUrl]];
            break;
        case CURRENT_NETWORK_STATE_LOCAL:
            DLogNotice(@"局域网穿透成功");
            [PCUtilityShareGlobalVar setUrlServer:[NSString stringWithFormat:@"http://%@/", _defaultLanUrl]];
            break;
        case CURRENT_NETWORK_STATE_NAT:
            DLogNotice(@"NAT穿透成功");
            [PCUtilityShareGlobalVar setUrlServer:[NSString stringWithFormat:@"http://%@/", _defaultNatUrl]];
            break;
        default:
            break;
    }
    _isChecking = NO;
}

- (void)checkNetPenetrate
{
    if (_isChecking)
        return;
    
    DLogNotice(@"checkNetPenetrate");
    
    if (self.currentRequest)
        [self cancel];
    
    if (_defaultLanUrl)
        [self getPenetrateResult:_defaultLanUrl];
    else if (_defaultNatUrl)
        [self getPenetrateResult:_defaultNatUrl];
    else
        [self changePenetrate:CURRENT_NETWORK_STATE_DEFAULT];
}

#pragma mark - private methods
- (void)getPenetrateResult:(NSString *)urlStr
{
    _isChecking = YES;
    self.currentRequest = [[[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotPenetrateResult:)] autorelease];
    self.currentRequest.process = @"Login";
    
    if ([PCSettings sharedSettings].bSessionSupported)
    {
        self.currentRequest.params = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [PCLogin getResource],  @"sn",
                                      nil];
    }
    else
    {
        self.currentRequest.params = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [[PCUserInfo currentUser] userId] ,  @"username",
                                      [[PCUserInfo currentUser] password] ,  @"password",
                                      [PCLogin getResource],  @"sn",
                                      nil];
    }

    self.currentRequest.urlServer = urlStr;
    self.currentRequest.timeoutSeconds  = HTTP_REQUEST_TIMEOUT;
    [self.currentRequest start];
}

- (void)cancel
{
     if (self.currentRequest) {
        [self.currentRequest cancel];
        self.currentRequest = nil;
    }
}

- (void)requestDidGotPenetrateResult:(KTURLRequest *)request
{
    NSString *host = [request urlServer];
    if (request.error) {
        [self  penetrateDidFailWithError:request.error andHost:host];
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                [self penetrateDidFinishWithDic:dict andHost:host];
            }
            else {
                if ([dict objectForKey:@"errCode"]) {
                    result = [[dict objectForKey:@"errCode"] intValue];
                }
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                 [self  penetrateDidFailWithError:error andHost:host];
            }
        }
        else {
            NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
            [self  penetrateDidFailWithError:error andHost:host];
        }
    }
}

- (void) penetrateDidFinishWithDic:(NSDictionary*)dic andHost:(NSString*)host
{
    DLogNotice(@"checkNetPenetrate.host: %@",host);
    
    if (_defaultLanUrl && [_defaultLanUrl isEqualToString:host])
        [self changePenetrate:CURRENT_NETWORK_STATE_LOCAL];
    else if (_defaultNatUrl && [_defaultNatUrl isEqualToString:host])
        [self changePenetrate:CURRENT_NETWORK_STATE_NAT];
    else
        [self changePenetrate:CURRENT_NETWORK_STATE_DEFAULT];
}

- (void)penetrateDidFailWithError:(NSError *)error andHost:(NSString*)host
{
    //NSString *host = [NSString stringWithString:connection.originalRequest.URL.host];
    DLogNotice(@"checkNetPenetrate.host: %@, error: %d, %@", host, error.code, [error localizedDescription]);
    
    if (_defaultLanUrl && [_defaultLanUrl isEqualToString:host] && _defaultNatUrl)
        [self getPenetrateResult:_defaultNatUrl];
	else
        [self changePenetrate:CURRENT_NETWORK_STATE_DEFAULT];
}

@end
