//
//  NewAccountViewController.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-8.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextFieldWithNoSpace.h"
#import "PCAuthentication.h"
@interface NewAccountViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate,PCAuthenticationDelegate> {
    BOOL isKeywordShow;
    PCAuthentication *pcAuth;
}

@property (nonatomic, retain) IBOutlet UIImageView *bgUser;
@property (nonatomic, retain) IBOutlet UIImageView *bgPassword;
@property (nonatomic, retain) IBOutlet UIImageView *bgRePassword;
@property (nonatomic, retain) IBOutlet TextFieldWithNoSpace *txtUser;
@property (nonatomic, retain) IBOutlet TextFieldWithNoSpace *txtPassword;
@property (nonatomic, retain) IBOutlet TextFieldWithNoSpace *txtRePassword;
@property (nonatomic, retain) IBOutlet UIButton *checkbox;
@property (nonatomic, retain) IBOutlet UIButton *btnRegisterProtocol;
@property (nonatomic, retain) IBOutlet UIButton *btnRegister;

- (IBAction)checkboxClick:(UIButton *)btn;
- (IBAction)btnRegisterProtocolClicked:(id)sender;
- (IBAction)btnRegisterClicked:(id)sender;

- (IBAction)EmailtextDidChange:(UITextField *)textField;

@end