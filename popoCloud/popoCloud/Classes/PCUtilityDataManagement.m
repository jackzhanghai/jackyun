//
//  PCUtilityDataManagement.m
//  popoCloud
//
//  Created by xy  on 13-8-26.
//
//

#import "PCUtilityDataManagement.h"
#import "PCAppDelegate.h"
@implementation PCUtilityDataManagement

static NSManagedObjectContext* gContext = nil;

+ (NSManagedObjectContext*) managedObjectContext
{
    if (!gContext) {
        gContext = [(PCAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext] ;
    }
    
    return gContext;
}

/**
 * 查询数据库返回想要的数据，从主线程的NSManagedObjectContext获取
 * @param entityName 数据库表名
 * @param descriptors 排序的NSSortDescriptor对象数组
 * @param predicate 查询条件判断，过滤数据
 * @param limit 限制查询返回的数据的最大数量，传0表示没限制
 * @param name 查询缓存名
 * @return 查询到的符合条件的项组成的数组
 */
+ (NSArray *)fetchObjects:(NSString *)entityName
          sortDescriptors:(NSArray *)descriptors
                predicate:(NSPredicate *)predicate
               fetchLimit:(NSUInteger)limit
                threadMOC:(NSManagedObjectContext *)moc
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    [fetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:moc]];
    [fetchRequest setSortDescriptors:descriptors];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:limit];
    
    NSError *error = nil;
    NSArray *objects = [moc executeFetchRequest:fetchRequest error:&error];
    
    if (error)
        DLogError(@"fetch DB Objects error:%@",error.localizedDescription);
    
    //    NSFetchedResultsController *fetchResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[PCUtility managedObjectContext] sectionNameKeyPath:nil cacheName:name];
    //
    //    NSError *err = nil;
    //    if (![fetchResultsController performFetch:&err])
    //        NSLog(@"fetchObjects:%@", [err localizedDescription]);
    //
    //    NSArray* objects = fetchResultsController.fetchedObjects;
    //
    //    [fetchResultsController release];
    [fetchRequest release];
    
    return objects;
}

/**
 * 查询数据库返回想要的数据，从指定的NSManagedObjectContext获取（可能是子线程的MOC）
 * @param entityName 数据库表名
 * @param descriptors 排序的NSSortDescriptor对象数组
 * @param predicate 查询条件判断，过滤数据
 * @param limit 限制查询返回的数据的最大数量，传0表示没限制
 * @param moc 指定的NSManagedObjectContext
 * @return 查询到的符合条件的项组成的数组
 */

+ (NSArray *)fetchObjects:(NSString *)entityName
          sortDescriptors:(NSArray *)descriptors
                predicate:(NSPredicate *)predicate
               fetchLimit:(NSUInteger)limit
                cacheName:(NSString *)name
{
    return [PCUtilityDataManagement fetchObjects:entityName
                   sortDescriptors:descriptors
                         predicate:predicate
                        fetchLimit:limit
                         threadMOC:[PCUtilityDataManagement managedObjectContext]];
}

/**
 * 数据库内容改变后，存储更新
 */
+ (void)saveInfos
{
    NSError *err;
    if (![[PCUtilityDataManagement managedObjectContext] save:&err])
        DLogError(@"save database error:%@", [err localizedDescription]);
}

/**
 * 获取当前设备的磁盘可用容量
 * @return 可用容量大小
 */
+ (long long)getFreeSpace
{
    NSFileManager *fm = [NSFileManager defaultManager];
	NSDictionary *fattributes = [fm attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    //    long long totalSize = [[fattributes objectForKey:NSFileSystemSize] longLongValue];
    long long freeSize = [[fattributes objectForKey:NSFileSystemFreeSize] longLongValue];
    NSLog(@"freeSize=%lld",freeSize);
    
    return freeSize;
}

@end
