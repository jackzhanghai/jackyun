//
//  Dictionary.h
//  vcardtest
//
//  Created by xy  on 13-5-18.
//  Copyright (c) 2013年 xy . All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

@interface Dictionary : NSObject{
    NSMutableDictionary *dict;
}
//+(id) mutableDictionary;
-(void) setMultiValue:(id)value forKey:(NSString *)key;
-(NSArray*) allValuesForKey:(NSString *)key;
-(NSArray*) allKeys;
-(NSArray*) allValues;
-(BOOL) containObjectWithValue:(id)value andKey:(NSString *) key;
-(int) indexOfValues:(id) value andKey:(NSString*) key;
-(int) indexOfAllValues:(id) value;
-(void) clearDictionary;
-(NSString*) containObjectAllkey:(id)value;
-(BOOL) fullCompare:(Dictionary *) compareDate;
@end
