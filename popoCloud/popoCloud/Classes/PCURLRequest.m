//
//  PCURLRequest.m
//  popoCloud
//
//  Created by suleyu on 13-8-26.
//
//

#import "PCURLRequest.h"
#import "NetPenetrate.h"
#import "PCLogin.h"
#import "PCUtilityUiOperate.h"

@interface PCURLRequest ()
{
    BOOL isCanceled;
    int networkState;
}
@end

@implementation PCURLRequest

- (void)start {
    isCanceled = NO;
    
    if (self.urlServer.length > 0) {
        networkState = -1;
        [super start];
        return;
    }
    
    networkState = [[NetPenetrate sharedInstance] gCurrentNetworkState];
    switch (networkState) {
        case CURRENT_NETWORK_STATE_LOCAL:
            self.urlServer = [[NetPenetrate sharedInstance] defaultLanUrl];
            break;
            
        case CURRENT_NETWORK_STATE_NAT:
            self.urlServer = [[NetPenetrate sharedInstance] defaultNatUrl];
            break;
            
        default:
            self.urlServer = [[NetPenetrate sharedInstance] defaultHubUrl];
            break;
    }
    
    [super start];
}

- (void)cancel {
    isCanceled = YES;
    [super cancel];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)conError {
    if(networkState == CURRENT_NETWORK_STATE_LOCAL || networkState == CURRENT_NETWORK_STATE_NAT)
    {
        networkState = CURRENT_NETWORK_STATE_DEFAULT;
        self.urlServer = [[NetPenetrate sharedInstance] defaultHubUrl];
        [super start];
    }
    else
    {
        [super connection:connection didFailWithError:conError];
    }
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSDictionary *dict = (NSDictionary *)[self resultJSON];
    if (dict) {
        int result = [[dict valueForKey:@"result"] intValue];
        if ((result == 1) && ([[dict valueForKey:@"errCode"] intValue] == 1028 || [[dict valueForKey:@"errCode"] intValue] == 1029)){
            [PCLogin setToken:nil];
            [[PCLogin sharedManager]  getAccessToken:self];
        }
        else{
            [super  connectionDidFinishLoading:connection];
        }
    }
    else{
        [super  connectionDidFinishLoading:connection];
    }
}

- (void)gotAccessToken:(NSDictionary*)result
{
    NSString *newToken = [result objectForKey:@"token"];
    [PCLogin  setToken:newToken];
    [super start];
}

- (void)getAccessTokenFailedWithError:(NSError*)error2
{
    if (isCanceled)
        return;
    
    // 可能导致重复的错误提示
    // [ErrorHandler showErrorAlert:error2];
    DLogWarn(@"connection error: %d, %@", error2.code, error2.localizedDescription);
    error = [error2 retain];
    [target performSelector:selector withObject:self];
}

- (void)requestDidGotAccessToken:(KTURLRequest *)request
{
    if (isCanceled)
        return;
    
    if (request.error) {
        [self  getAccessTokenFailedWithError:request.error];
    }
    else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                [self gotAccessToken:dict];
            }
            else {
                if ([dict objectForKey:@"errCode"]) {
                    result = [[dict objectForKey:@"errCode"] intValue];
                }
                NSError *error2 = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                [ErrorHandler showErrorAlert:error2];
                [PCUtilityUiOperate logout];
            }
        }
        else {
            NSError *error2 = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
            [self  getAccessTokenFailedWithError:error2];
        }
    }
}

@end
