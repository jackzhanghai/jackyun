//
//  PCFileInfo.m
//  popoCloud
//
//  Created by Kortide on 13-8-26.
//
//

#import "PCFileInfo.h"
#import "FileCache.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"

@implementation PCFileInfo
@synthesize         createTime;
@synthesize         modifyTime;
@synthesize         visitTime;
@synthesize         size;
@synthesize         dir;
@synthesize         ext;
@synthesize         name;
@synthesize         path;
@synthesize         bFileFoldType;
@synthesize         bIsUploading;
@synthesize        identify;
@synthesize        hash;
@synthesize        publicAccess;
@synthesize bIsAdded;

- (id)init
{
	self = [super init];
	if (self != nil) {
	}
	return self;
}

- (void) checkFileType
{
    if ([[PCUtilityFileOperate getImgByExt:self.ext] isEqualToString:@"file_pic.png"]) {
        self.mFileType =  PC_FILE_IMAGE;
    }
    else if ([[PCUtilityFileOperate getImgByExt:self.ext] isEqualToString:@"file_video.png"] )
    {
        self.mFileType =  PC_FILE_VEDIO;
    }
    else if([[PCUtilityFileOperate getImgByExt:self.ext] isEqualToString:@"file_music.png"])
    {
        self.mFileType =  PC_FILE_AUDIO;
    }
    else
    {
        self.mFileType =  PC_FILE_OTHER;
    }
}

- (id)initWithImageFileInfo:(NSDictionary*)dic
{
    self = [super init];
	if (self != nil) {
        self.hash =  [dic objectForKey:@"hash"];
        self.modifyTime =    [dic objectForKey:@"modifyTime"];
        self.size =  [dic objectForKey:@"size"];
        self.name =  [dic objectForKey:@"name"] ;
        self.path =  [dic objectForKey:@"path"];
        self.identify = [dic objectForKey:@"id"];
        self.ext =  [self.name pathExtension];
        self.bFileFoldType = NO;
        [self checkFileType];
	}
	return self;
}

- (id)initWithFileShareInfo:(NSDictionary*)dic
{
    self = [super init];
	if (self != nil) {
        self.modifyTime =    [dic objectForKey:@"modifyTime"];
        self.size =  [dic objectForKey:@"size"];
        self.name =  [[dic objectForKey:@"location"] lastPathComponent];
        self.path =  [dic objectForKey:@"location"];
        self.identify = [dic objectForKey:@"id"];
        self.ext =  [self.name pathExtension];
        id publicToken = [dic objectForKey:@"allowpublicaccess"];
        self.publicAccess = publicToken?([NSString stringWithFormat:@"%@",publicToken]):nil;

        id type = [dic objectForKey:@"isdir"];
        if (type &&  ([type intValue] ==0)) {
            self.bFileFoldType = NO;;
        }
        else{
            self.bFileFoldType = YES;
        }
        [self checkFileType];
	}
	return self;
}

- (id)initWithFileInfoDic:(NSDictionary*)dic
{
    self = [super init];
	if (self != nil) {
        self.createTime = [dic objectForKey:@"createTime"];
        self.modifyTime = [dic objectForKey:@"modifyTime"];
        self.visitTime = [dic objectForKey:@"visitTime"];
        self.size = [dic objectForKey:@"size"];
        self.dir = [dic objectForKey:@"dir"];
        self.name = [dic objectForKey:@"name"];
        self.path = [dic objectForKey:@"path"];
        self.ext = [self.name pathExtension];
        self.bIsAdded = [[dic objectForKey:@"isadd"] boolValue];
        id type = [dic objectForKey:@"type"];
        if ([type isKindOfClass:[NSString class]]) {
            self.bFileFoldType = [[type lowercaseString] isEqualToString:@"folder"];
        }
        else{
            self.bFileFoldType = YES;
        }
        [self checkFileType];
	}
	return self;
}

- (id)initWithPCFileDownloadedInfo:(PCFileDownloadedInfo*)downLoadInfo
{
    self = [super init];
	if (self != nil) {
        self.modifyTime = downLoadInfo.modifyTime;
        self.path   = downLoadInfo.hostPath;
        self.size    = downLoadInfo.size;
        self.name = downLoadInfo.localPath;
        self.bFileFoldType = NO;
        self.ext = [self.path pathExtension];
        [self checkFileType];
	}
	return self;
}

- (void)dealloc
{
    [createTime   release];
    [modifyTime release];
    [visitTime      release];
    [size              release];
    [identify        release];
    [hash             release];
    [publicAccess release];
    [dir release];
	[ext release];
	[name release];
    [path release];
	[super dealloc];
}

@end
