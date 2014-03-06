//
//  AboutViewController.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-11-1.
//  Copyright (c) 2011年 Kortide. All rights reserved.
//

#import "AboutViewController.h"
#import "MobClick.h"
@implementation AboutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = NSLocalizedString(@"About", nil);
    
    [self orientationDidChange:self.interfaceOrientation];
    
//    NSString *str = [NSString stringWithFormat:@"<html><head><meta name=\"viewport\" content=\"width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=no;\"/><style type=\"text/css\">body {font-size: 16;}</style></head><body style=\"-webkit-text-size-adjust:none\">%@ V%@<br/><br/>%@</body></html>",
//                     NSLocalizedString(@"VersionInfo", nil),
//                     [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"],
//                     NSLocalizedString(@"LinkInfo", nil)];
//    [self.webView loadHTMLString:str baseURL:nil];
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [self setImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"AboutView"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"AboutView"];
}

#pragma mark -  OrientationChange


- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return  IS_IPAD ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (IS_IPAD || (interfaceOrientation == UIInterfaceOrientationPortrait));
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self orientationDidChange:interfaceOrientation];
}

- (void)orientationDidChange:(UIInterfaceOrientation)interfaceOrientation
{
    if (IS_IPAD) {
        if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            self.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"about_l"]];
            self.textLabel.frame = CGRectMake(178, 270, 668, 140);
        }
        else {
            self.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"about"]];
            self.textLabel.frame = CGRectMake(50, 330, 668, 140);
        }
    }
}

#pragma mark - UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *path = request.URL.path;
    if (path) {
        NSString *link = [path substringFromIndex:1];
        NSString *url = [NSString stringWithFormat:@"%@://%@",[link rangeOfString:@"@"].location == NSNotFound ? @"http" : @"mailto", link];

        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        return NO;
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidStartLoad");
}

@end
