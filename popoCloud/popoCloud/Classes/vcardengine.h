//
//  VcardEngine.h
//  vcardtest
//
//  Created by xy  on 13-5-15.
//  Copyright (c) 2013年 xy . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "Dictionary.h"

@protocol vcardEngineDelegate <NSObject>

@optional
- (void) updateProgress:(float)progress title:(NSString *)promptStr mode:(MBProgressHUDMode)progressMode;
@end

@interface VcardEngine : NSObject
{
    NSInteger uploadContactNum;
    Dictionary *groupInfo;
}
@property (assign) id<vcardEngineDelegate> delegate;
@end
