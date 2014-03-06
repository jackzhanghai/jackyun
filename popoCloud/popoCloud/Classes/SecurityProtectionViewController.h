//
//  SecurityProtectionViewController.h
//  popoCloud
//
//  Created by suleyu on 13-5-30.
//
//

#import <UIKit/UIKit.h>
#import "PCAccountManagement.h"
@interface SecurityProtectionViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate,UITextFieldDelegate,PCAccountManagementDelegate>

@property (retain, nonatomic) IBOutlet UIImageView *bgTableView;
@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UIButton *buttonSubmit;
@property (readwrite, nonatomic) int historyAlertViewTag;
@property (retain, nonatomic) NSString *historyAnswer;

- (IBAction)submit:(id)sender;

@end
