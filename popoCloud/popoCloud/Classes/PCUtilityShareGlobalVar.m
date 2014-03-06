//
//  PCUtilityShareGlobalVar.m
//  popoCloud
//
//  Created by xy  on 13-8-26.
//
//

#import "PCUtilityShareGlobalVar.h"

@implementation PCUtilityShareGlobalVar

static NSMutableString* gUrlServer = nil;
static NSMutableString* gCookie = nil;
static NSString *gPlistPath = nil;

+ (NSString*) urlServer
{
    @synchronized(gUrlServer)
    {
        return gUrlServer;
    }
}

+ (void) setUrlServer:(NSString*)url
{
    if (!url) return;
    
    if (!gUrlServer) {
        gUrlServer = [[NSMutableString alloc] initWithCapacity:256];
    }
    
    @synchronized(gUrlServer)
    {
        [gUrlServer setString:url];
    }
    //    NSLog(gUrlServer);
}

+ (NSString*) cookie
{
    return gCookie;
}

+ (NSString *) getPListPath
{
    if (!gPlistPath) {
        //        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        //        NSString *plistPath = [NSString stringWithFormat:@"%@/Preferences", [paths objectAtIndex:0]];
        NSString *plistPath = [NSString stringWithFormat:@"%@/Preferences", NSTemporaryDirectory()];
        NSFileManager *fileManage = [NSFileManager defaultManager];
        
        if (![fileManage fileExistsAtPath:plistPath isDirectory:nil]) {
            if ([fileManage createDirectoryAtPath:plistPath withIntermediateDirectories:YES attributes:nil error:nil]==NO) {
                NSLog(@"创建文件夹:%@ 失败", plistPath);
            }
        }
        gPlistPath = [plistPath copy];
    }
    
    return gPlistPath;
}

@end
