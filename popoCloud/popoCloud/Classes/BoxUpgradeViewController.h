//
//  BoxUpgradeViewController.h
//  popoCloud
//
//  Created by suleyu on 14-1-23.
//
//

#import <UIKit/UIKit.h>

@interface BoxUpgradeViewController : UIViewController

@property (retain, nonatomic) IBOutlet UIView *viewUpgrading;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (retain, nonatomic) IBOutlet UIImageView *bgRemind;

@property (retain, nonatomic) IBOutlet UIView *viewSuccess;
@property (retain, nonatomic) IBOutlet UILabel *labelSuccess;
@property (retain, nonatomic) IBOutlet UIButton *btnSuccess;

@property (retain, nonatomic) IBOutlet UIView *viewFailed;

@property (assign, nonatomic) BOOL isLogin;
@property (assign, nonatomic) BOOL isForceUpgrade;

@property (retain, nonatomic) NSString *currentSystemVersion;

- (IBAction)btnSuccessClicked:(id)sender;

@end
