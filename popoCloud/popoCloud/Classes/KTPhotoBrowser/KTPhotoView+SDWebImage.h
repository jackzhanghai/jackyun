//
//  KTPhotoView+SDWebImage.h
//  Sample
//
//  Created by Henrik Nyh on 3/18/10.
//

#import "KTPhotoView.h"
#import "SDWebImageManagerDelegate.h"
#import "SDWebImageManager.h"
#import "FileCache.h"
#import "PCFileInfo.h"

@interface KTPhotoView (SDWebImage) <PCFileCacheDelegate, SDWebImageManagerDelegate>

- (void)setImageWithURL:(NSURL *)url;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;
//- (BOOL)StartLoadFileWithNode:(NSDictionary *)node;
- (BOOL)StartLoadFileWithPCFileInfo:(PCFileInfo *)fileInfo andImageType:(int)type;
@end