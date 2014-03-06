//
//  PCLogout.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-9-30.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PCLogoutDelegate <NSObject>
- (void) logOut;
@end

@interface PCLogout : NSObject

@end
