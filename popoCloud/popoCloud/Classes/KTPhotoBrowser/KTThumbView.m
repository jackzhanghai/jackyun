//
//  KTThumbView.m
//  KTPhotoBrowser
//
//  Created by Kirby Turner on 2/3/10.
//  Copyright 2010 White Peak Software Inc. All rights reserved.
//

#import "KTThumbView.h"
#import "KTThumbsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "PCUtility.h"

@implementation KTThumbView

@synthesize controller = controller_;

- (void)dealloc 
{
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.userInteractionEnabled = YES;
        self.image = nil;
    }
    return self;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (controller_)
        [controller_ didSelectThumbAtIndex:self.tag];
}

//- (void)didTouch:(id)sender 
//{
//    if (controller_)
//    {
//        [controller_ didSelectThumbAtIndex:[self tag]];
//    }
//}

- (void)setThumbImage:(UIImage *)newImage
{
//    DLogNotice(@"img.tag=%d,newImage=%@",self.tag,newImage);
    self.image = newImage ? newImage : nil;
    
    [self setNeedsDisplay];
}

- (void)setHasBorder:(BOOL)hasBorder
{
    if (hasBorder)
    {
        self.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
        self.layer.borderWidth = 1;
    }
    else
    {
        self.layer.borderColor = nil;
    }
}

@end
