//
//  PCFileDownloadedInfo.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-11-7.
//  Copyright (c) 2011年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PCFileDownloadedInfo : NSManagedObject

@property (nonatomic, retain) NSString * hostPath;
@property (nonatomic, retain) NSString * localPath;
@property (nonatomic, retain) NSString * modifyTime;
@property (nonatomic, retain) NSNumber * recordTime;
@property (nonatomic, retain) NSNumber * size;
@property (nonatomic, retain) NSString * user;

@end
