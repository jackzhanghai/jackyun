//
//  PCShareUrl.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-9-16.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "PCShareUrl.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityUiOperate.h"
#import "PCUtilityStringOperate.h"
#import "PCLogin.h"
#import "FileListViewController.h"
#import "PCUserInfo.h"

#define SHARE_TYPE_EMAIL 1
#define SHARE_TYPE_SMS 2
#define SHARE_TYPE_CLIPBOARD 3

#define BUTTON_TYPE_AGAIN 1
#define BUTTON_TYPE_STOP 2
#define BUTTON_TYPE_DOWNLOAD 3
#define BUTTON_TYPE_EMAIL 4
#define BUTTON_TYPE_SMS 5
#define BUTTON_TYPE_CLIPBOARD 6
#define BUTTON_TYPE_STOP_CONFIRM 7

@implementation PCShareUrl

@synthesize actionSheet;
@synthesize delegate;
@synthesize hostPath;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        hostPath = nil;
        viewController = nil;
        actionSheet = nil;
        modifyGTMTime = 0;
        pcShare = [[PCShareServices alloc] init];
        pcShare.delegate = self;
        NSLog(@"CREAT PCShareUrl   %@",self);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackgroud) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    
    return self;
}
-(void)restoreActionSheet
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ScreenLockCorrect" object:nil];
    if (hasMassegaeUI)
    {
        hasMassegaeUI = NO;
        [self sendUrl:shareUrl accessCode:shareAccessCode];
        return;
    }
    [self showActionSheet];
}
-(void)enterBackgroud
{
    if (self.actionSheet && [[PCSettings sharedSettings] screenLock])
    {
        self.actionSheet.delegate = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreActionSheet) name:@"ScreenLockCorrect" object:nil];
        [self.actionSheet dismissWithClickedButtonIndex:0 animated:YES];
        self.actionSheet = nil;
    }

    if (viewController &&
        ([viewController.modalViewController isKindOfClass:[MFMessageComposeViewController class]] || [viewController.modalViewController isKindOfClass:[MFMailComposeViewController class]])
        && [[PCSettings sharedSettings] screenLock])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreActionSheet) name:@"ScreenLockCorrect" object:nil];
        [viewController dismissViewControllerAnimated:NO completion:NULL];
        hasMassegaeUI = YES;
    }
}
-(void)cancelConnection
{
    [pcShare cancelAllRequests];
}
- (void)dealloc
{
    NSLog(@"DEALLOC PCShareUrl   %@",self);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (shareAccessCode) {
        [shareAccessCode release];
        shareAccessCode = nil;
    }
    if (shareUrl) {
        [shareUrl release];
        shareUrl = nil;
    }
    self.hostPath = nil;
    viewController = nil;
    delegate = nil;
    [pcShare release];
    [super dealloc];
}

-(void) showActionSheet {
    self.actionSheet = [[UIActionSheet alloc] autorelease];
    memset(buttonIndexMap, 0, sizeof(int) * MAX_INDEX_COUNT);
    switch (actionType)
    {
        case TYPE_SHARE_DETAIL:
        {
            [actionSheet initWithTitle:NSLocalizedString(@"ShareLink", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"StopShare", nil), NSLocalizedString(@"ContinueShare", nil), /*NSLocalizedString(@"DownloadFile", nil), */nil];
            buttonIndexMap[0] = BUTTON_TYPE_STOP;
            buttonIndexMap[1] = BUTTON_TYPE_AGAIN;
        }
            break;
        case TYPE_SHARE_FOLDER:
        {
            
        }
        case TYPE_SHARE_AGAIN:
        {
            [actionSheet initWithTitle:NSLocalizedString(@"ShareLink", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ShareWithEmail", nil), NSLocalizedString(@"ShareWithSMS", nil), NSLocalizedString(@"CopyToClipboard", nil), nil];
            buttonIndexMap[0] = BUTTON_TYPE_EMAIL;
            buttonIndexMap[1] = BUTTON_TYPE_SMS;
            buttonIndexMap[2] = BUTTON_TYPE_CLIPBOARD;
        }
            break;
        case TYPE_SHARE_FILE:
        {
            [actionSheet initWithTitle:NSLocalizedString(@"ShareLink", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ShareWithEmail", nil), NSLocalizedString(@"ShareWithSMS", nil), NSLocalizedString(@"CopyToClipboard", nil),/* NSLocalizedString(@"DownloadFile", nil),*/ nil];
            buttonIndexMap[0] = BUTTON_TYPE_EMAIL;
            buttonIndexMap[1] = BUTTON_TYPE_SMS;
            buttonIndexMap[2] = BUTTON_TYPE_CLIPBOARD;
        }
            break;
        case TYPE_SHARE_PHOTO:
        {
            [actionSheet initWithTitle:NSLocalizedString(@"ShareLink", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ShareWithEmail", nil), NSLocalizedString(@"ShareWithSMS", nil), NSLocalizedString(@"CopyToClipboard", nil),/* NSLocalizedString(@"DownloadFile", nil),*/ nil];
            buttonIndexMap[0] = BUTTON_TYPE_EMAIL;
            buttonIndexMap[1] = BUTTON_TYPE_SMS;
            buttonIndexMap[2] = BUTTON_TYPE_CLIPBOARD;
        }
            break;
        case TYPE_SHARE_STOP:
        {
            [actionSheet initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Stop", nil), nil];
            buttonIndexMap[0] = BUTTON_TYPE_STOP_CONFIRM;
        }
            break;
        default:
            break;
    }
    
    if (viewController.tabBarController) {
        [actionSheet showInView:viewController.tabBarController.view];
    }
    else {
        [actionSheet showInView:viewController.view];
    }
}

-(void) getShareUrl
{
    [delegate shareUrlStart];
    BOOL isPublic = shareType == SHARE_TYPE_CLIPBOARD;
    [pcShare getShareURLForFile:[PCUtilityStringOperate encodeToPercentEscapeString:hostPath ] withPublic:isPublic];
}

-(void) sendUrl:(NSString*)url accessCode:(NSString *)accessCode
{
    if (shareUrl)
    {
        if (![shareUrl isEqualToString:url])
        {
            [shareUrl release];
            shareUrl = nil;
        }
    }
    if (shareAccessCode)
    {
        if (![shareAccessCode isEqualToString:accessCode])
        {
            [shareAccessCode release];
            shareAccessCode = nil;
        }
    }
    shareUrl = [[NSString alloc] initWithString:url];
    shareAccessCode = [[NSString alloc] initWithString:accessCode];
    
    switch (shareType)
    {
        case SHARE_TYPE_EMAIL:
        {
            NSLog(@"%d", [MFMailComposeViewController canSendMail]);
            NSString *account = [[[PCUserInfo currentUser] phone] length] > 0 ? [[PCUserInfo currentUser] phone] : [[PCUserInfo currentUser] email];
            MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            [controller setSubject:NSLocalizedString(@"Cloud Share", nil)];
            [controller setMessageBody:[NSString stringWithFormat:@"泡泡云%@ 想和你分享泡泡云里的文件名为：%@，URL为：\n%@\n查看提取码为：%@。", account , [self.hostPath lastPathComponent], url, accessCode] isHTML:NO];
            if (controller && viewController)
                [viewController presentModalViewController:controller animated:YES];
            [controller release];
        }
            break;
        case SHARE_TYPE_SMS:
        {
            NSLog(@"%d", [MFMessageComposeViewController canSendText]);
            if (![MFMessageComposeViewController canSendText])
            {
                [PCUtilityUiOperate showErrorAlert:[NSLocalizedString(@"Can not Send SMS Content", nil) stringByReplacingOccurrencesOfString:@"%" withString: [[UIDevice currentDevice]   model]]
                                             title:NSLocalizedString(@"Can not Send SMS Title", nil)  delegate:self];
                return;
            }
            
            NSString *account = [[[PCUserInfo currentUser] phone] length] > 0 ? [[PCUserInfo currentUser] phone] : [[PCUserInfo currentUser] email];
            MFMessageComposeViewController* controller1 = [[MFMessageComposeViewController alloc] init];
            controller1.messageComposeDelegate = self;
            controller1.recipients = [NSArray arrayWithObjects: nil];
            controller1.body = [NSString stringWithFormat:@"泡泡云%@ 想和你分享泡泡云里的文件：%@，URL为：%@，查看提取码为：%@。", account , [self.hostPath lastPathComponent], url, accessCode];
            if (controller1 && viewController)
                [viewController presentModalViewController:controller1 animated:YES];
            [controller1 release];
        }
            break;
        case SHARE_TYPE_CLIPBOARD:
        {
            NSLog(@"clipboard");
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            [pasteboard setString:url];
        }
            break;
        default:
            break;
    }
}

-(void) downloadFile
{
    [[PCUtilityFileOperate downloadManager] addItem:hostPath fileSize:fileSize modifyGTMTime:modifyGTMTime];
}

//--------------------------------------------------------------

- (void)actionSheet:(UIActionSheet *)_actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    self.actionSheet = nil;
    NSLog(@"click actionsheet in    %@",self);
    if (buttonIndex == _actionSheet.cancelButtonIndex)
    {
        if (delegate && [delegate respondsToSelector:@selector(shareUrlComplete) ])
            [delegate shareUrlComplete];
    }
    else
    {
        NSInteger index = buttonIndexMap[buttonIndex];
        NSString *fileType = nil;
        if(NSOrderedSame == [[hostPath substringWithRange:NSMakeRange([hostPath length]-4,1) ] compare:@"."])
        {
            fileType = [hostPath substringWithRange:NSMakeRange([hostPath length]-3,3)];
        }
        else if(NSOrderedSame == [[hostPath substringWithRange:NSMakeRange([hostPath length]-3,1) ] compare:@"."])
        {
            fileType = [hostPath substringWithRange:NSMakeRange([hostPath length]-2,2)];
        }
        else
        {
            fileType =@"";
        }
        
        //NSString *fileType = [self.hostPath substringWithRange:NSMakeRange(range+1,[self.hostPath count]-1)];
        
        switch (index) {
            case BUTTON_TYPE_EMAIL:
                NSLog(@"email");
                NSLog(@"%d", [MFMailComposeViewController canSendMail]);
                [MobClick event:UM_SHARE label:fileType];
                shareType = SHARE_TYPE_EMAIL;
                [self getShareUrl];
                break;
            case BUTTON_TYPE_SMS:
                NSLog(@"%d", [MFMessageComposeViewController canSendText]);
                [MobClick event:UM_SHARE label:fileType];
                shareType = SHARE_TYPE_SMS;
                [self getShareUrl];
                
                break;
            case BUTTON_TYPE_CLIPBOARD:
                //http://www.cnblogs.com/zhuqil/archive/2011/08/04/2127883.html
                NSLog(@"clipboard");
                [MobClick event:UM_SHARE label:fileType];
                shareType = SHARE_TYPE_CLIPBOARD;
                [self getShareUrl];
                break;
            case BUTTON_TYPE_DOWNLOAD:
                [self performSelector:@selector(downloadFile) withObject:nil afterDelay:0.1];
                break;
            case BUTTON_TYPE_AGAIN:
                actionType = TYPE_SHARE_AGAIN;
                [self showActionSheet];
                break;
            case BUTTON_TYPE_STOP:
                actionType = TYPE_SHARE_STOP;
                [self showActionSheet];
                break;
                
            case BUTTON_TYPE_STOP_CONFIRM:
                //            [(ShareDetailViewController*)viewController btnStopClicked:nil];
                break;
            default:
                break;
        }
    }
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
    self.actionSheet = nil;
}

- (void)showAlertForClipboardFinish
{
    NSLog(@"show alertview  in    %@",self);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FinishClipBoard", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    NSLog(@"click alertview  in    %@",self);
    if (delegate && [delegate respondsToSelector:@selector(shareUrlComplete) ])
    {
        [delegate shareUrlComplete];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    switch (result)
	{
		case MFMailComposeResultCancelled:
			NSLog(@"邮件发送取消");
			break;
		case MFMailComposeResultSaved:
			NSLog(@"邮件已存为草稿");
			break;
		case MFMailComposeResultSent:
			break;
		case MFMailComposeResultFailed:
			NSLog(@"邮件发送失败");
			break;
		default:
			break;
	}
    
    [viewController dismissViewControllerAnimated:YES completion:NULL];
    
    if (delegate && [delegate respondsToSelector:@selector(shareUrlComplete) ])
    {
        [delegate shareUrlComplete];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    switch (result)
	{
		case MessageComposeResultCancelled:
			NSLog(@"短信发送取消");
			break;
		case MessageComposeResultSent:
			break;
		case MessageComposeResultFailed:
			break;
		default:
			break;
	}
    
    [viewController dismissViewControllerAnimated:YES completion:NULL];
    
    if (delegate && [delegate respondsToSelector:@selector(shareUrlComplete) ])
    {
        [delegate shareUrlComplete];
    }
}
-(void)shareFileWithInfo:(PCFileInfo *)pcShareInfo andDelegate:(id)controller
{
    if (!([pcShareInfo.path length] < FILE_PATH_MAX_LENGTH))
    {
        if (pcShareInfo.bFileFoldType)
        {
            [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"Can not ShareFolder", nil) delegate:nil];
            self.actionSheet = nil;
        }
        else
        {
            [PCUtilityUiOperate showErrorAlert:NSLocalizedString(@"Can not Share", nil) delegate:nil];
            self.actionSheet = nil;
        }

        if (delegate && [delegate respondsToSelector:@selector(shareUrlComplete)])
            [delegate shareUrlComplete];
    }
    else
    {
        fileSize = pcShareInfo.bFileFoldType ? -1 : [pcShareInfo.size longLongValue];
        actionType = pcShareInfo.bFileFoldType ? TYPE_SHARE_FOLDER : TYPE_SHARE_FILE;
        modifyGTMTime = pcShareInfo.bFileFoldType ? 0 : [pcShareInfo.modifyTime longLongValue];
        self.hostPath = pcShareInfo.path;
        viewController = (UIViewController *)controller;
        delegate = controller;
        [self showActionSheet];
    }
}
#pragma PCShareServicesDelegate
-(void)getShareURLWithPathSuccess:(PCShareServices *)pcShareServices withUrl:(NSString *)url accessCode:(NSString *)accessCode
{
    [self sendUrl:url accessCode:accessCode];
    if (delegate)
        [delegate shareUrlFinish];
    if(shareType == SHARE_TYPE_CLIPBOARD)
    {
        [self showAlertForClipboardFinish];
    }
    
}
-(void)getShareURLWithPathFailed:(PCShareServices *)pcShareServices withError:(NSError *)error
{
    DLogInfo(@"enter share failed delegate %@",self.hostPath);
    if (delegate)
    {
        NSString *message = nil;
        if ([error.domain isEqualToString:NSURLErrorDomain])
        {
            if (error.code == NSURLErrorTimedOut)
            {
                message = NSLocalizedString(@"ConnetError", nil);
            }
            else
            {
                message = NSLocalizedString(@"NetNotReachableError", nil);
            }
        }
        else if ([error.domain isEqualToString:KTNetworkErrorDomain])
        {
            message = [PCUtility checkResponseStautsCode:error.code];
        }
        else if ([error.domain isEqualToString:KTServerErrorDomain])
        {
            message = [ErrorHandler messageForError:error.code];
            if (message == nil)
            {
                message = [error.userInfo objectForKey:@"message"];
                if (message.length == 0)
                {
                    message = error.code == PC_Err_Unknown ? NSLocalizedString(@"AccessServerError", nil) : [NSString stringWithFormat:@"未知错误: %d", error.code];
                }
            }
        }
        [delegate shareUrlFail:message];
        
    }
    DLogInfo(@"share failed %@",self.hostPath);
    
}
-(void)deleteShareFileWithIDFailed:(PCShareServices *)pcShareServices withError:(NSError *)error
{
    DLogInfo(@"enter share failed delegate %@",self.hostPath);
    if (delegate)
    {
        NSString *message = nil;
        if ([error.domain isEqualToString:NSURLErrorDomain])
        {
            if (error.code == NSURLErrorTimedOut)
            {
                message = NSLocalizedString(@"ConnetError", nil);
            }
            else
            {
                message = NSLocalizedString(@"NetNotReachableError", nil);
            }
        }
        else if ([error.domain isEqualToString:KTNetworkErrorDomain])
        {
            message = [PCUtility checkResponseStautsCode:error.code];
        }
        else if ([error.domain isEqualToString:KTServerErrorDomain])
        {
            message = [ErrorHandler messageForError:error.code];
            if (message == nil)
            {
                message = [error.userInfo objectForKey:@"message"];
                if (message.length == 0)
                {
                    message = error.code == PC_Err_Unknown ? NSLocalizedString(@"AccessServerError", nil) : [NSString stringWithFormat:@"未知错误: %d", error.code];
                }
            }
        }
        [delegate shareUrlFail:message];
        
    }
    DLogInfo(@"share failed %@",self.hostPath);
}
-(void)deleteShareFileWithIDSuccess:(PCShareServices *)pcShareServices
{
    
}
@end
