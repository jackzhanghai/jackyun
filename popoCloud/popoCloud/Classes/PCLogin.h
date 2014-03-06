//
//  PCLogin.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-9-26.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCDeviceManagement.h"

@class PCLogin;

@protocol PCLoginDelegate <NSObject>

- (void) loginFail:(PCLogin*)pcLogin error:(NSString*)error;
- (void) loginFinish:(PCLogin*)pcLogin;

@optional
- (void)gotBoxNeedUpgrade:(BOOL)isNeed necessary:(BOOL)isNecessary;
- (void)getBoxNeedUpgradeFailedWithError:(NSError*)error;

@end

@interface PCLogin : NSObject <NSURLConnectionDelegate, PCDeviceManagementDelegate>
{
    NSInteger mStatus;
    PCDeviceManagement *deviceManagement;
}

@property (nonatomic, retain) id<PCLoginDelegate> delegate;
@property (nonatomic, readwrite) BOOL bGettingToken;
@property (nonatomic, assign) BOOL isNeedUpgrade;
@property (nonatomic, assign) BOOL isNecessaryUpgrade;
@property (nonatomic, retain) NSMutableArray* targetsArray;

+ (PCLogin *)sharedManager;

+ (void) clear;
+ (void) setResource:(NSString*)resource;
+ (void) setToken:(NSString*)token;
+ (NSString*) getResource;
+ (NSString*) getToken;
+ (void) initDevices;
+ (void) addDevice:(DeviceInfo*)device;
+ (void) removeDevice:(NSString*)deviceIdentifier;
+ (NSArray*) getAllDevices;
- (void)getAccessToken:(id)target;
- (NSMutableArray*)getTargets;
- (void)clearTargets;
- (void)setGetTokenState:(BOOL)state;

//+ (NSURLConnection*) needReLogin:(id)_delegate;
- (void) logIn:(id)_delegate node:(DeviceInfo*)node;

- (void) getDevicesList:(id)_delegate;
- (void) cancel;

-(void) getBoxNeedUpgrade:(id)_delegate;

@end
