//
//  PictureScanFolderViewController.h
//  popoCloud
//
//  Created by suleyu on 14-2-7.
//
//

#import <UIKit/UIKit.h>
#import "PCFileInfo.h"

@interface PictureScanFolderViewController : UITableViewController

@property (nonatomic, retain) NSString *dirName;
@property (nonatomic, retain) NSString *dirPath;
@property (nonatomic, retain) NSMutableArray *fileList;
@property (nonatomic, retain) NSArray *addFolders;
@property (nonatomic, retain) NSArray *delFolders;

- (id)initWithStyle:(UITableViewStyle)style editing:(BOOL)editing;

@end
