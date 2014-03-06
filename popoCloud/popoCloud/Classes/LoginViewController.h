//
//  LoginViewController.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-8.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PCLogin.h"
#import "PCCheckUpdate.h"
#import "TextFieldWithNoSpace.h"
#import "PCAuthentication.h"

#define HEIGHT_FOR_KEYBORD  100
#define ICON_PART__VIEW_TAG 1
#define OTHER_PART_VIEW_TAG 2
#define INTRO_PART_VIEW_TAG 3

@interface LoginViewController : UIViewController <UITextFieldDelegate, PCLoginDelegate, PCCheckUpdateDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, PCAuthenticationDelegate> {
    
    BOOL hasAppeared;
    BOOL isKeywordShow;
    
    //登出 时弹出的登录页面  不再自动登录
    BOOL bAutoLogin;
    
    PCAuthentication *pcAuth;
}

- (IBAction) btnLoginClicked:(id)sender;
- (IBAction) btnNewAccountClicked:(id)sender;
- (IBAction) btnForgetPasswordClicked:(id)sender;
- (BOOL)validateEmail:(NSString*)anEmail;

//@property (nonatomic, retain) IBOutlet UITabBarController *tabbarContent;
@property (nonatomic, retain) IBOutlet TextFieldWithNoSpace *txtUser;
@property (nonatomic, retain) IBOutlet TextFieldWithNoSpace *txtPassword;   
@property (nonatomic, retain) IBOutlet UIButton *checkbox;
@property (nonatomic, retain) IBOutlet UIButton *btnNewAccount;
@property (nonatomic, retain) IBOutlet UIButton *btnForgetPassword;
@property (nonatomic, retain) IBOutlet UIButton *btnLogin;
@property (nonatomic, retain) IBOutlet UILabel *lblLogin;
@property (nonatomic, retain) IBOutlet UILabel *lblAutoLogin;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *dicatorView;
@property (nonatomic, retain) IBOutlet UILabel *lblUser;
@property (nonatomic, retain) IBOutlet UILabel *lblPassword;
@property (nonatomic, readwrite)  BOOL bAutoLogin;

@property (nonatomic, retain) IBOutlet UIScrollView *loginView;
@property (nonatomic, retain) IBOutlet UIImageView *logoView;
@property (nonatomic, readwrite)  BOOL bLoginFinished;

- (IBAction)EmailtextDidChange:(id)sender;
- (void)orientationDidChange:(UIInterfaceOrientation)interfaceOrientation;
@end
