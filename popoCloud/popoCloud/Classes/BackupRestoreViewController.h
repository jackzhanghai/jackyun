//
//  BackupRestoreViewController.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-27.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PCBackupFile.h"
#import "EGORefreshTableHeaderView.h"
#import "PCLogout.h"

@interface BackupRestoreViewController : UIViewController <PCLogoutDelegate, PCBackupFileDelegate,EGORefreshTableHeaderDelegate,UIScrollViewDelegate> {
    NSMutableArray *tableData;
    NSInteger mStatus;

    PCBackupFile *backupFile;
    BOOL isFinish;
    
    EGORefreshTableHeaderView *_refreshHeaderView;
    
	//  Reloading var should really be your tableviews datasource
	//  Putting it here for demo purposes 
	BOOL _reloading;
}

- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;

-(void) backup;
-(void) restore;

- (void) listDevices;

@property (nonatomic, retain) IBOutlet UITableView* tableView;

@property (nonatomic, retain) IBOutlet UILabel* lblRestoreInfo;
@property (nonatomic, retain) IBOutlet UIProgressView *progressView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *dicatorView;

@end
