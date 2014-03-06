//
//  contactCustomAlert.m
//  AlertTest
//
//  Created by  on 13-5-29.
//  Copyright (c) 
//

#import <UIKit/UIKit.h>
@protocol CustomAlertDelegate <NSObject>
@optional
- (void)customAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@interface contactCustomAlert : UIAlertView {
    id  CustomAlertdelegate;
	UIImage *backgroundImage;
    UIImage *contentImage;
    NSMutableArray *_buttonArrays;
    CGRect drawRect;

}

@property(readwrite, retain) UIImage *backgroundImage;
@property(readwrite, retain) UIImage *contentImage;
@property(nonatomic, assign) id CustomAlertdelegate;
- (id)initWithImage:(UIImage *)image contentImage:(UIImage *)content; // Rect:(CGRect)drawInRect;
-(void) addButtonWithUIButton:(UIButton *) btn;
@end


