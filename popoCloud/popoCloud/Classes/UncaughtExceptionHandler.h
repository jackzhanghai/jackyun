//
//  UncaughtExceptionHandler.h
//  popoCloud
//
//  Created by leijun on 13-3-20.
//
//

#if !(TARGET_IPHONE_SIMULATOR)

#import <Foundation/Foundation.h>

@interface UncaughtExceptionHandler : NSObject
//{
//	BOOL dismissed;
//}

@end

/**
 * 设置app内出现crash的异常情况时，捕获异常信息的处理函数
 * 注：无参数需要添加void，为了消除警告no previous prototype for function
 */
void InstallUncaughtExceptionHandler(void);

#endif