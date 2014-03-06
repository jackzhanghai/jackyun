/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 3.0 Edition
 BSD License, Use at your own risk
 */

#import <UIKit/UIKit.h>

@interface ModalAlert : NSObject
+ (NSString *) ask: (NSString *) question withTextPrompt: (NSString *) prompt;
+ (NSString *) ask: (NSString *) question withText: (NSString *) text;
+ (NSUInteger) ask: (NSString *) question withCancel: (NSString *) cancelButtonTitle withButtons: (NSArray *) buttons;
+ (void) say: (id)formatstring,...;
+ (BOOL) ask: (id)formatstring,...;
+ (BOOL) confirm: (id)formatstring,...;
+ (BOOL) confirm:(NSString *)question prompt:(NSString *)prompt;
@end
