//
//  PCShareServices.m
//  popoCloud
//
//  Created by leijun on 13-9-2.
//
//

#import "PCShareServices.h"
#import "PCFileInfo.h"
#import "PCUtilityShareGlobalVar.h"
@interface PCShareServices()
{
    NSMutableSet *requests;
}

@end

@implementation PCShareServices
@synthesize delegate;
- (id)init {
    if (self = [super init])
    {
        requests = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self cancelAllRequests];
    [requests release];
    [super dealloc];
}

- (void)cancelAllRequests
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    for (KTURLRequest* request in requests) {
        [request cancel];
    }
    [requests removeAllObjects];
}

-(void)getShareURLForFile:(NSString *)path withPublic:(BOOL)bPublic
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishGetShareURLWithPath:)];
    request.process = @"CreateShare";
    if (!bPublic) {
        request.params = [NSDictionary dictionaryWithObjectsAndKeys:path,@"path",
                                                                   @"False",@"public",nil];
    }
    else{
        request.params = [NSDictionary dictionaryWithObject:path forKey:@"path"];
    }

    [request start];
    [requests addObject:request];
    [request release];
}

-(void)requestDidFinishGetShareURLWithPath:(PCURLRequest *)request
{
    if (request.error)
    {
        if ([delegate respondsToSelector:@selector(getShareURLWithPathFailed:withError:)])
        {
            [delegate deleteShareFileWithIDFailed:self withError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict)
        {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                NSString *shareUrl = [dict valueForKey:@"url"];
                if (shareUrl)
                {
                    id temp = [dict valueForKey:@"allowpublicaccess"];
                    NSString *accessCode = temp ? [NSString stringWithString:temp] : nil;
                    if ([delegate respondsToSelector:@selector(getShareURLWithPathSuccess:withUrl:accessCode:)])
                    {
                        [delegate getShareURLWithPathSuccess:self withUrl:shareUrl accessCode:accessCode];
                    }
                }
                else
                {
                    if ([delegate respondsToSelector:@selector(getShareURLWithPathFailed:withError:)])
                    {
                        NSDictionary *info = [NSDictionary dictionaryWithObject:NSLocalizedString(@"ShareFail", nil) forKey:@"message"];
                        NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:1 userInfo:info];
                        [delegate getShareURLWithPathFailed:self withError:error];
                    }

                }

            }
            else if (result == 1 || result >1000)
            {
                
                if ([delegate respondsToSelector:@selector(getShareURLWithPathFailed:withError:)])
                {
                    NSString *errMsg = dict[@"errMsg"];
                    NSString *errStr = [errMsg hasSuffix:@"NotExist"] ?
                    NSLocalizedString(@"FileNotExist", nil) : NSLocalizedString(@"ServerError", nil);
                    NSDictionary *info = [NSDictionary dictionaryWithObject:errStr forKey:@"message"];
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:1 userInfo:info];
                    [delegate getShareURLWithPathFailed:self withError:error];
                }

            }
            else
            {
                if ([delegate respondsToSelector:@selector(getShareURLWithPathFailed:withError:)])
                {
                    NSDictionary *info = [NSDictionary dictionaryWithObject:NSLocalizedString(@"FileNotFound", nil) forKey:@"message"];
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:1 userInfo:info];
                    [delegate getShareURLWithPathFailed:self withError:error];
                }
            }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(getShareURLWithPathFailed:withError:)])
            {
                NSDictionary *info = [NSDictionary dictionaryWithObject:NSLocalizedString(@"ShareFail", nil) forKey:@"message"];
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:1 userInfo:info];
                [delegate getShareURLWithPathFailed:self withError:error];
            }
        }
    }
    
    [requests removeObject:request];
}
-(void)getAllShareFiles
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishGetAllShareFiles:)];
    request.process = @"GetShares";
    [request start];
    [requests addObject:request];
    [request release];

}
-(void)requestDidFinishGetAllShareFiles:(PCURLRequest *)request
{
    if (request.error)
    {
        if ([delegate respondsToSelector:@selector(getAllShareFilesFailed:withError:)])
        {
            [delegate getAllShareFilesFailed:self withError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict)
        {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                NSArray *fileList = [dict valueForKey:@"data"];
                NSMutableArray *fileListData = [NSMutableArray arrayWithCapacity:fileList.count];
                NSEnumerator *enumerator = [fileList reverseObjectEnumerator];
                for (NSDictionary *fileInfo in enumerator)
                {
                    PCFileInfo *temp = [[PCFileInfo alloc] initWithFileShareInfo:fileInfo];
                    [fileListData addObject:temp];
                    [temp release];
                }
                if ([delegate respondsToSelector:@selector(getAllShareFilesSuccess:withFileArray:)])
                {
                    [delegate getAllShareFilesSuccess:self withFileArray:fileListData];
                }
            }
            else
            {
                if ([delegate respondsToSelector:@selector(getAllShareFilesFailed:withError:)])
                {
                    if ([dict objectForKey:@"errCode"])
                    {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate getAllShareFilesFailed:self withError:error];
                }
            }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(getAllShareFilesFailed:withError:)])
            {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate getAllShareFilesFailed:self withError:error];
            }
        }
    }
    
    [requests removeObject:request];
}

-(void)deleteShareFileWithID:(NSString *)shareID
{
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidFinishdeleteShareFileWithID:)];
    request.process = @"DeleteShare";
    request.params = [NSDictionary dictionaryWithObject:shareID forKey:@"id"];
    [request start];
    [requests addObject:request];
    [request release];
}
-(void)requestDidFinishdeleteShareFileWithID:(PCURLRequest *)request
{
    if (request.error)
    {
        if ([delegate respondsToSelector:@selector(deleteShareFileWithIDFailed:withError:)])
        {
            [delegate deleteShareFileWithIDFailed:self withError:request.error];
        }
    }
    else
    {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict)
        {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0)
            {
                
                if ([delegate respondsToSelector:@selector(deleteShareFileWithIDSuccess:)])
                {
                    [delegate deleteShareFileWithIDSuccess:self];
                }
            }
            else
            {
                if ([delegate respondsToSelector:@selector(deleteShareFileWithIDFailed:withError:)])
                {
                    if ([dict objectForKey:@"errCode"])
                    {
                        result = [[dict objectForKey:@"errCode"] intValue];
                    }
                    NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                    [delegate deleteShareFileWithIDFailed:self withError:error];
                }
            }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(deleteShareFileWithIDFailed:withError:)])
            {
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
                [delegate deleteShareFileWithIDFailed:self withError:error];
            }
        }
    }
    
    [requests removeObject:request];
}
@end
