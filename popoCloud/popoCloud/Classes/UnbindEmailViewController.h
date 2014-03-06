//
//  UnbindEmailViewController.h
//  popoCloud
//
//  Created by suleyu on 13-5-29.
//
//

#import <UIKit/UIKit.h>
#import "PCAccountManagement.h"
@interface UnbindEmailViewController : UIViewController <PCAccountManagementDelegate>

@property (retain, nonatomic) IBOutlet UILabel *labelAccount;
@property (retain, nonatomic) IBOutlet UILabel *labelEmail;
@property (retain, nonatomic) IBOutlet UIImageView *bgPassword;
@property (retain, nonatomic) IBOutlet UITextField *textFieldPassword;
@property (retain, nonatomic) IBOutlet UIButton *buttonUnbind;

- (IBAction)hideKeyboard:(id)sender;
- (IBAction)unbind:(id)sender;

@end
