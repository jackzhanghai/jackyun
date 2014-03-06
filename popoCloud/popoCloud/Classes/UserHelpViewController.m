//
//  UserHelpViewController.m
//  popoCloud
//
//  Created by Kortide on 13-9-16.
//
//

#import "UserHelpViewController.h"
#import <QuartzCore/QuartzCore.h>
#define SCROLL_VIEW_TAG  1
#define IMAGE_VIEW_TAG  2

@interface UserHelpViewController ()

@end

@implementation UserHelpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"帮助";
    self.view.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];

	// Do any additional setup after loading the view.
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth| UIViewAutoresizingFlexibleHeight;
    scrollView.tag = SCROLL_VIEW_TAG;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:scrollView.frame];
    [scrollView addSubview:imageView];
    imageView.tag = IMAGE_VIEW_TAG;
    scrollView.bounces  = NO;
    [imageView release];
    [self.view addSubview:scrollView];
    [scrollView release];
    
    [self orientationDidChange:self.interfaceOrientation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)orientationDidChange:(UIInterfaceOrientation)interfaceOrientation
{
    UIInterfaceOrientation to = interfaceOrientation;
    UIImageView *imgeView = (UIImageView *)[self.view viewWithTag:IMAGE_VIEW_TAG];
    UIScrollView *scrollView = (UIScrollView *)[self.view viewWithTag:SCROLL_VIEW_TAG];
    UIImage * helpImg;
    if (to == UIInterfaceOrientationLandscapeLeft || to == UIInterfaceOrientationLandscapeRight) {
        helpImg = [UIImage imageNamed:@"help_page_h.jpg"];
    }
    else {
        helpImg = [UIImage imageNamed:@"help_page_v.jpg"];
    }
    
    imgeView.image = helpImg;
    imgeView.frame = CGRectMake(0, 0, helpImg.size.width, helpImg.size.height);
    scrollView.contentSize = CGSizeMake(helpImg.size.width,helpImg.size.height);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self orientationDidChange:interfaceOrientation];
}


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
