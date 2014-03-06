//
//  BackupViewController.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-27.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PCBackupFile.h"
#import "PCProgressView.h"
#import "FileUpload.h"

@interface BackupViewController : UIViewController <PCFileUploadDelegate>
{
    NSInteger mStatus;
    NSString *plistPath;
    
    NSInteger contactsCount;
    float uploadSize;
    float fileSize;
    
    UIView *footerView;
    BOOL isCancel;
    BOOL isBackuping;
    NSURLConnection *connection;
    NSMutableArray *fileUploadCacheArr;
}

@property (nonatomic, retain) PCBackupFile *backupFile;

@property (nonatomic, retain) IBOutlet UIToolbar* toolBar;
@property (nonatomic, retain) IBOutlet UILabel* lblResult;
@property (nonatomic, retain) IBOutlet UILabel* lblCount;
@property (nonatomic, retain) IBOutlet UILabel* lblBackupTip;
@property (nonatomic, retain) IBOutlet UILabel* lblButtonTitle;
@property (nonatomic, retain) IBOutlet UILabel* lblContacts;
@property (nonatomic, retain) IBOutlet UIButton* btnStart;
@property (nonatomic, retain) IBOutlet PCProgressView *progressView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *dicatorView;

- (void) finishBackup:(NSString*)resultText;

-(IBAction) btnBackupClicked: (id) sender;
-(IBAction) btnCancelClicked: (id) sender;

@end
