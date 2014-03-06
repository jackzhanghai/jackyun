//
//  ErrorHandler.m
//  LinkCare
//
//  Created by suleyu on 12-12-19.
//
//

#import "ErrorHandler.h"
#import "KTURLRequest.h"
#import "PCUtilityUiOperate.h"
#import "PCAppDelegate.h"

@implementation ErrorHandler

+ (void)showAlert:(int)errorCode
{
    [ErrorHandler showAlert:errorCode description:nil delegate:nil];
}

+ (void)showAlert:(int)errorCode description:(NSString *)description
{
    [ErrorHandler showAlert:errorCode description:description delegate:nil];
}

+ (void)showAlert:(int)errorCode description:(NSString *)description delegate:(id)delegate;
{
    NSString *message = [ErrorHandler messageForError:errorCode];
    if (message == nil) {
        message = description.length > 0 ? description : errorCode == PC_Err_Unknown ? NSLocalizedString(@"AccessServerError", nil) : [NSString stringWithFormat:@"未知错误: %d", errorCode];
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:message
                                                   delegate:delegate
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

+ (NSString *)messageForError:(int)errorCode
{
    NSString *message = nil;
    
	switch (errorCode) {
        case PC_Err_NetworkError:
            message = NSLocalizedString(@"NetNotReachableError", nil);
			break;
            
        case PC_Err_NetworkTimeout:
            message = NSLocalizedString(@"ConnetError", nil);
			break;
            
		case PC_Err_InputPhoneNumber:
            message = @"请输入手机号";
			break;
            
		case PC_Err_InputVerifyCode:
            message = @"请输入验证码";
			break;
            
        case PC_Err_InputEmail:
            message = NSLocalizedString(@"InputRegistername", nil);
			break;
            
        case PC_Err_InputPassword:
            message = NSLocalizedString(@"InputPassword", nil);
			break;
            
        case PC_Err_InputConfirmPassword:
            message = NSLocalizedString(@"InputConfirmPassword", nil);
			break;
            
        case PC_Err_InvalidPhoneNumber:
            message = @"请输入正确的手机号码";
			break;
            
        case PC_Err_InvalidVerifyCode:
            message = @"验证码输入错误！";
			break;
            
        case PC_Err_InvalidEmail:
            message = NSLocalizedString(@"EmailIsNotValid", nil);
			break;
            
        case PC_Err_InvalidPassword:
            message = NSLocalizedString(@"InvalidPasswordLength", nil);
			break;
            
        case PC_Err_InvalidUsername:
            message = @"帐号应当为电子邮箱地址或手机号";
            break;
            
        case PC_Err_InvalidSerialNumber:
            message = @"找不到该泡泡云盒子，请检查～";
            break;
            
        case PC_Err_NoVerifyCode:
            message = @"请先获取验证码";
            break;
            
        case PC_Err_OutdateVerifyCode:
            message = @"验证码已失效";
            break;
            
        case PC_Err_PasswordNotSame:
            message = NSLocalizedString(@"NoSamePassword", nil);
            break;
            
        case PC_Err_PasswordWrong:
            message = @"登录密码错误";
            break;
            
        case 9:
            message = NSLocalizedString(@"ErrorUsernameAndPassword", nil);
            break;
            
        case 13:
            message = @"该泡泡云盒子已经被绑定过！";
            break;
            
        case 20:
            message = NSLocalizedString(@"DeviceOfflien", nil);
            break;
            
        case PC_Err_LoginFailed:
            message = NSLocalizedString(@"LoginFailed", nil);
            break;
            
        case PC_Err_BoxUnbind:
            message = NSLocalizedString(@"BoxUnbind", nil);
            break;
            
        case PC_Err_FileNotExist:
            message = NSLocalizedString(@"FileNotExist", nil);
            break;
            
        case PC_Err_FileHasExisted:
            message = NSLocalizedString(@"HasExisted", nil);
            break;
            
        case PC_Err_LackSpace:
            message = NSLocalizedString(@"NoSpaceLeft", nil);
            break;
            
        case PC_Err_ReadOnly:
            message = NSLocalizedString(@"DiskReadOnly", nil);
            break;
            
        case PC_Err_CreateThumbFailed:
            message = NSLocalizedString(@"CreateThumbFailed", nil);
            break;
            
        case PC_Err_NoDisk:
            message = NSLocalizedString(@"NotExistDisks", nil);
            break;
            
		default:
			break;
	}
    
    return message;
}

+ (void)showErrorAlert:(NSError*)error
{
    [ErrorHandler showErrorAlert:error delegate:nil];
}

+ (void)showErrorAlert:(NSError*)error delegate:(id)delegate;
{
    NSString *message = nil;
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        if (error.code == NSURLErrorTimedOut) {
            message = NSLocalizedString(@"ConnetError", nil);
        }
        else {
            message = NSLocalizedString(@"NetNotReachableError", nil);
        }
    }
    else if ([error.domain isEqualToString:KTNetworkErrorDomain]) {
        message = @"服务器异常，请稍候重试！";
    }
    else if ([error.domain isEqualToString:KTServerErrorDomain]) {
        message = [ErrorHandler messageForError:error.code];
        if (message == nil) {
            message = [error.userInfo objectForKey:@"message"];
            if (message.length == 0) {
                message = error.code == PC_Err_Unknown ? NSLocalizedString(@"AccessServerError", nil) : [NSString stringWithFormat:@"服务器异常: %d", error.code];
            }
        }
    }
    
    if (( ([message isEqualToString: NSLocalizedString(@"OpenNetwork", nil)]
           ||[message isEqualToString: NSLocalizedString(@"NetNotReachableError", nil)])
         &&((PCAppDelegate*)[[UIApplication sharedApplication] delegate]).bNetOffline ==NO)
        )
    {
        [PCUtilityUiOperate showNoNetAlert:[[UIApplication sharedApplication] delegate]];
    }
    else if([message isEqualToString: NSLocalizedString(@"ErrorUsernameAndPassword", nil)]
            ||  [message isEqualToString:NSLocalizedString(@"PasswordChanged", nil)])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:message
                                                       delegate:(PCAppDelegate*)[[UIApplication sharedApplication] delegate]
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
        alert.tag = ErrorPWAlertTag;
        [alert release];
    }
    else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:message
                                                       delegate:delegate
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}
@end
