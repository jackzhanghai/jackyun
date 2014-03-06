//
//  ErrorHandler.h
//  LinkCare
//
//  Created by suleyu on 12-12-19.
//
//

#import <Foundation/Foundation.h>

typedef enum
{
    PC_OK                       = 0,    ///< No error, success
    PC_Canceled                 = -1,   ///< The operation was canceled
    PC_Err_Unknown              = -2,   ///< Unknown error
    PC_Err_NotSupported         = -3,   ///< The method has not been supported
    PC_Err_NetworkError         = -4,   ///< Network error, please try again
    PC_Err_NetworkTimeout       = -5,   ///< Network timeout, please try again
    PC_Err_IllegalParam         = -6,   ///< At least one parameter is illegal
    PC_Err_InputPhoneNumber     = -7,   ///< Phone number is empty
    PC_Err_InputVerifyCode      = -8,   ///< Verify code is empty
    PC_Err_InputEmail           = -9,   ///< Email is empty
    PC_Err_InputPassword        = -10,  ///< Password is empty
    PC_Err_InputConfirmPassword = -11,  ///< Confirm password is empty
    PC_Err_InvalidPhoneNumber   = -12,  ///< Phone number is invalid
    PC_Err_InvalidVerifyCode    = -13,  ///< Verify code is invalid
    PC_Err_InvalidEmail         = -14,  ///< Email format error
    PC_Err_InvalidUsername      = -15,  ///< No phone number and email address
    PC_Err_InvalidPassword      = -16,  ///< Password is invalid
    PC_Err_InvalidSerialNumber  = -17,  ///< Serial Number is invalid
    PC_Err_NoVerifyCode         = -18,  ///< Has not requested verify code
    PC_Err_OutdateVerifyCode    = -19,  ///< Verify code has expired
    PC_Err_PasswordNotSame      = -20,  ///< Password and confirm password is not same
    PC_Err_PasswordWrong        = -21,  ///< Password is wrong
    
    // box error
    PC_Err_LoginFailed          = 1001,
    PC_Err_InvalidArgument = 1002,
    PC_Err_FileNotExist         = 1003,
    PC_Err_FileHasExisted     = 1004,
    PC_Err_BoxUnbind    = 1005,
    PC_Err_LackSpace           = 1007,
    PC_Err_ReadOnly            = 1008,
    PC_Err_CreateThumbFailed    = 1009,
    PC_Err_NoDisk                = 1023,
} PCErrorCode;

@interface ErrorHandler : NSObject

+ (void)showAlert:(int)errorCode;
+ (void)showAlert:(int)errorCode description:(NSString *)description;
+ (void)showAlert:(int)errorCode description:(NSString *)description delegate:(id /*<UIAlertViewDelegate>*/)delegate;
+ (void)showErrorAlert:(NSError*)error;
+ (void)showErrorAlert:(NSError*)error delegate:(id)delegate;
+ (NSString *)messageForError:(int)errorCode;

@end
