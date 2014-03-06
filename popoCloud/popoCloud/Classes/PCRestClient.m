//
//  PCRestClient.m
//  popoCloud
//
//  Created by suleyu on 13-8-26.
//
//

#import "PCRestClient.h"
#import "PCURLRequest.h"
#import "PCUtility.h"
#import "PCFileInfo.h"
#import "PCUtilityStringOperate.h"

@interface PCRestClient () {
    NSMutableSet* requests;
}
@end


@implementation PCRestClient
@synthesize delegate;

- (id)init
{
    if (self = [super init]) {
        requests = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self cancelAllRequests];
    [requests release];
    requests = nil;
    [super dealloc];
}

- (void)cancelAllRequests
{
    for (KTURLRequest* request in requests){
        [request cancel];
    }
    [requests removeAllObjects];
}

- (void)cancelRequest:(KTURLRequest *)request
{
    if ([requests containsObject:request]) {
        [request cancel];
        [requests removeObject:request];
    }
}

- (KTURLRequest *)getAllDiskSpaceInfo
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotDiskSpace:)];
    request.process = @"GetAllDiskSpaceInfo";
    [request start];
    
    [requests addObject:request];
    return [request autorelease];
}

- (KTURLRequest *)getAllDiskSpaceInfoWithServerAddr:(NSString*)serverUrl
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotDiskSpace:)];
    request.process = @"GetAllDiskSpaceInfo";
    request.urlServer = serverUrl;
    [request start];
    
    [requests addObject:request];
    return [request autorelease];
}


- (void)requestDidGotDiskSpace:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:getDiskSpaceFailedWithError:)]) {
            [delegate restClient:self getDiskSpaceFailedWithError:request.error];
        }
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                NSArray *disks = [dict valueForKey:@"data"];
                NSMutableArray *diskSizeData = [NSMutableArray arrayWithCapacity:disks.count];
                for (NSDictionary *disk in disks) {
                    PCDiskInfo *temp = [[PCDiskInfo alloc] initWithDic:disk];
                    [diskSizeData addObject:temp];
                    [temp release];
                }
                
                if ([delegate respondsToSelector:@selector(restClient:gotDiskSpace:)]) {
                    [delegate restClient:self gotDiskSpace:diskSizeData];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(restClient:getDiskSpaceFailedWithError:)]) {
                    if ([dict objectForKey:@"errCode"]) {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate restClient:self getDiskSpaceFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(restClient:getDiskSpaceFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate restClient:self getDiskSpaceFailedWithError:error];
            }
        }
    }
}

- (KTURLRequest *)getFileListInfoByPage:(NSDictionary *)dic
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotFileListInfo:)];
    request.process = @"GetFileList";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      [PCUtilityStringOperate encodeToPercentEscapeString:[dic objectForKey:@"parentDir"]], @"parentDir",
                      [PCUtilityStringOperate encodeToPercentEscapeString:@"type desc,name asc"], @"orderBy",
                      [dic objectForKey:@"start"],@"start",
                      [dic objectForKey:@"limit"],@"limit",nil];
    
    [request start];
    
    [requests addObject:request];
    return [request autorelease];

}
- (KTURLRequest *)getFileListInfo:(NSString *)parentDir
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotFileListInfo:)];
    if (parentDir == nil) {
        request.process = @"GetFolderList";
        request.params = [NSDictionary dictionaryWithObject:[PCUtilityStringOperate encodeToPercentEscapeString:@"name asc"] forKey:@"orderBy"];
    }
    else {
        request.process = @"GetFileList";
        request.params = [NSDictionary dictionaryWithObjectsAndKeys:[PCUtilityStringOperate encodeToPercentEscapeString:parentDir], @"parentDir",
                          [PCUtilityStringOperate encodeToPercentEscapeString:@"type desc,name asc"], @"orderBy", nil];
    }
    [request start];
    
    [requests addObject:request];
    return [request autorelease];
}

- (void)requestDidGotFileListInfo:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:getFileListInfoFailedWithError:)]) {
            [delegate restClient:self getFileListInfoFailedWithError:request.error];
        }
    } else {
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                NSArray *fileList = [dict valueForKey:@"data"];
                NSMutableArray *fileListData = [NSMutableArray arrayWithCapacity:fileList.count];
                for (NSDictionary *fileInfo in fileList) {
                    PCFileInfo *temp = [[PCFileInfo alloc] initWithFileInfoDic:fileInfo];
                    [fileListData addObject:temp];
                    [temp release];
                }
                
                if ([delegate respondsToSelector:@selector(restClient:gotFileListInfo:)]) {
                    [delegate restClient:self gotFileListInfo:fileListData];
                }
            }
            else {
                DLogInfo(@"ret: %@", [request resultString]);
                if ([delegate respondsToSelector:@selector(restClient:getFileListInfoFailedWithError:)]) {
                    if ([dict objectForKey:@"errCode"]) {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate restClient:self getFileListInfoFailedWithError:error];
                }
            }
        }
        else {
            DLogInfo(@"ret: %@", [request resultString]);
            if ([delegate respondsToSelector:@selector(restClient:getFileListInfoFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate restClient:self getFileListInfoFailedWithError:error];
            }
        }
    }
}


- (KTURLRequest *)getFileSerchIDForKey:(NSString*)key atPath:(NSString*)path
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotFileSerchID:)];
    request.process =  @"Search";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:[PCUtilityStringOperate encodeToPercentEscapeString:path], @"folder",
                      [PCUtilityStringOperate encodeToPercentEscapeString:key], @"keyword", nil];
    [request start];
    
    [requests addObject:request];
    return [request autorelease];
}

- (void)requestDidGotFileSerchID:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:getFileSerchIDFailedWithError:)]) {
            [delegate restClient:self getFileSerchIDFailedWithError:request.error];
        }
    }
    else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                NSString *searchId= [dict valueForKey:@"id"];
                if ([delegate respondsToSelector:@selector(restClient:gotFileSerchIDInfo:)]) {
                    [delegate restClient:self gotFileSerchIDInfo:searchId];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(restClient:getFileSerchIDFailedWithError:)]) {
                    if ([dict objectForKey:@"errCode"]) {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate restClient:self getFileSerchIDFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(restClient:getFileSerchIDFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate restClient:self getFileSerchIDFailedWithError:error];
            }
        }
    }
}

- (KTURLRequest *)getFileSearchStatusForSearchID:(NSString*)searchID
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotSearchStatus:)];
    request.process = @"GetSearchStatus";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      searchID, @"id", nil];
    [request start];
    [requests addObject:request];
    return [request autorelease];
}

- (void)requestDidGotSearchStatus:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:getFileSearchStatusFailedWithError:)]) {
            [delegate restClient:self getFileSearchStatusFailedWithError:request.error];
        }
    }
    else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                if ([delegate respondsToSelector:@selector(restClient:gotFileSerchStatusInfo:)]) {
                    [delegate restClient:self gotFileSerchStatusInfo:dict];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(restClient:getFileSearchStatusFailedWithError:)]) {
                    if ([dict objectForKey:@"errCode"]) {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate restClient:self getFileSearchStatusFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(restClient:getFileSearchStatusFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate restClient:self getFileSearchStatusFailedWithError:error];
            }
        }
    }
}


- (KTURLRequest *)getFileSearchResultForSearchID:(NSString*)searchID andStartIndex:(int)start andLimit:(int)limit
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotFileSearchResult:)];
    request.process = @"GetSearchResult";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      searchID, @"id",
                      //start, @"start",
                      [NSNumber numberWithInt:start], @"start",
                      //limit, @"limit",nil];
                      [NSNumber numberWithInt:limit], @"limit",nil];

    [request start];
    
    [requests addObject:request];
    return [request autorelease];
}

- (void)requestDidGotFileSearchResult:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:getFileSearchResultFailedWithError:)]) {
            [delegate restClient:self getFileSearchResultFailedWithError:request.error];
        }
    }
    else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                NSArray *searchResultInfo = [dict valueForKey:@"data"];
                NSMutableArray *serchResultListData = [NSMutableArray arrayWithCapacity:searchResultInfo.count];
                for (NSDictionary *fileInfo in searchResultInfo) {
                    PCFileInfo *temp = [[PCFileInfo alloc] initWithFileInfoDic:fileInfo];
                    [serchResultListData addObject:temp];
                    [temp release];
                }
                 if ([delegate respondsToSelector:@selector(restClient:gotFileSerchResultInfo:)]) {
                    [delegate restClient:self gotFileSerchResultInfo:serchResultListData];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(restClient:getFileSearchResultFailedWithError:)]) {
                    if ([dict objectForKey:@"errCode"]) {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate restClient:self getFileSearchResultFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(restClient:getFileSearchResultFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate restClient:self getFileSearchResultFailedWithError:error];
            }
        }
    }
}

- (KTURLRequest *)cancelFileSerchForSearchId:(NSString*)serchId
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotCancelFileSearchResult:)];
    request.process = @"CancelSearch";
    
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      serchId, @"id",nil];

    [request start];
    
    [requests addObject:request];
    return [request autorelease];
}

- (void)requestDidGotCancelFileSearchResult:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:getCancelFileSearchResultFailedWithError:)]) {
            [delegate restClient:self getCancelFileSearchResultFailedWithError:request.error];
        }
    }
    else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                if ([delegate respondsToSelector:@selector(restClient:gotCancelFileSerchResultInfo:)]) {
                    [delegate restClient:self gotCancelFileSerchResultInfo:dict];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(restClient:getCancelFileSearchResultFailedWithError:)]) {
                    if ([dict objectForKey:@"errCode"]) {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate restClient:self getCancelFileSearchResultFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(restClient:getCancelFileSearchResultFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate restClient:self getCancelFileSearchResultFailedWithError:error];
            }
        }
    }
}

- (KTURLRequest *)createFolder:(NSString*)path
{
     PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotCreateFolderResult:)];
    request.process = @"CreateFolder";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      [PCUtilityStringOperate encodeToPercentEscapeString:path], @"path",nil];
    [request start];
    
    [requests addObject:request];
    return [request autorelease];
}

- (void)requestDidGotCreateFolderResult:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:getCreateFolderResultFailedWithError:)]) {
            [delegate restClient:self getCreateFolderResultFailedWithError:request.error];
        }
    }
    else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                if ([delegate respondsToSelector:@selector(restClient:gotCreateFolderResultInfo:)]) {
                    [delegate restClient:self gotCreateFolderResultInfo:dict];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(restClient:getCreateFolderResultFailedWithError:)]) {
                    if ([dict objectForKey:@"errCode"]) {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate restClient:self getCreateFolderResultFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(restClient:getCreateFolderResultFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate restClient:self getCreateFolderResultFailedWithError:error];
            }
        }
    }
}

- (KTURLRequest *)deletePath:(NSString*)path
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotDeleteFolderResult:)];
    request.process = @"Remove";
    
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:[PCUtilityStringOperate encodeToPercentEscapeString:path], @"path"
                     , nil];

    [request start];
    
    [requests addObject:request];
    return [request autorelease];
}

- (void)requestDidGotDeleteFolderResult:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:deletePathFailedWithError:)]) {
            [delegate restClient:self deletePathFailedWithError:request.error];
        }
    }
    else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                if ([delegate respondsToSelector:@selector(restClient:deletedPath:)]) {
                    [delegate restClient:self deletedPath:dict];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(restClient:deletePathFailedWithError:)]) {
                    if ([dict objectForKey:@"errCode"]) {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate restClient:self deletePathFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(restClient:deletePathFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate restClient:self deletePathFailedWithError:error];
            }
        }
    }
}

- (KTURLRequest *)reNameFile:(NSString*)path  andNewName:(NSString*)name
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotReNameFilerResult:)];
    request.process = @"Rename";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      [PCUtilityStringOperate encodeToPercentEscapeString:name], @"newName",
                      [PCUtilityStringOperate encodeToPercentEscapeString:path], @"oldPath",nil];
    [request start];
    
    [requests addObject:request];
    return [request autorelease];
}

- (void)requestDidGotReNameFilerResult:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:reNameFileFailedWithError:)]) {
            [delegate restClient:self reNameFileFailedWithError:request.error];
        }
    }
    else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                if ([delegate respondsToSelector:@selector(restClient:reNameFile:)]) {
                    [delegate restClient:self reNameFile:dict];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(restClient:reNameFileFailedWithError:)]) {
                    if ([dict objectForKey:@"errCode"]) {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate restClient:self reNameFileFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(restClient:reNameFileFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate restClient:self reNameFileFailedWithError:error];
            }
        }
    }
}
-(void)requestDidGetGroupImageResult:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error)
    {
        if ([delegate respondsToSelector:@selector(restClient:pictureListGetGroupImageByInfoFailedWithError:)])
        {
            [delegate restClient:self pictureListGetGroupImageByInfoFailedWithError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        if (dict)
        {
            int result = [[dict objectForKey:@"result"] intValue];
            
            if (result == 0)
            {
//                NSMutableArray *resultArray = [NSMutableArray array];
//                NSArray *dataArray = dict[@"data"];
//                for (NSDictionary* fileInfoDic in dataArray)
//                {
//                    PCFileInfo *fileInfo = [[[PCFileInfo alloc] initWithImageFileInfo:fileInfoDic] autorelease];
//                    [resultArray addObject:fileInfo];
//                }
                if ([delegate respondsToSelector:@selector(restClient:pictureListGetGroupImageByInfoSuccess:)])
                {
                    [delegate restClient:self pictureListGetGroupImageByInfoSuccess:dict];
                }

            }
            else if (result  == 20)
            {
                
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                if ([delegate respondsToSelector:@selector(restClient:pictureListGetGroupImageByInfoFailedWithError:)])
                {
                    [delegate restClient:self pictureListGetGroupImageByInfoFailedWithError:error];
                }
            }
            else if([dict objectForKey:@"errCode"])
            {
               result = [[dict objectForKey:@"errCode"] intValue];
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                if ([delegate respondsToSelector:@selector(restClient:pictureListGetGroupImageByInfoFailedWithError:)])
                {
                    [delegate restClient:self pictureListGetGroupImageByInfoFailedWithError:error];
                }
            }
        else{
            NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
            if ([delegate respondsToSelector:@selector(restClient:pictureListGetGroupImageByInfoFailedWithError:)])
            {
                [delegate restClient:self pictureListGetGroupImageByInfoFailedWithError:error];
            }
        }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(restClient:pictureListGetGroupImageByInfoFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate restClient:self pictureListGetGroupImageByInfoFailedWithError:error];
            }
        }

    }

}
- (KTURLRequest *)pictureListGetGroupImageByInfo:(NSDictionary *)dic
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGetGroupImageResult:)];
    request.process = @"GetLibraryGroupFiles";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      @"picture",@"name",
                      @"modifyTime",@"groupKey",
                      @"month",@"groupType",
                      [dic objectForKey:@"groupName"],@"groupValue",
                      [PCUtilityStringOperate encodeToPercentEscapeString:@"modifyTime desc"],@"orderBy",
                      [dic objectForKey:@"start"], @"start",
                      [dic objectForKey:@"limit"],@"limit",
                      nil];

    [request start];

    [requests addObject:request];
    return [request autorelease];
}
-(void)requestDidGetPictureGroupByInfo:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:getPictureGroupByInfoFailedWithError:)]) {
            [delegate restClient:self getPictureGroupByInfoFailedWithError:request.error];
        }
    }
    else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict)
        {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                if ([delegate respondsToSelector:@selector(restClient:getPictureGroupByInfoSuccess:)])
                {
                    [delegate restClient:self getPictureGroupByInfoSuccess:[dict objectForKey:@"data"]];
                }
            }
            else
            {
                if ([delegate respondsToSelector:@selector(restClient:getPictureGroupByInfoFailedWithError:)]) {
                    if ([dict objectForKey:@"errCode"])
                    {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSString *errMsg = dict[@"errMsg"];
                    if ([errMsg hasSuffix:@"NotEnoughSpace"])
                    {
                        result = PC_Err_LackSpace;
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate restClient:self getPictureGroupByInfoFailedWithError:error];
                }
            }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(restClient:getPictureGroupByInfoFailedWithError:)])
            {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate restClient:self getPictureGroupByInfoFailedWithError:error];
            }
        }
    }

}

- (KTURLRequest *)getPictureGroupByInfo:(NSString *)sortedType andGroupType:(NSString*)groupType
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGetPictureGroupByInfo:)];
    request.process = @"GetLibraryGroup";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      @"picture",@"name",
                      @"modifyTime",@"groupKey",
                      groupType,@"groupType",
                      [PCUtilityStringOperate encodeToPercentEscapeString:sortedType],@"orderBy",
                      nil];
    
    [request start];
    
    [requests addObject:request];
    return [request autorelease];
}


-(void)requestDidBatchDeletePath:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:batchDeletedPathFailedWithError:)]) {
            [delegate restClient:self batchDeletedPathFailedWithError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        if ([[dict objectForKey:@"result"] intValue] == 0)
        {
            if ([delegate respondsToSelector:@selector(restClient:batchDeletedPathSuccess:)])
            {
                [delegate restClient:self batchDeletedPathSuccess:[dict objectForKey:@"id"]];
            }
            
        }
        else
        {
            if ([delegate respondsToSelector:@selector(restClient:batchDeletedPathFailedWithError:)])
            {
                int result = [[dict valueForKey:@"result"] intValue];
                if ([dict objectForKey:@"errCode"]) {
                    result = [[dict objectForKey:@"errCode"] intValue];
                }
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                [delegate restClient:self batchDeletedPathFailedWithError:error];
            }
        }
    }
}
/**
 * 批量删除
 * @param path  删除的路径
 * @return
 */
- (KTURLRequest *)batchDeletePath:(NSString*)path
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidBatchDeletePath:)];
    request.process = @"OperateFile";
    request.method = @"POST";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:[PCUtilityStringOperate encodeToPercentEscapeString:path],@"path",@"remove",@"method", nil];
    [request start];
    [requests addObject:request];
    return [request autorelease];
}


-(void)requestDidGetOperateFileStatus:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error)
    {
        if ([delegate respondsToSelector:@selector(restClient:getOperateFileStatusFailedWithError:)]) {
            [delegate restClient:self getOperateFileStatusFailedWithError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        if ([[dict objectForKey:@"result"] intValue] == 0)
        {
            if ([delegate respondsToSelector:@selector(restClient:getOperateFileStatusSuccess:)])
            {
                [delegate restClient:self getOperateFileStatusSuccess:dict];
            }
            
        }
        else
        {
            if ([delegate respondsToSelector:@selector(restClient:getOperateFileStatusFailedWithError:)])
            {
                int result = [[dict valueForKey:@"result"] intValue];
                if ([dict objectForKey:@"errCode"]) {
                    result = [[dict objectForKey:@"errCode"] intValue];
                }
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                [delegate restClient:self getOperateFileStatusFailedWithError:error];
            }
        }
    }

}
/**
 * 取得文件操作状态，批量删除时配合此函数使用
 * @param id  文件操作返回的id
 * @return
 */
- (KTURLRequest *)getOperateFileStatus:(NSString*)operateID
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGetOperateFileStatus:)];
    request.process = @"GetOperateFileStatus";
    request.params = [NSDictionary dictionaryWithObject:operateID forKey:@"id"];
    [request start];
    [requests addObject:request];
    return [request autorelease];
}


-(void)requestDidCancelOperateFile:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:cancelOperateFileFailedWithError:)]) {
            [delegate restClient:self cancelOperateFileFailedWithError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        if ([[dict objectForKey:@"result"] intValue] == 0)
        {
            if ([delegate respondsToSelector:@selector(restClient:cancelOperateFileSuccess:)])
            {
                [delegate restClient:self cancelOperateFileSuccess:dict];
            }
            
        }
        else
        {
            if ([delegate respondsToSelector:@selector(restClient:batchDeletedPathFailedWithError:)])
            {
                int result = [[dict valueForKey:@"result"] intValue];
                if ([dict objectForKey:@"errCode"]) {
                    result = [[dict objectForKey:@"errCode"] intValue];
                }
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                [delegate restClient:self cancelOperateFileFailedWithError:error];
            }
        }
    }

}
/**
 * 取消文件操作
 * @param id  文件操作返回的id
 * @return
 */
- (KTURLRequest *)cancelOperateFile:(NSString*)operateID
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidCancelOperateFile:)];
    request.process = @"CancelOperateFile";
    request.params = [NSDictionary dictionaryWithObject:operateID forKey:@"id"];
    [request start];
    [requests addObject:request];
    return [request autorelease];
}


-(void)requestDidClearOperateFile:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:clearOperateFileFailedWithError:)]) {
            [delegate restClient:self clearOperateFileFailedWithError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        if ([[dict objectForKey:@"result"] intValue] == 0)
        {
            if ([delegate respondsToSelector:@selector(restClient:clearOperateFileSuccess:)])
            {
                [delegate restClient:self clearOperateFileSuccess:dict];
            }
            
        }
        else
        {
            if ([delegate respondsToSelector:@selector(restClient:clearOperateFileFailedWithError:)])
            {
                int result = [[dict valueForKey:@"result"] intValue];
                if ([dict objectForKey:@"errCode"]) {
                    result = [[dict objectForKey:@"errCode"] intValue];
                }
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                [delegate restClient:self clearOperateFileFailedWithError:error];
            }
        }
    }

}
/**
 * 文件操作完成后，清除相关信息(成功之后调用)
 * @param id  文件操作返回的id
 * @return
 */
- (KTURLRequest *)clearOperateFile:(NSString*)operateID
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidClearOperateFile:)];
    request.process = @"ClearOperateFile";
    request.params = [NSDictionary dictionaryWithObject:operateID forKey:@"id"];
    [request start];
    [requests addObject:request];
    return [request autorelease];
}

- (KTURLRequest *)getPictureFileList:(NSString *)dirPath
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGetPictureFileList:)];
    request.process = @"GetImageFileList";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      [PCUtilityStringOperate encodeToPercentEscapeString:dirPath], @"dir",
                      [PCUtilityStringOperate encodeToPercentEscapeString:@"type desc,name asc"], @"orderBy",
                      nil];
    [request start];
    
    [requests addObject:request];
    return [request autorelease];
}

-(void)requestDidGetPictureFileList:(KTURLRequest *)request
{
    [requests removeObject:request];
    
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:getPictureFileListFailedWithError:)]) {
            [delegate restClient:self getPictureFileListFailedWithError:request.error];
        }
    } else {
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                DLogInfo(@"ret: %@", [request resultString]);
                NSArray *fileList = [dict valueForKey:@"data"];
                NSMutableArray *fileListData = [NSMutableArray arrayWithCapacity:fileList.count];
                for (NSDictionary *fileInfo in fileList) {
                    PCFileInfo *temp = [[PCFileInfo alloc] initWithFileInfoDic:fileInfo];
                    [fileListData addObject:temp];
                    [temp release];
                }
                
                if ([delegate respondsToSelector:@selector(restClient:gotPictureFileList:)]) {
                    [delegate restClient:self gotPictureFileList:fileListData];
                }
            }
            else {
                DLogInfo(@"ret: %@", [request resultString]);
                if ([delegate respondsToSelector:@selector(restClient:getPictureFileListFailedWithError:)]) {
                    if ([dict objectForKey:@"errCode"]) {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate restClient:self getPictureFileListFailedWithError:error];
                }
            }
        }
        else {
            DLogInfo(@"ret: %@", [request resultString]);
            if ([delegate respondsToSelector:@selector(restClient:getPictureFileListFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate restClient:self getPictureFileListFailedWithError:error];
            }
        }
    }
}

- (KTURLRequest *)setPictureScanFolder:(NSArray *)folders exceptFolder:(NSArray *)exceptFolders
{
    NSMutableString *paths = [[NSMutableString alloc] initWithString:@"["];
    NSEnumerator *enumerator = [folders objectEnumerator];
    PCFileInfo *file = [enumerator nextObject];
    if (file) {
        while (YES) {
            [paths appendFormat:@"\"%@\"", file.path];
            
            file = [enumerator nextObject];
            if (file == nil) {
                break;
            }
            
            [paths appendString:@","];
        }
    }
    [paths appendString:@"]"];
    
    NSMutableString *exceptPaths = [[NSMutableString alloc] initWithString:@"["];
    enumerator = [exceptFolders objectEnumerator];
    file = [enumerator nextObject];
    if (file) {
        while (YES) {
            [exceptPaths appendFormat:@"\"%@\"", file.path];
            
            file = [enumerator nextObject];
            if (file == nil) {
                break;
            }
            
            [exceptPaths appendString:@","];
        }
    }
    [exceptPaths appendString:@"]"];
    
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidSetPictureScanFolder:)];
    request.process = @"SetScanFolder";
    request.method = @"POST";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      [PCUtilityStringOperate encodeToPercentEscapeString:paths], @"paths",
                      [PCUtilityStringOperate encodeToPercentEscapeString:exceptPaths], @"exceptPaths",
                      nil];
    [request start];
    [paths release];
    
    [requests addObject:request];
    return [request autorelease];
}

- (void)requestDidSetPictureScanFolder:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:setPictureScanFolderFailedWithError:)]) {
            [delegate restClient:self setPictureScanFolderFailedWithError:request.error];
        }
    }
    else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                if ([delegate respondsToSelector:@selector(restClient:setPictureScanFolderSuccess:)]) {
                    [delegate restClient:self setPictureScanFolderSuccess:dict];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(restClient:setPictureScanFolderFailedWithError:)]) {
                    if ([dict objectForKey:@"errCode"]) {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate restClient:self setPictureScanFolderFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(restClient:setPictureScanFolderFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate restClient:self setPictureScanFolderFailedWithError:error];
            }
        }
    }
}

- (KTURLRequest *)deletePictureScanFolder:(NSArray *)folders
{
    NSMutableString *paths = [[NSMutableString alloc] initWithString:@"["];
    
    NSEnumerator *enumerator = [folders objectEnumerator];
    PCFileInfo *file = [enumerator nextObject];
    if (file) {
        while (YES) {
            [paths appendFormat:@"\"%@\"", file.path];
            
            file = [enumerator nextObject];
            if (file == nil) {
                break;
            }
            
            [paths appendString:@","];
        }
    }
    [paths appendString:@"]"];
    
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidDeletePictureScanFolder:)];
    request.process = @"DelScanFolder";
    request.method = @"POST";
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:
                      [PCUtilityStringOperate encodeToPercentEscapeString:paths], @"paths",
                      nil];
    [request start];
    [paths release];
    
    [requests addObject:request];
    return [request autorelease];
}

- (void)requestDidDeletePictureScanFolder:(KTURLRequest *)request
{
    [requests removeObject:request];
    if (request.error) {
        if ([delegate respondsToSelector:@selector(restClient:deletePictureScanFolderFailedWithError:)]) {
            [delegate restClient:self deletePictureScanFolderFailedWithError:request.error];
        }
    }
    else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                if ([delegate respondsToSelector:@selector(restClient:deletePictureScanFolderSuccess:)]) {
                    [delegate restClient:self deletePictureScanFolderSuccess:dict];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(restClient:deletePictureScanFolderFailedWithError:)]) {
                    if ([dict objectForKey:@"errCode"]) {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate restClient:self deletePictureScanFolderFailedWithError:error];
                }
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(restClient:deletePictureScanFolderFailedWithError:)]) {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate restClient:self deletePictureScanFolderFailedWithError:error];
            }
        }
    }
}

@end
