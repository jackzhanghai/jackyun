//
//  PCAppDelegate.h
//  popoCloud
//
//  Created by suleyu on 13-02-25.
//  Copyright (c) 2013年 Kortide. All rights reserved.
//

#import "KTLogger.h"

static KTLogLevel gLogLever = KT_LOG_ALL;
static BOOL gcreateFile = YES;

@implementation KTLogger

+ (NSString *)getStringByDateTime:(NSDate *)nsDate{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString * stringDate = [dateFormatter stringFromDate:nsDate];
    [dateFormatter release];
	return stringDate;
}

+ (void)LogtoFile:(NSString *)log
{
    NSString *logsPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Logs"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:logsPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:logsPath 
                                  withIntermediateDirectories:YES 
                                                   attributes:nil 
                                                        error:nil];
    }
    
	NSString *fileName = [logsPath stringByAppendingPathComponent:@"PopoCloud.log"];
	if (gcreateFile) {
		
		if( [[NSFileManager defaultManager] fileExistsAtPath:fileName] ) {
			NSString *bakFileName = [NSString stringWithFormat:@"PopoCloud_%@.log", [self getStringByDateTime:[NSDate date]]];
			NSString *bakFilePath = [logsPath stringByAppendingPathComponent:bakFileName];
			[[NSFileManager defaultManager] copyItemAtPath:fileName toPath:bakFilePath error:NULL];
			[[NSFileManager defaultManager] removeItemAtPath:fileName error:NULL];
		}
		[[NSFileManager defaultManager] createFileAtPath:fileName 
												contents:nil 
											  attributes:nil];
		gcreateFile = NO;
	}
	
//	va_list v;
//	va_start(v,fmt);
//	
//	NSString * str = [[NSString alloc] initWithFormat:fmt arguments:v];
	NSMutableData *data = [[NSMutableData alloc] init];
	[data appendData:[log dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileName];
	if(fileHandle != nil)
	{
		[fileHandle seekToEndOfFile];
		[fileHandle writeData:data];
		[fileHandle closeFile];
	}
	//[str writeToFile:fileName atomically:NO];
	[data release];
	//[str release];
	//va_end(v);

}


+ (void)KTLogSetLever:(KTLogLevel)logLever
{
	gLogLever = logLever;
}


+ (void)KTLogInfo:(NSString *)tag message:(NSString*)msg,...
{
	if(gLogLever < KT_LOG_INFO)
		return;
	va_list args;
	va_start(args, msg);
	NSString * log = [[NSString alloc] initWithFormat:msg arguments:args];
	NSString *log1 = [NSString stringWithFormat:@"<Info> %@: %@\n",tag,log];
	NSString *log2 = [NSString stringWithFormat:@"%@ %@", [self getStringByDateTime:[NSDate date]], log1];
	NSLog(@"%@", log1);
	if(LOG2FILE)
		[KTLogger LogtoFile:log2];
	[log release];
	va_end(args);
}

+ (void)KTLogDebug:(NSString *)tag message:(NSString*)msg, ...
{
	if(gLogLever < KT_LOG_DEBUG)
		return;

	va_list args;
	va_start(args, msg);
	NSString * log = [[NSString alloc] initWithFormat:msg arguments:args];
	NSString *log1 = [NSString stringWithFormat:@"<Debug> %@: %@\n",tag,log];
	NSString *log2 = [NSString stringWithFormat:@"%@ %@", [self getStringByDateTime:[NSDate date]], log1];
	NSLog(@"%@", log1);
	if(LOG2FILE)
		[KTLogger LogtoFile:log2];
	[log release];
	va_end(args);
}

+ (void)KTLogWarning:(NSString *)tag message:(NSString*)msg, ...
{
	if(gLogLever < KT_LOG_WARNING)
		return;
	va_list args;
	va_start(args, msg);
	NSString * log = [[NSString alloc] initWithFormat:msg arguments:args];
	NSString *log1 = [NSString stringWithFormat:@"<Warning> %@: %@\n",tag,log];
	NSString *log2 = [NSString stringWithFormat:@"%@ %@", [self getStringByDateTime:[NSDate date]], log1];
	NSLog(@"%@", log1);
	if(LOG2FILE)
		[KTLogger LogtoFile:log2];
	[log release];
	va_end(args);
}

+ (void)KTLogError:(NSString *)tag message:(NSString*)msg, ...
{
	if(gLogLever < KT_LOG_ERROR)
		return;
	va_list args;
	va_start(args, msg);
	NSString * log = [[NSString alloc] initWithFormat:msg arguments:args];
	NSString *log1 = [NSString stringWithFormat:@"<Error> %@: %@\n",tag,log];
	NSString *log2 = [NSString stringWithFormat:@"%@ %@", [self getStringByDateTime:[NSDate date]], log1];
	NSLog(@"%@", log1);
	if(LOG2FILE)
		[KTLogger LogtoFile:log2];
	[log release];
	va_end(args);
}

+ (void)KTLogNotice:(NSString *)tag message:(NSString*)msg, ...
{
	if(gLogLever < KT_LOG_NOTICE)
		return;
	va_list args;
	va_start(args, msg);
	NSString * log = [[NSString alloc] initWithFormat:msg arguments:args];
	NSString *log1 = [NSString stringWithFormat:@"<Notice> %@: %@\n",tag,log];
	NSString *log2 = [NSString stringWithFormat:@"%@ %@", [self getStringByDateTime:[NSDate date]], log1];
	NSLog(@"%@", log1);
	if(LOG2FILE)
		[KTLogger LogtoFile:log2];
	[log release];
	va_end(args);
}
		   
@end
