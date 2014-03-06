//
//  PCDeviceManagement.m
//  popoCloud
//
//  Created by suleyu on 13-8-30.
//
//

#import "PCDeviceManagement.h"
#import "PCUserInfo.h"
#import "PCUtilityEncryptionAlgorithm.h"
#import "DeviceInfo.h"
#import "NetPenetrate.h"

@interface PCDeviceManagement () {
    NSMutableSet* requests;
}
@end


@implementation PCDeviceManagement
@synthesize delegate;

- (id)init {
    if (self = [super init]) {
        requests = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self cancelAllRequests];
    [requests release];
    [super dealloc];
}

- (void)cancelAllRequests
{
    for (KTURLRequest* request in requests){
        [request cancel];
    }
    [requests removeAllObjects];
}

- (void)getDeviceList
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotDeviceList:)];
    request.urlServer = SERVER_HOST;
    request.process = @"accounts/list";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:[[PCUserInfo currentUser] userId], @"username",
                      [[PCUserInfo currentUser] password], @"password", nil];
    [request start];
    
    [requests addObject:request];
    [request release];
}

- (void)requestDidGotDeviceList:(KTURLRequest *)request
{
    if (request.error) {
        if ([delegate respondsToSelector:@selector(pcDeviceManagement:getDeviceListFailedWithError:)]) {
            [delegate pcDeviceManagement:self getDeviceListFailedWithError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                NSArray *disks = [dict valueForKey:@"data"];
                NSMutableArray *diskSizeData = [NSMutableArray arrayWithCapacity:disks.count];
                for (NSDictionary *disk in disks) {
                    DeviceInfo *temp = [[DeviceInfo alloc] initWithDic:disk];
                    [diskSizeData addObject:temp];
                    [temp release];
                }
                
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:gotDeviceList:)]) {
                    [delegate pcDeviceManagement:self gotDeviceList:diskSizeData];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:getDeviceListFailedWithError:)]) {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate pcDeviceManagement:self getDeviceListFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(pcDeviceManagement:getDeviceListFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate pcDeviceManagement:self getDeviceListFailedWithError:error];
            }
        }
    }
    
    [requests removeObject:request];
}

-(void)bindBox:(NSString *)serialNumber
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidBoundBox:)];
    request.urlServer = SERVER_HOST;
    request.method = @"POST";
    request.process = @"accounts/activatingBox";
    request.timeoutSeconds = TIMEOUT_INTERVAL_DOWNLOAD;
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:[[PCUserInfo currentUser] userId], @"username",
                      [[PCUserInfo currentUser] password], @"password",
                      serialNumber, @"serialNo", nil];
    [request start];
    
    [requests addObject:request];
    [request release];
}

- (void)requestDidBoundBox:(KTURLRequest *)request
{
    if (request.error) {
        if ([delegate respondsToSelector:@selector(pcDeviceManagement:bindBoxFailedWithError:)]) {
            [delegate pcDeviceManagement:self bindBoxFailedWithError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                NSDictionary *device = [dict valueForKey:@"resource"];
                DeviceInfo *temp = [[[DeviceInfo alloc] initWithDic:device] autorelease];
                
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:boundBox:)]) {
                    [delegate pcDeviceManagement:self boundBox:temp];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:bindBoxFailedWithError:)]) {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate pcDeviceManagement:self bindBoxFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(pcDeviceManagement:bindBoxFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate pcDeviceManagement:self bindBoxFailedWithError:error];
            }
        }
    }
    
    [requests removeObject:request];
}

-(void)unbindBox:(NSString *)verifyCode serialNumber:(NSString *)serialNumber password:(NSString *)password
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidUnboundBox:)];
    request.urlServer = SERVER_HOST;
    request.method = @"POST";
    request.process = @"accounts/unbindBox";
    request.timeoutSeconds = TIMEOUT_INTERVAL_DOWNLOAD;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:4];
    params[@"username"] = [[PCUserInfo currentUser] userId];
    if (verifyCode.length > 0) {
        params[@"verifyCode"] = verifyCode;
    }
    if (serialNumber.length > 0) {
        params[@"serialNo"] = serialNumber;
    }
    if (password.length > 0) {
        params[@"password"] = [PCUtilityEncryptionAlgorithm md5:password];
    }
    request.params = params;
    
    [request start];
    
    [requests addObject:request];
    [request release];
}

- (void)requestDidUnboundBox:(KTURLRequest *)request
{
    if (request.error) {
        if ([delegate respondsToSelector:@selector(pcDeviceManagement:unbindBoxFailedWithError:)]) {
            [delegate pcDeviceManagement:self unbindBoxFailedWithError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:unboundBox:)]) {
                    [delegate pcDeviceManagement:self unboundBox:nil];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:unbindBoxFailedWithError:)]) {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate pcDeviceManagement:self unbindBoxFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(pcDeviceManagement:unbindBoxFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate pcDeviceManagement:self unbindBoxFailedWithError:error];
            }
        }
    }
    
    [requests removeObject:request];
}
-(void)requestDidRenameBox:(KTURLRequest *)request
{
    if (request.error) {
        if ([delegate respondsToSelector:@selector(pcDeviceManagement:renameBoxFailedWithError:)]) {
            [delegate pcDeviceManagement:self renameBoxFailedWithError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:renameBoxSuccess:)]) {
                    [delegate pcDeviceManagement:self renameBoxSuccess:nil];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:renameBoxFailedWithError:)]) {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate pcDeviceManagement:self renameBoxFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(pcDeviceManagement:renameBoxFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate pcDeviceManagement:self renameBoxFailedWithError:error];
            }
        }
    }
    
    [requests removeObject:request];
}

-(void)renameBox:(NSDictionary *)info
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidRenameBox:)];
    request.urlServer = SERVER_HOST;
    request.method = @"POST";
    request.process = @"accounts/renameResourceNickname";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:[[PCUserInfo currentUser] userId], @"username",
                      [[PCUserInfo currentUser] password], @"password",
                      [info objectForKey:@"resourceId"], @"serialNo",
                      [info objectForKey:@"nickName"], @"nickname",nil];
    [request start];
    
    [requests addObject:request];
    [request release];
}

- (void)requestDidGetBoxSystemVersion:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(pcDeviceManagement:getBoxSystemVersionFailedWithError:)]) {
            [delegate pcDeviceManagement:self getBoxSystemVersionFailedWithError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                NSString *version = [dict valueForKey:@"version"];
                
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:gotBoxSystemVersion:)]) {
                    [delegate pcDeviceManagement:self gotBoxSystemVersion:version];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:getBoxSystemVersionFailedWithError:)]) {
                    if ([dict objectForKey:@"errCode"]) {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate pcDeviceManagement:self getBoxSystemVersionFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(pcDeviceManagement:getBoxSystemVersionFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate pcDeviceManagement:self getBoxSystemVersionFailedWithError:error];
            }
        }
    }
}

-(void)getBoxSystemVersion
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGetBoxSystemVersion:)];
    request.process = @"GetSystemVersion";
    [request start];
    
    [requests addObject:request];
    [request release];
}

- (void)requestDidGetBoxNeedUpgrade:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(pcDeviceManagement:getBoxNeedUpgradeFailedWithError:)]) {
            [delegate pcDeviceManagement:self getBoxNeedUpgradeFailedWithError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                BOOL isNeed = [[dict valueForKey:@"isneed"] boolValue];
                BOOL isNecessary = [[dict valueForKey:@"isnecessary"] boolValue];
                
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:gotBoxNeedUpgrade:necessary:)]) {
                    [delegate pcDeviceManagement:self gotBoxNeedUpgrade:isNeed necessary:isNecessary];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:getBoxNeedUpgradeFailedWithError:)]) {
                    if ([dict objectForKey:@"errCode"]) {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate pcDeviceManagement:self getBoxNeedUpgradeFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(pcDeviceManagement:getBoxNeedUpgradeFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate pcDeviceManagement:self getBoxNeedUpgradeFailedWithError:error];
            }
        }
    }
}

-(void)getBoxNeedUpgrade
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGetBoxNeedUpgrade:)];
    request.process = @"IsNeedUpgrade";
    [request start];
    
    [requests addObject:request];
    [request release];
}

- (void)requestDidUpgradeBoxSystem:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(pcDeviceManagement:upgradeBoxSystemWithError:)]) {
            [delegate pcDeviceManagement:self upgradeBoxSystemWithError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:upgradeBoxSystemWithError:)]) {
                    [delegate pcDeviceManagement:self upgradeBoxSystemWithError:nil];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:upgradeBoxSystemWithError:)]) {
                    if ([dict objectForKey:@"errCode"]) {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate pcDeviceManagement:self upgradeBoxSystemWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(pcDeviceManagement:upgradeBoxSystemWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate pcDeviceManagement:self upgradeBoxSystemWithError:error];
            }
        }
    }
}

-(void)upgradeBoxSystem
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidUpgradeBoxSystem:)];
    request.process = @"SystemUpgrade";
    request.urlServer = [[NetPenetrate sharedInstance] defaultHubUrl];
    [request start];
    
    [requests addObject:request];
    [request release];
}

-(void)requestDidModifyPassword:(KTURLRequest *)request
{
    if (request.error) {
        if ([delegate respondsToSelector:@selector(pcDeviceManagement:modifyPasswordFailedWithError:)]) {
            [delegate pcDeviceManagement:self modifyPasswordFailedWithError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:modifyPasswordSuccess:)]) {
                    [delegate pcDeviceManagement:self modifyPasswordSuccess:nil];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(pcDeviceManagement:modifyPasswordFailedWithError:)]) {
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate pcDeviceManagement:self modifyPasswordFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(pcDeviceManagement:modifyPasswordFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate pcDeviceManagement:self modifyPasswordFailedWithError:error];
            }
        }
    }
    
    [requests removeObject:request];
}
-(void)modifyPassword:(NSDictionary *)info
{
    KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:self selector:@selector(requestDidModifyPassword:)];
    request.urlServer = SERVER_HOST;
    request.method = @"POST";
    request.process = @"accounts/modifyPassword";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:[[PCUserInfo currentUser] userId], @"username",
                      [PCUtilityEncryptionAlgorithm md5:[info objectForKey:@"password"]], @"password",
                      [PCUtilityEncryptionAlgorithm md5:[info objectForKey:@"newPassword"]], @"newPassword",nil];
    [request start];
    
    [requests addObject:request];
    [request release];
}
@end
