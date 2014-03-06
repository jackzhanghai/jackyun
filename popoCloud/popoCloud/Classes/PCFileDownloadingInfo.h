//
//  PCFileDownloadingInfo.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-11-7.
//  Copyright (c) 2011年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PCFileDownloadingInfo : NSManagedObject
@property (nonatomic, retain) NSString * deviceName;
@property (nonatomic, retain) NSString * downhostPath;
@property (nonatomic, retain) NSString * hostPath;
@property (nonatomic, retain) NSString * localPath;
@property (nonatomic, retain) NSNumber * modifyGTMTime;
@property (nonatomic, retain) NSNumber * progress;
@property (nonatomic, retain) NSNumber * recordTime;
@property (nonatomic, retain) NSNumber * size;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSString * user;

@end
