//
//  ChangePasswordViewController.h
//  popoCloud
//
//  Created by ice on 13-11-18.
//
//

#import <UIKit/UIKit.h>
#import "PCDeviceManagement.h"
@interface ChangePasswordViewController : UIViewController <PCDeviceManagementDelegate>
{
    PCDeviceManagement *management;
}
@property (nonatomic,retain) IBOutlet UITextField *oldPasswordField;
@property (nonatomic,retain) IBOutlet UITextField *passwordField;
@property (nonatomic,retain) IBOutlet UITextField *confirmPasswordFiled;
@property (nonatomic,retain) IBOutlet UIButton *confirmChangeBtn;
@property (nonatomic,retain) IBOutlet UIImageView *oldPasswordBgImage;
@property (nonatomic,retain) IBOutlet UIImageView *passwordBgImage;
@property (nonatomic,retain) IBOutlet UIImageView *confirmPasswordBgImage;
-(IBAction)changePasswordAction:(id)sender;
@end
