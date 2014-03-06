//
//  CustomMediaPlayerViewController.m
//  popoCloud
//
//  Created by Kortide on 13-11-13.
//
//

#import "CustomMediaPlayerViewController.h"

@interface CustomMediaPlayerViewController ()

@end

@implementation CustomMediaPlayerViewController
@synthesize mUrl;

- (id)initWithContentURL:(NSURL*)url
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.mUrl = url;
        MPMoviePlayerController *player = [ [ MPMoviePlayerController alloc]initWithContentURL:url];//本地的
        player.controlStyle = MPMovieControlStyleFullscreen;
        player.scalingMode = MPMovieScalingModeAspectFill;
        player.view.frame = [[UIScreen mainScreen] applicationFrame];;
        player.backgroundView.backgroundColor = [UIColor blackColor];
        self.currentController = player;
        [player prepareToPlay];
        [player release];
        self.wantsFullScreenLayout = YES;
    }
    return self;
}

- (MPMoviePlayerController*) moviePlayer
{
    return self.currentController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.currentController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.currentController.view];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.currentController.view.frame = self.view.frame;
    self.currentController.backgroundView.frame = self.view.frame;
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.moviePlayer setFullscreen:NO animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    self.mUrl = nil;
    self.currentController  = nil;
    [super dealloc];
}

@end
