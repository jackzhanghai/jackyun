//
//  UnbindBoxViewController.h
//  popoCloud
//
//  Created by suleyu on 13-5-30.
//
//

#import <UIKit/UIKit.h>
#import "PCVerifyCode.h"
#import "PCDeviceManagement.h"

@interface UnbindBoxViewController : UIViewController <PCVerifyCodeDelegate, PCDeviceManagementDelegate>

@property (retain, nonatomic) IBOutlet UILabel *labelAccount;
@property (retain, nonatomic) IBOutlet UIImageView *bgVerifyCode;
@property (retain, nonatomic) IBOutlet UIImageView *bgSerialNumber;
@property (retain, nonatomic) IBOutlet UIImageView *bgPassword;
@property (retain, nonatomic) IBOutlet UITextField *textFieldVerifyCode;
@property (retain, nonatomic) IBOutlet UITextField *textFieldSerialNumber;
@property (retain, nonatomic) IBOutlet UITextField *textFieldPassword;
@property (retain, nonatomic) IBOutlet UIButton *buttonRequestVerifyCode;
@property (retain, nonatomic) IBOutlet UIButton *buttonBack;
@property (retain, nonatomic) IBOutlet UIButton *buttonUnbind;
@property (retain, nonatomic) IBOutlet UILabel *labelCustomerService;

@property (copy, nonatomic) NSString *deviceIdentifier;

- (IBAction)hideKeyboard:(id)sender;
- (IBAction)requestVerifyCode:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)unbind:(id)sender;

@end
