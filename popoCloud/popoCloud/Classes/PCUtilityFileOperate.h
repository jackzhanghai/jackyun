//
//  PCUtilityFileOperate.h
//  popoCloud
//
//  Created by xy  on 13-8-26.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVAsset.h>
#import <QuickLook/QLPreviewController.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "FileCache.h"
#import "FileDownloadManager.h"
#import "PCFileInfo.h"
#import "QLPreviewController2.h"

@interface PCUtilityFileOperate : NSObject

+ (BOOL)livingMediaSupport:(NSString *)ext;

+ (BOOL)itemCanOpenWithPath:(NSString *)path;

+ (NSString*) getImgByExt:(NSString*)ext;

+ (NSString*) getImgName:(NSString*)imgName;

+ (NSString*) getXibName:(NSString*)xibName;

+ (NSString*) formatFileSize:(long long)size isNeedBlank:(BOOL)isNeedBlank;

+ (NSData *)getUploadImageData:(ALAssetRepresentation *)present;

+ (BOOL)moveCacheFileToDownload:(NSString *)hostPath
                       fileSize:(long long)size
                      fileCache:(FileCache *)fileCache
                       fileType:(NSInteger)type;

+ (NSString *)moveDownloadFileToCache:(NSString *)hostPath
                             downPath:(NSString *)downFilePath;

+ (FileDownloadManager*) downloadManager;

+ (BOOL) checkPrivacyForAlbum;

+ (void)checkDownloadFilesExist;

+ (void) deleteFile:(NSString*)path;

+ (void) openFileAtPath:(NSString*)path WithBackTitle:(NSString*)title andFileInfo:(PCFileInfo*)fileInfo andNavigationViewControllerDelegate:(UIViewController*)delegate;
@end
