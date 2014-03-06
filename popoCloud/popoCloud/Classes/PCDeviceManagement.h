//
//  PCDeviceManagement.h
//  popoCloud
//
//  Created by suleyu on 13-8-30.
//
//

#import <Foundation/Foundation.h>
#import "PCURLRequest.h"

@protocol PCDeviceManagementDelegate;

@interface PCDeviceManagement : NSObject

@property (nonatomic,assign) id<PCDeviceManagementDelegate> delegate;

/**
 * 取消所有请求
 */
- (void)cancelAllRequests;

/**
 * 获取设备列表
 */
-(void)getDeviceList;

-(void)bindBox:(NSString *)serialNumber;

-(void)unbindBox:(NSString *)verifyCode serialNumber:(NSString *)serialNumber password:(NSString *)password;

-(void)renameBox:(NSDictionary *)info;

-(void)getBoxSystemVersion;

-(void)getBoxNeedUpgrade;

-(void)upgradeBoxSystem;

/**
 * 应用内部修改密码
 * @param info 包含接口需要的参数，用户名  旧密码  新密码
 * @return
 */
-(void)modifyPassword:(NSDictionary *)info;

@end


@protocol PCDeviceManagementDelegate <NSObject>

@optional

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement gotDeviceList:(NSArray*)devices;
- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement getDeviceListFailedWithError:(NSError*)error;

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement boundBox:(DeviceInfo*)device;
- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement bindBoxFailedWithError:(NSError*)error;

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement unboundBox:(NSString*)device;
- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement unbindBoxFailedWithError:(NSError*)error;

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement renameBoxSuccess:(NSString*)device;
- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement renameBoxFailedWithError:(NSError*)error;

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement gotBoxSystemVersion:(NSString*)version;
- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement getBoxSystemVersionFailedWithError:(NSError*)error;

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement gotBoxNeedUpgrade:(BOOL)isNeed necessary:(BOOL)isNecessary;
- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement getBoxNeedUpgradeFailedWithError:(NSError*)error;

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement upgradeBoxSystemWithError:(NSError*)error;

- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement modifyPasswordSuccess:(NSString*)device;
- (void)pcDeviceManagement:(PCDeviceManagement*)pcDeviceManagement modifyPasswordFailedWithError:(NSError*)error;

@end

