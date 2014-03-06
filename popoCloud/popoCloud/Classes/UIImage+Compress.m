//
//  UIImage+Compress.m
//  popoCloud
//
//  Created by Kortide on 13-4-24.
//
//

#import "UIImage+Compress.h"
#import "Constants.h"

@implementation UIImage(Compress)
- (UIImage *)compressedImage {
    CGSize imageSize = self.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    NSLog(@"max  width and max height is  %f  and  %f ", MAX_IMAGEPIX_X,MAX_IMAGEPIX_Y);
    if (width <= MAX_IMAGEPIX_X && height <= MAX_IMAGEPIX_Y) {
        // no need to compress.
        return self;
    }
    if (width == 0 || height == 0) {
        // void zero exception
        return self;
    }
    UIImage *newImage = nil;
    CGFloat widthFactor = MAX_IMAGEPIX_X / width;
    CGFloat heightFactor = MAX_IMAGEPIX_Y / height;
    CGFloat scaleFactor = 0.0;
    if (widthFactor > heightFactor)
        scaleFactor = heightFactor; // scale to fit height
    else
        scaleFactor = widthFactor; // scale to fit width
    CGFloat scaledWidth  = width * scaleFactor;
    CGFloat scaledHeight = height * scaleFactor;
    CGSize targetSize = CGSizeMake(scaledWidth, scaledHeight);
    UIGraphicsBeginImageContext(targetSize); // this will crop
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    [self drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    NSData * newData =  UIImageJPEGRepresentation(newImage, 0.8);
    return  [UIImage imageWithData:newData];
    //return newImage;
}

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize
{
    // Create a graphics image context
    UIGraphicsBeginImageContext(newSize);
    
    // Tell the old image to draw in this new context, with the desired
    // new size
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    
    // Get the new image from the context
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // End the context
    UIGraphicsEndImageContext();
    
    // Return the new image.
    return newImage;
}

@end
