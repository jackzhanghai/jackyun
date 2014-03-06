//
//  PCURLRequest.h
//  popoCloud
//
//  Created by suleyu on 13-8-26.
//
//

#import <Foundation/Foundation.h>
#import "KTURLRequest.h"

/**
 请求box的接口时使用，urlServer不需要设置，优先尝试穿透，穿透失败再重试hub转发的方式。
 */

@interface PCURLRequest : KTURLRequest

@end
