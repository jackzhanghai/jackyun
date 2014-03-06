//
//  FileUploadInfo.h
//  popoCloud
//
//  Created by leijun on 13-3-14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface FileUploadInfo : NSManagedObject

@property (nonatomic, copy) NSString * deviceID;
@property (nonatomic, copy) NSString * deviceName;
@property (nonatomic, copy) NSString * diskName;
@property (nonatomic, retain) NSNumber * fileSize;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSDate * uploadTime;
@property (nonatomic, copy) NSString * assetUrl;
@property (nonatomic, copy) NSString * hostPath;
@property (nonatomic, copy) NSString * user;

@end
