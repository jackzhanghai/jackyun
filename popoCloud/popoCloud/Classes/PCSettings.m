//
//  PCSettings.m
//  popoCloud
//
//  Created by suleyu on 13-2-27.
//
//

#import "PCSettings.h"

#define KEY_UserID                  @"userId"
#define KEY_Username                @"email"
#define KEY_Password                @"password"
#define KEY_AutoLogin               @"autoLogin"
#define KEY_CurrentDeviceIdentifier @"currentDeviceIdentifier"
#define KEY_CurrentDeviceName       @"currentDeviceName"
#define KEY_CurrentDeviceType       @"currentDeviceType"
#define KEY_AutoCameraUpload        @"autoCameraUpload"
#define KEY_UseCellularData         @"useCellularData"
#define KEY_KKScreenLock            @"ScreenLock"
#define KEY_KKScreenLockValue       @"ScreenLockValue"

@implementation PCSettings
@synthesize userId;
@synthesize username;
@synthesize password;
@synthesize autoLogin;

@synthesize currentDeviceIdentifier;
@synthesize currentDeviceName;
@synthesize currentDeviceType;

@synthesize autoCameraUpload;
@synthesize useCellularData;
@synthesize folderInfos;
@synthesize bSessionSupported;

static PCSettings *g_sharedSettings = nil;

+ (PCSettings *)sharedSettings
{
    if (g_sharedSettings == nil)
    {
        g_sharedSettings = [[PCSettings alloc] init];
    }
    
    return g_sharedSettings;
}

- (id)init
{
	self = [super init];
	if (self != nil) {
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		userId = [[prefs objectForKey:KEY_UserID] copy];
		username = [[prefs objectForKey:KEY_Username] copy];
        password = [[prefs objectForKey:KEY_Password] copy];
        autoLogin = [prefs boolForKey:KEY_AutoLogin];
        
        if ([userId length] > 0) {
            [self readUserSettings];
        }
        
        folderInfos = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
    [userId release];
	[username release];
	[password release];
    
    [currentDeviceIdentifier release];
    [currentDeviceName release];
    
    [settings release];
    
    [folderInfos release];
	[super dealloc];
}

- (void)readUserSettings
{
    NSDictionary *oldSettings = [[NSUserDefaults standardUserDefaults] persistentDomainForName:userId];
    
    if (settings) [settings release];
    
    if (oldSettings == nil) {
        currentDeviceIdentifier = nil;
        currentDeviceName = nil;
        autoCameraUpload = NO;
        useCellularData = NO;
        
        settings = [[NSMutableDictionary alloc] init];
        [settings setObject:[NSNumber numberWithBool:autoCameraUpload] forKey:KEY_AutoCameraUpload];
        [settings setObject:[NSNumber numberWithBool:useCellularData] forKey:KEY_UseCellularData];
        [[NSUserDefaults standardUserDefaults] setPersistentDomain:settings forName:userId];
    }
    else {
        settings = [[NSMutableDictionary alloc] initWithDictionary:oldSettings];
        currentDeviceIdentifier = [[settings objectForKey:KEY_CurrentDeviceIdentifier] copy];
        currentDeviceName = [[settings objectForKey:KEY_CurrentDeviceName] copy];
        autoCameraUpload = [[settings objectForKey:KEY_AutoCameraUpload] boolValue];
        //useCellularData = [[settings objectForKey:KEY_UseCellularData] boolValue];
    }
}

- (BOOL)setUser:(NSString*)uid name:(NSString*)name password:(NSString*)pwd
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if ([username isEqualToString:name] == NO) {
        [username release];
        username = [name copy];
        [prefs setObject:username forKey:KEY_Username];
    }
    
    if ([password isEqualToString:pwd] == NO) {
        [password release];
        password = [pwd copy];
        [prefs setObject:password forKey:KEY_Password];
    }
    
    BOOL isSameUser = [userId isEqualToString:uid]; // || [username isEqualToString:name];
    if (!isSameUser) {
        [userId release];
        userId = [uid copy];
        [prefs setObject:userId forKey:KEY_UserID];
        
        [currentDeviceIdentifier release];
        [currentDeviceName release];
        [settings release];
        settings = nil;
        
        [self readUserSettings];
    }
    
    [prefs synchronize];
    return isSameUser;
}

- (void)setAutoLogin:(BOOL)isAutoLogin
{
    autoLogin = isAutoLogin;
    [[NSUserDefaults standardUserDefaults] setBool:autoLogin forKey:KEY_AutoLogin];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setCurrentDeviceIdentifier:(NSString*)deviceIdentifier
{
    if (currentDeviceIdentifier == deviceIdentifier) return;
    
    [currentDeviceIdentifier release];
    currentDeviceIdentifier = [deviceIdentifier copy];
    
    [settings setObject:currentDeviceIdentifier forKey:KEY_CurrentDeviceIdentifier];
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:settings forName:userId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setCurrentDeviceName:(NSString*)deviceName
{
    if (currentDeviceName == deviceName) return;
    
    [currentDeviceName release];
    currentDeviceName = [deviceName copy];
    
    [settings setObject:currentDeviceName forKey:KEY_CurrentDeviceName];
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:settings forName:userId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
//锁屏密码设置
- (BOOL)screenLock
{
    id lock = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_KKScreenLock];
    if (lock)
    {
        return [lock boolValue];
    }
    return NO;
}
- (void)setScreenLock:(BOOL)value
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:value] forKey:KEY_KKScreenLock];
	[[NSUserDefaults standardUserDefaults] synchronize];
}
-(NSString *)screenLockValue
{
    NSString *value = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_KKScreenLockValue];
    if (value)
    {
        return value;
    }
    return nil;
}
- (void)setScreenLockValue:(NSString *)value
{
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:KEY_KKScreenLockValue];
	[[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)setCurrentDeviceType:(DEVICE_TYPE)type
{
    currentDeviceType = type;
    [settings setObject:[NSNumber numberWithInt:currentDeviceType] forKey:KEY_CurrentDeviceType];
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:settings forName:userId];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoCameraUpload:(BOOL)autoUpload
{
    autoCameraUpload = autoUpload;
    [settings setObject:[NSNumber numberWithBool:autoUpload] forKey:KEY_AutoCameraUpload];
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:settings forName:userId];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setUseCellularData:(BOOL)useCellular
{
    useCellularData = useCellular;
    [settings setObject:[NSNumber numberWithBool:useCellular] forKey:KEY_UseCellularData];
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:settings forName:userId];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setSessionInfoWithBoxVersion:(NSString*)boxVersion
{
    if ([[[boxVersion componentsSeparatedByString:@"."]  objectAtIndex:0] intValue]>2) {
        bSessionSupported = YES;
    }
    else if ([boxVersion compare:@"2.3"] == NSOrderedAscending) {
        bSessionSupported = NO;
    }
    else{
        bSessionSupported = YES;
    }
}
@end
