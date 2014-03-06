//
//  BoxUpgradeConfirmViewController.h
//  popoCloud
//
//  Created by suleyu on 14-1-23.
//
//

#import <UIKit/UIKit.h>

@interface BoxUpgradeConfirmViewController : UIViewController

@property (retain, nonatomic) IBOutlet UIButton *btnCancel;
@property (retain, nonatomic) IBOutlet UIButton *btnUpgrade;
@property (retain, nonatomic) IBOutlet UIImageView *bgRemind;

@property (retain, nonatomic) NSString *currentSystemVersion;

- (IBAction)btnCancelClicked:(id)sender;
- (IBAction)btnUpgradeClicked:(id)sender;

@end
