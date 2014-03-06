//
//  PCUtilityDataManagement.h
//  popoCloud
//
//  Created by xy  on 13-8-26.
//
//

#import <Foundation/Foundation.h>

@interface PCUtilityDataManagement : NSObject

+ (NSManagedObjectContext*) managedObjectContext;

+ (NSArray *)fetchObjects:(NSString *)entityName
          sortDescriptors:(NSArray *)descriptors
                predicate:(NSPredicate *)predicate
               fetchLimit:(NSUInteger)limit
                threadMOC:(NSManagedObjectContext *)moc;

+ (NSArray *)fetchObjects:(NSString *)entityName
          sortDescriptors:(NSArray *)descriptors
                predicate:(NSPredicate *)predicate
               fetchLimit:(NSUInteger)limit
                cacheName:(NSString *)name;

+ (void)saveInfos;

+ (long long)getFreeSpace;
@end
