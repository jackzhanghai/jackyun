//
//  DeviceInfo.h
//  popoCloud
//
//  Created by leijun on 13-9-13.
//
//

#import <Foundation/Foundation.h>

@interface DeviceInfo : NSObject
@property (nonatomic,copy) NSString *hardwareVersion;
@property (nonatomic,copy) NSString *_id;
@property (nonatomic,copy) NSString *jid;
@property (nonatomic,copy) NSString *localIP;
@property (nonatomic,copy) NSString *localPort;
@property (nonatomic,copy) NSString *serNum;
@property (nonatomic,copy) NSString *natIP;
@property (nonatomic,copy) NSString *natPort;
@property (nonatomic,copy) NSString *nickName;
@property (nonatomic,copy) NSString *versionCode;
@property (nonatomic,copy) NSString *type;
@property (nonatomic,assign) BOOL online;
@property (nonatomic,assign) BOOL isUpgrading;
-(id)initWithDic:(NSDictionary *)dic;
@end
