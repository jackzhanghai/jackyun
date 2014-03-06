//
//  PCLogin.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-9-26.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "PCLogin.h"
#import "PCUserInfo.h"
#import "PCUtility.h"
#import "IPAdress.h"
#import "NetPenetrate.h"
#import "PCUtilityShareGlobalVar.h"
#import "PCUtilityStringOperate.h"
#import "PCURLRequest.h"
#import "UIDevice+IdentifierAddition.h"
#import "PCAppDelegate.h"
#import "PCLogout.h"

#define STATUS_INIT 0
#define STATUS_GET_DEVICES_LIST 1
#define STATUS_LONGIN_BOX 2

static NSString *gResource = nil;
static NSMutableArray *gDevices = nil;
static NSString *currentToken = nil;

@interface PCLogin ()
{
}
@end

@implementation PCLogin
@synthesize delegate;
@synthesize targetsArray;
@synthesize bGettingToken;
@synthesize isNeedUpgrade;
@synthesize isNecessaryUpgrade;

- (NSMutableArray*)getTargets
{
    return self.targetsArray;
}

- (void)setGetTokenState:(BOOL)state
{
    @synchronized(self)
    {
        self.bGettingToken = state;
    }
}

- (void)clearTargets
{
     [self.targetsArray removeAllObjects];
}

+ (PCLogin *)sharedManager
{
    static PCLogin *g_sharedManager = nil;
    if (g_sharedManager == nil)
    {
        g_sharedManager = [[PCLogin alloc] init];
    }
    
    return g_sharedManager;
}


- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.targetsArray = [NSMutableArray array];
        deviceManagement = [[PCDeviceManagement alloc] init];
        deviceManagement.delegate = self;
    }
    
    return self;
}

- (void)dealloc
{
    [self cancel];
    self.targetsArray  = nil;
    if (delegate) [delegate release];
    [deviceManagement release];
    [super dealloc];
}

- (void) logIn:(id)_delegate node:(DeviceInfo*)node {
    [[PCSettings sharedSettings] setSessionInfoWithBoxVersion:node.versionCode];
    self.delegate = _delegate;
    self.isNeedUpgrade = NO;
    self.isNecessaryUpgrade = NO;
   
    mStatus = STATUS_LONGIN_BOX;
    
    [PCLogin setResource:node.serNum];
    
    int deviceType = [node.type intValue];
    NSString* localIP = node.localIP;
    NSString* natIP = node.natIP;
    NSString* localPort = node.localPort;
    NSString* natPort = node.natPort;
    
    NSString* defaultAdress = [NSString stringWithFormat:@"%@/webMessageRelayService/%@.%@", MESSAGE_SERVER_HOST, [PCUtilityStringOperate encodeToPercentEscapeString:gResource], [[PCUserInfo currentUser] userId]];
    [PCUtilityShareGlobalVar setUrlServer:[NSString stringWithFormat:@"http://%@/", defaultAdress]];
    
    //modified by ray
    NetPenetrate *penetrate = [NetPenetrate sharedInstance];
    penetrate.gCurrentNetworkState = CURRENT_NETWORK_STATE_DEFAULT;
    penetrate.isChecking = NO;
    penetrate.defaultHubUrl = defaultAdress;
    if (localIP.length && ![localIP isEqualToString:@"null"] && localPort && localPort.integerValue >= 0) {
        penetrate.defaultLanUrl = [NSString stringWithFormat:@"%@:%@", localIP, localPort];
    }
    else {
        penetrate.defaultLanUrl = nil;
    }
    if (natIP.length && ![natIP isEqualToString:@"null"] && natPort && natPort.integerValue >= 0) {
        penetrate.defaultNatUrl = [NSString stringWithFormat:@"%@:%@", natIP, natPort];
    }
    else {
        penetrate.defaultNatUrl = nil;
    }
    
    [[PCSettings sharedSettings] setCurrentDeviceIdentifier:[PCLogin getResource]];
    [[PCSettings sharedSettings] setCurrentDeviceName:node.nickName];
    [[PCSettings sharedSettings] setCurrentDeviceType:deviceType];
    
    if ([PCSettings sharedSettings].bSessionSupported) {
        [self getAccessToken:self];
    }
    else{
        [[NetPenetrate sharedInstance] checkNetPenetrate];
        [self.delegate loginFinish:self];
        mStatus = STATUS_INIT;
    }
}

- (void) getDevicesList:(id)_delegate {
    self.delegate = _delegate;
    
    if (mStatus == STATUS_INIT) {
        mStatus = STATUS_GET_DEVICES_LIST;
        [deviceManagement getDeviceList];
    }
}

- (void) cancel {
    [deviceManagement cancelAllRequests];
    mStatus = STATUS_INIT;
}

//---------------------------------------------------------------

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement gotDeviceList:(NSArray*)devices
{
    [gDevices release];
    gDevices = [[NSMutableArray alloc] initWithArray:devices];
    NSLog(@"devices:\n%@", gDevices);
    
    if ([PCLogin getResource] == nil && gDevices.count > 0) {
        PCAppDelegate *appDelegate = (PCAppDelegate*)[[UIApplication sharedApplication] delegate];
        NSArray *arrayView = appDelegate.tabbarContent.viewControllers;
        for (UINavigationController *nav in arrayView) {
            id<PCLogoutDelegate> view = [nav.viewControllers objectAtIndex:0];
            if ([(NSObject *)view respondsToSelector:@selector(logOut)])
            {
                [view logOut];
            }
        }
    }
    
    BOOL bFoundLastDevice = NO;
    NSString *lastDevice = [[PCSettings sharedSettings] currentDeviceIdentifier];
    if (lastDevice.length > 0) {
        for (DeviceInfo *node in gDevices) {
            if (([lastDevice isEqualToString:node.serNum])) {
                if ([PCLogin getResource] == nil) {
                    [self logIn:delegate node:node];
                }
                else {
                    [delegate loginFinish:self];
                    mStatus = STATUS_INIT;
                }
                bFoundLastDevice = YES;
                break;
            }
        }
    }
    
    if (bFoundLastDevice == NO) {
        if (gDevices.count == 0) {
            [[PCSettings sharedSettings] setCurrentDeviceIdentifier:@""];
            [[PCSettings sharedSettings] setCurrentDeviceName:@""];
            [PCLogin setResource:nil];
            
            [PCUtility setUrlServer:@""];
            
            NetPenetrate *penetrate = [NetPenetrate sharedInstance];
            penetrate.gCurrentNetworkState = CURRENT_NETWORK_STATE_DEFAULT;
            penetrate.isChecking = NO;
            penetrate.defaultHubUrl = nil;
            penetrate.defaultLanUrl = nil;
            penetrate.defaultNatUrl = nil;
            
            [delegate loginFinish:self];
            mStatus = STATUS_INIT;
        }
        else {
            [self logIn:delegate node:[gDevices objectAtIndex:0]];
        }
    }
}

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement getDeviceListFailedWithError:(NSError*)error
{
    NSString *message = nil;
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        if (error.code == NSURLErrorTimedOut) {
            message = NSLocalizedString(@"ConnetError", nil);
        }
        else {
            message = NSLocalizedString(@"NetNotReachableError", nil);
        }
    }
    else if ([error.domain isEqualToString:KTNetworkErrorDomain]) {
        message = [PCUtility checkResponseStautsCode:error.code];
    }
    else if ([error.domain isEqualToString:KTServerErrorDomain]) {
        if (error.code == 9) //用户名密码错误
        {
            message = NSLocalizedString(@"PasswordChanged", nil);
        }
        else {
            message = [error.userInfo objectForKey:@"errMsg"]?[error.userInfo objectForKey:@"errMsg"]:
            ([error.userInfo objectForKey:@"message"]?[error.userInfo objectForKey:@"message"]:NSLocalizedString(@"AccessServerError", nil));
        }
    }
    
    [delegate loginFail:self error:message];
    mStatus = STATUS_INIT;
}

//-------------------------------------------------------------------------

+ (void) clear {
    if (gDevices) {
        [gDevices release];
        gDevices = nil;
    }
    
    if (gResource) {
        [gResource release];
        gResource = nil;
    }
    
    [PCLogin setToken:nil];
}

+ (void) setResource:(NSString*)resource {
    if (gResource == resource) return;
    // || [resource compare:gResource] == NSOrderedSame
    
//    [PCUtility setUrlServer:[NSString stringWithFormat:@"http://%@/service/%@.%@/", SERVER_HOST, resource, [PCUtility md5:gUser]]];
    [gResource release];
    gResource = [resource copy];
}

+ (NSString*) getResource {
    return gResource;
}


+ (void) setToken:(NSString*)token {
    if ([token isEqualToString:currentToken]) return;
    [currentToken release];
    if (token) {
        currentToken = [token copy];
    }
    else{
        currentToken = nil;
    }
}

+ (NSString*) getToken {
    return currentToken;
}


+ (void) initDevices {
    if (gDevices) {
        [gDevices removeAllObjects];
    }
    else {
        gDevices = [[NSMutableArray alloc] init];
    }
}

+ (void) addDevice:(DeviceInfo*)device {

    if (gDevices == nil) {
        gDevices = [[NSMutableArray alloc] init];
    }
    
    [gDevices addObject:device];
}

+ (void) removeDevice:(NSString*)deviceIdentifier {
    if (gDevices == nil || deviceIdentifier == nil) return;
    
    for (DeviceInfo *device in gDevices) {
        if (([deviceIdentifier isEqualToString:device.serNum])) {
            [gDevices removeObject:device];
            break;
        }
    }
    
    if ([deviceIdentifier isEqualToString:gResource]) {
        if (gDevices.count > 0) {
            [[PCLogin sharedManager] logIn:nil node:gDevices[0]];
        }
        else {
            [[PCSettings sharedSettings] setCurrentDeviceIdentifier:@""];
            [[PCSettings sharedSettings] setCurrentDeviceName:@""];
            [PCLogin setResource:nil];
            
            [PCUtilityShareGlobalVar setUrlServer:@""];
            
            NetPenetrate *penetrate = [NetPenetrate sharedInstance];
            penetrate.gCurrentNetworkState = CURRENT_NETWORK_STATE_DEFAULT;
            penetrate.isChecking = NO;
            penetrate.defaultHubUrl = nil;
            penetrate.defaultLanUrl = nil;
            penetrate.defaultNatUrl = nil;
        }
    }
}

+ (NSArray*) getAllDevices {
    return gDevices;
}


- (void)getAccessToken:(id)target;
{
    @synchronized(self){
        if (self.bGettingToken == NO) {
            self.bGettingToken =YES;
            KTURLRequest *request = [[KTURLRequest alloc] initWithTarget:target selector:@selector(requestDidGotAccessToken:)];
            request.urlServer = SERVER_HOST;
            request.method = @"POST";
            request.process = @"accounts/getAccessToken";
            request.params = [NSDictionary dictionaryWithObjectsAndKeys:[[PCUserInfo currentUser] userId], @"username",
                              [[PCUserInfo currentUser] password], @"password",
                              [NSNumber numberWithInt:1], @"targetType",
                              [PCLogin getResource], @"serialNo",
                              [[UIDevice currentDevice] uniqueDeviceIdentifier], @"clientID",
                              nil];
            [request start];
            [request release];
        }
        
         [self.targetsArray addObject:target];
    }
}

- (void)requestDidGotAccessToken:(KTURLRequest *)request
{
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
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                [self  getAccessTokenFailedWithError:error];
            }
        }
        else {
            NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
            [self  getAccessTokenFailedWithError:error];
        }
    }
}

- (void)gotAccessToken:(NSDictionary*)result
{
    currentToken = [[result objectForKey:@"token"] copy];
    [[NetPenetrate sharedInstance] checkNetPenetrate];
    [self.delegate loginFinish:self];
    mStatus = STATUS_INIT;
}

- (void)getAccessTokenFailedWithError:(NSError*)error
{
    [ErrorHandler showErrorAlert:error];
    [self.delegate loginFail:self error:nil];
    mStatus = STATUS_INIT;
}

-(void) getBoxNeedUpgrade:(id)_delegate
{
    self.delegate = _delegate;
    [deviceManagement getBoxNeedUpgrade];
}

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement gotBoxNeedUpgrade:(BOOL)isNeed necessary:(BOOL)isNecessary
{
    self.isNeedUpgrade = isNeed;
    self.isNecessaryUpgrade = isNeed;
    
    if (delegate && [delegate respondsToSelector:@selector(gotBoxNeedUpgrade:necessary:)]) {
        [delegate gotBoxNeedUpgrade:isNeed necessary:isNecessary];
    }
}

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement getBoxNeedUpgradeFailedWithError:(NSError*)error
{
    if (delegate && [delegate respondsToSelector:@selector(getBoxNeedUpgradeFailedWithError:)]) {
        [delegate getBoxNeedUpgradeFailedWithError:error];
    }
}

@end
