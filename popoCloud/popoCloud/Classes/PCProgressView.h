//
//  PCProgressView.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-10-19.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PCProgressView : UIProgressView {
    UILabel* lblProgress;
//    NSString* stringExt;
}

- (void) initProgressLabel;
//- (void) setLabelExt:(NSString*)strExt;
- (void) setTip:(NSString*)tip;
@end
