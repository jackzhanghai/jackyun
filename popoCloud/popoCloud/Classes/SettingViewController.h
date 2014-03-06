//
//  SettingViewController.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-27.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PCLogin.h"
#import "PCCheckUpdate.h"

@interface SettingViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, PCLoginDelegate, PCCheckUpdateDelegate ,UIActionSheetDelegate> {
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;

@end
