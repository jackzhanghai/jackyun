//
//  RestoreViewController.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-9-5.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PCBackupFile.h"
#import "PCProgressView.h"

@interface RestoreViewController : UIViewController {
    NSMutableData* data;
    NSString *plistPath;
    NSString *localPath;
    NSString *localMD5Path;
    NSInteger mStatus;
    
    UIView *footerView;
    BOOL isCancel;
    NSMutableArray *fileCacheArr;
//    NSURLConnection *connection;
}

@property (nonatomic, retain) PCBackupFile *backupFile;
@property (nonatomic, retain) IBOutlet UIToolbar* toolBar;
@property (nonatomic, retain) IBOutlet PCProgressView *progressView;
@property (nonatomic, retain) IBOutlet UILabel *lblText1;
@property (nonatomic, retain) IBOutlet UILabel *lblButton;
@property (nonatomic, retain) IBOutlet UILabel *lblInfo;
@property (nonatomic, retain) IBOutlet UILabel *lblContact;
@property (nonatomic, retain) IBOutlet UILabel *lblContactNumber;
@property (nonatomic, retain) IBOutlet UILabel *lblHint;
@property (nonatomic, retain) IBOutlet UIButton *btnRestore;
@property (nonatomic, retain) IBOutlet UIButton *btnInfo;
@property (nonatomic, retain) IBOutlet UIImageView *imgView;
@property (nonatomic, retain) IBOutlet UIImageView *imgLine1;
@property (nonatomic, retain) IBOutlet UIImageView *imgLine2;
@property (nonatomic, retain) IBOutlet UILabel* lblModifyTime;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *dicatorView;
@property (nonatomic, retain) NSMutableArray *fileCacheArr;
- (void) downloadBackupFile;
- (void) restoreContact:(NSString*)path;

- (IBAction) btnRestoreClicked: (id) sender;
-(IBAction) btnInfoClicked: (id) sender;
-(IBAction) btnCancelClicked: (id) sender;

@end
