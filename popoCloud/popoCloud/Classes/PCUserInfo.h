//
//  PCUserInfo.h
//  popoCloud
//
//  Created by suleyu on 13-6-8.
//
//

#import <Foundation/Foundation.h>

@interface PCUserInfo : NSObject

@property(nonatomic, copy)NSString *userId;
@property(nonatomic, copy)NSString *phone;
@property(nonatomic, copy)NSString *email;
@property(nonatomic, copy)NSString *password;

@property BOOL emailVerified;
@property BOOL setSecurityQuestion;

+ (PCUserInfo *)currentUser;
+ (id)setCurrentUserWithServerInfo:(NSDictionary *)serverUserInfo;

@end
