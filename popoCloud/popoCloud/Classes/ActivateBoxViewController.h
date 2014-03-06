//
//  ActivateBoxViewController
//  popoCloud
//
//  Created by suleyu on 13-5-27.
//
//

#import <UIKit/UIKit.h>
#import "ZBarReaderViewController.h"
#import "PCLogin.h"
#import "PCDeviceManagement.h"

@interface ActivateBoxViewController : UIViewController <UITextFieldDelegate, ZBarReaderDelegate, PCLoginDelegate, PCDeviceManagementDelegate>

@property (retain, nonatomic) IBOutlet UIImageView *bgScanResult;
@property (retain, nonatomic) IBOutlet UIImageView *bgSerialNumber;
@property (retain, nonatomic) IBOutlet UITextField *textFieldScanResult;
@property (retain, nonatomic) IBOutlet UITextField *textFieldSerialNumber;
@property (retain, nonatomic) IBOutlet UIButton *buttonScan;
@property (retain, nonatomic) IBOutlet UIButton *buttonActivate;

- (IBAction)hideKeyboard:(id)sender;
- (IBAction)scanBtnClick:(id)sender;
- (IBAction)activateBtnClick:(id)sender;

@end
