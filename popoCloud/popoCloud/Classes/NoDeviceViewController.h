//
//  NoDeviceViewController.h
//  popoCloud
//
//  Created by public on 12-8-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NoDeviceViewController : UIViewController

@property (retain, nonatomic) IBOutlet UIImageView *imageView;
@property (retain, nonatomic) IBOutlet UIButton *buttonIgnore;
@property (retain, nonatomic) IBOutlet UIButton *buttonActivate;

- (IBAction)ignoreBtnClick:(id)sender;
- (IBAction)activateBtnClick:(id)sender;

@end
