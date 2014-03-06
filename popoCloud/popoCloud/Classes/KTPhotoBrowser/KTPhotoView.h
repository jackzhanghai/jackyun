//
//  KTPhotoView.h
//  Sample
//
//  Created by Kirby Turner on 2/24/10.
//  Copyright 2010 White Peak Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileCache.h"
@class KTPhotoScrollViewController;

@interface KTPhotoView : UIScrollView <UIScrollViewDelegate>
{
   UIImageView *imageView_;
   KTPhotoScrollViewController *scroller_;
   NSInteger index_;
    BOOL loadImageFailed;
}

@property (nonatomic, assign) KTPhotoScrollViewController *scroller;
@property (nonatomic, assign) NSInteger index;
@property(nonatomic, retain) FileCache * currentCache;
@property(nonatomic, retain) UILabel  *labelProgress;
@property(nonatomic, retain) UIImageView *imageView_;
@property(nonatomic, retain) UIActivityIndicatorView *indicator;

- (void)setImage:(UIImage *)newImage;
- (void)turnOffZoom;

- (CGPoint)pointToCenterAfterRotation;
- (CGFloat)scaleToRestoreAfterRotation;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)restoreCenterPoint:(CGPoint)oldCenter scale:(CGFloat)oldScale;
- (void)setContentModeForImgSize:(CGSize)newSize;

@end
