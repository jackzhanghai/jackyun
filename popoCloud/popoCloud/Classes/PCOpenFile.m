//
//  PCOpenFile.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-9-16.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "PCOpenFile.h"
#import "PCAppDelegate.h"
#import "FileListViewController.h"
#import "PCUtilityFileOperate.h"

@implementation PCOpenFile
@synthesize localPath;
- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.localPath = nil;
        viewController = nil;
    }
    
    return self;
}

- (void)dealloc
{
    self.localPath = nil;
    if (viewController)
    {
        [viewController release];
    }
    [super dealloc];
}

- (void) openFile:(NSString*)path viewType:(NSInteger)type viewController:(UIViewController*)controller{
    
    self.localPath = path;

    
//    if ([localPath hasSuffix:@".txt"])
//    {
//        NSDictionary *attr = [ [NSFileManager defaultManager] attributesOfItemAtPath:localPath error:nil];
//        if ([[attr objectForKey:NSFileSize] intValue] > 1024 * 1024 * 10)
//        {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"NoSuitableProgram", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
//            [alert show];
//            [alert release];
//            return;
//        }
//    }
    
    if (viewController) [viewController release];
    [controller retain];
    viewController = controller;
    
    NSLog(@"open.... %@", localPath);
    //    [(FileListViewController*)viewController stopAnimating];
    
//    NSURL *fileURL = [NSURL fileURLWithPath:localPath];
    
    //add by libing 2013-6-26 fix bug bug54838  bug 55854
    
    //    BOOL result = [QLPreviewController2 canPreviewItem:(id<QLPreviewItem>)fileURL];
    BOOL result = [PCUtilityFileOperate itemCanOpenWithPath:localPath];
        if (!result) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"NoSuitableProgram", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        [alert release];
//        [self release];
    }
    else{
        QLPreviewController *previewController = [[QLPreviewController alloc] init];
        previewController.dataSource = self;
        previewController.delegate = self;
        
        // start previewing the document at the current section index
        previewController.currentPreviewItemIndex = 0;
//        [viewController.navigationController pushViewController:previewController animated:YES];
//        [previewController release];
        [viewController.navigationController presentModalViewController: previewController animated:YES];
        [previewController release];

    }
}

#pragma mark -
#pragma mark Document Interaction Controller Delegate Methods

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return viewController;
}
/*
 - (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
 NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
 NSString *documentsDirectory = [paths objectAtIndex:0];
 NSString *appFile = [documentsDirectory stringByAppendingPathComponent:previewDocumentFileName];
 NSFileManager *fileManager = [NSFileManager defaultManager];
 [fileManager removeItemAtPath:appFile error:NULL];
 //[controller release]; // Release here was causing crashes
 }
 */
//*/
#pragma mark -
#pragma mark QLPreviewControllerDataSource

// Returns the number of items that the preview controller should preview
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)previewController
{
    return 1;
}

- (void)previewControllerDidDismiss:(QLPreviewController *)controller
{
    // if the preview dismissed (done button touched), use this method to post-process previews
    [self release];
}

// returns the item that the preview controller should preview
- (id)previewController:(QLPreviewController *)previewController previewItemAtIndex:(NSInteger)idx
{
    return [NSURL fileURLWithPath:localPath];
}

- (void)previewControllerWillDismiss:(QLPreviewController *)controller
{
    if (controller.navigationController) {
        [controller.navigationController setToolbarHidden:YES animated:NO];
    }
}

@end
