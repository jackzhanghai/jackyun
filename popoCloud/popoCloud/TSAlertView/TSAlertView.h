//
//  TSAlertView.h
//
//  Created by Nick Hodapp aka Tom Swift on 1/19/11.
//


#import <UIKit/UIKit.h>

typedef enum 
{
	TSAlertViewButtonLayoutNormal,
	TSAlertViewButtonLayoutStacked
	
} TSAlertViewButtonLayout;

typedef enum
{
	TSAlertViewStyleNormal,
	TSAlertViewStyleInput,
	
} TSAlertViewStyle;

@class TSAlertViewController;
@class TSAlertView;

@protocol TSAlertViewDelegate <NSObject>
@optional

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)tsAlertView:(TSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

// Called when we cancel a view (eg. the user clicks the Home button). This is not called when the user clicks the cancel button.
// If not defined in the delegate, we simulate a click in the cancel button
- (void)tsAlertViewCancel:(TSAlertView *)alertView;

- (void)willPresentAlertView:(TSAlertView *)alertView;  // before animation and showing view
- (void)didPresentAlertView:(TSAlertView *)alertView;  // after animation

- (void)tsAlertView:(TSAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex; // before animation and hiding view
- (void)tsAlertView:(TSAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;  // after animation

@end

@interface TSAlertView : UIView
{
	UIImage*				_backgroundImage;
	UILabel*				_titleLabel;
	UILabel*				_messageLabel;
	UITextView*				_messageTextView;
	UIImageView*			_messageTextViewMaskImageView;
	UITextField*			_inputTextField;
	NSMutableArray*			_buttons;
}
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *message;
@property(nonatomic, assign) id<TSAlertViewDelegate> delegate;
@property(nonatomic) NSInteger cancelButtonIndex;
@property(nonatomic, readonly) NSInteger firstOtherButtonIndex;
@property(nonatomic, readonly) NSInteger numberOfButtons;
@property(nonatomic, readonly, getter=isVisible) BOOL visible;

@property(nonatomic, assign) TSAlertViewButtonLayout buttonLayout;
@property(nonatomic, assign) CGFloat width;
@property(nonatomic, assign) CGFloat maxHeight;
@property(nonatomic, assign) BOOL usesMessageTextView;
@property(nonatomic, retain) UIImage* backgroundImage;
@property(nonatomic, assign) TSAlertViewStyle style;
@property(nonatomic, readonly) UITextField* inputTextField;

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;
- (NSInteger)addButtonWithTitle:(NSString *)title;
- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex;
- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;
- (void)show;

@end




