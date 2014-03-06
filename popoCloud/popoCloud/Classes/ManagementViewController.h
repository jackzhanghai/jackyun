//
//  ManagementViewController.h
//  popoCloud
//
//  Created by xuyang on 13-3-14.
//
//

#import <UIKit/UIKit.h>

@interface ManagementViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) IBOutlet UITableView* tableView;

@end
