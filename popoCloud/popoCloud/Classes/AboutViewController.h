//
//  AboutViewController.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-11-1.
//  Copyright (c) 2011年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AboutViewController : UIViewController <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@end
