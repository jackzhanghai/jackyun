//
//  FileDownloadManagerViewController.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-30.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "FileDownloadManagerViewController.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "PCUtilityDataManagement.h"
#import "PCFileDownloadedInfo.h"
#import "PCFileDownloadingInfo.h"
#import "PCOpenFile.h"
#import "PCProgressView.h"
#import "FileListViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "FileCacheController.h"
#import "PCFileInfo.h"
#import "PCUtilityFileOperate.h"

#define CONFIRM_DELETE_ALERT_TAG   3
@implementation FileDownloadManagerViewController

@synthesize tableView;
@synthesize lblText;
@synthesize isOpen;
@synthesize selectIndexPath;
@synthesize imageView;
@synthesize lblDes;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    self.localPath = nil;
    
    if (btnEdit) [btnEdit release];
    
    self.selectIndexPath = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    self.lblDes = nil;
    [super dealloc];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"DownloadContent", nil);
    lblDes.text = NSLocalizedString(@"NoFileForDownload", nil);
    lblDes.textColor = [UIColor grayColor];
    lblText.text = NSLocalizedString(@"NoContentCurrent", nil);
    lblText.textColor = [UIColor  blackColor];
    self.view.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    tableView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
//    isEdit = YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self refreshTable];
    
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableView:) name:@"RefreshTableView" object:nil];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshProgress:) name:@"RefreshProgress" object:nil];
    
    if(IS_IPAD)
    {
        if (UIInterfaceOrientationIsPortrait((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation))
        {
            imageView.center = CGPointMake(self.view.center.x, 300);
            lblText.center = CGPointMake(self.view.center.x, 426.5);
            lblDes.center = CGPointMake(self.view.center.x, 581.5);
        }
        else
        {
            imageView.center = CGPointMake(self.view.center.x, 200);
            lblText.center = CGPointMake(self.view.center.x, 326.5);
            lblDes.center = CGPointMake(self.view.center.x, 481.5);
        }
        
    }
    else
    {
        imageView.center = CGPointMake(self.view.center.x, 127.5);
        lblText.center = CGPointMake(self.view.center.x, 227);
        lblDes.center = CGPointMake(self.view.center.x, 277);
    }
    
    [self layoutSubviews];
    
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"FileDownloadManager"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.selectIndexPath)
    {
        self.isOpen = NO;
        [self didSelectCellRow:NO otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];
        self.selectIndexPath = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RefreshTableView" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RefreshProgress" object:nil];
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"FileDownloadManager"];
   
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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
        if (imageView.center.y==200 && UIInterfaceOrientationIsPortrait((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation))
        {
            offset = 100;
        }
        if(imageView.center.y==300 && UIInterfaceOrientationIsLandscape((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation))
        {
            offset =-100;
        }
        imageView.center = CGPointMake(self.view.center.x, imageView.center.y+offset);
        lblText.center = CGPointMake(self.view.center.x, lblText.center.y+offset);
        lblDes.center = CGPointMake(self.view.center.x, lblDes.center.y+offset);
    }
}


#pragma mark - Notification key:RefreshTableView
- (void)refreshTableView:(NSNotification*)notification
{
    [self refreshTable];
}

- (void)refreshProgress:(NSNotification*)notification
{
    
    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:0 inSection:0];
    
   PCFileDownloadingInfo *downloadingInfo = [[PCUtilityFileOperate downloadManager].tableDownloading objectAtIndex:indexPath.section];
    
    PCFileCell *cell = (PCFileCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.progressView.progress = [downloadingInfo.progress floatValue];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [PCUtilityFileOperate downloadManager].tableDownloading.count + [PCUtilityFileOperate downloadManager].tableDownloadingStoped.count + [PCUtilityFileOperate downloadManager].tableDownloaded.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isOpen)
    {
        if (self.selectIndexPath.section == section)
        {
            return 2;
        }
    }
    return 1;
}


-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (self.isOpen&&self.selectIndexPath.section == indexPath.section&&indexPath.row!=0)
    {
        return 55;
    }
    else
    {
        return TABLE_CELL_HEIGHT;
    }
}


- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (self.isOpen&&self.selectIndexPath.section == indexPath.section&&indexPath.row!=0)
    {
        static NSString *CellIdentifier = @"Cell2";
        PCFileExpansionCell *cell2 = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell2 == nil)
        {
            cell2 = [[[PCFileExpansionCell alloc] initWithStyle: UITableViewCellStyleSubtitle
                                                reuseIdentifier: CellIdentifier] autorelease];
            cell2.selectionStyle = UITableViewCellSelectionStyleNone;
            cell2.accessoryType = UITableViewCellAccessoryNone;
            cell2.textLabel.font = [UIFont systemFontOfSize:16];
            
        }
        cell2.delegate = self;
        cell2.indexPath = indexPath;
        
        //正在下载的  暂停下载 取消收藏
        if(indexPath.section <[PCUtilityFileOperate downloadManager].tableDownloading.count)
        {
            [cell2 initActionContent:FAVORITELIST_STATUS_RUN];
        }
        
        //暂停下载   继续下载  取消收藏
        else if([PCUtilityFileOperate downloadManager].tableDownloading.count <= indexPath.section&&indexPath.section <  [PCUtilityFileOperate downloadManager].tableDownloading.count + [PCUtilityFileOperate downloadManager].tableDownloadingStoped.count )
        {
            [cell2 initActionContent:FAVORITELIST_STATUS_STOP];
        }
        //下载完成的   取消收藏
        else
        {
            [cell2 initActionContent:FAVORITELIST_OTHER];
        }
        
        return cell2;
        
    }
    
    else
    {
        static NSString *CellIdentifier2 = @"downloadCell";

        //正在下载的
        if(indexPath.section <[PCUtilityFileOperate downloadManager].tableDownloading.count)
        {
            PCFileDownloadingInfo *downloadingInfo = [[PCUtilityFileOperate downloadManager].tableDownloading objectAtIndex:indexPath.section];
            //NSLog(@"downloadingInfo=%@",downloadingInfo);
            PCFileCell *cell = [_tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
            if (cell == nil)
            {
                cell = [[[PCFileCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier2] autorelease];
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
            }
            if (self.isOpen&&self.selectIndexPath.section == indexPath.section)
            {
                [cell changeArrowImageWithExpansion:YES];
            }
            else
            {
                [cell changeArrowImageWithExpansion:NO];
            }
            cell.delegate = self;
            cell.indexRow = indexPath.row;
            cell.indexSection = indexPath.section;
            
            [cell initPCFileDownloadingInfo:downloadingInfo andStatus:(downloadingInfo.status.shortValue + 1)];
            return  cell;
        }
        //暂停下载
        if([PCUtilityFileOperate downloadManager].tableDownloading.count <= indexPath.section&&indexPath.section <  [PCUtilityFileOperate downloadManager].tableDownloading.count + [PCUtilityFileOperate downloadManager].tableDownloadingStoped.count )
        {
            NSInteger index = indexPath.section - [PCUtilityFileOperate downloadManager].tableDownloading.count;
            PCFileDownloadingInfo *downloadingInfo = [[PCUtilityFileOperate downloadManager].tableDownloadingStoped objectAtIndex:index];
            
            
            PCFileCell *cell = [_tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
            
            if (cell == nil)
            {
            
                cell = [[[PCFileCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier2] autorelease];
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
                        }
          
             if (self.isOpen&&self.selectIndexPath.section == indexPath.section)
            {
                [cell changeArrowImageWithExpansion:YES];
            }
            else
            {
                [cell changeArrowImageWithExpansion:NO];
            }
            
            cell.delegate = self;
            cell.indexRow = indexPath.row;
            cell.indexSection = indexPath.section;
            [cell initPCFileDownloadingInfo:downloadingInfo andStatus:[[PCUtilityFileOperate downloadManager] getFileStatus:downloadingInfo.hostPath andModifyTime:[NSString stringWithFormat:@"%@",downloadingInfo.modifyGTMTime]]];
            return  cell;
        }
      
        //下载完毕
        if([PCUtilityFileOperate downloadManager].tableDownloading.count +  [PCUtilityFileOperate downloadManager].tableDownloadingStoped.count <= indexPath.section )
        {
            NSInteger index = indexPath.section - [PCUtilityFileOperate downloadManager].tableDownloading.count - [PCUtilityFileOperate downloadManager].tableDownloadingStoped.count;
            
            PCFileDownloadedInfo *downloadedInfo = [[PCUtilityFileOperate downloadManager].tableDownloaded objectAtIndex:index];
            PCFileCell *cell = [_tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
            if (cell == nil)
            {
                cell = [[[PCFileCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier2] autorelease];
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
            }
            if (self.isOpen&&self.selectIndexPath.section == indexPath.section)
            {
                [cell changeArrowImageWithExpansion:YES];
            }
            else
            {
                [cell changeArrowImageWithExpansion:NO];
            }
            
            cell.delegate = self;
            cell.indexRow = indexPath.row;
            cell.indexSection = indexPath.section;
            [cell initPCFileDownloadedInfo:downloadedInfo andStatus:[[PCUtilityFileOperate downloadManager] getFileStatus:downloadedInfo.hostPath andModifyTime:downloadedInfo.modifyTime]];
            return cell;
            
        }
       return nil;
    }

}

#pragma mark - Table view delegate


#pragma mark - PCFileExpansionCell delegate
- (void)downCancelCollectButtonClick
{
    UIAlertView *Alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConfirmDel", nil)
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    Alert.tag = CONFIRM_DELETE_ALERT_TAG;
    [Alert show];
    [Alert release];
}

- (void)pauseButtonClick:(PCFileExpansionCell *)cell
{
    if(self.selectIndexPath.section <[PCUtilityFileOperate downloadManager].tableDownloading.count)
    {
         PCFileDownloadingInfo *downloadingInfo = [[PCUtilityFileOperate downloadManager].tableDownloading objectAtIndex:selectIndexPath.section];
         [[PCUtilityFileOperate downloadManager] downloadingStop:downloadingInfo];
        self.isOpen = NO;
        self.selectIndexPath = nil;
        [self refreshTable];
    }
       
}

- (void)resumeButtonClick:(PCFileExpansionCell *)cell
{
    if([PCUtilityFileOperate downloadManager].tableDownloading.count <= self.selectIndexPath.section&&self.selectIndexPath.section <  [PCUtilityFileOperate downloadManager].tableDownloading.count + [PCUtilityFileOperate downloadManager].tableDownloadingStoped.count )
    {
        NSInteger index = self.selectIndexPath.section - [PCUtilityFileOperate downloadManager].tableDownloading.count;
        PCFileDownloadingInfo *downloadingInfo = [[PCUtilityFileOperate downloadManager].tableDownloadingStoped objectAtIndex:index];
        [[PCUtilityFileOperate downloadManager]    downloadingStopedToRun:downloadingInfo];
        self.isOpen = NO;
        self.selectIndexPath = nil;
        [self refreshTable];

    }
}

#pragma mark - PCFileCell delegate
- (void)expansionView:(NSIndexPath *)indexPath
{
    if (nil == indexPath)
    {
        return;
    }
     DLogNotice(@"收藏列表。expansionView indexPath=%@",indexPath);
    if (indexPath.row == 0)
    {
        if ([indexPath isEqual:self.selectIndexPath])
        {
            self.isOpen = NO;
            // 有一个是开的 allCellsIsClose = no 当前操作的是开的 selectedCellIsClose = no
            [self didSelectCellRow:NO otherCellIsOpen:NO currentIndexPath:indexPath];  //关自己
            self.selectIndexPath = nil;
            
        }
        else
        {
            if (!self.selectIndexPath)
            {
                self.selectIndexPath = [indexPath retain];
                [indexPath release];
                [self didSelectCellRow:YES otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];
            }
            else
            {
                
                [self didSelectCellRow:NO otherCellIsOpen:YES currentIndexPath:indexPath];
            }
        }
        
    }
}

/**
 * 打开工具cell
 * @param  allCellsIsClose  所有的cell是否都是关闭的
 * @param  otherCellIsOpen  操作的cell以外的cell是否有打开的
 */
- (void)didSelectCellRow:(BOOL)allCellsIsClose otherCellIsOpen:(BOOL)selectedCellIsClose currentIndexPath:(NSIndexPath *) currentIndexPath;
{
    self.isOpen = allCellsIsClose;
    
    PCFileCell *cell = (PCFileCell *)[self.tableView cellForRowAtIndexPath:self.selectIndexPath];
    [cell changeArrowImageWithExpansion:allCellsIsClose];
    
//    [self.tableView beginUpdates];
    
    int section = self.selectIndexPath.section;
	NSMutableArray* rowToInsert = [[NSMutableArray alloc] init];
    NSIndexPath* indexPathToInsert = [NSIndexPath indexPathForRow:1 inSection:section];
    [rowToInsert addObject:indexPathToInsert];
	
	if (allCellsIsClose)
    {
        [self.tableView insertRowsAtIndexPaths:rowToInsert withRowAnimation:UITableViewRowAnimationTop];
    }
	else
    {
        [self.tableView deleteRowsAtIndexPaths:rowToInsert withRowAnimation:UITableViewRowAnimationTop];
    }
    
	[rowToInsert release];
	
//	[self.tableView endUpdates];
    
    if (selectedCellIsClose)
    {
        self.isOpen = YES;
        self.selectIndexPath = [currentIndexPath retain];
        [currentIndexPath release];
        [self didSelectCellRow:YES otherCellIsOpen:NO currentIndexPath:self.selectIndexPath];
    }
    
    if (self.isOpen)
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:selectIndexPath];
        
        //当前滚动到的位置
        CGFloat deltaY = self.tableView.contentOffset.y;
        //cell的位置
        CGPoint position = CGPointMake(0, cell.frame.origin.y + cell.frame.size.height*2 - 5 );
        //tableview的高度
        CGFloat height = self.tableView.frame.size.height;
        
        //偏移量
        CGFloat offsetY;
        
        if (position.y - deltaY >= height)
        {
            offsetY = position.y - height - deltaY ;
            
        }
        else
        {
            offsetY = 0;
        }
        
        [self.tableView setContentOffset:CGPointMake(0, offsetY + deltaY) animated:YES];
    }
 }

-(IBAction) btnEditItemClicked: (id) sender{
    if(isEdit == YES) {
        [self.tableView setEditing:YES animated:YES];
        btnEdit.title = NSLocalizedString(@"Done", nil);
        isEdit = NO;
    }
    else {
        [self.tableView setEditing:NO animated:YES];
        btnEdit.title = NSLocalizedString(@"Edit", nil);
        isEdit = YES;
    }
}

- (void) refreshTable {
    [self.tableView reloadData];
    
    if ([PCUtilityFileOperate downloadManager].tableDownloading.count || [PCUtilityFileOperate downloadManager].tableDownloaded.count || [PCUtilityFileOperate downloadManager].tableDownloadingStoped.count) {
        [self.tableView setHidden:NO];
        self.navigationItem.rightBarButtonItem = btnEdit;
    }
    else {
        [self.tableView setHidden:YES];
        self.navigationItem.rightBarButtonItem = nil;
        if(isEdit == NO) {
            [self btnEditItemClicked:nil];
        }

    }    
}


- (void)didSelectCell:(NSIndexPath *)indexPath
{
    if([PCUtilityFileOperate downloadManager].tableDownloading.count +  [PCUtilityFileOperate downloadManager].tableDownloadingStoped.count <= indexPath.section )
    {
        NSInteger index = indexPath.section - [PCUtilityFileOperate downloadManager].tableDownloading.count - [PCUtilityFileOperate downloadManager].tableDownloadingStoped.count;
        
        PCFileDownloadedInfo *downloadedInfo = [[PCUtilityFileOperate downloadManager].tableDownloaded objectAtIndex:index];

        if ([[PCUtilityFileOperate getImgByExt:[downloadedInfo.localPath pathExtension]] isEqualToString:@"file_pic.png"])
        {
            [self openImageFile:downloadedInfo];
        }
        else{
            [self openFile:downloadedInfo.localPath WithFileInfo:[[[PCFileInfo alloc]  initWithPCFileDownloadedInfo:downloadedInfo] autorelease] ];
             }
    }
}

- (void)openFile:(NSString*)localPath2  WithFileInfo:(PCFileInfo*)fileInfo{
    if (![localPath2 hasPrefix:NSHomeDirectory()]) {
        localPath2 = [NSHomeDirectory() stringByAppendingPathComponent:localPath2];
    }
    self.localPath = localPath2;
    //add by libing 2013-6-26 fix bug bug54838  bug 55854
//    BOOL result = [QLPreviewController2 canPreviewItem:(id<QLPreviewItem>)fileURL];
    BOOL result = [PCUtilityFileOperate itemCanOpenWithPath:localPath2];
    if (!result) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"NoSuitableProgram", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        [alert release];
        //        [self release];
    }
    else
    {
        QLPreviewController2 *previewController = [[QLPreviewController2 alloc] init];
        previewController.currentFileInfo = fileInfo;
        
        NSString *fileType = nil;
        if(NSOrderedSame == [[localPath2 substringWithRange:NSMakeRange([localPath2 length]-4,1) ] compare:@"."])
        {
            fileType = [localPath2 substringWithRange:NSMakeRange([localPath2 length]-3,3)];
        }
        else if(NSOrderedSame == [[localPath2 substringWithRange:NSMakeRange([localPath2 length]-3,1) ] compare:@"."])
        {
            fileType = [localPath2 substringWithRange:NSMakeRange([localPath2 length]-2,2)];
        }
        else
        {
            fileType =@"";
        }
        [MobClick event:UM_FAVOUR_VIEW label:fileType];
        /////
        if (fileInfo.mFileType == PC_FILE_VEDIO)
        {
            NSURL *url = [NSURL  fileURLWithPath:self.localPath];
            
            MPMoviePlayerViewController *playerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
            [self presentMoviePlayerViewControllerAnimated:playerViewController];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
            
            MPMoviePlayerController *player = [playerViewController moviePlayer];
            [player play];
            
            [playerViewController release];
            [previewController release];
            return;
        }
        else if (fileInfo.mFileType == PC_FILE_AUDIO)
        {
            NSURL *url = [NSURL  fileURLWithPath:self.localPath];
            
            MPMoviePlayerViewController *playerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
            [self presentMoviePlayerViewControllerAnimated:playerViewController];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
            
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [[AVAudioSession sharedInstance] setActive: YES error:nil];
            
            MPMoviePlayerController *player = [playerViewController moviePlayer];
            [player play];
            [playerViewController release];
            [previewController release];
            return;
        }
        
        previewController.localPath = self.localPath;
        previewController.dataSource = previewController;
        previewController.delegate = self;
        previewController.backBtnTitle = self.navigationItem.title;
        // start previewing the document at the current section index
        previewController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:previewController animated:YES];
        [previewController release];
    }
}

//刷新数据，其它页面做删除后可能通过这个函数来更新当前页面
- (void)refreshFileList:(PCFileInfo*)fileInfo
{
    [[PCUtilityFileOperate downloadManager] deleteFileWithPath:fileInfo.path];
    self.isOpen = NO;
    self.selectIndexPath = nil;
    [self refreshTable];
}

#pragma mark -
#pragma mark QLPreviewControllerDataSource

// Returns the number of items that the preview controller should preview
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)previewController
{
    return 1;
}

- (void)previewControllerDidDismiss:(QLPreviewController *)controller
{
    // if the preview dismissed (done button touched), use this method to post-process previews
}

// returns the item that the preview controller should preview
- (id)previewController:(QLPreviewController *)previewController previewItemAtIndex:(NSInteger)idx
{
    return [NSURL fileURLWithPath:self.localPath];
}

- (void)previewControllerWillDismiss:(QLPreviewController *)controller
{
    if (self.navigationController) {
        [self.navigationController setToolbarHidden:YES animated:NO];
    }
}

- (void)openImageFile:(PCFileDownloadedInfo*) downloadedInfo
{
    PCFileInfo *fileInfo = [[[PCFileInfo alloc] initWithPCFileDownloadedInfo:downloadedInfo] autorelease];
    NSArray *currentData = [self getNodeArrayFromDownloaded];
    
    FileCacheController *cacheController = [[FileCacheController alloc] initWithPath:downloadedInfo.localPath andFinishLoadingState:YES
                                                                           andDataSource:currentData
                                                                          andCurrentPCFileInfo: fileInfo
                                                               andLastViewControllerName:self.navigationItem.title];
    cacheController.bOriginalImage = YES;
    KTPhotoScrollViewController *newController = [[KTPhotoScrollViewController alloc]
                                                          initWithDataSource:cacheController
                                                          andStartWithPhotoAtIndex:cacheController.startWithIndex_];
    newController.bDeletepPhoneContent = YES;//删除操作 删除下载到手机上的文件。
    [self.navigationController pushViewController:newController animated:YES];                          [newController release];
  
    [cacheController release];
}

- (NSArray*)getNodeArrayFromDownloaded
{
   NSMutableArray * mutableNodeArray = [NSMutableArray array];
    for (PCFileDownloadedInfo *nodeInfo in [PCUtilityFileOperate downloadManager].tableDownloaded)
    {
        PCFileInfo *fileInfo = [[[PCFileInfo alloc] initWithPCFileDownloadedInfo:nodeInfo] autorelease];
        [mutableNodeArray  addObject:fileInfo];
    }
    NSArray *nodeArray = [NSArray arrayWithArray:mutableNodeArray];
    return nodeArray;
}

//
#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag ==  NoSuitableProgramAlertTag) {
        [self dismissMoviePlayerViewControllerAnimated];
    }
    else if (buttonIndex == [alertView firstOtherButtonIndex]) {
        if (alertView.tag == CONFIRM_DELETE_ALERT_TAG) {
            [self refreshTable];
            
            if(self.selectIndexPath.section <[PCUtilityFileOperate downloadManager].tableDownloading.count)
            {
                
                [[PCUtilityFileOperate downloadManager] deleteDownloadingItem:selectIndexPath.section];
                self.isOpen = NO;
                
                self.selectIndexPath = nil;
                //删除正在下载的文件。后面排队的会下载
                if ([PCUtilityFileOperate downloadManager].tableDownloading.count > 0) {
                    PCFileDownloadingInfo *info = [[PCUtilityFileOperate downloadManager].tableDownloading objectAtIndex:0];
                    if (info.status.shortValue == STATUS_PAUSE) {
                        [[PCUtilityFileOperate downloadManager] itemChangeStatus:0];
                    }
                }
                
                [self refreshTable];
                return ;
            }
            if([PCUtilityFileOperate downloadManager].tableDownloading.count <= self.selectIndexPath.section&&self.selectIndexPath.section <  [PCUtilityFileOperate downloadManager].tableDownloading.count + [PCUtilityFileOperate downloadManager].tableDownloadingStoped.count )
            {
                NSInteger index = self.selectIndexPath.section - [PCUtilityFileOperate downloadManager].tableDownloading.count;
                
                [[PCUtilityFileOperate downloadManager] deleteDownloadingStopedItem:index];
                self.isOpen = NO;
                self.selectIndexPath = nil;
                
                [self refreshTable];
                return ;
            }
            if([PCUtilityFileOperate downloadManager].tableDownloading.count +  [PCUtilityFileOperate downloadManager].tableDownloadingStoped.count <= self.selectIndexPath.section )
            {
                NSInteger index = self.selectIndexPath.section - [PCUtilityFileOperate downloadManager].tableDownloading.count - [PCUtilityFileOperate downloadManager].tableDownloadingStoped.count;
                
                [[PCUtilityFileOperate downloadManager] deleteDownloadedItem:index];
                self.isOpen = NO;
                self.selectIndexPath = nil;
                [self refreshTable];
                return ;
            }
        }
    }
}


- (void) playerPlaybackDidFinish:(NSNotification*) aNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:nil];
    
    NSNumber *reason = [aNotification.userInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    if ([reason intValue] == MPMovieFinishReasonPlaybackError)
    {
        //NSError *error = [aNotification.userInfo objectForKey:@"error"];
        //NSString *errorInfo = error ? error.localizedDescription : NSLocalizedString(@"NoSuitableProgram", nil);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil)
                                                        message:@"播放失败"//errorInfo
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        alert.tag = NoSuitableProgramAlertTag;
        [alert show];
        [alert release];
    }
    else
    {
        [self dismissMoviePlayerViewControllerAnimated];
    }
}

@end
