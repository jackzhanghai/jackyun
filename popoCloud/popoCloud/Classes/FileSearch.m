//
//  FileSearch.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-24.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "PCUtility.h"
#import "FileSearch.h"
#import "FileListViewController.h"


@implementation FileSearch

@synthesize delegate;
@synthesize currentRequest;

- (id)init
{
    self = [super init];
    if (self) {
        restClient = [[PCRestClient alloc] init];
        restClient.delegate = self;
    }
    return self;
}

- (NSString*)currentSearchID
{
    return searchId;
}

- (void) searchFile:(NSString*)path key:(NSString*)key delegate:(id)_delegate {
    
    if (delegate) [(NSObject*)delegate release];
    [_delegate retain];
    delegate = _delegate;
    dirPath = [path copy];
    start = 0;
    isFinished = NO;
    isOver = NO;
    self.currentRequest = [restClient getFileSerchIDForKey:key atPath:path];
}

- (void) getSearchStatus {
    self.currentRequest = [restClient getFileSearchStatusForSearchID:searchId];
}

- (void) getSearchResult:(NSInteger)_start limit:(NSInteger)limit {
    self.currentRequest = [restClient getFileSearchResultForSearchID:searchId andStartIndex:_start andLimit:limit];
}

-(void) searchCancelWithdelegate:(id)_delegate  andSerchID:(NSString*)searchID{
    
    if (delegate) [(NSObject*)delegate release];
    [_delegate retain];
    delegate = _delegate;
    [searchId release];
    searchId = [searchID retain];
    self.currentRequest = [restClient cancelFileSerchForSearchId:searchId];
}

-(void)cancel
{
    if (self.currentRequest ) {
        [restClient cancelRequest:self.currentRequest];
        self.currentRequest = nil;
    }
    if (delegate)
    {
        [(NSObject*)delegate release];
        delegate = nil;
    }
}

- (void)dealloc
{
    if (url) [url release];
    if (delegate) [(NSObject*)delegate release];
    self.data = nil;
    if (self.currentRequest) {
        [restClient cancelRequest:self.currentRequest];
        self.currentRequest = nil;
    }
    [restClient release];
    [super dealloc];
}

#pragma mark - PCRestClientDelegate
- (void)restClient:(PCRestClient*)client gotFileSerchIDInfo:(NSString*)newId
{
    if (!newId) {
        isOver = YES;
        [delegate searchFileFail:self error:NSLocalizedString(@"SearchError", nil)];
    }
    
    searchId = [newId copy];
    [self getSearchStatus];
}

- (void)restClient:(PCRestClient*)client getFileSerchIDFailedWithError:(NSError*)error
{
    isOver = YES;
    if (error.code == PC_Err_LackSpace)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"SearchErrorNoSpaceLeft", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        [alert release];
        self.currentRequest = nil;
        [delegate searchFileFail:self error:nil];
        return;
    }
    [ErrorHandler showErrorAlert:error];
    self.currentRequest = nil;
    [delegate searchFileFail:self error:nil];
}


- (void)restClient:(PCRestClient*)client gotFileSerchStatusInfo:(NSDictionary*)serchStatusInfoDic
{
    if ( (![serchStatusInfoDic valueForKey:@"finished"])   ||  (![serchStatusInfoDic valueForKey:@"start"])) {
        isOver = YES;
        [delegate searchFileFail:self error:NSLocalizedString(@"SearchError", nil)];
        return;
    }
    isFinished = [[serchStatusInfoDic valueForKey:@"finished"] boolValue];
    start = [[serchStatusInfoDic valueForKey:@"start"] integerValue];
    [self getSearchResult:start limit:SEARCH_LIMIT];
}

- (void)restClient:(PCRestClient*)client getFileSearchStatusFailedWithError:(NSError*)error
{
    isOver = YES;
    [ErrorHandler showErrorAlert:error];
    self.currentRequest = nil;
    [delegate searchFileFail:self error:nil];
}

- (void)restClient:(PCRestClient*)client gotFileSerchResultInfo:(NSArray*)serchResultInfoArray
{
    if (serchResultInfoArray && serchResultInfoArray.count) {
        [delegate searchFileAddObjects:self objects:serchResultInfoArray];
        //                NSLog(@"%@", [dict valueForKey:@"data"]);
    }
    
    if (isFinished) {
        isOver = YES;
        [delegate searchFileFinish:self];
    }
    else {
        [self getSearchStatus];
    }
}

- (void)restClient:(PCRestClient*)client getFileSearchResultFailedWithError:(NSError*)error
{
    isOver = YES;
    [ErrorHandler showErrorAlert:error];
    self.currentRequest = nil;
    [delegate searchFileFail:self error:nil];
}

- (void)restClient:(PCRestClient*)client gotCancelFileSerchResultInfo:(NSDictionary*)cancelSerchResultDic
{
    isOver = YES;
    [delegate searchCancelFinish:self];
}

- (void)restClient:(PCRestClient*)client getCancelFileSearchResultFailedWithError:(NSError*)error
{
    [delegate   searchCancelFail:self error:nil];
}

@end
