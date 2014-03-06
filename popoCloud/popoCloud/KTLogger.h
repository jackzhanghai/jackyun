//
//  PCAppDelegate.h
//  popoCloud
//
//  Created by suleyu on 13-02-25.
//  Copyright (c) 2013年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DLogInfo(fmt, ...) [KTLogger KTLogInfo:@"" message:fmt,##__VA_ARGS__];
#define DLogDebug(fmt, ...) [KTLogger KTLogDebug:@"" message:fmt,##__VA_ARGS__];
#define DLogWarn(fmt, ...) [KTLogger KTLogWarning:@"" message:fmt,##__VA_ARGS__];
#define DLogError(fmt, ...) [KTLogger KTLogError:@"" message:fmt,##__VA_ARGS__];
#define DLogNotice(fmt, ...) [KTLogger KTLogNotice:@"" message:fmt,##__VA_ARGS__];

#define DTLogInfo(tag, fmt, ...) [KTLogger KTLogInfo:tag message:fmt,##__VA_ARGS__];
#define DTLogDebug(tag, fmt, ...) [KTLogger KTLogDebug:tag message:fmt,##__VA_ARGS__];
#define DTLogWarn(tag, fmt, ...) [KTLogger KTLogWarning:tag message:fmt,##__VA_ARGS__];
#define DTLogError(tag, fmt, ...) [KTLogger KTLogError:tag message:fmt,##__VA_ARGS__];
#define DTLogNotice(tag, fmt, ...) [KTLogger KTLogNotice:tag message:fmt,##__VA_ARGS__];

typedef enum {
	KT_LOG_NONE,
	KT_LOG_NOTICE,
	KT_LOG_ERROR,
	KT_LOG_WARNING,
	KT_LOG_DEBUG,
	KT_LOG_INFO,
	KT_LOG_ALL
} KTLogLevel;


@interface KTLogger : NSObject

+ (void)KTLogSetLever:(KTLogLevel)logLever;
+ (void)KTLogInfo:(NSString *)tag message:(NSString *)msg, ...;
+ (void)KTLogDebug:(NSString *)tag message:(NSString *)msg, ...;
+ (void)KTLogWarning:(NSString *)tag message:(NSString *)msg, ...;
+ (void)KTLogError:(NSString *)tag message:(NSString *)msg, ...;
+ (void)KTLogNotice:(NSString *)tag message:(NSString *)msg, ...;

@end