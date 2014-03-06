//
//  CustomContactData.m
//  vcardtest
//
//  Created by xy  on 13-5-17.
//  Copyright (c) 2013年 xy . All rights reserved.
//

#import "CustomContactData.h"

@implementation CustomContactData
@synthesize name = _name;
@synthesize firstNamePhonetic = _firstNamePhonetic;
@synthesize lastNamePhonetic = _lastNamePhonetic;
@synthesize group = _group;
@synthesize nickname = _nickname;
@synthesize org = _org;
@synthesize department = _department;
@synthesize tel = _tel;
@synthesize email = _email;
@synthesize url = _url;
@synthesize address = _address;
@synthesize date = _date;
@synthesize im = _im;
@synthesize related = _related;
@synthesize note = _note;
@synthesize bday = _bday;
@synthesize server = _server;

- (void)dealloc
{

    [_name release];
    [_firstNamePhonetic release];
    [_lastNamePhonetic release];
    [_group release];
    [_nickname release];
    [_org release];
    [_department release];
    [_title release];
    [_tel release];
    [_url release];
    [_email release];
    [_address release];
    [_date  release];
    [_im release];
    [_related release];
    [_note release];
    [_bday release];
    [_server release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init])
    {
        _name = [[NSMutableArray alloc] init];
        _lastNamePhonetic = [[NSMutableString alloc] init];
        _firstNamePhonetic = [[NSMutableString alloc] init];
        _group = [[NSMutableString alloc] init];
        _nickname = [[NSMutableString alloc] init];
        _org = [[NSMutableString alloc] init];
        _department = [[NSMutableString alloc] init];
        _title = [[NSMutableString alloc] init];
        _tel = [[Dictionary alloc]init];
        _url =[[Dictionary alloc]init];
        _email =[[Dictionary alloc]init];
        _address =[[Dictionary alloc]init];
        _bday =[[NSMutableString alloc]init];
        _date =[[Dictionary alloc]init];
        _im =[[NSMutableArray alloc]init];
        _related =[[Dictionary alloc]init];
        _note = [[NSMutableString alloc]init];
        _server = [[Dictionary alloc] init];
    }
    return self;
}

-(BOOL)compareSameContact:(CustomContactData *)compareData
{
    for(NSUInteger i = 0; i < [self.name count] && i < [compareData.name count]; i++)
    {
        //NSLog(@"self.name %@   %@",self.name , compareData.name );
        if (NSOrderedSame != [[self.name objectAtIndex:i] compare:[compareData.name objectAtIndex:i]])
        {
            return NO;
        }

    }

    if (NSOrderedSame != [self.group compare:compareData.group])
    {
        return NO;
    }
    
   /* if (NSOrderedSame != [self.nickname compare:compareData.nickname])
    {
        return NO;
    }

    if (NSOrderedSame != [self.org compare:compareData.org])
    {
        return NO;
    }
    
    if (NSOrderedSame != [self.department compare:compareData.department])
    {
        return NO;
    }
    if (NSOrderedSame != [self.title compare:compareData.title])
    {
        return NO;
    }
    if (NSOrderedSame != [self.bday compare:compareData.bday])
    {
        return NO;
    }*/
    if(NO == [self.tel fullCompare:compareData.tel])
    {
        return NO;
    }
  /*  if(NO == [self.url fullCompare:compareData.url])
    {
        return NO;
    }
    if(NO == [self.email fullCompare:compareData.email])
    {
        return NO;
    }*/
    /*if(NO == [self.address fullCompare:compareData.address])
    {
        return NO;
    }
    if(NO == [self.date fullCompare:compareData.date])
    {
        return NO;
    }
    if(NO == [self.im fullCompare:compareData.im])
    {
        return NO;
    }
    if(NO == [self.related fullCompare:compareData.related])
    {
        return NO;
    }*/
    return YES;
}
-(void)setData:(NSString *)type data:(id)contactData
{

}
@end
