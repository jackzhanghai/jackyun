//
//  PCCheckUpdate.h
//  popoCloud
//
//  Created by Chen Dongxiao on 11-11-16.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSAlertView.h"
@class PCCheckUpdate;

@protocol PCCheckUpdateDelegate <NSObject>
@optional
- (void) checkUpadteFinish:(PCCheckUpdate*)pcCheckUpdate;
- (void) checkUpadteFinish:(PCCheckUpdate*)pcCheckUpdate isUpdate:(BOOL)isUpdate;
- (void) checkUpadteFailed:(PCCheckUpdate*)pcCheckUpdate withError:(NSError *)error;
@end

@interface PCCheckUpdate : NSObject <NSXMLParserDelegate, UIAlertViewDelegate, TSAlertViewDelegate> {
    NSMutableData* data;
}

@property (nonatomic, assign) BOOL isChecking;

@property (nonatomic, assign) id<PCCheckUpdateDelegate> delegate;
@property (nonatomic, assign) BOOL isUpdate;
@property (nonatomic, assign) BOOL isForceUpdate;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *updateMsg;

+ (PCCheckUpdate *) sharedInstance;

- (void) checkUpdate:(id)_delegate;
- (BOOL) checkUpdateSynchronous;

@end
