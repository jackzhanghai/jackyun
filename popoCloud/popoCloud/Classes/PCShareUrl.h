//
//  PCShareUrl.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-9-16.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import "PCFileInfo.h"
#import "PCShareServices.h"
#define TYPE_SHARE_FILE 0
#define TYPE_SHARE_FOLDER 1
#define TYPE_SHARE_PHOTO 2
#define TYPE_SHARE_DETAIL 3
#define TYPE_SHARE_AGAIN 4
#define TYPE_SHARE_STOP 5
#define MAX_INDEX_COUNT 8

@protocol PCShareUrlDelegate <NSObject>
- (void) shareUrlStart;
- (void) shareUrlFinish;
- (void) shareUrlFail:(NSString*)error;
@optional
- (void) shareUrlComplete;
@end

@interface PCShareUrl : NSObject  <UIActionSheetDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate,PCShareServicesDelegate>
{
    
    NSString *hostPath;
    UIViewController *viewController;
    NSInteger actionType;
    long long modifyGTMTime;
    NSInteger shareType;
    long long fileSize;
    int buttonIndexMap[MAX_INDEX_COUNT];
    PCShareServices *pcShare;
    NSString *shareUrl;
    NSString *shareAccessCode;
    BOOL hasMassegaeUI;
}

@property (nonatomic, retain) UIActionSheet *actionSheet;
@property (assign) id<PCShareUrlDelegate> delegate;
@property (nonatomic, copy) NSString *hostPath;

-(void) showActionSheet;

- (void)cancelConnection;
/**
 * 用指定信息分享文件
 * @param pcShareInfo分享对象
 */
-(void)shareFileWithInfo:(PCFileInfo *)pcShareInfo andDelegate:(id)controller;

@end
