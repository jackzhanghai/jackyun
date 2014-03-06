//
//  PCFileCell.m
//  popoCloud
//
//  Created by xuyang on 13-2-25.
//
//

#import "PCFileCell.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityStringOperate.h"
#import "FileUploadManager.h"

//展开cell按钮
#define ARROWIMAGE_RECT_S CGRectMake([[UIScreen mainScreen] bounds].size.width - 31,21,21,21)
#define ARROWIMAGE_RECT_H CGRectMake([[UIScreen mainScreen] bounds].size.height - 38,21,21,21)
#define ARROWIMAGE_RECT_S_IPAD CGRectMake([[UIScreen mainScreen] bounds].size.width - 61,21,21,21)
#define ARROWIMAGE_RECT_H_IPAD CGRectMake([[UIScreen mainScreen] bounds].size.height - 52,21,21,21)

//展开cell的触发区域
#define ARROWIMAGE_CLICK_RECT_S CGRectMake([[UIScreen mainScreen] bounds].size.width - 80,0,80,60)
#define ARROWIMAGE_CLICK_RECT_H CGRectMake([[UIScreen mainScreen] bounds].size.height - 80 ,0,80,60)

//展开后的三角形
#define TIPIMAGE_RECT_S CGRectMake([[UIScreen mainScreen] bounds].size.width - 26,TABLE_CELL_HEIGHT - 7,12,7)
#define TIPIMAGE_RECT_H CGRectMake([[UIScreen mainScreen] bounds].size.height - 36,TABLE_CELL_HEIGHT - 7,12,7)
#define TIPIMAGE_RECT_S_IPAD CGRectMake([[UIScreen mainScreen] bounds].size.width - 56,TABLE_CELL_HEIGHT - 7,12,7)
#define TIPIMAGE_RECT_H_IPAD CGRectMake([[UIScreen mainScreen] bounds].size.height - 46,TABLE_CELL_HEIGHT - 7,12,7)

#define STATUSIMAGE_RECT CGRectMake(27, 27, 13, 13)

@implementation PCFileCell
@synthesize arrowImageView;
@synthesize tipImageView;
@synthesize stutasImageView;
@synthesize currentStatus;
@synthesize delegate;
@synthesize fileDownloadingInfo;
@synthesize fileDownloadedInfo;
@synthesize progressView;
@synthesize lblTime;
@synthesize lblPath;
@synthesize indexRow;
@synthesize indexSection;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        // Initialization code
//        if (IS_IPAD)
//        {
//            self.arrowImageView = [[UIImageView alloc] initWithFrame:ARROWIMAGE_RECT_IPAID];
//        }
//        else
//        {
            self.arrowImageView = [[[UIImageView alloc] initWithFrame:ARROWIMAGE_RECT_S] autorelease];
            self.tipImageView = [[[UIImageView alloc] initWithFrame:TIPIMAGE_RECT_S] autorelease];
            self.stutasImageView = [[[UIImageView alloc] initWithFrame:STATUSIMAGE_RECT] autorelease];
//        }
        arrowImageView.image = [UIImage imageNamed:[PCUtilityFileOperate getImgName:@"arrow_down"]];
        [self.contentView addSubview:arrowImageView];
        
        tipImageView.image = [UIImage imageNamed:[PCUtilityFileOperate getImgName:@"bg_contraction_arrow"]];
        
        currentStatus = kStatusNoDownload;
        self.fileDownloadingInfo = nil;
        self.fileDownloadedInfo = nil;
        
        CGRect frame = CGRectMake(arrowImageView.frame.origin.x - 126, 32, 116, 18);
        self.lblTime = [[[UILabel alloc] initWithFrame:frame] autorelease];
        lblTime.font = [lblTime.font fontWithSize:14];
        lblTime.textAlignment =  UITextAlignmentRight;
        lblTime.textColor = [UIColor grayColor];
        lblTime.backgroundColor = [UIColor clearColor];
        
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        
        [self addObserver:self forKeyPath:@"currentStatus" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"fileDownloadedInfo" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"fileDownloadingInfo" options:NSKeyValueObservingOptionNew context:nil];
        
        selectImageView = [[UIImageView alloc] initWithFrame:CGRectMake(-40, 0, 16, 16)];
        [self.contentView addSubview:selectImageView];
        selectImageView.image = [UIImage imageNamed:@"checkbox"];
    }
    return self;
}

-(void)fileDownloaded
{
    if (fileDownloadedInfo !=nil)
    {
        NSString *name = [fileDownloadedInfo.hostPath lastPathComponent];
        
        self.textLabel.text = @"";
        self.detailTextLabel.text = @"";
        
        self.textLabel.text = name;
        self.detailTextLabel.text = [PCUtilityFileOperate formatFileSize:[fileDownloadedInfo.size longLongValue] isNeedBlank:YES];
        
        lblTime.text = [PCUtilityStringOperate formatTime:[fileDownloadedInfo.recordTime doubleValue] formatString:@"yyyy-MM-dd HH:mm"];
        lblTime.frame = CGRectMake(arrowImageView.frame.origin.x - 126, 32, 116, 18);
        
        [self addSubview:lblTime];
        self.imageView.image = [UIImage imageNamed:[PCUtilityFileOperate getImgByExt:[name pathExtension]]];
    }

}
-(void)downloading
{
    if (nil != fileDownloadingInfo)
    {
        self.textLabel.text = @"";
        self.detailTextLabel.text = @"";
        
        self.textLabel.text = [fileDownloadingInfo.hostPath lastPathComponent];
        self.detailTextLabel.text = @"";
        
        if (currentStatus == kStatusDownloading)
        {
            [self createProgressView];
            
            PCProgressView *tmp = [[PCUtilityFileOperate downloadManager].tableProgressView objectForKey:fileDownloadingInfo.hostPath];
            progressView.progress = tmp.progress;
        }
        else if (progressView)
        {
            [progressView removeFromSuperview];
            self.progressView = nil;
        }
        
        self.imageView.image = [UIImage imageNamed:[PCUtilityFileOperate getImgByExt:[fileDownloadingInfo.hostPath pathExtension]]];
    }
}
-(void)changeStatus
{
    [stutasImageView removeFromSuperview];
    switch (currentStatus)
    {
        case kStatusNoDownload: //没有下载（未收藏）
        {
            break;
        }
        case kStatusDownloading: //正在下载
        {
            if (lblTime) {
                lblTime.text = nil;
            }
            [stutasImageView initWithImage:[UIImage imageNamed:[PCUtilityFileOperate getImgName:@"favorite_none"]]];
            [stutasImageView setFrame:STATUSIMAGE_RECT];
            [self.imageView addSubview:stutasImageView];
            if (nil == fileDownloadingInfo)
            {
                self.detailTextLabel.text = NSLocalizedString(@"STATUS_RUN", nil);
            }
            break;
        }
        case kStatusDownloadPause: //排队等待下载
        {
            if (lblTime) {
                lblTime.text = nil;
            }
            [stutasImageView initWithImage:[UIImage imageNamed:[PCUtilityFileOperate getImgName:@"favorite_none"]]];
            [stutasImageView setFrame:STATUSIMAGE_RECT];
            [self.imageView addSubview:stutasImageView];
            if (fileDownloadingInfo)
            {
                self.detailTextLabel.text = NSLocalizedString(@"STATUS_PAUSE", nil);
            }
            break;
        }
        case kStatusDownloadStop: //暂停下载
        {
            if (lblTime) {
                lblTime.text = nil;
            }
            if (progressView) {
                [progressView removeFromSuperview];
                self.progressView = nil;
            }
            [stutasImageView initWithImage:[UIImage imageNamed:[PCUtilityFileOperate getImgName:@"favorite_none"]]];
            [stutasImageView setFrame:STATUSIMAGE_RECT];
            [self.imageView addSubview:stutasImageView];
            if (fileDownloadingInfo)
            {
                self.detailTextLabel.text = NSLocalizedString(@"STATUS_STOP", nil);
            }
            break;
        }
        case kStatusDownloaded: //已经下载完（被收藏了）
        {
            [stutasImageView initWithImage:[UIImage imageNamed:[PCUtilityFileOperate getImgName:@"favorite"]]];
            [stutasImageView setFrame:STATUSIMAGE_RECT];
            [self.imageView addSubview:stutasImageView];
            [self fileDownloaded];
            break;
        }
        case kStatusUploading://正在上传
        {
            [self createProgressView];
            self.progressView.progress = [FileUploadManager sharedManager].progressValue;
            self.detailTextLabel.text = nil;
            break;
        }
        case kStatusWaitUploading://等待上传
        {
            [self.contentView addSubview:lblPath];
            [self.contentView addSubview:lblTime];
            break;
        }
        case kStatusPauseUploading://暂停上传
        {
            [self.contentView addSubview:lblPath];
            [self.contentView addSubview:lblTime];
            break;
        }
        default:
        {
            break;
        }
    }
    
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"currentStatus"])
    {
        [self downloading];
        [self changeStatus];
    }
    else if ([keyPath isEqualToString:@"fileDownloadedInfo"])
    {
        [self fileDownloaded];
        [self changeStatus];
    }
    else if ([keyPath isEqualToString:@"fileDownloadingInfo"])
    {
        [self downloading];
        [self changeStatus];
    }
    [self layoutSubviews];
    
}
- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
         hasPathLbl:(BOOL)hasPath
{
    if (self = [self initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        if (hasPath)
        {
            self.lblPath = [[[UILabel alloc] initWithFrame:CGRectMake(95, 32, 65, 18)] autorelease];
            lblPath.font = [UIFont systemFontOfSize:14];
            lblPath.textColor = [UIColor grayColor];
            lblPath.backgroundColor = [UIColor clearColor];
        }
    }
    return  self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"currentStatus" context:nil];
    [self removeObserver:self forKeyPath:@"fileDownloadedInfo" context:nil];
    [self removeObserver:self forKeyPath:@"fileDownloadingInfo" context:nil];
    [arrowImageView removeFromSuperview];
    [tipImageView removeFromSuperview];
    [stutasImageView removeFromSuperview];
    [selectImageView removeFromSuperview];
    [selectImageView release];
    
    [progressView removeFromSuperview];
    [lblTime removeFromSuperview];
    [lblPath removeFromSuperview];
    
//    [arrowImageView release];
    self.arrowImageView = nil;
    
//    [tipImageView release];
    self.tipImageView = nil;
    
//    [stutasImageView release];
    self.stutasImageView = nil;
    
    self.delegate = nil;
    
    
    self.progressView = nil;
    self.lblTime = nil;
    self.lblPath = nil;
    
    self.fileDownloadingInfo = nil;
    self.fileDownloadedInfo = nil;
    
    [super dealloc];
}

/**
 * 将textLabel长度减小。避免挡住展开状态按钮
 */
- (void) layoutSubviews
{
    [super layoutSubviews];
    
    if ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft ||[UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)
    {
        if (IS_IPAD)
        {
            self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x , self.textLabel.frame.origin.y -3, [[UIScreen mainScreen] bounds].size.height - 240, self.textLabel.frame.size.height);
            self.arrowImageView.frame = ARROWIMAGE_RECT_H_IPAD;
            self.tipImageView.frame = TIPIMAGE_RECT_H_IPAD;
        }
        else
        {
            self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x , self.textLabel.frame.origin.y -3, [[UIScreen mainScreen] bounds].size.height - 120, self.textLabel.frame.size.height);
            self.arrowImageView.frame = ARROWIMAGE_RECT_H;
            self.tipImageView.frame = TIPIMAGE_RECT_H;
        }
        self.lblTime.frame = CGRectMake(arrowImageView.frame.origin.x - 120, 32, 116, 18);
    }
    else
    {
        if (IS_IPAD)
        {
            self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x , self.textLabel.frame.origin.y -3, [[UIScreen mainScreen] bounds].size.width - 240 , self.textLabel.frame.size.height);
            self.arrowImageView.frame = ARROWIMAGE_RECT_S_IPAD;
            self.tipImageView.frame = TIPIMAGE_RECT_S_IPAD;
        }
        else
        {
            self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x , self.textLabel.frame.origin.y -3, [[UIScreen mainScreen] bounds].size.width - 120 , self.textLabel.frame.size.height);
            self.arrowImageView.frame = ARROWIMAGE_RECT_S;
            self.tipImageView.frame = TIPIMAGE_RECT_S;
        }
        self.lblTime.frame = CGRectMake(arrowImageView.frame.origin.x - 126, 32, 116, 18);
    }
    
    if (self.progressView)
        self.progressView.frame = CGRectMake(62, 40, arrowImageView.frame.origin.x - 70, 12);//70=62+8
    
    if (self.lblPath)
        self.lblPath.frame = CGRectMake(95, 32, self.lblTime.frame.origin.x - 105, 18);//105=95+10
    if (self.editing) {
        selectImageView.center = CGPointMake(-10, self.bounds.size.height/2.0);
    }
    else
    {
        selectImageView.center = CGPointMake(-20, self.bounds.size.height/2.0);
    }
    
}

- (void)changeArrowImageWithExpansion:(BOOL)isExpansion
{
    if (isExpansion)
    {
        self.arrowImageView.image = [UIImage imageNamed:[PCUtilityFileOperate getImgName:@"arrow_up"]];
         [self addSubview:tipImageView];
    }
    else
    {
        self.arrowImageView.image = [UIImage imageNamed:[PCUtilityFileOperate getImgName:@"arrow_down"]];
        [tipImageView removeFromSuperview];
    }
}

- (void)prepareForReuse
{
    [self changeSelectImage:NO hidden:YES];
    [lblTime removeFromSuperview];
    [lblPath removeFromSuperview];
    [progressView removeFromSuperview];
    self.progressView = nil;
}
#pragma mark - private methods

- (void)createProgressView
{
    if (!self.progressView)
    {
        self.progressView = [[[PCProgressView alloc] initWithFrame:CGRectMake(62, 40, arrowImageView.frame.origin.x - 70, 12)] autorelease];
        [progressView initProgressLabel]; 
    }
    
    [self.contentView addSubview:progressView];
}

#pragma mark - public methods

- (void)initPCFileDownloadingInfo:(PCFileDownloadingInfo *) downloadingInfo andStatus:(DownloadStatus)status
{
    self.fileDownloadingInfo = downloadingInfo;
    self.fileDownloadedInfo = nil;
    self.currentStatus = status;
    [self setNeedsDisplay];
}

- (void)initPCFileDownloadedInfo:(PCFileDownloadedInfo *) downloadedInfo andStatus:(DownloadStatus)status
{
    self.fileDownloadedInfo = downloadedInfo;
    self.fileDownloadingInfo = nil;
    self.currentStatus = status;
    [self setNeedsDisplay];
}

- (void)changeStatusImageWithFileStatus:(DownloadStatus)status
{
    self.currentStatus = status;
    
    [self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
   [super touchesBegan:touches withEvent:event];
}

- (void)changeSelectImage:(BOOL)selected
{
    [self changeSelectImage:selected hidden:NO];
}

- (void)changeSelectImage:(BOOL)selected hidden:(BOOL)hidden
{
    if (selected)
    {
        selectImageView.image = [UIImage imageNamed:@"checkbox_d"];
    }
    else
    {
        selectImageView.image = [UIImage imageNamed:@"checkbox"];
    }
    
    selectImageView.hidden = hidden;
}
-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    if (!editing)
    {
        self.indentationLevel = 0;
        [self changeSelectImage:NO hidden:YES];
    }
    else
    {
        self.indentationLevel = 1;
    }
    if (arrowImageView) {
        arrowImageView.hidden = indexSection < 0 ? YES : editing;
    }
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
	CGPoint endPoint = [touch locationInView: self];
//    Z_OK?YES:NO
//    if(CGRectContainsPoint(IS_IPAD?ARROWIMAGE_RECT_IPAID:ARROWIMAGE_RECT_IPHONE, endPoint))
    
    if (indexSection < 0) {
        if (!selectImageView.hidden && endPoint.x < self.contentView.frame.origin.x + self.imageView.frame.origin.x) {
            if(delegate && [delegate respondsToSelector:@selector(eidtStatusSelected:andCell:)])
            {
                NSIndexPath *path = [NSIndexPath indexPathForRow:indexRow inSection:0];
                [delegate eidtStatusSelected:path andCell:self];
            }
        }
        else {
            if(delegate && [delegate respondsToSelector:@selector(didSelectCell:)])
            {
                NSIndexPath *path = [NSIndexPath indexPathForRow:indexRow inSection:0];
                [delegate didSelectCell:path];
            }
        }
        return;
    }
    
    if (self.isEditing)
    {
        if(delegate && [delegate respondsToSelector:@selector(eidtStatusSelected:andCell:)])
        {
            NSIndexPath *path = [NSIndexPath indexPathForRow:indexRow inSection:indexSection];
            [delegate eidtStatusSelected:path andCell:self];
        }
        return;
    }
    
    
    if ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft ||[UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)
    {
        
        if(CGRectContainsPoint(ARROWIMAGE_CLICK_RECT_H, endPoint))
        {
            if(delegate && [delegate respondsToSelector:@selector(expansionView:)])
            {
                 NSIndexPath *path = [NSIndexPath indexPathForRow:indexRow inSection:indexSection];
                [delegate expansionView:path];
            }
        }
        else
        {
            if(delegate && [delegate respondsToSelector:@selector(didSelectCell:)])
            {
                 NSIndexPath *path = [NSIndexPath indexPathForRow:indexRow inSection:indexSection];
                [delegate didSelectCell:path];
            }
        }

    }
    else
    {
        if(CGRectContainsPoint(ARROWIMAGE_CLICK_RECT_S, endPoint))
        {
            if(delegate && [delegate respondsToSelector:@selector(expansionView:)])
            {
                NSIndexPath *path = [NSIndexPath indexPathForRow:indexRow inSection:indexSection];
                [delegate expansionView:path];
            }
        }
        else
        {
            if(delegate && [delegate respondsToSelector:@selector(didSelectCell:)])
            {
                NSIndexPath *path = [NSIndexPath indexPathForRow:indexRow inSection:indexSection];
                [delegate didSelectCell:path];
            }
        }

    }
    
}

@end
