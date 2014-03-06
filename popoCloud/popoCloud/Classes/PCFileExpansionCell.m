//
//  PCFileExpansionCell.m
//  popoCloud
//
//  Created by xuyang on 13-2-25.
//
//

#import "PCFileExpansionCell.h"
#import "PCUtility.h"
#import "UIButton+UIButtonImageWithLable.h"

@implementation PCFileExpansionCell
@synthesize currentfileCellType;
@synthesize indexPath;
@synthesize shareButton;
@synthesize cancelShareButton;
@synthesize collectButton;
@synthesize cancelCollectButton;
@synthesize pauseButton;
@synthesize resumeButton;
@synthesize cancelUploadButton;
@synthesize delegate;
@synthesize deleteButton;
@synthesize reNameButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        UIImageView *tmp = [[[UIImageView alloc] initWithFrame:self.backgroundView.bounds] autorelease];
        tmp.image = [UIImage imageNamed:@"bg_contraction.png"];
        self.backgroundView = tmp;
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
    self.indexPath = nil;
    self.shareButton = nil;
    self.cancelShareButton = nil;
    self.collectButton = nil;
    self.cancelCollectButton = nil;
    self.pauseButton = nil;
    self.resumeButton = nil;
	self.cancelUploadButton = nil;
    self.deleteButton = nil;
    self.reNameButton =nil;

    [super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    [shareButton removeFromSuperview];
    [cancelShareButton removeFromSuperview];
    [collectButton removeFromSuperview];
    [cancelCollectButton removeFromSuperview];
    [pauseButton removeFromSuperview];
    [resumeButton removeFromSuperview];
	[cancelUploadButton removeFromSuperview];
    [deleteButton removeFromSuperview];
    [reNameButton removeFromSuperview];
}

- (void)drawRect:(CGRect)rect
{
    [self prepareForReuse];
    switch (currentfileCellType)
    {
        case FILELIST_FOLDER:
        {
            [self createShareBtn];
            [self createDeleteBtn];
            [self createRenameBtn];
            if ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft ||[UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)
            {
                self.shareButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.height/4 - 45 , 0, 90,60);
                self.reNameButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.height/2 - 45 , 0, 90,60);
                self.deleteButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.height*3/4 - 45 , 0, 90,60);
            }
            else
            {
                self.shareButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.width/4 - 45, 0, 90,60);
                self.reNameButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.width/2 - 45, 0, 90,60);
                self.deleteButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.width*3/4 - 45, 0, 90,60);
            }
            break;
        }
        case FILELIST_FILE_NO_FAVORITE:
        {
            //没有收藏过的文件  分享  收藏
           [self createShareBtn];
           [self createCollectBtn];
           [self createDeleteBtn];
           [self createRenameBtn];
           
            if ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft ||[UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)
            {
                self.collectButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.height/5 - 45 , 0, 90,60);
                self.shareButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.height*2/5 - 45 , 0, 90,60);
                self.reNameButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.height*3/5 - 45 , 0, 90,60);
                self.deleteButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.height*4/5 - 45 , 0, 90,60);
            }
            else
            {
                self.collectButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.width/5 - 45 , 0, 90,60);
                self.shareButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.width*2/5 - 45 , 0, 90,60);
                self.reNameButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.width*3/5 - 45 , 0, 90,60);
                self.deleteButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.width*4/5 - 45 , 0, 90,60);
            }
            break;
        }
        case FILELIST_FILE_FAVORITE:
        {
            //收藏过的文件  分享  取消收藏
//            [self createCancelCollectBtn];
            [self createCollectBtn];
            [self createShareBtn];
            [self createDeleteBtn];
            [self createRenameBtn];
            if ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft ||[UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)
            {
                self.collectButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.height/5 - 45 , 0, 90,60);
                self.shareButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.height*2/5 - 45 , 0, 90,60);
                self.reNameButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.height*3/5 - 45 , 0, 90,60);
                self.deleteButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.height*4/5 - 45 , 0, 90,60);
            }
            else
            {
                self.collectButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.width/5 - 45 , 0, 90,60);
                self.shareButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.width*2/5 - 45 , 0, 90,60);
                self.reNameButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.width*3/5 - 45 , 0, 90,60);
                self.deleteButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.width*4/5 - 45 , 0, 90,60);
            }
            break;
        }
        case FAVORITELIST_STATUS_RUN:
        {
            //正在下载的  暂停下载  取消收藏
            [self createPauseBtn:NSLocalizedString(@"StopCollect", nil)];

            self.cancelCollectButton = [[[UIButton alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 120, 0, 90,60)] autorelease];
            
            [cancelCollectButton setImage:[UIImage imageNamed:@"del.png"] withTitle:NSLocalizedString(@"Delete", nil) forState:UIControlStateNormal];
            
            [cancelCollectButton addTarget:self action:@selector(downCancelCollectButtonClick:) forControlEvents:UIControlEventTouchUpInside];

            [self.contentView addSubview: cancelCollectButton];
            
            [self setBtnFrame:pauseButton rightBtn:cancelCollectButton];
            break;
        }
        case FAVORITELIST_STATUS_STOP:
        {
            //暂停下载的cell  继续下载  取消收藏
            [self createResumeBtn:NSLocalizedString(@"ContinueCollect", nil)];
            
            self.cancelCollectButton = [[[UIButton alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 120, 0, 90,60)] autorelease];
            
            [cancelCollectButton setImage:[UIImage imageNamed:@"del.png"] withTitle:NSLocalizedString(@"Delete", nil) forState:UIControlStateNormal];
            
            [cancelCollectButton addTarget:self action:@selector(downCancelCollectButtonClick:) forControlEvents:UIControlEventTouchUpInside];

            [self.contentView addSubview: cancelCollectButton];
            
            [self setBtnFrame:resumeButton rightBtn:cancelCollectButton];
            break;
        }
        case FAVORITELIST_OTHER:
        {
            //下载完成的 取消下载(删除操作)
            self.cancelCollectButton = [[[UIButton alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width/2 - 40, 0, 90,60)] autorelease];
            
            [cancelCollectButton setImage:[UIImage imageNamed:@"del.png"] withTitle:NSLocalizedString(@"Delete", nil) forState:UIControlStateNormal];
            
            [cancelCollectButton addTarget:self action:@selector(downCancelCollectButtonClick:) forControlEvents:UIControlEventTouchUpInside];
            
            if ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft ||[UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)
            {
                self.cancelCollectButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.height/2 - 40 , 0, 90,60);
            }
            else
            {
                self.cancelCollectButton.frame =  CGRectMake([[UIScreen mainScreen] bounds].size.width/2 - 40, 0, 90,60);
            }

            [self.contentView addSubview: cancelCollectButton];
            break;
        }
        case SHARELIST_FILE:
        {
            //分享的文件  分享  取消分享
            self.shareButton = [[[UIButton alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width/3 - 40, 0, 90,60)] autorelease];
            
            [shareButton setImage:[UIImage imageNamed:@"icon_share.png"] withTitle:NSLocalizedString(@"Share", nil) forState:UIControlStateNormal];
            
            [shareButton addTarget:self action:@selector(shareButtonClick:) forControlEvents:UIControlEventTouchUpInside];
            
            [self.contentView addSubview: shareButton];
            
            self.cancelShareButton = [[[UIButton alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 120, 0, 90,60)] autorelease];
            
            [cancelShareButton setImage:[UIImage imageNamed:@"icon_noshare.png"] withTitle:NSLocalizedString(@"CancelShare", nil) forState:UIControlStateNormal];
            
            [cancelShareButton addTarget:self action:@selector(cancelShareButtonClick:) forControlEvents:UIControlEventTouchUpInside];
            
            [self.contentView addSubview: cancelShareButton];
            
            [self setBtnFrame:shareButton rightBtn:cancelShareButton];
            break;
        }
		case FILE_UPLOAD_PAUSE:
		{
            [self createPauseBtn:NSLocalizedString(@"PauseUpload", nil)];
            [self createCancelUploadBtn];
            [self setBtnFrame:pauseButton rightBtn:cancelUploadButton];
			break;
		}
        case FILE_UPLOAD_RESUME:
        {
            [self createResumeBtn:NSLocalizedString(@"ResumeUpload", nil)];
            [self createCancelUploadBtn];
            [self setBtnFrame:resumeButton rightBtn:cancelUploadButton];
            break;
        }
        default:
            break;
    }
}

#pragma mark - private methods
- (void)createShareBtn
{
    self.shareButton = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
    [shareButton setImage:[UIImage imageNamed:@"icon_share.png"] withTitle:NSLocalizedString(@"Share", nil) forState:UIControlStateNormal];
    [shareButton addTarget:self action:@selector(shareButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview: shareButton];
}

- (void)createDeleteBtn
{
    self.deleteButton = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
    [deleteButton setImage:[UIImage imageNamed:@"del.png"] withTitle:NSLocalizedString(@"Delete", nil) forState:UIControlStateNormal];
    [deleteButton addTarget:self action:@selector(deleteButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview: deleteButton];
}

- (void)createRenameBtn
{
    self.reNameButton = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
    [reNameButton setImage:[UIImage imageNamed:@"name.png"] withTitle:NSLocalizedString(@"Rename", nil) forState:UIControlStateNormal];
    [reNameButton addTarget:self action:@selector(reNameButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview: reNameButton];
}

- (void)createCollectBtn
{
    self.collectButton = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
    [collectButton setImage:[UIImage imageNamed:@"download.png"] withTitle:NSLocalizedString(@"Collect", nil) forState:UIControlStateNormal];
    [collectButton addTarget:self action:@selector(collectButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview: collectButton];
}

- (void)createCancelCollectBtn
{
    self.cancelCollectButton = [[[UIButton alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 120, 0, 90,60)] autorelease];
    
    [cancelCollectButton setImage:[UIImage imageNamed:@"icon_cancel.png"] withTitle:NSLocalizedString(@"CancelCollect", nil) forState:UIControlStateNormal];
    
    [cancelCollectButton addTarget:self action:@selector(cancelCollectButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview: cancelCollectButton];
}


- (void)createPauseBtn:(NSString *)title
{
    self.pauseButton = [[[UIButton alloc] init] autorelease];
    
    [pauseButton setImage:[UIImage imageNamed:@"icon_stop.png"]
                withTitle:title
                 forState:UIControlStateNormal];
    
    [pauseButton addTarget:self
                    action:@selector(pauseButtonClick:)
          forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:pauseButton];
}

- (void)createResumeBtn:(NSString *)title
{
    self.resumeButton = [[[UIButton alloc] init] autorelease];
    
    [resumeButton setImage:[UIImage imageNamed:@"icon_play.png"]
                 withTitle:title
                  forState:UIControlStateNormal];
    
    [resumeButton addTarget:self
                     action:@selector(resumeButtonClick:)
           forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:resumeButton];
}

- (void)createCancelUploadBtn
{
    self.cancelUploadButton = [[[UIButton alloc] init] autorelease];
    
    [cancelUploadButton setImage:[UIImage imageNamed:@"icon_cancel.png"]
                       withTitle:NSLocalizedString(@"CancelUpload", nil)
                        forState:UIControlStateNormal];
    
    [cancelUploadButton addTarget:self
                           action:@selector(cancelUploadButtonClick:)
                 forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:cancelUploadButton];
}

- (void)setBtnFrame:(UIButton *)leftBtn rightBtn:(UIButton *)rightBtn
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    if ([UIApplication sharedApplication].statusBarOrientation > UIDeviceOrientationPortraitUpsideDown)
    {
        NSInteger height = size.height;
        leftBtn.frame = CGRectMake(height / 3 - 40, 0, 90, 60);
        rightBtn.frame = CGRectMake(height - (IS_IPAD ? 370 : 180), 0, 90, 60);
    }
    else
    {
        NSInteger width = size.width;
        leftBtn.frame = CGRectMake(width / 3 - 40, 0, 90, 60);
        rightBtn.frame = CGRectMake(width - (IS_IPAD ? 260 : 160), 0, 90, 60);
    }
}

#pragma mark - public methods

- (void)initActionContent: (PCFileCellType)fileCellType
{
    self.currentfileCellType = fileCellType;
    [self setNeedsDisplay];
}

#pragma mark - callback methods

-(void)shareButtonClick:(UIButton *)btn
{
    if(delegate && [delegate respondsToSelector:@selector(shareButtonClick)])
    {
        [delegate shareButtonClick];
    }

}

-(void)cancelShareButtonClick:(UIButton *)btn
{
    if(delegate && [delegate respondsToSelector:@selector(cancelShareButtonClick)])
    {
        [delegate cancelShareButtonClick];
    }
    
}

-(void)collectButtonClick:(UIButton *)btn
{
    if(delegate && [delegate respondsToSelector:@selector(collectButtonClick)])
    {
        [delegate collectButtonClick];
    }
}

-(void)cancelCollectButtonClick:(UIButton *)btn
{
    if(delegate && [delegate respondsToSelector:@selector(cancelCollectButtonClick)])
    {
        [delegate cancelCollectButtonClick];
    }
}

-(void)downCancelCollectButtonClick:(UIButton *)btn
{
    if(delegate && [delegate respondsToSelector:@selector(downCancelCollectButtonClick)])
    {
        [delegate downCancelCollectButtonClick];
    }
}

-(void)pauseButtonClick:(UIButton *)btn
{
    if(delegate && [delegate respondsToSelector:@selector(pauseButtonClick:)])
    {
        [delegate pauseButtonClick:self];
    }
}

-(void)resumeButtonClick:(UIButton *)btn
{
    if(delegate && [delegate respondsToSelector:@selector(resumeButtonClick:)])
    {
        [delegate resumeButtonClick:self];
    }
}

- (void)cancelUploadButtonClick:(UIButton *)btn
{
	if(delegate && [delegate respondsToSelector:@selector(cancelUploadButtonClick:)])
    {
        [delegate cancelUploadButtonClick:self];
    }
}

- (void)deleteButtonClick:(UIButton *)btn
{
	if(delegate && [delegate respondsToSelector:@selector(deleteButtonClick:)])
    {
        [delegate deleteButtonClick:self];
    }
}

- (void)reNameButtonClick:(UIButton *)btn
{
	if(delegate && [delegate respondsToSelector:@selector(reNameButtonClick:)])
    {
        [delegate reNameButtonClick:self];
    }
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
//   重写touches方法 内容为空 就不会执行didSelectRowAtIndexPath方法
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
//    [super touchesEnded:touches withEvent:event];
}

@end
