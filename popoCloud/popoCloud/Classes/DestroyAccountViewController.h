//
//  DestroyAccountViewController.h
//  popoCloud
//
//  Created by suleyu on 13-7-8.
//
//

#import <UIKit/UIKit.h>
#import "PCAccountManagement.h"

@interface DestroyAccountViewController : UIViewController <PCAccountManagementDelegate>

@property (retain, nonatomic) IBOutlet UILabel *labelAccount;
@property (retain, nonatomic) IBOutlet UIImageView *bgPassword;
@property (retain, nonatomic) IBOutlet UITextField *textFieldPassword;
@property (retain, nonatomic) IBOutlet UIButton *buttonDeleteAccount;

- (IBAction)hideKeyboard:(id)sender;
- (IBAction)deleteAccount:(id)sender;

@end
