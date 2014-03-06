//
//  FilesViewController.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-10.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGORefreshTableHeaderView.h"
#import "FileUpload.h"
#import "FileSearch.h"
#import "FileCache.h"
#import "PCShareUrl.h"
#import "PCOpenFile.h"
#import "PCProgressingViewController.h"
#import "PCFileCell.h"
#import "PCFileExpansionCell.h"
#import "QLPreviewController2.h"
#import "ELCImagePickerController.h"
#import "ToolView.h"
#import "NewFolderAndUploadCell.h"
#import "FileOperate.h"
#define STATUS_GET_FILELIST 1
#define STATUS_GET_SEARCH_LIST 2

@class PCRestClient;

@interface FileListViewController : UIViewController
<UINavigationControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate,UITableViewDelegate, 
UITableViewDataSource, UIActionSheetDelegate, UIImagePickerControllerDelegate, EGORefreshTableHeaderDelegate, UIPopoverControllerDelegate,
 PCFileCellDelegate, 
PCFileExpansionCellDelegate, ELCImagePickerControllerDelegate,PCFileCacheDelegate,PCRestClientDelegate,ToolViewDelegate,NewFolderAndUploadCellDelegate,PCFileOperateDelegate>
{
    NSMutableData *data;
    NSMutableArray *tableData;
    
    NSInteger selectIndex;
    
    BOOL isNetworkError;
    BOOL isFinish;
    BOOL isFirstResult;
    BOOL isProcessing;
    BOOL isSearchDisplay;
    BOOL isRefresh;//表示时候是否是右上角的刷新操作
    BOOL isNoMoreData;//表示是否还有更多数据
    
    FileCache* fileCache;
    FileSearch* fileSearch;
    PCShareUrl *shareUrl;
    PCProgressingViewController *progressingViewController;

    EGORefreshTableHeaderView *_refreshHeaderView;
    
	//  Reloading var should really be your tableviews datasource
	//  Putting it here for demo purposes 
	BOOL _reloading;
    UIPopoverController *popover;
    NSString *localPath;
    FileSearch* fileSearchCancel;
    PCFileInfo *currentFileInfo;
    BOOL isOpen;
    NSIndexPath *selectIndexPath;
    
    NSMutableArray	*filteredListContent;	// The content filtered as a result of a search.
	
	// The saved state of the search UI if a memory warning removed the view.
    NSString		*savedSearchTerm;
    BOOL			searchWasActive;
    UIDeviceOrientation oldOrientation;
    NSMutableArray *needLoadThumbImageArray;
    BOOL isScrolling;
    BOOL isCoveredByPushing;
    NSCache *thumbImageCache;
    PCRestClient *restClient;
    NSString		*tempNewName;
    
    NSMutableArray *downloadOrDeleteArray;//保存选择的数据
    NSMutableArray *downLoadArray;
    NSMutableArray *deleteArray;
    BOOL ignoreDownloaded;
    BOOL hasPopover;
    NSInteger totalDeleteCount;
    NSInteger successDeleteCount;
}

- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;
- (void)refreshFileList:(PCFileInfo*)fileInfo;

@property (nonatomic, retain) IBOutlet UITableView* tableView;
@property (nonatomic, retain) IBOutlet UISearchBar* searchBar;
@property (nonatomic, retain) IBOutlet UILabel* lblResult;
@property (nonatomic, retain) IBOutlet UILabel* lblProgress;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *dicatorView;
@property (assign)BOOL isOpen;
@property (nonatomic,retain)  NSIndexPath *selectIndexPath;
@property (nonatomic, copy)   NSString *dirPath;
@property (nonatomic, copy)   NSString *keyWord;
@property (retain, nonatomic) UIPopoverController *popover;
@property (nonatomic, copy)   NSString *localPath;
@property (nonatomic, copy)   NSString		*tempNewName;//记录重命名的新名字

@property (nonatomic, retain) NSMutableArray *filteredListContent;
@property (nonatomic, retain) NSMutableArray *historyfilteredListContent;

@property (nonatomic, copy) NSString *savedSearchTerm;
@property (nonatomic,readwrite) BOOL searchWasActive;

@property (nonatomic, copy) NSString *dirName;

@property (nonatomic, retain) FileCache *thumbImgFileCache;//用来获取缩略图
@property (nonatomic, retain) KTURLRequest *currentRequest;

- (void) getList;
- (void) getFileList;
- (void) getSearchList;

- (void) shareUrlFail:(NSString*)errorDescription;
- (void) shareUrlFinish;

- (void) startProcess;
- (void) endProcess;
- (void) cancelProcess;
- (NSString*)getLocalThumbImageRootPath;
@end
