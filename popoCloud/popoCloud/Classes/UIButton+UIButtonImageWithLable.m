//
//  UIButton+UIButtonImageWithLable.m
//  popoCloud
//
//  Created by xuyang on 13-2-25.
//
//

#import "UIButton+UIButtonImageWithLable.h"

@implementation UIButton (UIButtonImageWithLable)

- (void) setImage:(UIImage *)image withTitle:(NSString *)title forState:(UIControlState)stateType {
    
    //UIEdgeInsetsMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right)
    CGSize titleSize = [title sizeWithFont:[UIFont systemFontOfSize:12]];
    
    [self.imageView setContentMode:UIViewContentModeCenter];
    
    [self setImageEdgeInsets:UIEdgeInsetsMake(-20.0,0.0,0.0,-titleSize.width)];
    
    [self.titleLabel setContentMode:UIViewContentModeCenter];
    
    [self.titleLabel setBackgroundColor:[UIColor clearColor]];
    
    [self.titleLabel setFont:[UIFont systemFontOfSize:12]];
    
    [self.titleLabel setTextColor:[UIColor whiteColor]];
    
    [self setTitleEdgeInsets:UIEdgeInsetsMake(30.0,-image.size.width,0.0,0.0)];
    
    [self setImage:image forState:stateType];
    
    [self setTitle:title forState:UIControlStateNormal];
    [self setTitle:title forState:stateType];

}
@end
