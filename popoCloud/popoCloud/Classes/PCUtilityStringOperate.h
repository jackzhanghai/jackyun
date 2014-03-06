//
//  PCUtilityStringOperate.h
//  popoCloud
//
//  Created by xy  on 13-8-26.
//
//

#import <Foundation/Foundation.h>

@interface PCUtilityStringOperate : NSObject

+ (BOOL)isSameDay:(NSDate*)fistDate second:(NSDate*)secondDate;

+ (BOOL)checkValidSerialNumber:(NSString *)sn;

+ (BOOL)checkValidMobileNumber:(NSString *)mobileNum;

+ (BOOL)checkValidPassword:(NSString *)password;

+ (BOOL)checkValidEmail:(NSString*)emailAdderss;

+ (NSString *)formatDate:(NSDate *)date formatString:(NSString*)formatString;

+ (NSString*) formatTime:(float)time formatString:(NSString*)formatString;

+ (NSDate*) formatTimeString:(NSString*)time formatString:(NSString*)formatString;

+ (NSString *) encodeToPercentEscapeString: (NSString *) input;

+ (NSString *) decodeFromPercentEscapeString: (NSString *) input;
@end
