//
//  BindPhoneViewController.h
//  popoCloud
//
//  Created by suleyu on 13-5-29.
//
//

#import <UIKit/UIKit.h>
#import "PCAccountManagement.h"
#import "PCVerifyCode.h"
@interface BindPhoneViewController : UIViewController <PCAccountManagementDelegate,PCVerifyCodeDelegate>

@property (retain, nonatomic) IBOutlet UILabel *labelAccount;
@property (retain, nonatomic) IBOutlet UIImageView *bgPhoneNumber;
@property (retain, nonatomic) IBOutlet UIImageView *bgVerifyCode;
@property (retain, nonatomic) IBOutlet UITextField *textFieldPhoneNumber;
@property (retain, nonatomic) IBOutlet UITextField *textFieldVerifyCode;

@property (retain, nonatomic) IBOutlet UIButton *buttonRequestVerifyCode;
@property (retain, nonatomic) IBOutlet UIButton *buttonBind;

- (IBAction)hideKeyboard:(id)sender;
- (IBAction)requestVerifyCode:(id)sender;
- (IBAction)bind:(id)sender;

@end
