//
//  CustomContactData.h
//  vcardtest
//
//  Created by xy  on 13-5-17.
//  Copyright (c) 2013年 xy . All rights reserved.
//

#import <Foundation/Foundation.h>
#include "Dictionary.h"
@interface CustomContactData : NSObject
{
}
@property (retain, nonatomic) NSMutableArray *name;
@property (retain, nonatomic) NSMutableString *firstNamePhonetic;
@property (retain, nonatomic) NSMutableString *lastNamePhonetic;
@property (retain, nonatomic) NSMutableString *group;
@property (retain, nonatomic) NSMutableString *nickname;
@property (retain, nonatomic) NSMutableString *org;
@property (retain, nonatomic) NSMutableString *department;
@property (retain, nonatomic) NSMutableString *title;
@property (retain, nonatomic) Dictionary *tel;
@property (retain, nonatomic) Dictionary *url;
@property (retain, nonatomic) Dictionary *email;
@property (retain, nonatomic) Dictionary *address;
@property (retain, nonatomic) NSMutableString *bday;
@property (retain, nonatomic) Dictionary *date;
@property (retain, nonatomic) NSMutableArray *im;
@property (retain, nonatomic) Dictionary *server;
@property (retain, nonatomic) Dictionary *related;
@property (retain, nonatomic) NSMutableString *note;
-(void)setData:(NSString *)type data:(id)contactData;
//-(void)mutableDeepCopy:(NSString *)typeData data:(NSMutableDictionary *) sourceData;
-(BOOL)compareSameContact:(CustomContactData *)compareData;
@end

