//
//  FileDownloadManagerViewController.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-30.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PCOpenFile.h"
#import "PCFileCell.h"
#import "PCFileExpansionCell.h"
#import <QuickLook/QuickLook.h>

#define MAX_DOWNLOADING 1
@class KTPhotoScrollViewController;
@class MPMoviePlayerController;
@interface FileDownloadManagerViewController : UIViewController<PCFileCellDelegate,PCFileExpansionCellDelegate,QLPreviewControllerDataSource, QLPreviewControllerDelegate> {
    UIBarButtonItem *btnEdit;
    BOOL isEdit;
    PCOpenFile *m_openFile;
    BOOL isOpen;
    NSIndexPath *selectIndexPath;
    
}

@property (nonatomic, retain) IBOutlet UITableView* tableView;
@property (nonatomic, retain) IBOutlet UILabel* lblText;
@property (nonatomic, retain) IBOutlet UILabel* lblDes;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (assign)BOOL isOpen;
@property (nonatomic,retain)NSString *localPath;
@property (nonatomic,retain)NSIndexPath *selectIndexPath;


- (void) refreshTable;
- (void)refreshFileList:(PCFileInfo*)fileInfo;
@end
