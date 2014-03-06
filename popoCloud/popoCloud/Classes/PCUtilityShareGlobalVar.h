//
//  PCUtilityShareGlobalVar.h
//  popoCloud
//
//  Created by xy  on 13-8-26.
//
//

#import <Foundation/Foundation.h>

@interface PCUtilityShareGlobalVar : NSObject

+ (NSString*) urlServer;

+ (void) setUrlServer:(NSString*)url;

+ (NSString*) cookie;

+ (NSString *) getPListPath;

@end
