//
//  RegisterViewController.h
//  popoCloud
//
//  Created by suleyu on 13-5-21.
//
//

#import <UIKit/UIKit.h>
#import "PCAuthentication.h"
#import "PCVerifyCode.h"
@interface RegisterViewController : UIViewController <UITextFieldDelegate,PCAuthenticationDelegate,PCVerifyCodeDelegate>

@property (retain, nonatomic) IBOutlet UIView *viewVerifyVode;
@property (retain, nonatomic) IBOutlet UIImageView *bgPhoneNumber;
@property (retain, nonatomic) IBOutlet UIImageView *bgVerifyVode;
@property (retain, nonatomic) IBOutlet UITextField *textFieldPhoneNumber;
@property (retain, nonatomic) IBOutlet UITextField *textFieldVerifyCode;
@property (retain, nonatomic) IBOutlet UIButton *buttonRequestVerifyCode;
@property (retain, nonatomic) IBOutlet UIButton *buttonInputPassword;

@property (retain, nonatomic) IBOutlet UIView *viewInputPassword;
@property (retain, nonatomic) IBOutlet UILabel *labelWelcome;
@property (retain, nonatomic) IBOutlet UIImageView *bgPassword;
@property (retain, nonatomic) IBOutlet UITextField *textFieldPassword;
@property (retain, nonatomic) IBOutlet UIImageView *bgConfirmPasswod;
@property (retain, nonatomic) IBOutlet UITextField *textFieldConfirmPassword;
@property (retain, nonatomic) IBOutlet UIButton *checkbox;
@property (retain, nonatomic) IBOutlet UIButton *buttonRegister;

- (IBAction)hideKeyboard:(id)sender;

- (IBAction)requestVerifyCode:(id)sender;
- (IBAction)inputPassword:(id)sender;
- (IBAction)registerWithEmail:(id)sender;

- (IBAction)readUserAgreement:(id)sender;
- (IBAction)checkboxClick:(UIButton *)buttonsender;
- (IBAction)registerAccount:(id)sender;

@end
