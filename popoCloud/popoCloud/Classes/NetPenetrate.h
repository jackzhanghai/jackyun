//
//  NetPenetrate.h
//  popoCloud
//
//  Created by leijun on 13-2-5.
//
//

#import <Foundation/Foundation.h>
#import "PCRestClient.h"

///检测穿透url连接的超时时间为5秒
#define HTTP_REQUEST_TIMEOUT 5

typedef enum {
    ///默认通过hub url连接状态
    CURRENT_NETWORK_STATE_DEFAULT,
    ///通过局域网url连接状态
    CURRENT_NETWORK_STATE_LOCAL,
    ///通过NAT url连接状态
    CURRENT_NETWORK_STATE_NAT
} CURRENT_NETWORK_STATE;

@interface NetPenetrate : NSObject

///是否正在检测穿透
@property (nonatomic) BOOL isChecking;

///网络连接状态，取值为上面定义的3种枚举状态之一
@property (atomic, assign) CURRENT_NETWORK_STATE gCurrentNetworkState;

///局域网穿透url
@property (nonatomic, copy) NSString *defaultLanUrl;

///NAT穿透url
@property (nonatomic, copy) NSString *defaultNatUrl;

///默认hub url
@property (nonatomic, copy) NSString *defaultHubUrl;

@property (nonatomic, retain) KTURLRequest *currentRequest;
/**
 * 单例模式
 * @return 该类的唯一实例
 */
+ (NetPenetrate *)sharedInstance;

/**
 * 是否穿透
 * @return 穿透返回YES，否则NO
 */
- (BOOL)isPenetrate;

/**
 * 改变穿透方式，会设置当前网络状态，网络穿透url，PCUtility类定义的gUrlServer
 * @param state 网络连接状态
 */
- (void)changePenetrate:(CURRENT_NETWORK_STATE)state;

/**
 * 检测是否可以网络穿透，并设置相应变量
 */
- (void)checkNetPenetrate;

@end
