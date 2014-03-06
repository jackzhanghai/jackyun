//
//  RegisterProtocolViewController.m
//  popoCloud
//
//  Created by kortide on 12-3-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RegisterProtocolViewController.h"
#import "PCUtility.h"

@implementation RegisterProtocolViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
    
    self.navigationItem.title = NSLocalizedString(@"RegisterProtocol", nil);
    self.backgroundImage.image = [[UIImage imageNamed:@"reg_agreement"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
    
    NSURL *fileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"agreement.html" ofType:nil]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:fileURL]];
    self.webView.scrollView.bounces = NO;
}

- (void)viewDidUnload
{
    [self setBackgroundImage:nil];
    [self setWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.webView.loading) {
        [self.webView stopLoading];
    }
    [super viewWillDisappear:animated];
}

//- (void)viewDidDisappear:(BOOL)animated
//{
//    [self.navigationController  setNavigationBarHidden:YES];
//    [super viewDidDisappear:animated];
//}

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

@end
