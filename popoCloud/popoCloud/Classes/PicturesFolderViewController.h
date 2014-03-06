//
//  PicturesViewController.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-10.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PCLogout.h"
#import "PCLogin.h"
#import "PCRestClient.h"
#import "KTURLRequest.h"
#import "EGORefreshTableHeaderViewOriginal.h"
#import "ToolView.h"
#import "PCFileCell.h"
#import "DragButton.h"

@class DragButton;

@interface PicturesFolderViewController : UIViewController
<PCLogoutDelegate, UITableViewDelegate, UITableViewDataSource,PCLoginDelegate,PCRestClientDelegate,EGORefreshTableHeaderOriginalDelegate,ToolViewDelegate,PCFileCellDelegate,dragLocationDelegate>
{
    NSMutableArray *tableList;
  
    BOOL isNetworkError;
    BOOL isFinish;
    BOOL isRefresh;
    BOOL isEditing;
    PCRestClient *pcClient;
    
    EGORefreshTableHeaderViewOriginal *_refreshHeaderView;
//    EGORefreshTableHeaderView *_refreshHeaderPictureView;
//	
//	//  Reloading var should really be your tableviews datasource
//	//  Putting it here for demo purposes 
	BOOL _reloading;
//    UploadStatus uploadStatus;
    NSMutableArray *downloadOrDeleteArray;
    CGPoint  startPoint;
    CGPoint  lastDragBtnPoint;
}
@property (nonatomic, retain) KTURLRequest *currentRequest;
@property (nonatomic, retain) IBOutlet UITableView* tableView;
@property (nonatomic, retain) IBOutlet UITableView* picturetableView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *dicatorView;
@property(nonatomic,retain) NSArray *menuArray;
@property (nonatomic, retain)  DragButton *mDragBtn;
@property (nonatomic, retain)  NSString *mGroupType;

- (void)reloadEGOTableViewDataSource;
- (void)doneLoadingEGOTableViewData;

@end


//UIImageView *dragImgView = [[UIImageView alloc] initWithFrame:CGRectMake(maxItemWidth-dragImg.size.width, itemY, dragImg.size.width, dragImg.size.height)];
//[contentView addSubview: dragImgView];
//dragImgView.autoresizingMask = UIViewAutoresizingNone;