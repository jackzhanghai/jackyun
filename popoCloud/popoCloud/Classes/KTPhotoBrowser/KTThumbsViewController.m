//
//  KTThumbsViewController.m
//  KTPhotoBrowser
//
//  Created by Kirby Turner on 2/3/10.
//  Copyright 2010 White Peak Software Inc. All rights reserved.
//

#import "KTThumbsViewController.h"
#import "KTThumbsView.h"
#import "KTThumbView.h"
//#import "KTPhotoScrollViewController.h"


@interface KTThumbsViewController (Private)
@end


@implementation KTThumbsViewController

@synthesize dataSource = dataSource_;

- (void)dealloc {
    self.scrollView = nil;
   
   [super dealloc];
}

- (void)loadView {
   // Make sure to set wantsFullScreenLayout or the photo
   // will not display behind the status bar.
//   [self setWantsFullScreenLayout:YES];
    
    self.view = [[[UIView alloc] init] autorelease];

    KTThumbsView *scrollView = [[[KTThumbsView alloc] init] autorelease];
    
   [scrollView setDataSource:self];
   [scrollView setController:self];
   [scrollView setScrollsToTop:YES];
   [scrollView setScrollEnabled:YES];
   [scrollView setAlwaysBounceVertical:YES];
   [scrollView setBackgroundColor:[UIColor whiteColor]];
   
   if ([dataSource_ respondsToSelector:@selector(thumbsHaveBorder)]) {
      [scrollView setThumbsHaveBorder:[dataSource_ thumbsHaveBorder]];
   }
   
   if ([dataSource_ respondsToSelector:@selector(thumbSize)]) {
      [scrollView setThumbSize:[dataSource_ thumbSize]];
   }
    
    // Retain a reference to the scroll view.
    self.scrollView = scrollView;
   
    [self setViewFrame];
    
//   [self setView:scrollView];
    [self.view addSubview:scrollView];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (IS_IPAD || (interfaceOrientation == UIInterfaceOrientationPortrait));
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self layoutSubviews];
}

#pragma mark - public methods

- (void)layoutSubviews
{
    [self setViewFrame];
    [self reLayoutThumbs];
}

- (void)willLoadThumbs {
   // Do nothing by default.
}

- (void)didLoadThumbs {
   // Do nothing by default.
}

- (void)reLayoutThumbs
{
    [_scrollView layoutIfNeeded];
    [_scrollView setNeedsLayout];
}

- (void)reloadThumbs {
   [self willLoadThumbs];
   [_scrollView reloadData];
   [self didLoadThumbs];
}

- (void)setDataSource:(id <KTPhotoBrowserDataSource>)newDataSource {
   dataSource_ = newDataSource;
}

- (void)didSelectThumbAtIndex:(NSUInteger)index{}

- (void)setViewFrame
{
    CGRect appFrame = [UIScreen mainScreen].applicationFrame;
    CGRect barFrame = self.navigationController.navigationBar.frame;
    NSInteger tabBarHeight = self.tabBarController.tabBar ? self.tabBarController.tabBar.frame.size.height : 0;
    NSInteger appHeight = self.interfaceOrientation > UIInterfaceOrientationPortraitUpsideDown ?
    appFrame.size.width : appFrame.size.height;
    NSInteger height = appHeight - barFrame.size.height - tabBarHeight;
    
    self.view.frame = CGRectMake(0, 0, barFrame.size.width, height);
    
    _scrollView.frame = self.view.bounds;
    _scrollView.thumbsPerRow = [dataSource_ thumbsPerRow];
}

#pragma mark - KTThumbsViewDataSource

- (NSInteger)thumbsViewNumberOfThumbs:(KTThumbsView *)thumbsView
{
   NSInteger count = [dataSource_ numberOfPhotos];
   return count;
}

- (KTThumbView *)thumbsView:(KTThumbsView *)thumbsView thumbForIndex:(NSInteger)index
{
   KTThumbView *thumbView = [thumbsView dequeueReusableThumbView];
   if (!thumbView) {
      thumbView = [[[KTThumbView alloc] initWithFrame:CGRectZero] autorelease];
      [thumbView setController:self];
   }
    thumbView.tag = index;

   // Set thumbnail image.
   if ([dataSource_ respondsToSelector:@selector(thumbImageAtIndex:thumbView:)] == NO) {
      // Set thumbnail image synchronously.
      UIImage *thumbImage = [dataSource_ thumbImageAtIndex:index];
      [thumbView setThumbImage:thumbImage];
   } else {
      // Set thumbnail image asynchronously.
      [dataSource_ thumbImageAtIndex:index thumbView:thumbView];
   }
   
   return thumbView;
}


@end
