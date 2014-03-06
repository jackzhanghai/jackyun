//
//  CameraUploadInfo.h
//  popoCloud
//
//  Created by suleyu on 13-3-14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CameraUploadInfo : NSManagedObject

@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSString * deviceID;
@property (nonatomic, retain) NSString * assetUrl;
@property (nonatomic, retain) NSString * md5;
@property (nonatomic, retain) NSNumber * fileSize;
@property (nonatomic, retain) NSNumber * isUploaded;

@end
