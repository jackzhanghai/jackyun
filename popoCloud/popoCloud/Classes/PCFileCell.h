//
//  PCFileCell.h
//  popoCloud
//
//  Created by xuyang on 13-2-25.
//
//

#import <UIKit/UIKit.h>
#import "PCFileDownloadingInfo.h"
#import "PCFileDownloadedInfo.h"
#import "PCProgressView.h"
#import "PCUtility.h"
@class PCFileCell;
@protocol PCFileCellDelegate <NSObject>
@optional
- (void)expansionView:(NSIndexPath *)token;
- (void)didSelectCell:(NSIndexPath *)token;
- (void)eidtStatusSelected:(NSIndexPath *)token andCell:(PCFileCell *)cell;//在编辑状态下选中行
@end

@interface PCFileCell : UITableViewCell
{
    UIImageView *arrowImageView;
    UIImageView *tipImageView;
    UIImageView *stutasImageView;
    DownloadStatus currentStatus;
    id<PCFileCellDelegate> delegate;
    
    //正在下载和下载排队用到
    PCFileDownloadingInfo *fileDownloadingInfo;
    PCProgressView *progressView;
    
    //下载完成
    PCFileDownloadedInfo *fileDownloadedInfo;
    UILabel *lblTime;
    UILabel *lblPath;
    
    //将以前NSIndexPath替换。怀疑一些crash与NSIndexPath的释放有关
    int indexRow;
    int indexSection;
    
    UIImageView *selectImageView;
}


@property (nonatomic, retain) UIImageView *arrowImageView;
@property (nonatomic, retain) UIImageView *tipImageView;
@property (nonatomic, retain) UIImageView *stutasImageView;
@property (nonatomic, assign) DownloadStatus currentStatus;
@property (nonatomic, assign) id<PCFileCellDelegate> delegate;
@property (nonatomic, retain) PCFileDownloadingInfo *fileDownloadingInfo;
@property (nonatomic, retain) PCFileDownloadedInfo *fileDownloadedInfo;
@property (nonatomic, retain) PCProgressView *progressView;
@property (nonatomic, retain) UILabel *lblTime;
@property (nonatomic, retain) UILabel *lblPath;
@property (nonatomic, assign) int indexRow;
@property (nonatomic, assign) int indexSection;

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
         hasPathLbl:(BOOL)hasPath;

/**
 * 根据展开和关闭状态改变展开图标
 */
- (void)changeArrowImageWithExpansion:(BOOL)isExpansion;

/**
 * 根据收藏状态改变状态图标
 */
- (void)changeStatusImageWithFileStatus:(DownloadStatus)status;

/**
 * 初始化正在下载和排队下载的视图
 */
- (void)initPCFileDownloadingInfo:(PCFileDownloadingInfo *) fileDownloadingInfo andStatus:(DownloadStatus)status;

/**
 * 初始化下载完成的视图
 */
- (void)initPCFileDownloadedInfo:(PCFileDownloadedInfo *) fileDownloadedInfo andStatus:(DownloadStatus)status;
/**
 * 在编辑状态下改变选择图片的状态
 */
- (void)changeSelectImage:(BOOL)selected;
- (void)changeSelectImage:(BOOL)selected hidden:(BOOL)hidden;
@end
