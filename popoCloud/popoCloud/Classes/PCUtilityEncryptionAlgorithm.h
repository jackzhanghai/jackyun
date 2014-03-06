//
//  PCUtilityEncryptionAlgorithm.h
//  popoCloud
//
//  Created by xy  on 13-8-26.
//
//

#import <Foundation/Foundation.h>

@interface PCUtilityEncryptionAlgorithm : NSObject

+ (NSString*) SHA1:(NSString*)input;

+ (NSString*) md5:(NSString*)str;

+ (NSString*) file_md5:(NSString*)path;

@end
