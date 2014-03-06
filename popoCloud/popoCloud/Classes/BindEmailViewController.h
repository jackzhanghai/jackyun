//
//  BindEmailViewController.h
//  popoCloud
//
//  Created by suleyu on 13-5-29.
//
//

#import <UIKit/UIKit.h>
#import "PCAccountManagement.h"
@interface BindEmailViewController : UIViewController <PCAccountManagementDelegate>

@property (retain, nonatomic) IBOutlet UILabel *labelAccount;
@property (retain, nonatomic) IBOutlet UIImageView *bgEmail;
@property (retain, nonatomic) IBOutlet UITextField *textFieldEmail;
@property (retain, nonatomic) IBOutlet UIButton *buttonBind;

- (IBAction)hideKeyboard:(id)sender;
- (IBAction)bind:(id)sender;

- (IBAction)EmailtextDidChange:(UITextField *)textField;

@end
