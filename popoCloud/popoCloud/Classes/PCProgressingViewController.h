//
//  PCProgressingViewController.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-10-27.
//  Copyright (c) 2011年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PCProgressView.h"

@interface PCProgressingViewController : UIViewController

@property (nonatomic) BOOL isProgressing;
@property (nonatomic, retain) IBOutlet UIButton* btnCancel;
@property (nonatomic, retain) IBOutlet PCProgressView *progressView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *dicatorView;

@end
