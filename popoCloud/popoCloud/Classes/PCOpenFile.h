//
//  PCOpenFile.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-9-16.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>

#define TYPE_OPEN_FILE_DEFAULT 0

@class UIDocumentInteractionController;
@interface PCOpenFile : NSObject <UIDocumentInteractionControllerDelegate,QLPreviewControllerDataSource,
QLPreviewControllerDelegate> {
    NSString *localPath;
    UIViewController* viewController;
}
@property(nonatomic,retain) NSString *localPath;
- (void) openFile:(NSString*)path viewType:(NSInteger)type viewController:(UIViewController*)controller;
@end
