//
//  NewFolderAndUploadCell.h
//  popoCloud
//
//  Created by ice on 13-11-28.
//
//

#import <UIKit/UIKit.h>
@protocol NewFolderAndUploadCellDelegate <NSObject>
-(void)createNewFloder;
-(void)uploadPhoto;
@end
@class FileListViewController;
@interface NewFolderAndUploadCell : UITableViewCell
@property (nonatomic,strong) IBOutlet UIButton *createFolderBtn;
@property (nonatomic,strong) IBOutlet UIButton *uploadBtn;
@property (nonatomic,strong) IBOutlet UIView *line1;
@property (nonatomic,strong) IBOutlet UIView *line2;
@property (nonatomic,assign) id<NewFolderAndUploadCellDelegate> delegate;
-(IBAction)newFolderAction:(id)sender;
-(IBAction)uploadAction:(id)sender;
@end
