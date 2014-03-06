//
//  UIPlaceholderTextView
//  popoCloud
//
//  Created by suleyu on 13-5-23.
//
//

#import <UIKit/UIKit.h>

@interface UIPlaceholderTextView : UITextView

/**
 The string that is displayed when there is no other text in the text view.
 
 The default value is `nil`.
 */
@property (nonatomic, strong) NSString *placeholder;

/**
 The color of the placeholder.
 
 The default is `[UIColor lightGrayColor]`.
 */
@property (nonatomic, strong) UIColor *placeholderTextColor;

@end