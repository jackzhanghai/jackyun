//
//  DeviceManageViewController.h
//  popoCloud
//
//  Created by suleyu on 13-5-30.
//
//

#import <UIKit/UIKit.h>
#import "PCLogin.h"
#import "PCAccountManagement.h"
#import "PCRestClient.h"

@interface DeviceManageViewController : UITableViewController <PCLoginDelegate,PCDeviceManagementDelegate,PCRestClientDelegate,UIAlertViewDelegate>
{
    PCDeviceManagement *deviceManagement;
    NSString *newName;
    PCRestClient *restClient;
    BOOL  bRestarting;
    NSTimeInterval restartTime;
}

@property (retain, nonatomic) DeviceInfo *device;
@property (nonatomic, retain) KTURLRequest *currentRequest;
@end
