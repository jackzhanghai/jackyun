//
//  Dictionary.m
//  vcardtest
//
//  Created by xy  on 13-5-18.
//  Copyright (c) 2013年 xy . All rights reserved.
//

#import "Dictionary.h"

@implementation Dictionary
/*
static Dictionary *instance = nil;
+(id) mutableDictionary{
   // NSLog(@"%@:::%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    @synchronized(self){
        if (instance == nil) {
            instance = [[Dictionary alloc]init];
        }
    }
    return instance;
}
 */
-(void) dealloc{
  //  NSLog(@"%@:::%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    
    [dict release];

    [super dealloc];
}

-(id) init{
   // NSLog(@"%@:::%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    if (self = [super init]) {
        //dict = [NSMutableDictionary dictionaryWithCapacity:0];
        dict = [[NSMutableDictionary alloc]init];
    }
    return self;
}

-(void) setMultiValue:(id)value forKey:(NSString *)key{
   // NSLog(@"%@:::%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    if ([[dict allKeys] containsObject:key]) {
        [[dict valueForKey:key] addObject:value];
    }
    else {
        NSMutableArray *valuesArray = [NSMutableArray arrayWithCapacity:0];
        [valuesArray addObject:value];
        [dict setValue:valuesArray forKey:key];
    }
}
-(NSArray*) allValuesForKey:(NSString *)key{
   // NSLog(@"%@:::%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    return [dict valueForKey:key];
}

-(NSArray*) allKeys{
   // NSLog(@"%@:::%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    return [dict allKeys];
}
-(NSArray*) allValues{
  //  NSLog(@"%@:::%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    NSMutableArray *allValuesArray = [NSMutableArray arrayWithCapacity:0];
    for (NSString * key in [self allKeys]){
        for (id value in [NSArray arrayWithArray:[self allValuesForKey:key]]) {
            [allValuesArray addObject:value];
        }
    }
    return allValuesArray;
}
-(BOOL) containObjectWithValue:(id)value andKey:(NSString *) key{
  //  NSLog(@"%@:::%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    if ([[dict allKeys] containsObject:key]) {
        if ([[dict valueForKey:key] containsObject:value]) {
            return YES;
        }
        else {
            return NO;
        }
    }
    else {
        return NO;
    }
}
-(NSString*) containObjectAllkey:(id)value{
  //  NSLog(@"%@:::%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    for (NSString * key in [self allKeys]){

        for (NSString* valueStr in [self allValuesForKey:key])
        {
            if (NSOrderedSame == [valueStr compare:value])
            {
                return key;
            }
        }
    }
    return nil;
    
}
-(int) indexOfAllValues:(id) value{
   // NSLog(@"%@:::%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    if ([[self allValues] containsObject:value]) {
        return [[self allValues] indexOfObject:value];
        
    }else{
        return -1;//no contains
    }
}
-(int) indexOfValues:(id) value andKey:(NSString*) key{
  //  NSLog(@"%@:::%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    if (![self containObjectWithValue:value andKey:key]) {
        return -1;//no contains
    }else{
        return [[self allValuesForKey:key] indexOfObject:value];
    }
}
-(void) clearDictionary{
    [dict removeAllObjects];
}
-(BOOL) fullCompare:(Dictionary *) compareDate
{
    
    NSArray *sourceKeyArray = [self allKeys];
    NSArray *compareKeyArray = [compareDate allKeys];
    NSArray *sourceValuesArray = [self allValues];
    NSArray *compareValuesArray = [compareDate allValues];
    if([sourceKeyArray count] != [compareKeyArray count])
    {
        return NO;
    }
    else
    {
        for (NSString* str in sourceKeyArray)
        {
            if (NO ==[compareKeyArray containsObject:str])
            {
                return NO;
            }
        }
        for (NSString* str in compareKeyArray)
        {
            if (NO ==[sourceKeyArray containsObject:str])
            {
                return NO;
            }
        }
        
    }
    if([sourceValuesArray count] != [compareValuesArray count])
    {
        return NO;
    }
    else
    {
        for (NSString* str in sourceValuesArray)
        {
            if (NO ==[compareValuesArray containsObject:str])
            {
                return NO;
            }
        }
        for (NSString* str in compareValuesArray)
        {
            if (NO ==[sourceValuesArray containsObject:str])
            {
                return NO;
            }
        }
        
    }
    return YES;

}
@end
