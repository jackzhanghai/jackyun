//
//  PCFileExpansionCell.h
//  popoCloud
//
//  Created by xuyang on 13-2-25.
//
//

#import <UIKit/UIKit.h>
@protocol PCFileExpansionCellDelegate;

typedef enum
{
    //文件集-文件夹
	FILELIST_FOLDER = 0,
    //文件集-文件-没有收藏
	FILELIST_FILE_NO_FAVORITE,
    //文件集-文件-已收藏
    FILELIST_FILE_FAVORITE,
    //收藏列表 - 正在下载
    FAVORITELIST_STATUS_RUN,
    //收藏列表 - 暂停下载
    FAVORITELIST_STATUS_STOP,
    //收藏列表 - 其他
    FAVORITELIST_OTHER,
    //分享列表
    SHARELIST_FILE,
	//暂停上传
	FILE_UPLOAD_PAUSE,
    //恢复上传
    FILE_UPLOAD_RESUME,
} PCFileCellType;

@interface PCFileExpansionCell : UITableViewCell
{
    PCFileCellType currentfileCellType;
    NSIndexPath *indexPath;
    //分享按钮
    UIButton *shareButton;
    //收藏按钮
    UIButton *collectButton;
    //取消收藏按钮
    UIButton *cancelCollectButton;
    //暂停下载
    UIButton *pauseButton;
    //继续下载
    UIButton *resumeButton;
    //取消分享
    UIButton *cancelShareButton;
	//取消上传
    UIButton *cancelUploadButton;
    //删除按钮
    UIButton *deleteButton;
	//重命名按钮
    UIButton *reNameButton;

    id<PCFileExpansionCellDelegate> delegate;
}

@property (nonatomic, assign) PCFileCellType currentfileCellType;
@property (nonatomic, retain) NSIndexPath *indexPath;
@property (nonatomic, retain) UIButton *shareButton;
@property (nonatomic, retain) UIButton *collectButton;
@property (nonatomic, retain) UIButton *cancelCollectButton;
@property (nonatomic, retain) UIButton *pauseButton;
@property (nonatomic, retain) UIButton *resumeButton;
@property (nonatomic, retain) UIButton *cancelShareButton;
@property (nonatomic, retain) UIButton *cancelUploadButton;
@property (nonatomic, retain) UIButton *deleteButton;
@property (nonatomic, retain) UIButton *reNameButton;

@property (nonatomic, assign) id<PCFileExpansionCellDelegate> delegate;

- (void)initActionContent: (PCFileCellType)fileCellType;
@end

@protocol PCFileExpansionCellDelegate <NSObject>

@optional

- (void)shareButtonClick;
- (void)cancelShareButtonClick;
- (void)collectButtonClick;
- (void)cancelCollectButtonClick;
- (void)pauseButtonClick:(PCFileExpansionCell *)cell;
- (void)resumeButtonClick:(PCFileExpansionCell *)cell;
- (void)downCancelCollectButtonClick;

- (void)deleteButtonClick:(PCFileExpansionCell *)cell;
- (void)reNameButtonClick:(PCFileExpansionCell *)cell;

- (void)cancelUploadButtonClick:(PCFileExpansionCell *)cell;

@end
