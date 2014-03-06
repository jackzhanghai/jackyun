//
//  FilesViewController.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-10.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>
#import "PCLogin.h"
#import "PCLogout.h"
#import "EGORefreshTableHeaderView.h"
#import "FileSearch.h"
#import "FileCache.h"
#import "PCShareUrl.h"
#import "PCProgressingViewController.h"
#import "PCFileExpansionCell.h"
#import "PCFileCell.h"
#import "PCFileExpansionCell.h"
#import "PCRestClient.h"

#define SEARCH_DICTATOR_TAG 88

@interface FileFolderViewController : UIViewController <UIActionSheetDelegate, UISearchBarDelegate,UISearchDisplayDelegate, PCFileCellDelegate, PCLoginDelegate, PCLogoutDelegate, EGORefreshTableHeaderDelegate, UITableViewDelegate, UITableViewDataSource,QLPreviewControllerDataSource, QLPreviewControllerDelegate, PCFileExpansionCellDelegate, PCRestClientDelegate> {
    NSMutableArray *tableData;
    NSMutableArray *folderSizeData;
    BOOL isNetworkError;
    BOOL isFinish;
    BOOL isRefresh;
    BOOL isSearchDisplay;
    NSString *localPath;
    FileCache* fileCache;
    EGORefreshTableHeaderView *_refreshHeaderView;
    EGORefreshTableHeaderView *_refreshHeaderPictureView;
	BOOL _reloading;
    NSMutableArray	*filteredListContent;	// The content filtered as a result of a search.
	// The saved state of the search UI if a memory warning removed the view.
    NSString		*savedSearchTerm;
    BOOL			searchWasActive;
    FileSearch* fileSearch;
    FileSearch* fileSearchCancel;
    BOOL isProcessing;
    BOOL isOpen;
    NSIndexPath *selectIndexPath;
    PCProgressingViewController *progressingViewController;
    PCShareUrl *shareUrl;
    BOOL        bViewFirstAppear;
    PCRestClient *restClient;
}

- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;

@property (nonatomic, retain) IBOutlet UITableView* tableView;
@property (nonatomic, retain) IBOutlet UISearchBar* searchBar;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *dicatorView;
@property (nonatomic, retain) IBOutlet UITableView* picturetableView;
@property (nonatomic, retain) KTURLRequest *currentRequest;
@property (nonatomic, retain) NSMutableArray *filteredListContent;
@property (nonatomic, retain) NSMutableArray *historyfilteredListContent;
@property (nonatomic, retain) NSString *savedSearchTerm;
@property (nonatomic,readwrite) BOOL searchWasActive;
@property (nonatomic, retain)  UILabel* lblResult;
@property (assign)BOOL isOpen;
@property (nonatomic, copy) NSString *keyWord;
@property (nonatomic,retain)NSString *localPath;
@property (nonatomic,retain)NSIndexPath *selectIndexPath;

- (void) getFolderList;
- (void) refreshTable;

@end
