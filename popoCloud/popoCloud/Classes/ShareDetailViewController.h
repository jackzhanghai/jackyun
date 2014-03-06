//
//  ShareDetailViewController.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-9-20.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShareManagerViewController.h"
#import "PCShareUrl.h"

@interface ShareDetailViewController : UIViewController {
    PCShareUrl *shareUrl;
     NSMutableData* data;
    NSMutableArray *fileCacheArr;
}

@property (nonatomic, retain) NSDictionary *detail;
@property (nonatomic, retain) ShareManagerViewController* shareManagerViewController;

@property (nonatomic, retain) IBOutlet UILabel* lblPath;
@property (nonatomic, retain) IBOutlet UILabel* lblUrl;
@property (nonatomic, retain) IBOutlet UIButton* btnPath;
@property (nonatomic, retain) IBOutlet UIButton* btnUrl;
@property (nonatomic, retain) IBOutlet UIImageView* imgLine;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *dicatorView;

@property (nonatomic) NSInteger mStatus;
@property (nonatomic, retain) NSMutableArray *fileCacheArr;


-(IBAction) btnStopClicked: (id) sender;
-(IBAction) btnShareClicked: (id) sender;
-(IBAction) btnOpenFileClicked: (id) sender;

@end
