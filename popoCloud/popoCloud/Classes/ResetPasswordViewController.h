//
//  ResetPasswordViewController.h
//  popoCloud
//
//  Created by suleyu on 13-5-27.
//
//

#import <UIKit/UIKit.h>
#import "PCVerifyCode.h"
#import "PCAuthentication.h"
@interface ResetPasswordViewController : UIViewController <UITextFieldDelegate,PCAuthenticationDelegate,PCVerifyCodeDelegate>

@property (retain, nonatomic) IBOutlet UIImageView *bgPhoneNumber;
@property (retain, nonatomic) IBOutlet UIImageView *bgVerifyCode;
@property (retain, nonatomic) IBOutlet UIImageView *bgPassword;
@property (retain, nonatomic) IBOutlet UIImageView *bgConfirmPasswod;

@property (retain, nonatomic) IBOutlet UITextField *textFieldPhoneNumber;
@property (retain, nonatomic) IBOutlet UITextField *textFieldVerifyCode;
@property (retain, nonatomic) IBOutlet UITextField *textFieldPassword;
@property (retain, nonatomic) IBOutlet UITextField *textFieldConfirmPassword;

@property (retain, nonatomic) IBOutlet UIButton *buttonRequestVerifyCode;
@property (retain, nonatomic) IBOutlet UIButton *buttonResetPassword;

- (IBAction)hideKeyboard:(id)sender;

- (IBAction)requestVerifyCode:(id)sender;
- (IBAction)resetPassword:(id)sender;
- (IBAction)resetPasswordWithEmail:(id)sender;

@end
