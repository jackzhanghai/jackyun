//
//  FileOperate.m
//  popoCloud
//
//  Created by ice on 13-12-3.
//
//

#import "FileOperate.h"

@interface  FileOperate()
-(void)getFileOperateStatus;
-(void)clearFileOperate;
@end

@implementation FileOperate
@synthesize delegate;
@synthesize currentRequest;
@synthesize totalFileCount;
- (id)init
{
    self = [super init];
    if (self) {
        restClient = [[PCRestClient alloc] init];
        restClient.delegate = self;
    }
    return self;
}
-(void)dealloc
{
    delegate = nil;
    if (self.currentRequest)
    {
        [restClient cancelRequest:self.currentRequest];
        self.currentRequest = nil;
    }
    if (operatePath) {
        [operatePath release];
        operatePath = nil;
    }
    if (operateID) {
        [operateID release];
        operateID = nil;
    }
    if (finishedPathArray) {
        [finishedPathArray release];
        finishedPathArray = nil;
    }
    if (currentOperatePath) {
        [currentOperatePath release];
        currentOperatePath = nil;
    }
    restClient.delegate = nil;
    [restClient release];
    restClient = nil;
    
    [super dealloc];
}
-(void)fileOperateWithPath:(NSString *)path method:(NSString *)method  delegateOwner:(id<PCFileOperateDelegate>)operateDelegate
{
    delegate = operateDelegate;
    operatePath = [path copy];
    finished = NO;
    canceled = NO;
    if ([method isEqualToString:@"remove"])
    {
        self.currentRequest = [restClient batchDeletePath:path];
    }
    
}
-(void)getFileOperateStatus
{
    self.currentRequest = [restClient getOperateFileStatus:operateID];
}
-(void)clearFileOperate
{
    self.currentRequest = [restClient clearOperateFile:operateID];
}
-(void)cancelFileOperate
{
    self.currentRequest = [restClient cancelOperateFile:operateID];
}
-(NSString *)currentOperateID
{
    return operateID;
}

- (void)restClient:(PCRestClient*)client batchDeletedPathSuccess:(NSString *)operateFileID
{
    operateID = [operateFileID copy];
    [self getFileOperateStatus];
}
- (void)restClient:(PCRestClient*)client batchDeletedPathFailedWithError:(NSError*)error
{
    if (delegate && [delegate respondsToSelector:@selector(fileOperateFailed:error:)])
    {
        [delegate fileOperateFailed:self error:error];
    }
}
-(NSInteger)succeedCount
{
    return succeedFileCount;
}
-(NSInteger)finishedCount
{
    return finishedFileCount;
}
-(NSArray *)finishedPathArray
{
    return finishedPathArray;
}
- (void)restClient:(PCRestClient*)client getOperateFileStatusSuccess:(NSDictionary *)resultInfo
{
    canceled = [[resultInfo objectForKey:@"canceled"] boolValue];
    if (canceled)
    {
        return;
    }
    finished = [[resultInfo objectForKey:@"finished"] boolValue];
    succeedFileCount = [[resultInfo objectForKey:@"operated"] integerValue];
    finishedFileCount = [[resultInfo objectForKey:@"totalCount"] integerValue];
    if (!finished)//表示没有完成
    {
        if (finishedPathArray)
        {
            [finishedPathArray release];
            finishedPathArray = nil;
        }
        finishedPathArray = [[resultInfo objectForKey:@"finishedPath"] copy];
        
        
        if (currentOperatePath)
        {
            [currentOperatePath release];
            currentOperatePath = nil;
        }
        currentOperatePath = [[resultInfo objectForKey:@"operating"] copy];
        if (delegate && [delegate respondsToSelector:@selector(fileOperateFinishedCount:totalCount:)])
        {
            [delegate fileOperateFinishedCount:finishedPathArray.count totalCount:totalFileCount];
        }
        
        [self getFileOperateStatus];
    }
    else
    {
        [self clearFileOperate];
    }
}
- (void)restClient:(PCRestClient*)client getOperateFileStatusFailedWithError:(NSError*)error
{
    if (delegate && [delegate respondsToSelector:@selector(fileOperateFailed:error:)])
    {
        [delegate fileOperateFailed:self error:error];
    }
}

- (void)restClient:(PCRestClient*)client cancelOperateFileSuccess:(NSDictionary *)resultInfo
{
    if (delegate && [delegate respondsToSelector:@selector(fileOperateCanceledSuccess:)])
    {
        [delegate fileOperateCanceledSuccess:self];
    }
}
- (void)restClient:(PCRestClient*)client cancelOperateFileFailedWithError:(NSError*)error
{
    if (delegate && [delegate respondsToSelector:@selector(fileOperateCanceledFailed:error:)])
    {
        [delegate fileOperateCanceledFailed:self error:error];
    }
}

- (void)restClient:(PCRestClient*)client clearOperateFileSuccess:(NSDictionary *)resultInfo
{
    if (delegate && [delegate respondsToSelector:@selector(fileOperateFinished:)])
    {
        [delegate fileOperateFinished:self];
    }
}
- (void)restClient:(PCRestClient*)client clearOperateFileFailedWithError:(NSError*)error
{
    if (delegate && [delegate respondsToSelector:@selector(fileOperateFinished:)])
    {
//        [delegate fileOperateFailed:self error:error];
        [delegate fileOperateFinished:self];//清理的时候失败，但是删除成功之后才会主动调用这个函数，所以应该提示删除成功
    }
}

@end
