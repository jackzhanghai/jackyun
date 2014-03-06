//
//  FileSearch.h
//  ECloud
//
//  Created by Chen Dongxiao on 11-8-24.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCRestClient.h"

#define STATUS_GET_SEARCH_ID 1
#define STATUS_GET_SEARCH_STATUS 2
#define STATUS_GET_SEARCH_RESULT 3
#define STATUS_GET_SEARCH_CANCEL 4

#define SEARCH_LIMIT 2048

@class FileSearch;

@protocol PCFileSearchDelegate
- (void) searchFileFail:(FileSearch*)fileSearch error:(NSString*)error;
- (void) searchFileAddObjects:(FileSearch*)fileSearch objects:(NSArray*)objects;
- (void) searchFileFinish:(FileSearch*)fileSearch;

- (void) searchCancelFail:(FileSearch*)fileSearch error:(NSString*)error;
- (void) searchCancelFinish:(FileSearch*)fileSearch;

@end

@interface FileSearch : NSObject <PCRestClientDelegate>{
    NSString *dirPath;
    NSString *searchId;
    NSString *element;
    NSInteger result;
    
    NSInteger start;
    BOOL isFinished;
    BOOL isOver;
    NSString* url;
    NSString *searchKey;
    PCRestClient *restClient;
}

@property (assign) id<PCFileSearchDelegate> delegate;
@property (nonatomic,retain) NSMutableData* data;
@property (nonatomic, retain) KTURLRequest *currentRequest;

- (void) searchFile:(NSString*)path key:(NSString*)key delegate:(id)_delegate;
- (void) getSearchStatus;
- (void) getSearchResult:(NSInteger)start limit:(NSInteger)limit;
- (NSString*)currentSearchID;
- (void) searchCancelWithdelegate:(id)_delegate  andSerchID:(NSString*)searchID;
-(void)cancel;

@end
