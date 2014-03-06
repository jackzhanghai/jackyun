//
//  FileUploadController.m
//  popoCloud
//
//  Created by leijun on 13-3-14.
//
//

#import "FileUploadController.h"
#import "FileUploadManager.h"
#import "FileUploadInfo.h"
#import "PCUtilityStringOperate.h"

@implementation FileUploadController
@synthesize lblDes;
#pragma mark - methods from super class

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"UploadManager", nil);
    self.view.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    self.tableView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"FileUploadView"];
    [MobClick event:UM_UPLOAD_MANAGER];
    
    if ([FileUploadManager sharedManager].uploadTotalNum == 0)
    {
        [self createNoUploadView];
    }
    else
    {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.scrollEnabled = YES;
        
        if (self.imgView)
        {
            [self.imgView removeFromSuperview];
            self.imgView = nil;
        }
        
        if (self.lblTip)
        {
            [self.lblTip removeFromSuperview];
            self.lblTip = nil;
        }
        if (self.lblDes)
        {
            [self.lblDes removeFromSuperview];
            self.lblDes = nil;
        }
    }
    
    self.isOpen = NO;
    self.selectIndexPath = nil;
    
    [self.tableView reloadData];
    [FileUploadManager sharedManager].delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [FileUploadManager sharedManager].delegate = nil;
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"FileUploadView"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
    self.selectIndexPath = nil;
    self.cancelIndexPath = nil;
    
    self.cancelAlertView = nil;
    self.imgView = nil;
    self.lblTip = nil;
    self.lblDes = nil;
    [super dealloc];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self layoutSubviews];
}


- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return  IS_IPAD ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (IS_IPAD || (interfaceOrientation == UIInterfaceOrientationPortrait));
}

#pragma mark - private methods

- (void)layoutSubviews
{
    if (IS_IPAD)
    {
        CGFloat offset = 0.0;
        if (self.imgView.center.y==200 && UIInterfaceOrientationIsPortrait((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation))
        {
            offset = 100;
        }
        if(self.imgView.center.y==300 && UIInterfaceOrientationIsLandscape((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation))
        {
            offset =-100;
        }
        self.imgView.center = CGPointMake(self.view.center.x, self.imgView.center.y+offset);
        self.lblTip.center = CGPointMake(self.view.center.x, self.lblTip.center.y+offset);
        self.lblDes.center = CGPointMake(self.view.center.x, self.lblDes.center.y+offset);
    }
}

- (void)createNoUploadView
{
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.scrollEnabled = NO;
    
    if (!self.imgView)
    {
        NSString *imgName = @"empty.png";

        
        UIImage *noUploadImg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:imgName ofType:nil]];
        
        self.imgView = [[[UIImageView alloc] initWithImage:noUploadImg] autorelease];
        self.imgView.bounds = CGRectMake(0, 0, noUploadImg.size.width, noUploadImg.size.height);
        self.imgView.contentMode = UIViewContentModeScaleAspectFill;
        
        [self.view addSubview:self.imgView];
    }
    
    if (!self.lblTip)
    {
        NSInteger width = IS_IPAD ? 250 : 200;
        NSInteger height = IS_IPAD ? 36 : 21;
        
        self.lblTip = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, height)] autorelease];
        self.lblTip.textAlignment = UITextAlignmentCenter;
        self.lblTip.textColor = [UIColor blackColor];
        self.lblTip.backgroundColor = [UIColor clearColor];
        self.lblTip.text = NSLocalizedString(@"NoUploadTask", nil);
        if (IS_IPAD)
            self.lblTip.font = [UIFont systemFontOfSize:30];
        else
        {
            self.lblTip.font = [UIFont systemFontOfSize:15];
        }
        [self.view addSubview:self.lblTip];
    }
    
    if (!self.lblDes)
    {
        NSInteger width = IS_IPAD ? 700 : 300;
        NSInteger height = IS_IPAD ? 36*3 : 21*3;
        
        self.lblDes = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, height)] autorelease];
        self.lblDes.textAlignment = UITextAlignmentCenter;
        self.lblDes.textColor = [UIColor grayColor];
        self.lblDes.backgroundColor = [UIColor clearColor];
        self.lblDes.numberOfLines = 3;
        self.lblDes.text = NSLocalizedString(@"NoUploadDes", nil);
        if (IS_IPAD)
            self.lblDes.font = [UIFont systemFontOfSize:26];
        else
             self.lblDes.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:self.lblDes];
    }
    if(IS_IPAD)
    {
        if (UIInterfaceOrientationIsPortrait((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation))
        {
            self.imgView.center = CGPointMake(self.view.center.x, 300);
            self.lblTip.center = CGPointMake(self.view.center.x, 426.5);
            self.lblDes.center = CGPointMake(self.view.center.x, 581.5);
        }
        else
        {
            self.imgView.center = CGPointMake(self.view.center.x, 200);
            self.lblTip.center = CGPointMake(self.view.center.x, 326.5);
            self.lblDes.center = CGPointMake(self.view.center.x, 481.5);
        }
        
    }
    else
    {
        self.imgView.center = CGPointMake(self.view.center.x, 127.5);
        self.lblTip.center = CGPointMake(self.view.center.x, 227);
        self.lblDes.center = CGPointMake(self.view.center.x, 277);
    }
    
    [self layoutSubviews];
}

- (void)setCellInfo:(PCFileCell *)cell
              color:(UIColor *)color
         detailText:(NSString *)detailStr
           hostPath:(NSString *)hostPath
               date:(NSDate *)date
{
    cell.detailTextLabel.textColor = color;
    cell.detailTextLabel.text = detailStr;
    
    NSUInteger index = [hostPath rangeOfString:@"/" options:NSBackwardsSearch].location;
    cell.lblPath.text = [hostPath substringToIndex:index];
    
    cell.lblTime.text = [PCUtilityStringOperate formatDate:date formatString:@"yyyy-MM-dd HH:mm"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [FileUploadManager sharedManager].uploadFileArr.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger num = [[FileUploadManager sharedManager].uploadFileArr[section] count];
    
    if (self.isOpen && self.selectIndexPath.section == section)
    {
        num++;
    }
    DLogNotice(@"num=%d,section=%d",num,section);
    return num;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *uploadArr = [FileUploadManager sharedManager].uploadFileArr[section];
    return ((FileUploadInfo *)uploadArr.lastObject).deviceName;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;
    
    FileUploadManager *uploadMgr = [FileUploadManager sharedManager];
    NSArray *uploadArr = uploadMgr.uploadFileArr[section];
    FileUploadInfo *uploadInfo = nil;
    BOOL hasOpenCell = self.isOpen && self.selectIndexPath.section == section;
    
    if (hasOpenCell && self.selectIndexPath.row + 1 == row)
    {
        uploadInfo = uploadArr[--row];
        
        static NSString *CellIdentifier2 = @"UploadCell2";
        PCFileExpansionCell *cell2 = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
        
        if (!cell2)
        {
            cell2 = [[[PCFileExpansionCell alloc] initWithStyle: UITableViewCellStyleSubtitle
                                                reuseIdentifier: CellIdentifier2] autorelease];
            cell2.selectionStyle = UITableViewCellSelectionStyleNone;
            
        }
        cell2.delegate = self;
        cell2.indexPath = [NSIndexPath indexPathForRow:row inSection:section];
        [cell2 initActionContent:uploadInfo.status.shortValue == pauseUploadStatus ?
             FILE_UPLOAD_RESUME : FILE_UPLOAD_PAUSE];
        
        return cell2;
    }
    else
    {
        NSInteger index = hasOpenCell && row > self.selectIndexPath.row ? row - 1 : row;
        DLogNotice(@"uploadCell.index=%d,uploadArr.count=%d,section=%d",index,uploadArr.count,section);
        uploadInfo = uploadArr[index];
        NSString *hostPath = uploadInfo.diskName;
        
        static NSString *CellIdentifier = @"UploadCell";
         
        PCFileCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell)
        {
            cell = [[[PCFileCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier hasPathLbl:YES] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
        }
        [cell changeArrowImageWithExpansion:hasOpenCell && self.selectIndexPath.row == row];
       
        cell.delegate = self;
        cell.indexRow = index;
        cell.indexSection = section;
        cell.imageView.image = [UIImage imageNamed:@"file_pic.png"];
        
        SelectUploadStatus status = uploadInfo.status.shortValue;
        if (status == uploadingStatus)
        {
            if (cell.progressView.progress != 1)
                cell.progressView.progress = uploadMgr.progressValue;
        }
        else if (status == waitUploadStatus)
        {
            [self setCellInfo:cell
                        color:[UIColor greenColor]
                   detailText:NSLocalizedString(@"WaitForUpload", nil)
                     hostPath:hostPath
                         date:uploadInfo.uploadTime];
        }
        else
        {
            [self setCellInfo:cell
                        color:[UIColor redColor]
                   detailText:NSLocalizedString(@"Pause", nil)
                     hostPath:hostPath
                         date:uploadInfo.uploadTime];
        }

        //此处加5是为了与DownloadStatus枚举值对应
        [cell changeStatusImageWithFileStatus:status + 5];
        
        cell.textLabel.text = hostPath.lastPathComponent;
        
        return cell;
    }
}

#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.isOpen && self.selectIndexPath.section == indexPath.section &&
            self.selectIndexPath.row + 1 == indexPath.row ? 55 : TABLE_CELL_HEIGHT;
}

#pragma mark - PCFileCellDelegate methods

- (void)expansionView:(NSIndexPath *)indexPath
{
    DLogNotice(@"expansionView indexPath=%@",indexPath);
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1
                                               inSection:indexPath.section]];
    
    self.isOpen = ![indexPath isEqual:self.selectIndexPath];
    
    NSInteger cellRow = indexPath.row;
    if (self.selectIndexPath &&
        indexPath.section == _selectIndexPath.section &&
        cellRow > _selectIndexPath.row)
    {
        cellRow++;
    }
    
    PCFileCell *cell = (PCFileCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:cellRow inSection:indexPath.section]];
    [cell changeArrowImageWithExpansion:self.isOpen];
    
    if (!self.isOpen)//关闭自己
    {
        self.selectIndexPath = nil;
        [self.tableView deleteRowsAtIndexPaths:indexPaths
                              withRowAnimation:UITableViewRowAnimationTop];
    }
    else
    {
        if (self.selectIndexPath)//已经打开一个了
        {
            [(PCFileCell *)[self.tableView cellForRowAtIndexPath:_selectIndexPath] changeArrowImageWithExpansion:NO];
            
            [self.tableView beginUpdates];
            
            [self.tableView insertRowsAtIndexPaths:indexPaths
                                  withRowAnimation:UITableViewRowAnimationTop];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_selectIndexPath.row + 1 inSection:_selectIndexPath.section]]
                                  withRowAnimation:UITableViewRowAnimationTop];
            self.selectIndexPath = indexPath;
            
            [self.tableView endUpdates];
        }
        else//都是关闭状态，打开一个
        {
            self.selectIndexPath = indexPath;
            [self.tableView insertRowsAtIndexPaths:indexPaths
                                  withRowAnimation:UITableViewRowAnimationTop];
        }
        
        UITableViewCell *selectCell = [self.tableView cellForRowAtIndexPath:_selectIndexPath];
        
        //当前滚动到的位置
        CGFloat deltaY = self.tableView.contentOffset.y;
        //cell的位置
        CGFloat cellY = selectCell.frame.origin.y + selectCell.frame.size.height * 2 - 5;
        //tableview的高度
        CGFloat height = self.tableView.frame.size.height;
        //偏移量
        CGFloat offsetY = cellY - deltaY >= height ? cellY - height - deltaY : 0;
        
        [self.tableView setContentOffset:CGPointMake(0, offsetY + deltaY) animated:YES];
    }
}

//- (void)didSelectCell:(NSIndexPath *)indexPath
//{
//    DLogNotice(@"didSelectCell indexPath=%@",indexPath);
//}

#pragma mark - PCFileExpansionCellDelegate methods

- (void)cancelUploadButtonClick:(PCFileExpansionCell *)cell
{
    self.cancelIndexPath = cell.indexPath;
    _cancelCellIsPause = cell.currentfileCellType == FILE_UPLOAD_RESUME;
    
    self.cancelAlertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"IsCancelUpload", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease];
    [self.cancelAlertView show];
}

- (void)pauseButtonClick:(PCFileExpansionCell *)cell
{
    NSIndexPath *indexPath = cell.indexPath;
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section >= [FileUploadManager sharedManager].uploadFileArr.count)
    {
        return;
    }
    
    NSMutableArray *indexPaths = [NSMutableArray arrayWithObject:indexPath];
    FileUploadManager *uploadMgr = [FileUploadManager sharedManager];
    
    self.isOpen = NO;
    self.selectIndexPath = nil;
    
    if ([uploadMgr pauseUploadFile:section rowIndex:row])
    {
        NSInteger uploadSection = uploadMgr.uploadSectionIndex;
        NSInteger uploadRow = uploadMgr.uploadRowIndex;
        if (uploadSection == section && uploadRow > row)
        {
            uploadRow++;
        }
        [indexPaths addObject:[NSIndexPath indexPathForRow:uploadRow inSection:uploadSection]];
    }

    [self.tableView beginUpdates];
    
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row + 1 inSection:section]]
                          withRowAnimation:UITableViewRowAnimationNone];
    
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    
    [self.tableView endUpdates];
}

- (void)resumeButtonClick:(PCFileExpansionCell *)cell
{
    NSIndexPath *indexPath = cell.indexPath;
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    if (section >= [FileUploadManager sharedManager].uploadFileArr.count)
    {
        return;
    }
    
    self.isOpen = NO;
    self.selectIndexPath = nil;
    
    [[FileUploadManager sharedManager] resumeUploadFile:section rowIndex:row];
    
    [self.tableView beginUpdates];
    
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row + 1 inSection:section]]
                          withRowAnimation:UITableViewRowAnimationNone];
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    
    [self.tableView endUpdates];
}

#pragma mark - UploadDelegate methods

- (void)uploadFinish:(NSInteger)sectionIndex
            rowIndex:(NSInteger)rowIndex
            isCancel:(BOOL)cancel
           hasDelete:(BOOL)hasDelete
{
    if (self.cancelIndexPath &&
        self.cancelIndexPath.section == sectionIndex &&
        self.cancelIndexPath.row == rowIndex)
    {
        self.cancelIndexPath = nil;
        [self.cancelAlertView dismissWithClickedButtonIndex:0 animated:NO];
        self.cancelAlertView = nil;
    }
    
    NSInteger selectSection = self.selectIndexPath.section;
    NSInteger selectRow = self.selectIndexPath.row;
    DLogNotice(@"uploadFinish sectionIndex=%d,rowIndex=%d",sectionIndex,rowIndex);
    
    if (hasDelete)
    {
        if (self.selectIndexPath && selectSection == sectionIndex)
        {
            if (selectRow == rowIndex)
            {
                self.isOpen = NO;
                self.selectIndexPath = nil;
            }
            else if (selectRow > rowIndex)
            {
                self.selectIndexPath = [NSIndexPath indexPathForRow:--selectRow inSection:selectSection];
            }
        }
        
        NSInteger cancelRow = self.cancelIndexPath.row;
        if (self.cancelIndexPath && self.cancelIndexPath.section == sectionIndex && cancelRow > rowIndex)
        {
            self.cancelIndexPath = [NSIndexPath indexPathForRow:--cancelRow inSection:sectionIndex];
        }
    }
    
    if (!cancel)
    {
        NSInteger row = rowIndex;
        if (self.selectIndexPath && selectSection == sectionIndex && selectRow < rowIndex)
        {
            row++;
        }
        
        PCFileCell *cell = (PCFileCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:sectionIndex]];
        if (cell)
            cell.progressView.progress = 1;
    }
    
    [self.tableView reloadData];
    DLogNotice(@"uploadFinish after reloadData");
    
    if ([FileUploadManager sharedManager].uploadTotalNum == 0)
    {
        [self createNoUploadView];
    }
}

- (void)uploadProgress:(CGFloat)progress
{
    FileUploadManager *uploadMgr = [FileUploadManager sharedManager];
    NSInteger section = uploadMgr.uploadSectionIndex;
    NSInteger row = uploadMgr.uploadRowIndex;
    
    if (self.selectIndexPath && self.selectIndexPath.section == section &&
        self.selectIndexPath.row < row)
    {
        row++;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    
    PCFileCell *cell = (PCFileCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    if (cell.progressView.progress == 1)
        return;

    cell.progressView.progress = progress >= 1 ? 0.999f : progress;
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.cancelAlertView = nil;
    
    if (buttonIndex == 1 && self.cancelIndexPath)
    {
        FileUploadManager *uploadMgr = [FileUploadManager sharedManager];
        if (!uploadMgr.delegate)
            uploadMgr.delegate = self;
        
        DLogNotice(@"cancelUploadButtonClick indexPath=%@",self.cancelIndexPath);
        [uploadMgr cancelUploadAndProcessNext:self.cancelIndexPath.section
                                     whichRow:self.cancelIndexPath.row
                                      isPause:_cancelCellIsPause
                                     isCancel:YES
                                 deleteDBInfo:YES];
    }
    self.cancelIndexPath = nil;
}

@end
