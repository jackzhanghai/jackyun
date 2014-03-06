//
//  PCSettings.h
//  popoCloud
//
//  Created by suleyu on 13-2-27.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    DEVICE_TYPE_POPOBOX = 11,
    DEVICE_TYPE_PC = 1
} DEVICE_TYPE;

@interface PCSettings : NSObject {
    NSMutableDictionary *settings;
}

// Singleton instance of this class
+ (PCSettings*)sharedSettings;

@property (nonatomic, copy, readonly) NSString* userId;
@property (nonatomic, copy, readonly) NSString* username;
@property (nonatomic, copy, readonly) NSString* password;
@property (nonatomic, assign) BOOL autoLogin;

@property (nonatomic, copy) NSString* currentDeviceIdentifier;
@property (nonatomic, copy) NSString* currentDeviceName;
@property (nonatomic, assign) DEVICE_TYPE currentDeviceType;

@property (nonatomic, assign) BOOL autoCameraUpload;
@property (nonatomic, assign) BOOL useCellularData;
@property (nonatomic, retain) NSMutableArray *folderInfos;

//保存 当前选择的盒子的 是否支持session  的信息
@property (nonatomic, assign) BOOL bSessionSupported;

- (BOOL)setUser:(NSString*)uid name:(NSString*)name password:(NSString*)pwd;
- (void)setSessionInfoWithBoxVersion:(NSString*)boxVersion;
- (void)setScreenLockValue:(NSString *)value;
- (NSString *)screenLockValue;
- (BOOL)screenLock;
- (void)setScreenLock:(BOOL)value;
@end
