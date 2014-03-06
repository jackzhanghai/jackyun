//
//  SettingPhotosPermissionViewController.h
//  popoCloud
//
//  Created by Kortide on 13-3-1.
//
//

#import <UIKit/UIKit.h>

typedef enum
{
    kShowStartUp,
    kShowWhenUpload,
    kShowInPopover
} ShowType;

@interface SettingPhotosPermissionViewController : UIViewController
<UITableViewDataSource,UITableViewDelegate>
{
    //UINavigationItem  * navItem;
    BOOL   bISiOS6;
    UITableView *m_tableView;
}

@property(nonatomic,retain) IBOutlet UITableView *m_tableView;
@property (nonatomic) ShowType showType;

@end
