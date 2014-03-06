//
//  ContactBackUpViewController.h
//  popoCloud
//
//  Created by xy  on 13-5-18.
//
//

#import <UIKit/UIKit.h>
#include "MBProgressHUD.h"
#import"CustomPickerView.h"
#import "FileCache.h"
#import "vcardengine.h"
#import "FileUpload.h"
#import "contactCustomAlert.h"
#import "PCURLRequest.h"
@interface ContactBackUpViewController : UIViewController<MBProgressHUDDelegate,PCFileCacheDelegate,PCFileUploadDelegate,MBProgressHUDDelegate,CustomAlertDelegate,vcardEngineDelegate,CustomPickerViewDelegate>
{
    NSURLConnection *urlConnection;
    NSMutableData *data;
    NSMutableDictionary *getVcfInfo;
    NSMutableArray *vcfName;
    FileCache* fileCache;
    FileUpload *uploadTask;
    VcardEngine * vcardEngine;
    MBProgressHUD *progressBox;
    UITextField *text;
    NSInteger serverContactNum;
    UIButton *readButton;
    UIButton *writeButton;
    BOOL isAllowAccessContact;
    
    CustomPickerView *pickerView;
}
@property (nonatomic, retain) PCURLRequest *currentRequest;
@property (nonatomic, retain, readonly) NSMutableDictionary* tableFileCache;
- (void) BackupButtonPressed:(id)sender;
- (void) RestoreButtonPressed:(id)sender;


@end
