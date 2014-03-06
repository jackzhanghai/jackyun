//
//  PCFileCacheInfo.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-11-2.
//  Copyright (c) 2011年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PCFileCacheInfo : NSManagedObject

@property (nonatomic, retain) NSString * modifyTime;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSNumber * size;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * modifyGTMTime;
@property (nonatomic, retain) NSString * fileKey;
@property (nonatomic, retain) NSNumber * thumbIndex;
@property (nonatomic, retain) NSString * timeZone;

@end
