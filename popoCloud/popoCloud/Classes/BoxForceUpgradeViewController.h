//
//  BoxForceUpgradeViewController.h
//  popoCloud
//
//  Created by suleyu on 14-1-24.
//
//

#import <UIKit/UIKit.h>

@interface BoxForceUpgradeViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *btnUpgrade;
@property (strong, nonatomic) IBOutlet UIImageView *bgRemind;

- (IBAction)upgrade:(id)sender;
- (IBAction)viewDownloaded:(id)sender;

@end
