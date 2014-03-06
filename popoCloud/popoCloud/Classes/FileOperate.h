//
//  FileOperate.h
//  popoCloud
//
//  Created by ice on 13-12-3.
//
//

#import <Foundation/Foundation.h>
#import "PCRestClient.h"
@class FileOperate;

@protocol PCFileOperateDelegate <NSObject>

-(void)fileOperateFinished:(FileOperate *)fileOperate;//文件操作完成
-(void)fileOperateFailed:(FileOperate *)fileOperate error:(NSError*)error;
-(void)fileOperateFinishedCount:(NSInteger)finishedCount totalCount:(NSInteger)total;

-(void)fileOperateCanceledSuccess:(FileOperate *)fileOperate;
-(void)fileOperateCanceledFailed:(FileOperate *)fileOperate error:(NSError*)error;

@end


@interface FileOperate : NSObject <PCRestClientDelegate>
{
    NSString  *operatePath;//所有的操作路径
    NSString  *operateID;//操作id
    NSInteger succeedFileCount;//成功操作的数量
    NSInteger finishedFileCount;//完成操作的数量
    NSInteger totalFileCount;//总数量
    NSArray   *finishedPathArray;//完成操作的路径
    NSString  *currentOperatePath;//当前操作的路径
    PCRestClient *restClient;
    BOOL      finished;//是否完成操作
    BOOL      canceled;//是否取消
}

@property (assign) id<PCFileOperateDelegate> delegate;
@property (assign) NSInteger totalFileCount;//总数量
@property (nonatomic, retain) KTURLRequest *currentRequest;
-(void)fileOperateWithPath:(NSString *)path method:(NSString *)method delegateOwner:(id<PCFileOperateDelegate>)operateDelegate;
-(void)cancelFileOperate;
-(NSString *)currentOperateID;
-(NSInteger)succeedCount;
-(NSInteger)finishedCount;
-(NSArray *)finishedPathArray;
@end
