//
//  PCDiskInfo.m
//  popoCloud
//
//  Created by Kortide on 13-8-27.
//
//

#import "PCDiskInfo.h"

@implementation PCDiskInfo
@synthesize  path;
@synthesize  used;
@synthesize  max;

- (id) initWithDic:(NSDictionary*)dic
{
    self = [super init];
	if (self != nil) {
        self.path   =   [dic objectForKey:@"path"];
        
        if ([[dic objectForKey:@"used"] isKindOfClass:[NSNumber class]]) {
            self.used  =    [dic objectForKey:@"used"];
        }
        else{
            self.used  =   [NSNumber numberWithLongLong:0];
        }
        
        if ([[dic objectForKey:@"max"] isKindOfClass:[NSNumber class]]) {
            self.max  =    [dic objectForKey:@"max"];
        }
        else{
            self.max  =   [NSNumber numberWithLongLong:0];
        }
	}
	return self;
}

- (void)dealloc
{
    [path release];
	[used release];
	[max release];
	[super dealloc];
}
@end
