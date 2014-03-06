//
//  PCBackupFile.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-10-10.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PCBackupFileDelegate
- (void) getBackupFileInfoFail:(NSString*)error;
- (void) getBackupFileInfoFinish;
@end

@interface PCBackupFile : NSObject {
    NSMutableData* data;
    NSString* documentPath;
    NSInteger mStatus;
    BOOL isFinish;
    
    NSString *plistPath;
    NSString *tmpBackupPath;
    UIProgressView *progressView;
    
    float progressValue;
}

@property (nonatomic, readonly) NSString *filePath;
@property (nonatomic, readonly) NSString *md5File;
@property (nonatomic, copy) NSString *modifyTime;
@property (nonatomic) float fileSize;

@property (assign) id<PCBackupFileDelegate> delegate;

@property (nonatomic) BOOL haveGetInfo;
@property (nonatomic) BOOL isCancel;

@property (nonatomic, retain) NSMutableData* data;

- (void) getBackupInfo;
- (void) getDocumentPath;
- (NSString *) getModifyTime;

- (NSInteger) backupContact:(NSString*)path progressView:(UIProgressView*)progressView progressScale:(float)scale scaleOffset:(float)offset;
- (NSInteger) restoreContact:(NSString*)path progressView:(UIProgressView*)progressView progressScale:(float)scale;

+ (BOOL) checkRestoreOldData;
- (void) deleteRestoreOldData;
- (void) restoreOldData:(UIProgressView*)progressView progressScale:(float)scale;
- (void) backupOldData:(UIProgressView*)progressView progressScale:(float)scale scaleOffset:(float)offset;

@end
