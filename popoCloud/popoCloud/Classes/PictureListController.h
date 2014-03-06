//
//  PictureListController.h
//  popoCloud
//
//  Created by leijun on 12-10-18.
//
//

#import <UIKit/UIKit.h>
#import "FileCache.h"
#import "KKGridViewController.h"
#import "EGORefreshTableHeaderView.h"
#import "KTURLRequest.h"
#import "PCRestClient.h"
#import "ToolView.h"
#import "FileOperate.h"
#import "EGORefreshTableHeaderViewOriginal.h"
#import "PCRestClient.h"

@interface PictureListController : KKGridViewController <PCFileCacheDelegate,EGORefreshTableHeaderDelegate,PCRestClientDelegate,ToolViewDelegate,UIAlertViewDelegate,PCFileOperateDelegate,EGORefreshTableHeaderOriginalDelegate,UITableViewDataSource,UITableViewDelegate>
{
    NSMutableData *data;
    NSMutableArray *fileList;
    NSMutableDictionary *fileDict;
    
    NSInteger curIndex;
    NSInteger cahceEndIndex;//需要cache缩略图的最后一个的index
    NSInteger cacheStartIndex;///需要cache缩略图的第一个的index
    
    BOOL isNetworkError;
//    BOOL isFinish;
    BOOL bGettingPicList;
    BOOL isRefresh;//表示是否是刷新操作
    BOOL isNoMoreData;//表示是否还是数据
    
    BOOL bDownloadThumbnailFailed;//缩略图下载失败
    
    EGORefreshTableHeaderView *_refreshBottomView;//底部上拉刷新

	BOOL _reloading;
    BOOL bNeedRefresh;
    
    UIAlertView *getPicFailAlertView;
    
    UIActivityIndicatorView *dicatorView;
    UILabel *lblProgress;
    
    NSString *deviceID;
    
    UIDeviceOrientation oldOrientation;
    dispatch_queue_t dicSetQueue;
    NSMutableArray *downloadOrDeleteArray;
    NSInteger totalDeleteCount;
    NSInteger successDeleteCount;
    BOOL isEditing;
    EGORefreshTableHeaderViewOriginal *_refreshHeaderView;//顶部下拉刷新
    
    UITableView *mTable;//弹出框(我喜欢）
    UIView         *mFavoriteBG;
    PCRestClient *pcClient;
}

@property (nonatomic, retain) KTURLRequest *currentRequest;
@property (atomic, assign) BOOL bDisAppearing;
@property (nonatomic, assign) BOOL bCoverdByPushing;

@property (nonatomic, retain) NSMutableArray *fileList;
@property (nonatomic, retain) NSMutableDictionary *fileDict;
@property (nonatomic, retain) NSMutableDictionary *thumbsDic;
@property (atomic, retain) NSMutableDictionary *thumbsPathDic;

@property (nonatomic, copy) NSString *deviceID;
@property (nonatomic, copy) NSString *groupName;
@property (nonatomic) NSInteger fileCount;
@property (nonatomic, retain) FileCache *zipFileCache;
@property (nonatomic, retain) FileCache *imgFileCache;
@property (nonatomic, retain) NSMutableDictionary *sameThumbIndexDic;
@property (nonatomic, retain) NSString *currentFavoriteFileName;

@property(nonatomic,retain)   NSMutableArray *mFavoriteList;//我喜欢 文件夹 列表
@property (nonatomic, retain)  NSString *mGroupType;

- (void)pushSlideImageWithStartIndex:(int)index andImageDownLoaded:(BOOL)bDownLoaded;
- (void) processThumbImage:(NSString*)thumbImgPath;
- (void)refreshFileList:(PCFileInfo*)fileInfo;

- (void)reloadEGOTableViewDataSource;
- (void)doneLoadingEGOTableViewData;

@end
