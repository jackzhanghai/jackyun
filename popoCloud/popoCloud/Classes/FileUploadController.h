//
//  FileUploadController.h
//  popoCloud
//
//  Created by leijun on 13-3-14.
//
//

#import <UIKit/UIKit.h>
#import "PCFileCell.h"
#import "PCFileExpansionCell.h"
#import "FileUploadManager.h"

@interface FileUploadController : UITableViewController
<PCFileCellDelegate, PCFileExpansionCellDelegate, UploadDelegate, UIAlertViewDelegate>

///是否展开了操作按钮栏
@property (nonatomic) BOOL isOpen;

///展开的当前项的索引
@property (nonatomic, retain) NSIndexPath *selectIndexPath;

///取消上传的cell的索引
@property (nonatomic, retain) NSIndexPath *cancelIndexPath;

///取消上传的cell是否是处于暂停状态
@property (nonatomic) BOOL cancelCellIsPause;

///取消上传确认框
@property (nonatomic, retain) UIAlertView *cancelAlertView;

@property (nonatomic, retain) UIImageView *imgView;
@property (nonatomic, retain) UILabel *lblTip;
@property (nonatomic, retain) UILabel *lblDes;

@end
