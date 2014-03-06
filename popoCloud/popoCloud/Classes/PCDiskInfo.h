//
//  PCDiskInfo.h
//  popoCloud
//
//  Created by Kortide on 13-8-27.
//
//

#import <Foundation/Foundation.h>

@interface PCDiskInfo : NSObject
@property(nonatomic,retain) NSString       *path;
@property(nonatomic,retain) NSNumber   *used;
@property(nonatomic,retain) NSNumber   *max;
- (id) initWithDic:(NSDictionary*)dic;

@end
