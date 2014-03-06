//
//  ToolView.h
//  popoCloud
//
//  Created by ice on 13-11-14.
//
//
#define QuanBuXuanTag 999
#define QuanXuanTag 1000
#define ShanChuTag 1001
#define WoXiHuanTag 1002
#define XiaZaiTag 1003
#define RemoveWoxihuanTag 1004

@protocol ToolViewDelegate <NSObject>
-(void)didSelectBtn:(NSInteger)tag;
@end
typedef enum
{
    QuanXuanShanChuXiaZai,
    QuanXuanShanChuWoXiHuan,
    QuanXuanShanChu,
    QuanXuanRemoveWoxihuan,
    
}ToolViewType;
#import <UIKit/UIKit.h>
@interface ToolView : UITabBar <UITabBarDelegate>
{
    
}
@property (nonatomic, assign) ToolViewType toolViewType;
@property (nonatomic, assign) id<ToolViewDelegate> toolViewDelegate;
-(void)changeTitleOfSelectAll;
-(void)enableBtnDownloadAndDelete:(BOOL)enable;
-(void)resetTitleAndStatus;
@end
