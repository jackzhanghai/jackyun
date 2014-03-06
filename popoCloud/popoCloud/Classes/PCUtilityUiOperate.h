//
//  PCUtilityUiOperate.h
//  popoCloud
//
//  Created by xy  on 13-8-26.
//
//

#import <Foundation/Foundation.h>

@interface PCUtilityUiOperate : NSObject

+ (void)showTip:(NSString *)msg;

+ (void)showHasCollectTip:(NSString *)name;

+ (void)showTip:(NSString *)msg needMultiline:(BOOL)multiline;

+ (BOOL)animateRefreshBtn:(UIView *)view;

+ (UIBarButtonItem *)createRefresh:(id)target;

+ (void) logoutPop;

+ (void) logout;

+ (void) showErrorAlert:(NSString *)message delegate:(id)delegate;

+ (void) showErrorAlert:(NSString *)message  title:(NSString *)title delegate:(id)delegate;

+ (void) showOKAlert:(NSString *)message delegate:(id)delegate;

+ (void) showNoNetAlert:(id)delegate;

+ (void) gotoFileManagerViewAndPop;
@end
