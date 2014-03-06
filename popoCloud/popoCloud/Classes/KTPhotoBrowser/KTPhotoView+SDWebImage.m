//
//  KTPhotoView+SDWebImage.m
//  Sample
//
//  Created by Henrik Nyh on 3/18/10.
//

#import "KTPhotoView+SDWebImage.h"
#import "PCUtility.h"
#import "UIImage+Compress.h"
#import "PCUtilityUiOperate.h"

@implementation KTPhotoView (SDWebImage)

- (void)setImageWithURL:(NSURL *)url {
    [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    
    // Remove in progress downloader from queue
    [manager cancelForDelegate:self];
    
    UIImage *cachedImage = nil;
    if (url) {
        cachedImage = [manager imageWithURL:url];
    }
    
    if (cachedImage) {
        [self setImage:cachedImage];
    }
    else {
        if (placeholder) {
            [self setImage:placeholder];
        }
        
        if (url) {
            [manager downloadWithURL:url delegate:self];
        }
    }
}

- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image {
    [self setImage:image];
}

- (void)loadImageFail
{
    [self.indicator stopAnimating];
    loadImageFailed = YES;
    [self setImage:[UIImage imageNamed:@"load_fail_img.png"]];
    self.labelProgress.hidden = NO;
    self.labelProgress.text =   NSLocalizedString(@"CachePictureFail", nil);
    self.currentCache = nil;
}

- (void)cacheFileFinish:(FileCache *)fileCache
{
    NSString *filePath = nil;
    filePath = fileCache.localPath;
    UIImage * original = [UIImage imageWithContentsOfFile:filePath];
    if(original)
    {
        if ( fileCache.fileSize  >= K_MAX_IMAGE_SIZE)
        {
            loadImageFailed = YES;
            [self setImage:[UIImage imageNamed:@"load_fail_img.png"]];
            self.labelProgress.hidden = NO;
            self.labelProgress.text = NSLocalizedString(@"CachePictureFail", nil);
            [self.indicator stopAnimating];
            return;
        }
        
        if (original.size.width>MAX_IMAGEPIX_X || original.size.height>MAX_IMAGEPIX_Y)
        {
            if ((original.size.width)*(original.size.height) >= K_MAX_IMAGE_POINTS)
            {
                loadImageFailed = YES;
                [self setImage:[UIImage imageNamed:@"load_fail_img.png"]];
                self.labelProgress.hidden = NO;
                self.labelProgress.text = NSLocalizedString(@"CachePictureFail", nil);
                [self.indicator stopAnimating];
                return;
            }
            //
            NSMutableDictionary *dic =  [NSMutableDictionary dictionaryWithDictionary:  [PCUtility compressingImgDic]];
            //已经在对图片做处理了
            NSLog(@"最近的 压缩完的窗口信息是:%@   对应的路径:%@ , 字典： %@",self,filePath,dic);
            if ([dic objectForKey:filePath]) {
                [dic setObject:self forKey:filePath];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^        {
                    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                    UIImage * original = [UIImage imageWithContentsOfFile:filePath];
                    if(original)
                    {
                        UIImage *compressedImgae = [original   compressedImage];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //[photoView setImage:compressedImgae];
                            NSLog(@"当前的 压缩完的图片信息是:%@   对应的路径:%@",dic,filePath);
                            self.labelProgress.hidden = YES;
                            [self.indicator stopAnimating];
                            loadImageFailed = NO;
                            [self setImage:compressedImgae];
                            [PCUtility setCompressImgDic:dic];
                        });
                    }
                    [pool release];
                });
                
                return;
            }
            else{
                [dic setObject:self forKey:filePath];
                [PCUtility setCompressImgDic:dic];
            }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^        {
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                UIImage * original = [UIImage imageWithContentsOfFile:filePath];
                if(original)
                {
                    UIImage *compressedImgae = [original   compressedImage];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //[photoView setImage:compressedImgae];
                        NSLog(@"当前的 压缩完的图片信息是:%@   对应的路径:%@",dic,filePath);
                        self.labelProgress.hidden = YES;
                        [self.indicator stopAnimating];
                        loadImageFailed = NO;
                        [self setImage:compressedImgae];
                        [[[PCUtility compressingImgDic] objectForKey:filePath] setImage:compressedImgae];
                        [[PCUtility compressingImgDic] removeObjectForKey:filePath];
                        //[PCUtility setCompressImgDic:dic];
                    });
                }
                [pool release];
            });
            //
        }
        else
        {
            loadImageFailed = NO;
            [self setImage:original];
            self.labelProgress.hidden = YES;
            [self.indicator stopAnimating];
        }
    }
    else{//文件size为0时，没发起网络请求，直接回调过来了
        [self loadImageFail];
        return;
    }
    
    self.currentCache = nil;
    //self.labelProgress.hidden = YES;
}

- (void) cacheFileFail:(FileCache*)fileCache hostPath:(NSString *)hostPath error:(NSString*)error
{
    [self loadImageFail];
    if (fileCache.errorNo == FILE_CACHE_ERROR_NO_NETWORK)
    {
        [PCUtilityUiOperate showNoNetAlert:[[UIApplication sharedApplication] delegate]];
    }
}

- (void)cacheFileProgress:(float)progress hostPath:(NSString *)hostPath
{
    //self.progressView.progress = progress;
    self.labelProgress.text = [NSString stringWithFormat:@"下载中：%.1f%%",  progress * 100];
    NSLog(@"当前图片下载进度 %f",progress * 100);
}

- (BOOL)StartLoadFileWithPCFileInfo:(PCFileInfo *)fileInfo andImageType:(int)type
{
    if ([fileInfo.size longLongValue]>= K_MAX_IMAGE_SIZE && type == TYPE_DOWNLOAD_FILE)
    {
        self.labelProgress.hidden = NO;
        self.labelProgress.text = NSLocalizedString(@"CachePictureFail", nil);
        return NO;
    }
    
    self.labelProgress.text = @"";
    FileCache *fileCache = [[FileCache alloc] init];
    fileCache.currentDeviceID = [[PCSettings sharedSettings] currentDeviceIdentifier];
    [fileCache setProgressView:nil progressScale:1.0];
    self.labelProgress.hidden = NO;
    [self bringSubviewToFront:self.labelProgress];
    self.currentCache = fileCache;
    [fileCache release];
    if(([self.currentCache cacheFile:fileInfo.path viewType:type viewController:self  fileSize:[fileInfo.size longLongValue] modifyGTMTime:[fileInfo.modifyTime longLongValue] showAlert:YES]))
    {
        return YES;
    }
    return NO;
}
@end