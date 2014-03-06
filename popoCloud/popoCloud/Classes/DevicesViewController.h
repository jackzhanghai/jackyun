//
//  DevicesViewController.h
//  popoCloud
//
//  Created by Chen Dongxiao on 12-2-2.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PCLogin.h"
#import "PCUtility.h"

@interface DevicesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, PCLoginDelegate, PCNetworkDelegate> {
    NSMutableData* data;
    NSMutableArray *tableData;
    NSInteger selectId;
    
    BOOL   isFinish;//用来表示 登录的网络请求是否完成（并非获取设备列表的请求）
    BOOL _isDataSourceAvailable;
    
    //EGORefreshTableHeaderView *_refreshHeaderView;
    
	//  Reloading var should really be your tableviews datasource
	//  Putting it here for demo purposes 
	BOOL _reloading;
    NSMutableArray *deviceListConnectionArray;
    BOOL  bViewWillDisappear;
    BOOL  bPushedByTabViewController;
    BOOL  bNeedShowNodevice;
    
    int deviceType;
}

- (void)reloadTableViewDataSource;

@property (nonatomic,readwrite) BOOL  bNeedShowNodevice;
@property (nonatomic,readwrite) BOOL  bPushedByTabViewController;
@property (nonatomic, copy) NSString* resource;

@property (nonatomic, retain) IBOutlet UITableView* tableView;
@property (nonatomic, retain) IBOutlet UILabel* lblTip;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *dicatorView;

- (void) getDevicesList;

@end
