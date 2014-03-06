//
//  PCFileUpload.h
//  popoCloud
//
//  Created by LeoZhang on 13-8-28.
//
//

#import <Foundation/Foundation.h>

@protocol PCFileUploadDelegate;
@interface PCFileUpload : NSObject

@property (nonatomic,retain) NSString *dstPath;
@property (nonatomic,retain) NSData *data;
@property (nonatomic,retain) NSString *src;
@property (nonatomic,retain) NSString *md5;
@property (nonatomic,assign) int fileType;
@property (nonatomic,assign) id<PCFileUploadDelegate> delegate;
@property (nonatomic,retain) NSString *deviceID;
@property (nonatomic,assign) long long fileSize;
@property (nonatomic,retain) NSDate *modifyTime;
@end
