//
//  PCUserInfo.m
//  popoCloud
//
//  Created by suleyu on 13-6-8.
//
//

#import "PCUserInfo.h"

@implementation PCUserInfo

@synthesize userId;
@synthesize phone;
@synthesize email;
@synthesize password;
@synthesize emailVerified;
@synthesize setSecurityQuestion;

static PCUserInfo *g_currentUser = nil;

+ (PCUserInfo *)currentUser
{
    return g_currentUser;
}

+ (id)setCurrentUserWithServerInfo:(NSDictionary *)serverUserInfo
{
    if (g_currentUser == nil)
    {
        g_currentUser = [[PCUserInfo alloc] init];
    }
    
    g_currentUser.userId = [serverUserInfo valueForKey:@"uid"];
    g_currentUser.phone = [serverUserInfo valueForKey:@"mobile"];
    g_currentUser.email = [serverUserInfo valueForKey:@"email"];
    //g_currentUser.password = [serverUserInfo valueForKey:@"password"];
    g_currentUser.emailVerified = [[serverUserInfo valueForKey:@"emailVerifyed"] boolValue];
    g_currentUser.setSecurityQuestion = [[serverUserInfo valueForKey:@"setSecurityQuestion"] boolValue];
    
	return self;
}

- (void)dealloc {
	[userId release];
    [phone release];
	[email release];
    [password release];
    [super dealloc];
}

@end
