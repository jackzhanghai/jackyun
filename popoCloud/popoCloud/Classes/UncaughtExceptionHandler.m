//
//  UncaughtExceptionHandler.m
//  popoCloud
//
//  Created by leijun on 13-3-20.
//
//

#if !(TARGET_IPHONE_SIMULATOR)

#import "UncaughtExceptionHandler.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>

NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";

NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;
const NSInteger UncaughtExceptionHandlerSkipAddressCount = 4;
const NSInteger UncaughtExceptionHandlerReportAddressCount = 5;

@implementation UncaughtExceptionHandler

+ (NSArray *)backtrace
{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    int i;
    
    NSMutableArray *backtrace = [NSMutableArray array];
    
    for (i = UncaughtExceptionHandlerSkipAddressCount;
         i < UncaughtExceptionHandlerSkipAddressCount + UncaughtExceptionHandlerReportAddressCount;
         i++)
    {
	 	[backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    
    free(strs);
    return backtrace;
}

//- (void)alertView:(UIAlertView *)anAlertView clickedButtonAtIndex:(NSInteger)anIndex
//{
//	if (anIndex == 0)
//	{
//		dismissed = YES;
//	}
//}

- (void)handleException:(NSException *)exception
{
//	UIAlertView *alert =
//    [[[UIAlertView alloc]
//      initWithTitle:NSLocalizedString(@"Unhandled exception", nil)
//      message:[NSString stringWithFormat:NSLocalizedString(
//                                                           @"You can try to continue but the application may be unstable.\n"
//                                                           @"%@\n%@", nil),
//               [exception reason],
//               [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey]]
//      delegate:self
//      cancelButtonTitle:NSLocalizedString(@"Quit", nil)
//      otherButtonTitles:NSLocalizedString(@"Continue", nil), nil]
//     autorelease];
//	[alert show];
    
    NSArray *stackArray = exception.userInfo[UncaughtExceptionHandlerAddressesKey];
    NSString *reason = [exception reason];
    NSString *name = [exception name];
    
    NSString *syserror = [NSString stringWithFormat:@"signal异常名称：%@\n异常原因：%@\n异常堆栈信息：%@",
                          name, reason, stackArray];
    
    DLogError(@"%@", syserror);
    
    
//	CFRunLoopRef runLoop = CFRunLoopGetCurrent();
//	CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
//	while (!dismissed)
//	{
//		for (NSString *mode in (NSArray *)allModes)
//		{
//			CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
//		}
//	}
//	CFRelease(allModes);
    
	NSSetUncaughtExceptionHandler(NULL);
	signal(SIGABRT, SIG_DFL);
	signal(SIGILL, SIG_DFL);
	signal(SIGSEGV, SIG_DFL);
	signal(SIGFPE, SIG_DFL);
	signal(SIGBUS, SIG_DFL);
	signal(SIGPIPE, SIG_DFL);
    
	if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName])
	{
		kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
	}
	else
	{
		[exception raise];
	}
}

@end

//NSString* getAppInfo()
//{
//    NSString *appInfo = [NSString stringWithFormat:@"App : %@ %@(%@)\nDevice : %@\nOS Version : %@ %@\nUDID : %@\n",
//                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
//                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
//                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
//                         [UIDevice currentDevice].model,
//                         [UIDevice currentDevice].systemName,
//                         [UIDevice currentDevice].systemVersion,
//                         [UIDevice currentDevice].uniqueIdentifier];
//    NSLog(@"Crash!!!! %@", appInfo);
//    return appInfo;
//}

//添加static是为了消除警告no previous prototype for function，且该函数仅在本文件里才用到的私有函数
static void MySignalHandler(int signal)
{
	int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
	if (exceptionCount > UncaughtExceptionMaximum)
	{
		return;
	}
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:@(signal) forKey:UncaughtExceptionHandlerSignalKey];
	NSArray *callStack = [UncaughtExceptionHandler backtrace];
    
    userInfo[UncaughtExceptionHandlerAddressesKey] = callStack;

    UncaughtExceptionHandler *handler = [[[UncaughtExceptionHandler alloc] init] autorelease];
    
    NSString *reason = [NSString stringWithFormat:@"Signal %d was raised",signal];
//    NSString *reason = [NSString stringWithFormat:@"Signal %d was raised.\n%@",signal, getAppInfo()];
    
    NSException *exception = [NSException exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
                                                     reason:reason
                                                   userInfo:userInfo];
    
	[handler performSelectorOnMainThread:@selector(handleException:)
                              withObject:exception
                           waitUntilDone:YES];
}

static void MyExceptionHandler(NSException *exception)
{
    // 异常的堆栈信息
    NSArray *stackArray = [exception callStackSymbols];
    // 出现异常的原因
    NSString *reason = [exception reason];
    // 异常名称
    NSString *name = [exception name];
    NSString *syserror = [NSString stringWithFormat:@"异常名称：%@\n异常原因：%@\n异常堆栈信息：%@",name, reason, stackArray];
    
    DLogError(@"%@", syserror);
}

void InstallUncaughtExceptionHandler(void)
{
    NSSetUncaughtExceptionHandler(&MyExceptionHandler);
	signal(SIGABRT, MySignalHandler);
	signal(SIGILL, MySignalHandler);
	signal(SIGSEGV, MySignalHandler);
	signal(SIGFPE, MySignalHandler);
	signal(SIGBUS, MySignalHandler);
	signal(SIGPIPE, MySignalHandler);
}

#endif