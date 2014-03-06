//
//  EmailResetPasswordViewController.h
//  popoCloud
//
//  Created by suleyu on 13-5-27.
//
//

#import <UIKit/UIKit.h>
#import "PCAuthentication.h"
@interface EmailResetPasswordViewController : UIViewController <PCAuthenticationDelegate>

@property (retain, nonatomic) IBOutlet UIView *firstPage;
@property (retain, nonatomic) IBOutlet UIImageView *bgEmail1;
//@property (retain, nonatomic) IBOutlet UILabel *registerEmailLabel;
@property (retain, nonatomic) IBOutlet UITextField *textFieldEmail;
@property (retain, nonatomic) IBOutlet UIButton *ConfirmBtn;//确定按钮
//@property (retain, nonatomic) IBOutlet UILabel *remindLabel;
@property (retain, nonatomic) IBOutlet UIButton *nextBtn;//下一步按钮

@property (retain, nonatomic) IBOutlet UIImageView *bgEmail2;
@property (retain, nonatomic) IBOutlet UIImageView *bgEmail3;
@property (retain, nonatomic) IBOutlet UIImageView *bgEmail4;
@property (retain, nonatomic) IBOutlet UIView *secondPage;
//@property (retain, nonatomic) IBOutlet UILabel *inputVerifyCodeLabel;
@property (retain, nonatomic) IBOutlet UITextField *verifyCodeField;
//@property (retain, nonatomic) IBOutlet UILabel *inputPWLabel;
@property (retain, nonatomic) IBOutlet UITextField *PWField;
@property (retain, nonatomic) IBOutlet UITextField *rePWField;
@property (retain, nonatomic) IBOutlet UIButton *buttonResetPassword;//确定按钮

- (IBAction)hideKeyboard:(id)sender;
- (IBAction)getEamilVerifyCode:(id)sender;
- (IBAction)resetPassWord:(id)sender;
- (IBAction)jumpToSencondPage:(id)sender;

- (IBAction)EmailtextDidChange:(UITextField *)textField;

@end
