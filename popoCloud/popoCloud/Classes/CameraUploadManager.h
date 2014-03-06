//
//  CameraUploadManager.h
//  popoCloud
//
//  Created by suleyu on 13-3-14.
//
//

#import <Foundation/Foundation.h>
#import "FileUpload.h"
#import "PCURLRequest.h"
typedef enum
{
    kCameraUploadStatus_Stoped,
    kCameraUploadStatus_NoUpload,
    kCameraUploadStatus_Preparing,
    kCameraUploadStatus_Uploading,
    kCameraUploadStatus_Failed,
    kCameraUploadStatus_Wait,
    kCameraUploadStatus_Denied,
    kCameraUploadStatus_NetworkError,
    kCameraUploadStatus_ServerError,
    kCameraUploadStatus_NoSpace,
} CameraUploadStatus;

@interface CameraUploadManager : NSObject <PCFileUploadDelegate> {
    NSManagedObjectContext *childContext;
    
    NSMutableArray *serverFileList;
    NSMutableArray *uploadedList;
    NSMutableArray *needUploadList;
    NSMutableArray *failedUploadList;
    NSString *uploadFolder;
    
    FileUpload *uploadTask;
    NSString *deviceIdentifier;
}
@property (nonatomic, retain) PCURLRequest *currentRequest;
@property (nonatomic, retain) FileUpload *uploadTask;
@property (atomic, assign) CameraUploadStatus uploadStatus;
@property (atomic, assign) NSUInteger uploadNum;

+ (CameraUploadManager *)sharedManager;

- (void) startCameraUpload;
- (void) stopCameraUpload;
- (void) setUseCellularData:(BOOL)useCellularData;

@end