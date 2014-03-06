
//
//  vcardengine.m
//  vcardtest
//
//  Created by xy  on 13-5-15.
//  Copyright (c) 2013年 xy . All rights reserved.
//

#import "VcardEngine.h"
#import "CustomContactData.h"
@implementation VcardEngine
#define ABMULTIVALUESUM  20
#define SAVE_CONTACT_INTERVAl     100
#define SHOW_SAVE_CONTACT_PROGRESS   100
-(NSString *)loadAddressBook
{
    //读取本地电话本
    CFArrayRef ref = [self readAddressBook];
    if(ref) {
        //存储vcf文件到本地路径
        NSString* filePath = [self saveVCF:ref];
        /*  if(filePath) {
         //从本地路径读取vcf文件
         [self loadVCF:filePath];
         }*/
        
        CFRelease(ref);
        return filePath;
    }
    return nil;
}

-(CFArrayRef)readAddressBook
{
    
    ABAddressBookRef addressBook = nil;
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
    {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     dispatch_semaphore_signal(sema);
                                                 });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
        
        
    }
    else
    {
        addressBook = ABAddressBookCreate();
    }
    if (nil == groupInfo)
    {
        groupInfo =[[Dictionary alloc] init];
    }
    
    [self getAllContactGroupInfo:addressBook];
    CFArrayRef contacts = ABAddressBookCopyArrayOfAllPeople(addressBook);
    [self paintInfo:contacts];
    CFRelease(addressBook);
    return contacts;
}


-(NSMutableString*)generateVCardStringWithContacts:(CFArrayRef)contacts
{
    //NSInteger counter  = 0;
    NSMutableString *vcard = [[[NSMutableString alloc]init]autorelease];
    uploadContactNum = CFArrayGetCount(contacts);
    for(NSInteger i = 0; i < uploadContactNum; i++)
    {
        [_delegate updateProgress:((float)i/(float)uploadContactNum) title:[NSString stringWithFormat:@"获取本机通讯录数据 第%d条",i] mode:MBProgressHUDModeDeterminate];
        ABRecordRef person = CFArrayGetValueAtIndex(contacts, i);
        
        NSString *firstName = (NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        firstName = (firstName ? firstName : @"");
        NSString *lastName = (NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        lastName = (lastName ? lastName : @"");
        NSString *middleName = (NSString *)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
        NSString *prefix = (NSString *)ABRecordCopyValue(person, kABPersonPrefixProperty);
        NSString *suffix = (NSString *)ABRecordCopyValue(person, kABPersonSuffixProperty);
        NSString *nickName = (NSString *)ABRecordCopyValue(person, kABPersonNicknameProperty);
        NSString *firstNamePhonetic = (NSString *)ABRecordCopyValue(person,kABPersonFirstNamePhoneticProperty);
        NSString *lastNamePhonetic = (NSString *)ABRecordCopyValue(person, kABPersonLastNamePhoneticProperty);
        
        NSString *organization = (NSString *)ABRecordCopyValue(person, kABPersonOrganizationProperty);
        NSString *jobTitle = (NSString *)ABRecordCopyValue(person, kABPersonJobTitleProperty);
        NSString *department = (NSString *)ABRecordCopyValue(person, kABPersonDepartmentProperty);
        
        if(i > 0) {
            [vcard appendFormat:@"\n"];
        }
        ABRecordID recId = ABRecordGetRecordID(person);
        NSString *stringId = [NSString stringWithFormat:@"%d",recId];
        NSString *groupString = [groupInfo containObjectAllkey:stringId];
        
        if(nil == groupString)
        {
            [vcard appendFormat:@"BEGIN:VCARD\nN:%@;%@;%@;%@;%@\n",
             (firstName ? firstName : @""),
             (lastName ? lastName : @""),
             (middleName ? middleName : @""),
             (prefix ? prefix : @""),
             (suffix ? suffix : @"")];
            
        }
        else
        {
            [vcard appendFormat:@"BEGIN:VCARD\nN:%@;%@;%@;%@;%@\nX-GROUP:%@\n",
             (firstName ? firstName : @""),
             (lastName ? lastName : @""),
             (middleName ? middleName : @""),
             (prefix ? prefix : @""),
             (suffix ? suffix : @""),
             (groupString ? groupString :@"")];
        }
        
        if(nickName)
        {
            [vcard appendFormat:@"NICKNAME:%@\n",nickName];
        }
        
        if(firstNamePhonetic)
        {
            [vcard appendFormat:@"X-PHONETIC-FIRST-NAME:%@\n",firstNamePhonetic];
        }
        
        if(lastNamePhonetic)
        {
            [vcard appendFormat:@"X-PHONETIC-LAST-NAME:%@\n",lastNamePhonetic];
        }
        
        // Work
        if(organization)
        {
            [vcard appendFormat:@"ORG:%@;%@\n",(organization?organization:@""),(department?department:@"")];
        }
        
        if(jobTitle)
        {
            [vcard appendFormat:@"TITLE:%@\n",jobTitle];
        }
        
        // Tel
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        if(phoneNumbers)
        {
            for (int k = 0; (k < ABMultiValueGetCount(phoneNumbers)&& k < ABMULTIVALUESUM ); k++)
            {
                NSString *label = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(phoneNumbers, k));
                NSString *numberTemp = (NSString *)ABMultiValueCopyValueAtIndex(phoneNumbers, k);
                NSString *labelLower = [label lowercaseString];
                NSString *number = [[numberTemp componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"+0123456789()*#,;"] invertedSet]] componentsJoinedByString:@""];
                
                if ([labelLower isEqualToString:@"mobile"] ||[labelLower isEqualToString:@"移动"])
                    [vcard appendFormat:@"TEL;TYPE=MOBIlE:%@\n",number];
                else if ([labelLower isEqualToString:@"iphone"])
                    [vcard appendFormat:@"TEL;TYPE=iPhone:%@\n",number];
                else if ([labelLower isEqualToString:@"home"] ||[labelLower isEqualToString:@"住宅"])
                    [vcard appendFormat:@"TEL;TYPE=HOME:%@\n",number];
                else if ([labelLower isEqualToString:@"work"] ||[labelLower isEqualToString:@"工作"])
                    [vcard appendFormat:@"TEL;TYPE=WORK:%@\n",number];
                else if ([labelLower isEqualToString:@"main"] ||[labelLower isEqualToString:@"主要"])
                    [vcard appendFormat:@"TEL;TYPE=MAIN:%@\n",number];
                else if ([labelLower isEqualToString:@"home fax"] ||[labelLower isEqualToString:@"住宅传真"])
                    [vcard appendFormat:@"TEL;TYPE=HOME FAX:%@\n",number];
                else if ([labelLower isEqualToString:@"work fax"] || [labelLower isEqualToString:@"工作传真"])
                    [vcard appendFormat:@"TEL;TYPE=WORK FAX:%@\n",number];
                else if ([labelLower isEqualToString:@"other fax"]||[labelLower isEqualToString:@"其他传真"])
                    [vcard appendFormat:@"TEL;TYPE=OTHER FAX:%@\n",number];
                else if ([labelLower isEqualToString:@"pager"]||[labelLower isEqualToString:@"传呼"])
                    [vcard appendFormat:@"TEL;TYPE=PAGER:%@\n",number];
                else if([labelLower isEqualToString:@"other"] ||[labelLower isEqualToString:@"其他"])
                    [vcard appendFormat:@"TEL;TYPE=OTHER:%@\n",number];
                else
                { //类型解析不出来的
                    // counter++;
                    [vcard appendFormat:@"TEL;TYPE=%@:%@\n",label,number];
                }
            }
        }
        
        
        // Mail
        ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
        if(emails)
        {
            for (int k = 0; (k < ABMultiValueGetCount(emails) && k < ABMULTIVALUESUM ); k++)
            {
                NSString *label = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(emails, k));
                NSString *email = (NSString *)ABMultiValueCopyValueAtIndex(emails, k);
                NSString *labelLower = [label lowercaseString];
                
                if ([labelLower isEqualToString:@"home"] || [labelLower isEqualToString:@"住宅"])
                    [vcard appendFormat:@"EMAIL;TYPE=HOME:%@\n",email];
                else if ([labelLower isEqualToString:@"work"] || [labelLower isEqualToString:@"工作"])
                    [vcard appendFormat:@"EMAIL;TYPE=WORK:%@\n",email];
                else if ([labelLower isEqualToString:@"other"] || [labelLower isEqualToString:@"其他"])
                    [vcard appendFormat:@"EMAIL;TYPE=OTHER:%@\n",email];
                else
                {//类型解析不出来的
                    [vcard appendFormat:@"EMAIL;TYPE=%@:%@\n",label,email];
                }
            }
        }
        
        // url
        ABMultiValueRef urls = ABRecordCopyValue(person, kABPersonURLProperty);
        if(urls)
        {
            for (int k = 0; (k < ABMultiValueGetCount(urls) && k < ABMULTIVALUESUM ); k++)
            {
                NSString *label = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(urls, k));
                NSString *url = (NSString *)ABMultiValueCopyValueAtIndex(urls, k);
                NSString *labelLower = [label lowercaseString];
                
                
                if ([labelLower isEqualToString:@"home page"] || [labelLower isEqualToString:@"首页"])
                    [vcard appendFormat:@"URL;TYPE=HOME PAGE:%@\n",url];
                else if ([labelLower isEqualToString:@"home"] || [labelLower isEqualToString:@"住宅"])
                    [vcard appendFormat:@"URL;TYPE=HOME:%@\n",url];
                else if ([labelLower isEqualToString:@"work"] || [labelLower isEqualToString:@"工作"])
                    [vcard appendFormat:@"URL;TYPE=WORK:%@\n",url];
                else if ([labelLower isEqualToString:@"other"] || [labelLower isEqualToString:@"其他"])
                    [vcard appendFormat:@"URL;TYPE=OTHER:%@\n",url];
                else
                {//类型解析不出来的
                    [vcard appendFormat:@"URL;TYPE=%@:%@\n",label,url];
                }
            }
        }
        
        
        // Address
        ABMultiValueRef address = ABRecordCopyValue(person, kABPersonAddressProperty);
        if(address) {
            for (int k = 0; (k < ABMultiValueGetCount(address) && k < ABMULTIVALUESUM ); k++)
            {
                //获取地址Label
                NSString *label = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(address, k));
                //获取該label下的地址6属性
                NSDictionary * dic =(NSDictionary*) ABMultiValueCopyValueAtIndex(address, k);
                NSString *labelLower = [label lowercaseString];
                
                NSString * country = [dic valueForKey:(NSString *)kABPersonAddressCountryKey];
                
                NSString * city = [dic valueForKey:(NSString *)kABPersonAddressCityKey];
                
                NSString * state = [dic valueForKey:(NSString *)kABPersonAddressStateKey];
                
                NSString * streetTemp = [dic valueForKey:(NSString *)kABPersonAddressStreetKey ];
                
                NSString * street = [streetTemp stringByReplacingOccurrencesOfString: @"\n" withString:@" "];
                
                NSString * zip = [dic valueForKey:(NSString *)kABPersonAddressZIPKey];
                
                NSString *type = @"";
                NSString *labelField = @"";
                if([labelLower isEqualToString:@"work"] ||[labelLower isEqualToString:@"工作"]) type = @"WORK";
                else if([labelLower isEqualToString:@"home"] ||[labelLower isEqualToString:@"住宅"]) type = @"HOME";
                else if([labelLower isEqualToString:@"other"]||[labelLower isEqualToString:@"其他"]) type = @"OTHER";
                else type = labelLower;
                
                [vcard appendFormat:@"ADR;TYPE=%@:%@;%@;%@;%@;%@\n",type,street ,city,state,zip,country];
            }
        }
        NSString *Birthday = (NSString *)ABRecordCopyValue(person, kABPersonBirthdayProperty);
        if(Birthday)
        {
            [vcard appendFormat:@"BDAY:%@\n",Birthday];
        }
        
        
        //获取dates多值
        ABMultiValueRef dates = ABRecordCopyValue(person, kABPersonDateProperty);
        if(dates)
        {
            for (int k = 0; (k < ABMultiValueGetCount(dates) && k < ABMULTIVALUESUM ); k++)
            {
                NSString *label = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(dates, k));
                NSString *date = (NSString *)ABMultiValueCopyValueAtIndex(dates, k);
                //NSString *date =[dateTemp substringToIndex:7];
                NSString *labelLower = [label lowercaseString];
                
                if ([labelLower isEqualToString:@"anniversary"] || [labelLower isEqualToString:@"周年"])
                    [vcard appendFormat:@"DATE;TYPE=ANNIVERSARY:%@\n",date];
                else if ([labelLower isEqualToString:@"other"] || [labelLower isEqualToString:@"其他"])
                    [vcard appendFormat:@"DATE;TYPE=OTHER:%@\n",date];
                else
                {//类型解析不出来的
                    //  counter++;
                    [vcard appendFormat:@"DATE;TYPE=%@:%@\n",label,date];
                }
                
                
            }
        }
        
        // im
        ABMultiValueRef IMs = ABRecordCopyValue(person, kABPersonInstantMessageProperty);
        if(urls)
        {
            for (int k = 0; (k < ABMultiValueGetCount(IMs) && k < ABMULTIVALUESUM ); k++)
            {
                NSString *label = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(IMs, k));
                NSDictionary* instantMessageContent =(NSDictionary*) ABMultiValueCopyValueAtIndex(IMs, k);
                NSString *labelLower = [label lowercaseString];
                
                NSString* username = [instantMessageContent valueForKey:(NSString *)kABPersonInstantMessageUsernameKey];
                NSString* service = [instantMessageContent valueForKey:(NSString *)kABPersonInstantMessageServiceKey];
                
                if ([labelLower isEqualToString:@"home"] || [labelLower isEqualToString:@"住宅"])
                    //vcard = [vcard stringByAppendingFormat:@"X-IM;SERVICE=%@;TYPE=HOME:%@\n",service,username];
                    [vcard appendFormat:@"X-IM;SERVICE=%@;TYPE=HOME:%@\n",service,username];
                else if ([labelLower isEqualToString:@"work"] || [labelLower isEqualToString:@"工作"])
                    //vcard = [vcard stringByAppendingFormat:@"X-IM;SERVICE=%@;TYPE=WORK:%@\n",service,username];
                    [vcard appendFormat:@"X-IM;SERVICE=%@;TYPE=WORK:%@\n",service,username];
                else if ([labelLower isEqualToString:@"other"] || [labelLower isEqualToString:@"其他"])
                    //vcard = [vcard stringByAppendingFormat:@"X-IM;SERVICE=%@;TYPE=OTHER:%@\n",service,username];
                    [vcard appendFormat:@"X-IM;SERVICE=%@;TYPE=OTHER:%@\n",service,username];
                else
                {//类型解析不出来的
                    // counter++;
                    //  vcard = [vcard stringByAppendingFormat:@"X-IM;SERVICE=%@;TYPE=%@:%@\n",labelLower,service,username];
                    [vcard appendFormat:@"X-IM;SERVICE=%@;TYPE=%@:%@\n",labelLower,service,username];
                }
                
            }
        }
        if (IMs) {
            CFRelease(IMs);
        }
        ABMultiValueRef socials = ABRecordCopyValue(person, kABPersonSocialProfileProperty);
        if (socials)
        {
            for (int k = 0 ; (k<ABMultiValueGetCount(socials)&& k < ABMULTIVALUESUM ) ; k++)
            {
                CFDictionaryRef socialValue = ABMultiValueCopyValueAtIndex(socials, k);
                if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
                {
                    if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceTwitter, 0)==kCFCompareEqualTo)
                    {
                        NSString *twitterUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
                        [vcard appendFormat:@"X-SERVER;TYPE=twitter:%@\n",twitterUsername];
                    }
                    else if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceSinaWeibo, 0)==kCFCompareEqualTo)
                    {
                        NSString *SinaWeiboUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
                        [vcard appendFormat:@"X-SERVER;TYPE=SinaWeibo:%@\n",SinaWeiboUsername];
                    }
                    else if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceFacebook, 0)==kCFCompareEqualTo)
                    {
                        NSString *FacebookUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
                        [vcard appendFormat:@"X-SERVER;TYPE=Facebook:%@\n",FacebookUsername];
                    }
                    else if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceMyspace, 0)==kCFCompareEqualTo)
                    {
                        NSString *MyspaceUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
                        [vcard appendFormat:@"X-SERVER;TYPE=Myspace:%@\n",MyspaceUsername];
                    }
                    else if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceLinkedIn, 0)==kCFCompareEqualTo)
                    {
                        NSString *LinkedInUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
                        [vcard appendFormat:@"X-SERVER;TYPE=LinkedIn:%@\n",LinkedInUsername];
                    }
                    else if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceFlickr, 0)==kCFCompareEqualTo)
                    {
                        NSString *FlickrInUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
                        [vcard appendFormat:@"X-SERVER;TYPE=Flickr:%@\n",FlickrInUsername];
                    }
                    else
                    {
                        NSString *InUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
                        [vcard appendFormat:@"X-SERVER;TYPE=%@:%@\n",(NSString *)CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey),InUsername];
                    }
                    CFRelease(socialValue);
                }
                else
                {
                    if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceTwitter, 0)==kCFCompareEqualTo)
                    {
                        NSString *twitterUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
                        [vcard appendFormat:@"X-SERVER;TYPE=twitter:%@\n",twitterUsername];
                    }
                    else if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceFacebook, 0)==kCFCompareEqualTo)
                    {
                        NSString *FacebookUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
                        [vcard appendFormat:@"X-SERVER;TYPE=Facebook:%@\n",FacebookUsername];
                    }
                    else if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceMyspace, 0)==kCFCompareEqualTo)
                    {
                        NSString *MyspaceUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
                        [vcard appendFormat:@"X-SERVER;TYPE=Myspace:%@\n",MyspaceUsername];
                    }
                    else if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceLinkedIn, 0)==kCFCompareEqualTo)
                    {
                        NSString *LinkedInUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
                        [vcard appendFormat:@"X-SERVER;TYPE=LinkedIn:%@\n",LinkedInUsername];
                    }
                    else if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceFlickr, 0)==kCFCompareEqualTo)
                    {
                        NSString *FlickrInUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
                        [vcard appendFormat:@"X-SERVER;TYPE=Flickr:%@\n",FlickrInUsername];
                    }
                    else
                    {
                        NSString *InUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
                        [vcard appendFormat:@"X-SERVER;TYPE=%@:%@\n",(NSString *)CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey),InUsername];
                    }
                    CFRelease(socialValue);
                    
                }
            }
        }
        if (socials) {
            CFRelease(socials);
        }
        
        
        ABMultiValueRef related = ABRecordCopyValue(person, kABPersonRelatedNamesProperty);
        for (int y = 0; (y < ABMultiValueGetCount(related) && y < ABMULTIVALUESUM ); y++)
        {
            NSString* relatedLabel = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(related, y));
            NSString* relatedContent = (NSString*)ABMultiValueCopyValueAtIndex(related, y);
            if ([relatedLabel isEqualToString:@"mother"] || [relatedLabel isEqualToString:@"母亲"])
                [vcard appendFormat:@"X-RELATED;TYPE=mother:%@\n",relatedContent];
            else if ([relatedLabel isEqualToString:@"father"] || [relatedLabel isEqualToString:@"父亲"])
                [vcard appendFormat:@"X-RELATED;TYPE=father:%@\n",relatedContent];
            else if ([relatedLabel isEqualToString:@"parent"] || [relatedLabel isEqualToString:@"父母"])
                [vcard appendFormat:@"X-RELATED;TYPE=parent:%@\n",relatedContent];
            else if ([relatedLabel isEqualToString:@"brother"] || [relatedLabel isEqualToString:@"兄弟"])
                [vcard appendFormat:@"X-RELATED;TYPE=brother:%@\n",relatedContent];
            else if ([relatedLabel isEqualToString:@"sister"] || [relatedLabel isEqualToString:@"姐妹"])
                [vcard appendFormat:@"X-RELATED;TYPE=sister:%@\n",relatedContent];
            else if ([relatedLabel isEqualToString:@"child"] || [relatedLabel isEqualToString:@"子女"])
                [vcard appendFormat:@"X-RELATED;TYPE=child:%@\n",relatedContent];
            else if ([relatedLabel isEqualToString:@"friend"] || [relatedLabel isEqualToString:@"朋友"])
                [vcard appendFormat:@"X-RELATED;TYPE=friend:%@\n",relatedContent];
            else if ([relatedLabel isEqualToString:@"spouse"] || [relatedLabel isEqualToString:@"配偶"])
                [vcard appendFormat:@"X-RELATED;TYPE=spouse:%@\n",relatedContent];
            else if ([relatedLabel isEqualToString:@"partner"] || [relatedLabel isEqualToString:@"搭档"])
                [vcard appendFormat:@"X-RELATED;TYPE=partner:%@\n",relatedContent];
            else if ([relatedLabel isEqualToString:@"assistant"] || [relatedLabel isEqualToString:@"助理"])
                [vcard appendFormat:@"X-RELATED;TYPE=assistant:%@\n",relatedContent];
            else if ([relatedLabel isEqualToString:@"manager"] || [relatedLabel isEqualToString:@"上司"])
                [vcard appendFormat:@"X-RELATED;TYPE=manager:%@\n",relatedContent];
            else if ([relatedLabel isEqualToString:@"other"] || [relatedLabel isEqualToString:@"其他"])
                [vcard appendFormat:@"X-RELATED;TYPE=other:%@\n",relatedContent];
            else
                [vcard appendFormat:@"X-RELATED;TYPE=%@:%@\n",relatedLabel,relatedContent];
            [relatedLabel release];
            [relatedContent release];
        }
        
        if(related)
            CFRelease(related);
        
        NSString *note = (NSString *)ABRecordCopyValue(person, kABPersonNoteProperty);
        NSString *noteTemp = [note stringByReplacingOccurrencesOfString: @"\n" withString:@"\\n"];
        if (note)
        {
            [vcard appendFormat:@"NOTE:%@\n",[noteTemp stringByReplacingOccurrencesOfString: @"\r" withString:@"\\n"]];
            [note release];
        }
        
        [vcard appendFormat:@"END:VCARD"];
    }
    [groupInfo release];
    groupInfo = nil;
    return vcard;
}


-(void)parseVCardString:(NSString*)vcardString
{
    NSArray *lines = [vcardString componentsSeparatedByString:@"\n"];
    
    ABAddressBookRef addressBook = nil;
    CFErrorRef error = NULL;
    ABRecordRef newPerson = nil;
    ABMutableMultiValueRef multiPhone = nil;
    ABMutableMultiValueRef multiEmail = nil;
    ABMutableMultiValueRef multiUrl = nil;
    ABMutableMultiValueRef multiAddress = nil;
    ABMutableMultiValueRef multiDate = nil;
    ABMutableMultiValueRef multiSocials = nil;
    ABMutableMultiValueRef multiMessageService = nil;
    ABMutableMultiValueRef multiRelated = nil;
    //NSMutableDictionary *imDict = nil;
    NSMutableString *groupName = [[NSMutableString alloc]init];
    NSDictionary *telType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"MOBIlE:",@"2",@"iPhone:",@"3",@"HOME:",@"4",@"WORK:",@"5",@"MAIN:",@"6",@"HOME FAX:",@"7",@"WORK FAX:",@"8",@"OTHER FAX:",@"9",@"PAGER:",@"10",@"OTHER:",nil];
    
    NSDictionary *imType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"Facebook:",@"2",@"Skype:",@"3",@"Yahoo:",@"4",@"ICQ:",@"5",@"GoogleTalk:",@"6",@"GaduGadu:",@"7",@"QQ:",@"8",@"AIM:",@"9",@"Jabber:",@"10",@"twitter:",@"11",@"Flickr:",@"12",@"Myspace:",@"13",@"SinaWeibo:",@"14",@"LinkedIn:",nil];
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
    {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     dispatch_semaphore_signal(sema);
                                                 });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
        
        
    }
    else
    {
        addressBook = ABAddressBookCreate();
    }
    NSArray *groupArray = (NSArray *)ABAddressBookCopyArrayOfAllGroups(addressBook);
    
    for(NSString* line in lines)
    {
        if ([line hasPrefix:@"BEGIN"])
        {
            // NSLog(@"parse start");
            
            newPerson = ABPersonCreate();
            [groupName deleteCharactersInRange:NSMakeRange(0,[groupName length])];
            
        } else if ([line hasPrefix:@"END"])
        {
            
            
            if( !ABRecordSetValue(newPerson, kABPersonPhoneProperty, multiPhone, &error ))
            {
                NSLog(@"set person multiPhone error");
            }
            if( !ABRecordSetValue(newPerson, kABPersonEmailProperty, multiEmail, &error ))
            {
                NSLog(@"set person EMAIL error");
            }
            if( !ABRecordSetValue(newPerson, kABPersonURLProperty, multiUrl, &error ))
            {
                NSLog(@"set person multiUrl error");
            }
            if( !ABRecordSetValue(newPerson, kABPersonDateProperty, multiDate, &error ))
            {
                NSLog(@"set person multiDate error");
            }
            if (!ABRecordSetValue(newPerson, kABPersonSocialProfileProperty, multiSocials, &error))
            {
                NSLog(@"set person multiSocials error");
            }
            if (!ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiMessageService, &error))
            {
                NSLog(@"set person multiMessageService error");
            }
            if (!ABRecordSetValue(newPerson, kABPersonRelatedNamesProperty, multiRelated, &error))
            {
                NSLog(@"set person multiRelated error");
            }
            multiPhone = nil;
            multiEmail = nil;
            multiUrl = nil;
            multiAddress = nil;
            multiDate = nil;
            multiSocials =nil;
            multiMessageService = nil;
            multiRelated = nil;
            
            
            //将新的记录，添加到通讯录中
            ABAddressBookAddRecord(addressBook, newPerson, NULL);
            
            if([groupName length] >0)
            {
                if (0 == [groupArray count])
                {
                    //CFTypeRef groupNameRef = ABRecordCopyValue(group, kABGroupNameProperty);
                    CFErrorRef error;
                    ABRecordRef group = ABGroupCreate();
                    ABRecordSetValue(group, kABGroupNameProperty,groupName, &error);
                    ABAddressBookAddRecord(addressBook, group, &error);
                    ABAddressBookSave(addressBook, &error);
                    
                    ABGroupAddMember(group, newPerson, &error);
                    
                    //CFRelease(groupNameRef);
                }
                else
                {
                    
                    for (int i = 0 ; i < [groupArray count]; i++)
                    {
                        ABRecordRef group = [groupArray objectAtIndex:i];
                        CFTypeRef groupNameRef = ABRecordCopyValue(group, kABGroupNameProperty);
                        NSString *groupNameStr = [NSString stringWithFormat:@"%@", (NSString *)groupNameRef];
                        if (NSOrderedSame== [groupNameStr compare:groupName])
                        {
                            ABGroupAddMember(group, newPerson, &error);
                            CFRelease(groupNameRef);
                            break;
                        }
                        else if (NSOrderedSame!= [groupNameStr compare:groupName] && i == [groupArray count]-1)
                        {
                            CFErrorRef error;
                            ABRecordRef group = ABGroupCreate();
                            ABRecordSetValue(group, kABGroupNameProperty,groupName, &error);
                            ABAddressBookAddRecord(addressBook, group, &error);
                            ABAddressBookSave(addressBook, &error);
                            
                            ABGroupAddMember(group, newPerson, &error);
                            
                            CFRelease(groupNameRef);
                        }
                        //  [groupNames addObject:groupNameStr];
                        
                    }
                    
                }
                
            }
            //通讯录执行保存
            ABAddressBookSave(addressBook, NULL);
            
            // NSLog(@"parse end");
        } else if ([line hasPrefix:@"N:"])
        {
            NSArray *upperComponents = [line componentsSeparatedByString:@":"];
            NSArray *components = [[upperComponents objectAtIndex:1] componentsSeparatedByString:@";"];
            
            NSString * lastName = [components objectAtIndex:1];
            NSString * firstName = [components objectAtIndex:0];
            NSString * middleName = [components objectAtIndex:2];
            NSString * prefix = [components objectAtIndex:3];
            NSString * suffix = [components objectAtIndex:4];
            ABRecordSetValue(newPerson, kABPersonFirstNameProperty, firstName, &error);
            ABRecordSetValue(newPerson, kABPersonLastNameProperty, lastName, &error);
            ABRecordSetValue(newPerson, kABPersonMiddleNameProperty, middleName, &error);
            ABRecordSetValue(newPerson, kABPersonPrefixProperty, prefix, &error);
            ABRecordSetValue(newPerson, kABPersonSuffixProperty, suffix, &error);
            
        }else if([line hasPrefix:@"NICKNAME:"])
        {
            NSArray *upperComponents = [line componentsSeparatedByString:@":"];
            NSString * nickname = [upperComponents objectAtIndex:1];
            ABRecordSetValue(newPerson, kABPersonNicknameProperty, nickname, &error);
        }else if([line hasPrefix:@"X-GROUP:"])
        {
            NSArray *upperComponents = [line componentsSeparatedByString:@":"];
            //groupName= [upperComponents objectAtIndex:1];
            [groupName appendString:[upperComponents objectAtIndex:1]];
            
        }
        
        /* else if([line hasPrefix:@"X-PHONETIC-FIRST-NAME:"])
         {
         NSArray *upperComponents = [line componentsSeparatedByString:@":"];
         NSString * phoneticFirstName = [upperComponents objectAtIndex:1];
         ABRecordSetValue(newPerson, kABPersonFirstNamePhoneticProperty, phoneticFirstName, &error);
         NSLog(@"X-PHONETIC-FIRST-NAME:%@",phoneticFirstName);
         }
         else if([line hasPrefix:@"X-PHONETIC-LAST-NAME:"])
         {
         NSArray *upperComponents = [line componentsSeparatedByString:@":"];
         NSString * phoneticLastName = [upperComponents objectAtIndex:1];
         ABRecordSetValue(newPerson, kABPersonLastNamePhoneticProperty, phoneticLastName, &error);
         NSLog(@"X-PHONETIC-LAST-NAME:%@",phoneticLastName);
         }*/
        else if([line hasPrefix:@"ORG:"])
        {
            NSArray *upperComponents = [line componentsSeparatedByString:@":"];
            NSArray *components = [[upperComponents objectAtIndex:1] componentsSeparatedByString:@";"];
            
            NSString * org = [components objectAtIndex:0];
            NSString * department = [components objectAtIndex:1];
            ABRecordSetValue(newPerson, kABPersonOrganizationProperty, org, &error);
            ABRecordSetValue(newPerson, kABPersonDepartmentProperty, department, &error);
        }
        else if([line hasPrefix:@"TITLE:"])
        {
            NSArray *upperComponents = [line componentsSeparatedByString:@":"];
            NSString * title = [upperComponents objectAtIndex:1];
            ABRecordSetValue(newPerson, kABPersonJobTitleProperty, title, &error);
        }
        else if ([line hasPrefix:@"TEL;"])
        {
            // NSArray *components = [line componentsSeparatedByString:@";"];
            NSInteger range = [line rangeOfString:@"="].location;
            NSInteger rangeType  = [line rangeOfString:@":"].location;
            NSInteger length = [line length];
            NSString * type = [line substringWithRange:NSMakeRange(range+1,rangeType-range)];
            NSString * telNum = [line substringWithRange:NSMakeRange(rangeType+1,length-rangeType-1)];
            
            NSInteger dictionaryNum = [[telType objectForKey:type] intValue];
            if(multiPhone == nil)
                multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            
            switch (dictionaryNum)
            {
                case 1:
                    ABMultiValueAddValueAndLabel(multiPhone,telNum, kABPersonPhoneMobileLabel, NULL);
                    break;
                case 2:
                    ABMultiValueAddValueAndLabel(multiPhone,telNum, kABPersonPhoneIPhoneLabel, NULL);
                    break;
                case 3:
                    ABMultiValueAddValueAndLabel(multiPhone,telNum, kABPersonPhoneWorkFAXLabel, NULL);
                    break;
                case 4:
                    ABMultiValueAddValueAndLabel(multiPhone,telNum, kABPersonPhoneMainLabel, NULL);
                    break;
                case 5:
                    ABMultiValueAddValueAndLabel(multiPhone,telNum, kABPersonPhoneHomeFAXLabel, NULL);
                    break;
                case 6:
                    ABMultiValueAddValueAndLabel(multiPhone,telNum, kABPersonPhoneWorkFAXLabel, NULL);
                    break;
                case 7:
                    ABMultiValueAddValueAndLabel(multiPhone,telNum, kABPersonPhoneOtherFAXLabel, NULL);
                    break;
                case 8:
                    ABMultiValueAddValueAndLabel(multiPhone,telNum, kABPersonPhonePagerLabel, NULL);
                    break;
                    
                default:
                    ABMultiValueAddValueAndLabel(multiPhone,telNum, (CFStringRef)type, NULL);
                    break;
            }
            
        }
        else if ([line hasPrefix:@"EMAIL;"])
        {
            if (multiEmail == nil)
                multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            
            
            NSArray *components = [line componentsSeparatedByString:@":"];
            NSString *emailAddress = [components objectAtIndex:1];
            NSString *emailTemp = [components objectAtIndex:0];
            NSInteger rangeType  = [line rangeOfString:@"="].location;
            NSString *emailType = [emailTemp substringWithRange:NSMakeRange(rangeType+1,[emailTemp length]-rangeType-1)];
            
            if ([emailType isEqualToString:@"HOME"])
            {
                ABMultiValueAddValueAndLabel(multiEmail,emailAddress, kABHomeLabel, NULL);
            }
            else if([emailType isEqualToString:@"WORK"])
            {
                ABMultiValueAddValueAndLabel(multiEmail,emailAddress, kABWorkLabel, NULL);
            }
            else if([emailType isEqualToString:@"OTHER"])
            {
                ABMultiValueAddValueAndLabel(multiEmail,emailAddress, kABOtherLabel, NULL);
            }
            else
            {
                ABMultiValueAddValueAndLabel(multiEmail,emailAddress, (CFStringRef)emailType, NULL);
            }
            
        }
        else if ([line hasPrefix:@"URL;"])
        {
            if (multiUrl == nil)
                multiUrl = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            
            NSArray *components = [line componentsSeparatedByString:@":"];
            NSString *urlAddress = [components objectAtIndex:1];
            NSString *urlTemp = [components objectAtIndex:0];
            NSInteger rangeType  = [line rangeOfString:@"="].location;
            NSString *urlType = [urlTemp substringWithRange:NSMakeRange(rangeType+1,[urlTemp length]-rangeType-1)];
            
            if ([urlType isEqualToString:@"HOME"])
            {
                ABMultiValueAddValueAndLabel(multiUrl,urlAddress, kABHomeLabel, NULL);
            }
            else if([urlType isEqualToString:@"WORK"])
            {
                ABMultiValueAddValueAndLabel(multiUrl,urlAddress, kABWorkLabel, NULL);
            }
            else if([urlType isEqualToString:@"OTHER"])
            {
                ABMultiValueAddValueAndLabel(multiUrl,urlAddress, kABOtherLabel, NULL);
            }
            else if([urlType isEqualToString:@"HOME PAGE"])
            {
                ABMultiValueAddValueAndLabel(multiUrl,urlAddress, kABPersonHomePageLabel, NULL);
            }
            else
            {
                ABMultiValueAddValueAndLabel(multiUrl,urlAddress, (CFStringRef)urlType, NULL);
            }
            
        }
        else if ([line hasPrefix:@"ADR;"])
        {
            NSInteger range = [line rangeOfString:@"="].location;
            NSInteger rangeType  = [line rangeOfString:@":"].location;
            NSInteger length = [line length];
            NSString *adrType = [line substringWithRange:NSMakeRange(range+1,rangeType-range-1)];
            NSString *adr = [line substringWithRange:NSMakeRange(rangeType+1,length-rangeType-1)];
            
            NSArray *adrComponents = [adr componentsSeparatedByString:@";"];
            
            NSMutableDictionary *addressDictionary = [[NSMutableDictionary alloc] init];
            
            if (multiAddress == nil)
                multiAddress = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
            
            
            //save adr info
            
            NSString *streetTemp = [adrComponents objectAtIndex:0];
            NSString * AddressStreet = [streetTemp stringByReplacingOccurrencesOfString: @" " withString:@"\n"];
            
            [addressDictionary setObject: AddressStreet forKey:(NSString *) kABPersonAddressStreetKey];
            [addressDictionary setObject:[adrComponents objectAtIndex:1] forKey:(NSString *) kABPersonAddressCityKey];
            [addressDictionary setObject:[adrComponents objectAtIndex:2] forKey:(NSString *) kABPersonAddressStateKey];
            [addressDictionary setObject:[adrComponents objectAtIndex:3] forKey:(NSString *) kABPersonAddressZIPKey];
            [addressDictionary setObject:[adrComponents objectAtIndex:4] forKey:(NSString *) kABPersonAddressCountryKey];
            
            if ([adrType isEqualToString:@"HOME"])
            {
                ABMultiValueAddValueAndLabel(multiAddress, addressDictionary, kABHomeLabel, NULL);
            }
            else if([adrType isEqualToString:@"WORK"])
            {
                ABMultiValueAddValueAndLabel(multiAddress, addressDictionary, kABWorkLabel, NULL);
            }
            else if([adrType isEqualToString:@"OTHER"])
            {
                ABMultiValueAddValueAndLabel(multiAddress, addressDictionary, kABOtherLabel, NULL);
            }
            else
            {
                ABMultiValueAddValueAndLabel(multiAddress, addressDictionary, (CFStringRef)adrType, NULL);
            }
            
            ABRecordSetValue(newPerson, kABPersonAddressProperty, multiAddress, &error);
            [addressDictionary release];
            
        }
        else if([line hasPrefix:@"BDAY:"])
        {
            //NSArray *upperComponents = [line componentsSeparatedByString:@":"];
            //CFDataRef * bady = (CFDataRef *)[upperComponents objectAtIndex:1];
            NSString * bady = [line substringWithRange:NSMakeRange(5,10)];
            //    NSDate *birthday =
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
            [formatter setDateFormat:@"yyyy-MM-dd"];
            NSDate *dateComponent=[formatter dateFromString:bady];
            [formatter release];
            ABRecordSetValue(newPerson, kABPersonBirthdayProperty,(CFDataRef)dateComponent, &error);
        }
        else if([line hasPrefix:@"DATE;"])
        {
            if (multiDate == nil)
                multiDate = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            
            NSInteger typeStart = [line rangeOfString:@"DATE;TYPE="].length;
            NSInteger typeEnd  = [line rangeOfString:@":"].location;
            // NSInteger componentEnd  = [line rangeOfString:@" "].location;
            
            NSString *dateType = [line substringWithRange:NSMakeRange(typeStart,typeEnd-typeStart)];
            NSString *date = [line substringWithRange:NSMakeRange(typeEnd+1,10)];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
            [formatter setDateFormat:@"yyyy-MM-dd"];
            NSDate *dateComponent=[formatter dateFromString:date];
            [formatter release];
            
            
            if ([dateType isEqualToString:@"ANNIVERSARY"])
            {
                ABMultiValueAddValueAndLabel(multiDate,(CFDataRef)dateComponent, kABPersonAnniversaryLabel, NULL);
            }
            else if([dateType isEqualToString:@"OTHER"])
            {
                ABMultiValueAddValueAndLabel(multiDate,(CFDataRef)dateComponent, kABOtherLabel, NULL);
            }
            else
            {
                ABMultiValueAddValueAndLabel(multiDate,(CFDataRef)dateComponent, (CFStringRef)dateType, NULL);
            }
        }
        else if([line hasPrefix:@"X-IM;"])
        {
            if (multiSocials == nil)
            {
                multiSocials = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
            }
            if (multiMessageService == nil)
            {
                multiMessageService = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
            }
            
            NSInteger range = [line rangeOfString:@"="].location;
            NSInteger rangeType  = [line rangeOfString:@":"].location;
            NSInteger length = [line length];
            NSString * type = [line substringWithRange:NSMakeRange(range+1,rangeType-range)];
            NSString * imUserName = [line substringWithRange:NSMakeRange(rangeType+1,length-rangeType-1)];
            NSMutableDictionary *imDict = [[NSMutableDictionary alloc] init];
            NSInteger dictionaryIMs = [[imType objectForKey:type] intValue];
            switch (dictionaryIMs)
            {
                    
                case 1:
                    [imDict setObject:(NSString*)kABPersonInstantMessageServiceFacebook forKey:(NSString*)kABPersonInstantMessageServiceKey];
                    [imDict setObject:imUserName forKey:(NSString*)kABPersonInstantMessageUsernameKey];
                    ABMultiValueAddValueAndLabel(multiMessageService, imDict, kABWorkLabel, NULL);
                    ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiMessageService, &error);
                    break;
                case 2:
                    [imDict setObject:(NSString*)kABPersonInstantMessageServiceSkype forKey:(NSString*)kABPersonInstantMessageServiceKey];
                    [imDict setObject:imUserName forKey:(NSString*)kABPersonInstantMessageUsernameKey];
                    ABMultiValueAddValueAndLabel(multiMessageService, imDict, kABWorkLabel, NULL);
                    ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiMessageService, &error);
                    break;
                case 3:
                    [imDict setObject:(NSString*)kABPersonInstantMessageServiceYahoo forKey:(NSString*)kABPersonInstantMessageServiceKey];
                    [imDict setObject:imUserName forKey:(NSString*)kABPersonInstantMessageUsernameKey];
                    ABMultiValueAddValueAndLabel(multiMessageService, imDict, kABWorkLabel, NULL);
                    ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiMessageService, &error);
                    break;
                case 4:
                    [imDict setObject:(NSString*)kABPersonInstantMessageServiceICQ forKey:(NSString*)kABPersonInstantMessageServiceKey];
                    [imDict setObject:imUserName forKey:(NSString*)kABPersonInstantMessageUsernameKey];
                    ABMultiValueAddValueAndLabel(multiMessageService, imDict, kABWorkLabel, NULL);
                    ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiMessageService, &error);
                    break;
                case 5:
                    [imDict setObject:(NSString*)kABPersonInstantMessageServiceGoogleTalk forKey:(NSString*)kABPersonInstantMessageServiceKey];
                    [imDict setObject:imUserName forKey:(NSString*)kABPersonInstantMessageUsernameKey];
                    ABMultiValueAddValueAndLabel(multiMessageService, imDict, kABWorkLabel, NULL);
                    ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiMessageService, &error);
                    break;
                case 6:
                    [imDict setObject:(NSString*)kABPersonInstantMessageServiceGaduGadu forKey:(NSString*)kABPersonInstantMessageServiceKey];
                    [imDict setObject:imUserName forKey:(NSString*)kABPersonInstantMessageUsernameKey];
                    ABMultiValueAddValueAndLabel(multiMessageService, imDict, kABWorkLabel, NULL);
                    ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiMessageService, &error);
                    break;
                case 7:
                    [imDict setObject:(NSString*)kABPersonInstantMessageServiceQQ forKey:(NSString*)kABPersonInstantMessageServiceKey];
                    [imDict setObject:imUserName forKey:(NSString*)kABPersonInstantMessageUsernameKey];
                    ABMultiValueAddValueAndLabel(multiMessageService, imDict, kABWorkLabel, NULL);
                    ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiMessageService, &error);
                    break;
                case 8:
                    [imDict setObject:(NSString*)kABPersonInstantMessageServiceAIM forKey:(NSString*)kABPersonInstantMessageServiceKey];
                    [imDict setObject:imUserName forKey:(NSString*)kABPersonInstantMessageUsernameKey];
                    ABMultiValueAddValueAndLabel(multiMessageService, imDict, kABWorkLabel, NULL);
                    ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiMessageService, &error);
                    break;
                case 9:
                    [imDict setObject:(NSString*)kABPersonInstantMessageServiceJabber forKey:(NSString*)kABPersonInstantMessageServiceKey];
                    [imDict setObject:imUserName forKey:(NSString*)kABPersonInstantMessageUsernameKey];
                    ABMultiValueAddValueAndLabel(multiMessageService, imDict, kABWorkLabel, NULL);
                    ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiMessageService, &error);
                    break;
                case 10:
                {
                    CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
                        kABPersonSocialProfileURLKey }, valuestw[] = { kABPersonSocialProfileServiceTwitter,
                            (CFStringRef)imUserName, CFSTR("http://www.twitter.com/") }, valuesfb[] = {
                                kABPersonSocialProfileServiceTwitter,  (CFStringRef)imUserName,
                                CFSTR("http://www.twitter.com/") };
                    ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
                                                                                  (void*)valuestw, 3, NULL, NULL), NULL, NULL);
                    CFRelease(keys);
                    break;
                }
                    
                case 11:
                {
                    CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
                        kABPersonSocialProfileURLKey }, valuestw[] = { kABPersonSocialProfileServiceFlickr,
                            (CFStringRef)imUserName, CFSTR("http://www.flickr.com/") }, valuesfb[] = {
                                kABPersonSocialProfileServiceFlickr,  (CFStringRef)imUserName,
                                CFSTR("http://www.flickr.com/") };
                    ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
                                                                                  (void*)valuestw, 3, NULL, NULL), NULL, NULL);
                    CFRelease(keys);
                    break;
                }
                case 12:
                {
                    CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
                        kABPersonSocialProfileURLKey }, valuestw[] = { kABPersonSocialProfileServiceMyspace,
                            (CFStringRef)imUserName, CFSTR("http://www.myspace.com/") }, valuesfb[] = {
                                kABPersonSocialProfileServiceMyspace,  (CFStringRef)imUserName,
                                CFSTR("http://www.myspace.com/") };
                    ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
                                                                                  (void*)valuestw, 3, NULL, NULL), NULL, NULL);
                    CFRelease(keys);
                    break;
                }
                case 13:
                {
                    CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
                        kABPersonSocialProfileURLKey }, valuestw[] = { kABPersonSocialProfileServiceSinaWeibo,
                            (CFStringRef)imUserName, CFSTR("http://www.weibo.com/") }, valuesfb[] = {
                                kABPersonSocialProfileServiceSinaWeibo,  (CFStringRef)imUserName,
                                CFSTR("http://www.weibo.com/") };
                    ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
                                                                                  (void*)valuestw, 3, NULL, NULL), NULL, NULL);
                    
                    break;
                }
                case 14:
                {
                    CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
                        kABPersonSocialProfileURLKey }, valuestw[] = { kABPersonSocialProfileServiceLinkedIn,
                            (CFStringRef)imUserName, CFSTR("http://www.linkedin.com/") }, valuesfb[] = {
                                kABPersonSocialProfileServiceLinkedIn,  (CFStringRef)imUserName,
                                CFSTR("http://www.linkedin.com/") };
                    ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
                                                                                  (void*)valuestw, 3, NULL, NULL), NULL, NULL);
                    break;
                }
                default:
                    [imDict setObject:type forKey:(NSString*)kABPersonInstantMessageServiceKey];
                    [imDict setObject:imUserName forKey:(NSString*)kABPersonInstantMessageUsernameKey];
                    ABMultiValueAddValueAndLabel(multiMessageService, imDict, kABWorkLabel, NULL);
                    ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiMessageService, &error);
                    break;
            }
            [imDict release];
            // CFRelease(multiSocials);
        }
        else if ([line hasPrefix:@"X-RELATED;"])
        {
            if (multiRelated == nil)
            {
                multiRelated = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
            }
            
            
            
            NSArray *components = [line componentsSeparatedByString:@":"];
            NSString *relatedName = [components objectAtIndex:1];
            NSString *urlTemp = [components objectAtIndex:0];
            NSInteger rangeType  = [line rangeOfString:@"="].location;
            NSString *relatedType = [urlTemp substringWithRange:NSMakeRange(rangeType+1,[urlTemp length]-rangeType-1)];
            
            if ([relatedType isEqualToString:@"mother:"])
            {
                ABMultiValueAddValueAndLabel(multiRelated,relatedName, kABPersonMotherLabel, NULL);
            }
            else if([relatedType isEqualToString:@"father:"])
            {
                ABMultiValueAddValueAndLabel(multiRelated,relatedName, kABPersonFatherLabel, NULL);
            }
            else if([relatedType isEqualToString:@"parent:"])
            {
                ABMultiValueAddValueAndLabel(multiRelated,relatedName, kABPersonParentLabel, NULL);
            }
            else if([relatedType isEqualToString:@"brother:"])
            {
                ABMultiValueAddValueAndLabel(multiRelated,relatedName, kABPersonBrotherLabel, NULL);
            }
            else if([relatedType isEqualToString:@"sister:"])
            {
                ABMultiValueAddValueAndLabel(multiRelated,relatedName, kABPersonSisterLabel, NULL);
            }
            else if([relatedType isEqualToString:@"child:"])
            {
                ABMultiValueAddValueAndLabel(multiRelated,relatedName, kABPersonChildLabel, NULL);
            }
            else if([relatedType isEqualToString:@"friend:"])
            {
                ABMultiValueAddValueAndLabel(multiRelated,relatedName, kABPersonFriendLabel, NULL);
            }
            else if([relatedType isEqualToString:@"spouse:"])
            {
                ABMultiValueAddValueAndLabel(multiRelated,relatedName, kABPersonSpouseLabel, NULL);
            }
            else if([relatedType isEqualToString:@"partner:"])
            {
                ABMultiValueAddValueAndLabel(multiRelated,relatedName, kABPersonPartnerLabel, NULL);
            }
            else if([relatedType isEqualToString:@"assistant:"])
            {
                ABMultiValueAddValueAndLabel(multiRelated,relatedName, kABPersonAssistantLabel, NULL);
            }
            else if([relatedType isEqualToString:@"manager:"])
            {
                ABMultiValueAddValueAndLabel(multiRelated,relatedName, kABPersonManagerLabel, NULL);
            }
            else if([relatedType isEqualToString:@"other:"])
            {
                ABMultiValueAddValueAndLabel(multiRelated,relatedName, kABOtherLabel, NULL);
            }
            
        }
        
    }
    if(addressBook)
        CFRelease(addressBook);
    if (multiPhone)
        CFRelease(multiPhone);
    if (multiEmail)
        CFRelease(multiEmail);
    if (multiUrl)
        CFRelease(multiUrl);
    if(multiAddress)
        CFRelease(multiAddress);
    if(multiDate)
        CFRelease(multiDate);
    if (multiSocials)
        CFRelease(multiSocials);
    if (multiMessageService)
        CFRelease(multiMessageService);
    if (multiRelated)
        CFRelease(multiRelated);
    [groupArray release];
    [groupName release];
    [telType release];
    [imType release];
}

-(NSString*)saveVCF:(CFArrayRef)contacts {
    
    NSString *str = @"";
    
    str = [self generateVCardStringWithContacts:contacts];
    NSString *folderPath = NSTemporaryDirectory();
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy年MM月dd日 HH时mm分ss秒"];
    NSString *locationTime=[formatter stringFromDate: [NSDate date]];
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *name = [currentDevice name];
    NSString *filePath = [folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"[%@]%@.vcf",name,locationTime]];
    [str writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [formatter release];
    [_delegate updateProgress:0 title:@"开始备份数据文件到服务器" mode:MBProgressHUDModeIndeterminate];
    return filePath;
}

-(void)loadVCF:(NSString*)filePath {
    
    NSString* str = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    [self parseVCardString:str];
}

-(void)paintInfo:(CFArrayRef)contacts
{
    
    for(CFIndex i = 0; i < CFArrayGetCount(contacts); i++)
    {
        ABRecordRef person = CFArrayGetValueAtIndex(contacts, i);
        
        ABRecordCopyValue(person, kABPersonPhoneProperty);
        ABRecordCopyValue(person, kABPersonEmailProperty);
        ABRecordCopyValue(person, kABPersonURLProperty);
        ABRecordCopyValue(person, kABPersonAddressProperty);
        
        ABRecordCopyValue(person, kABPersonNoteProperty);
        ABRecordCopyValue(person, kABPersonFirstNamePhoneticProperty);
        ABRecordCopyValue(person, kABPersonLastNamePhoneticProperty);
        ABRecordCopyValue(person, kABPersonJobTitleProperty);
        ABRecordCopyValue(person, kABPersonDepartmentProperty);
        ABRecordCopyValue(person, kABPersonBirthdayProperty);
        ABRecordCopyValue(person, kABPersonDateProperty);
        ABRecordCopyValue(person, kABPersonInstantMessageProperty);
        ABRecordCopyValue(person, kABPersonRelatedNamesProperty);
        ABRecordCopyValue(person, kABPersonSocialProfileProperty);
        ABRecordCopyValue(person, kABPersonNoteProperty);
    }
}


-(void)getAllContactGroupInfo:(ABAddressBookRef) addressBook
{
    CFArrayRef groups = ABAddressBookCopyArrayOfAllGroups(addressBook);
    
    CFIndex numGroups = CFArrayGetCount(groups);
    
    for(CFIndex idx=0; idx<numGroups;++idx) {
        ABRecordRef groupItem = CFArrayGetValueAtIndex(groups, idx);
        
        //NSLog(@"gourpname = %@", ABRecordCopyValue(groupItem, kABGroupNameProperty));
        NSString *groupName =  ABRecordCopyValue(groupItem, kABGroupNameProperty);
        NSMutableArray *groupMembersID = [[NSMutableArray alloc] init];
        CFArrayRef members = ABGroupCopyArrayOfAllMembers(groupItem);
        
        if(members) {
            NSUInteger count = CFArrayGetCount(members);
            
            for(NSUInteger idx=0;idx<count;++idx) {
                ABRecordRef person = CFArrayGetValueAtIndex(members, idx);
                NSInteger recId = (NSInteger)ABRecordGetRecordID(person);
                NSString *stringId = [NSString stringWithFormat:@"%d",recId];
                [groupInfo setMultiValue:stringId forKey:groupName];
            }
            CFRelease(members);
            
        }
        // [groupInfo setMultiValue:groupMembersID forKey:groupName];
        [groupMembersID release];
        [groupName release];
    }
    
    CFRelease(groups);
    
}

-(NSInteger)addContactsToSystem:(NSString *)serverContactStr
{
    ABAddressBookRef addressBook = nil;
    NSMutableArray *systemContactArray = [[NSMutableArray alloc]init];
    NSMutableArray *serverContactArray = [[NSMutableArray alloc]init];
    
    NSString* serverStr = [NSString stringWithContentsOfFile:serverContactStr encoding:NSUTF8StringEncoding error:nil];
    
    [self getSystemContactToClass:systemContactArray];
    [self parseVCardStrToArray:serverStr array:serverContactArray];
    float j = 0;
    for (CustomContactData *systemVcard in systemContactArray)
    {
        j++;
        [_delegate updateProgress:j/(float)systemContactArray.count title:@"数据分析" mode:MBProgressHUDModeDeterminate];
        for (int i = 0 ; i < [serverContactArray count]; i++)
        {
            CustomContactData *serverVcard = [serverContactArray objectAtIndex:i];
            if (YES == [systemVcard compareSameContact:serverVcard])
            {
                [serverContactArray removeObjectAtIndex:i];
            }
        }
        
    }
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
    {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     dispatch_semaphore_signal(sema);
                                                 });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
        
        
    }
    else
    {
        addressBook = ABAddressBookCreate();
    }
    NSInteger count = 0;
    NSInteger progressGraininess  = 1;
    if (serverContactArray.count > SHOW_SAVE_CONTACT_PROGRESS) {
        progressGraininess  = serverContactArray.count/SHOW_SAVE_CONTACT_PROGRESS;
    }
    __block NSInteger tempNum = 0;
    __block float progressFloat = 0;
    for (CustomContactData *addContact in serverContactArray)
    {
        NSArray *groupArray = (NSArray *)ABAddressBookCopyArrayOfAllGroups(addressBook);
        //[self addContact: addContact ABAddBookRef:addressBook groupNameArray:groupArray];
        {
            
            ABRecordRef newPerson = ABPersonCreate();
            CFErrorRef error;
            
            ABMutableMultiValueRef multiPhone = nil;
            ABMutableMultiValueRef multiEmail = nil;
            ABMutableMultiValueRef multiUrl = nil;
            ABMutableMultiValueRef multiAddress = nil;
            ABMutableMultiValueRef multiDate = nil;
            ABMutableMultiValueRef multiSocials = nil;
            ABMutableMultiValueRef multiMessageService = nil;
            ABMutableMultiValueRef multiRelated = nil;
            
            
            
            NSDictionary *telType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"MOBIlE",@"2",@"iPhone",@"3",@"HOME",@"4",@"WORK",@"5",@"MAIN",@"6",@"HOME FAX",@"7",@"WORK FAX",@"8",@"OTHER FAX",@"9",@"PAGER",@"10",@"OTHER",nil];
            NSDictionary *emailType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"HOME",@"2",@"WORK",@"3",@"OTHER",nil];
            NSDictionary *dateType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"ANNIVERSARY",@"2",@"OTHER",nil];
            NSDictionary *urlType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"HOME",@"2",@"WORK",@"3",@"OTHER",@"4",@"HOME PAGE",nil];
            NSDictionary *adrType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"HOME",@"2",@"WORK",@"3",@"OTHER",nil];
            
            NSDictionary *imNameType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"QQ",@"2",@"Skype",@"3",@"MSN",@"4",@"GoogleTalk",@"5",@"Facebook",@"6",@"AIM",@"7",@"Yahoo",@"9",@"ICQ",@"10",@"Jabber",@"11",@"Gadu-Gadu",nil];
            NSDictionary *imType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"HOME",@"2",@"WORK",@"3",@"OTHER",nil];
            NSDictionary *serverType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"SinaWeibo",@"2",@"twitter",@"3",@"Facebook",@"4",@"Flickr",@"5",@"LinkedIn",@"6",@"Myspace",nil];
            NSDictionary *relateType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"mother",@"2",@"father",@"3",@"parent",@"4",@"brother",@"5",@"sister",@"6",@"child",@"7",@"friend",@"8",@"spouse",@"9",@"partner",@"10",@"assistant",@"11",@"manager",@"12",@"other",nil];
            
            NSString * lastName = [addContact.name objectAtIndex:0];
            NSString * firstName = [addContact.name objectAtIndex:1];
            NSString * middleName = [addContact.name objectAtIndex:2];
            NSString * prefix = [addContact.name objectAtIndex:3];
            NSString * suffix = [addContact.name objectAtIndex:4];
            
            if (0 != [lastName length])
            {
                ABRecordSetValue(newPerson, kABPersonLastNameProperty, lastName, &error);
            }
            
            if (0 != [firstName length])
            {
                ABRecordSetValue(newPerson, kABPersonFirstNameProperty, firstName, &error);
            }
            
            if (0 != [middleName length])
            {
                ABRecordSetValue(newPerson, kABPersonMiddleNameProperty, middleName, &error);
            }
            
            if (0 != [prefix length])
            {
                ABRecordSetValue(newPerson, kABPersonPrefixProperty, prefix, &error);
            }
            
            if (0 != [suffix length])
            {
                ABRecordSetValue(newPerson, kABPersonSuffixProperty, suffix, &error);
            }
            
            if (0 !=[addContact.nickname length])
            {
                ABRecordSetValue(newPerson, kABPersonNicknameProperty, addContact.nickname, &error);
            }
            
            if (0 !=[addContact.org length])
            {
                ABRecordSetValue(newPerson, kABPersonOrganizationProperty, addContact.org, &error);
            }
            if (0 !=[addContact.department length])
            {
                ABRecordSetValue(newPerson, kABPersonDepartmentProperty, addContact.department, &error);
            }
            
            if(0 !=[addContact.title length])
            {
                ABRecordSetValue(newPerson, kABPersonJobTitleProperty, addContact.title, &error);
            }
            if(0 !=[addContact.firstNamePhonetic length])
            {
                ABRecordSetValue(newPerson, kABPersonFirstNamePhoneticProperty, addContact.firstNamePhonetic, &error);
            }
            if(0 !=[addContact.lastNamePhonetic length])
            {
                ABRecordSetValue(newPerson, kABPersonLastNamePhoneticProperty, addContact.lastNamePhonetic, &error);
            }
            if (0 != [addContact.note length])
            {
                ABRecordSetValue(newPerson, kABPersonNoteProperty, addContact.note, &error);
            }
            NSArray *telTypeKey = [addContact.tel allKeys];
            if ([telTypeKey count] > 0)
            {
                multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                for (NSString* typeStr in telTypeKey)
                {
                    NSArray *telValue = [addContact.tel allValuesForKey:typeStr];
                    for (NSString* valueStr in telValue)
                    {
                        NSInteger dictionaryNum = [[telType objectForKey:typeStr] intValue];
                        
                        switch (dictionaryNum)
                        {
                            case 1:
                                ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABPersonPhoneMobileLabel, NULL);
                                break;
                            case 2:
                                ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABPersonPhoneIPhoneLabel, NULL);
                                break;
                            case 3:
                                ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABHomeLabel, NULL);
                                break;
                            case 4:
                                ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABWorkLabel, NULL);
                                break;
                            case 5:
                                ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABPersonPhoneMainLabel, NULL);
                                break;
                            case 6:
                                ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABPersonPhoneHomeFAXLabel, NULL);
                                break;
                            case 7:
                                ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABPersonPhoneWorkFAXLabel, NULL);
                                break;
                            case 8:
                                ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABPersonPhoneOtherFAXLabel, NULL);
                                break;
                            case 9:
                                ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABPersonPhonePagerLabel, NULL);
                                break;
                            case 10:
                                ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABOtherLabel, NULL);
                                break;
                                
                            default:
                                ABMultiValueAddValueAndLabel(multiPhone,valueStr, (CFStringRef)typeStr, NULL);
                                break;
                        }
                    }
                }
            }
            
            NSArray *emailTypeKey = [addContact.email allKeys];
            if ([emailTypeKey count] > 0) {
                multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                for (NSString* typeStr in emailTypeKey)
                {
                    NSArray *emailValue = [addContact.email allValuesForKey:typeStr];
                    for (NSString* valueStr in emailValue)
                    {
                        NSInteger dictionaryNum = [[emailType objectForKey:typeStr] intValue];
                        
                        switch (dictionaryNum)
                        {
                            case 1:
                                ABMultiValueAddValueAndLabel(multiEmail,valueStr, kABHomeLabel, NULL);
                                break;
                            case 2:
                                ABMultiValueAddValueAndLabel(multiEmail,valueStr, kABWorkLabel, NULL);
                                break;
                            case 3:
                                ABMultiValueAddValueAndLabel(multiEmail,valueStr, kABOtherLabel, NULL);
                                break;
                            default:
                                ABMultiValueAddValueAndLabel(multiEmail,valueStr, (CFStringRef)typeStr, NULL);
                                break;
                        }
                    }
                }
            }
            
            if( 0 != addContact.bday)
            {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
                [formatter setDateFormat:@"yyyy-MM-dd"];
                NSDate *dateComponent=[formatter dateFromString:addContact.bday];
                [formatter release];
                ABRecordSetValue(newPerson, kABPersonBirthdayProperty,(CFDataRef)dateComponent, &error);
            }
            
            NSArray *dateTypeKey = [addContact.date allKeys];
            if ( [dateTypeKey count] > 0 ) {
                multiDate = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                
                for (NSString* typeStr in dateTypeKey)
                {
                    NSArray *dateValue = [addContact.date allValuesForKey:typeStr];
                    
                    for (NSString* valueStr in dateValue)
                    {
                        NSInteger dictionaryNum = [[dateType objectForKey:typeStr] intValue];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
                        [formatter setDateFormat:@"yyyy-MM-dd"];
                        NSDate *dateComponent=[formatter dateFromString:valueStr];
                        
                        
                        switch (dictionaryNum)
                        {
                            case 1:
                                ABMultiValueAddValueAndLabel(multiDate,(CFDataRef)dateComponent, kABPersonAnniversaryLabel, NULL);
                                break;
                            case 2:
                                ABMultiValueAddValueAndLabel(multiDate,(CFDataRef)dateComponent, kABOtherLabel, NULL);
                                break;
                            default:
                                ABMultiValueAddValueAndLabel(multiDate,(CFDataRef)dateComponent, (CFStringRef)typeStr, NULL);
                                break;
                        }
                        [formatter release];
                    }
                }
            }
            
            NSArray *urlTypeKey = [addContact.url allKeys];
            if ([urlTypeKey count] > 0) {
                multiUrl = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                
                for (NSString* typeStr in urlTypeKey)
                {
                    NSArray *dateValue = [addContact.url allValuesForKey:typeStr];
                    for (NSString* valueStr in dateValue)
                    {
                        NSInteger dictionaryNum = [[urlType objectForKey:typeStr] intValue];
                        
                        switch (dictionaryNum)
                        {
                            case 1:
                                ABMultiValueAddValueAndLabel(multiUrl,valueStr, kABHomeLabel, NULL);
                                break;
                            case 2:
                                ABMultiValueAddValueAndLabel(multiUrl,valueStr, kABWorkLabel, NULL);
                                break;
                            case 3:
                                ABMultiValueAddValueAndLabel(multiUrl,valueStr, kABOtherLabel, NULL);
                                break;
                            case 4:
                                ABMultiValueAddValueAndLabel(multiUrl,valueStr, kABPersonHomePageLabel, NULL);
                                break;
                            default:
                                ABMultiValueAddValueAndLabel(multiUrl,valueStr, (CFStringRef)typeStr, NULL);
                                break;
                        }
                    }
                }
            }
            
            NSArray *adrTypeKey = [addContact.address allKeys];
            if ( [adrTypeKey count] > 0 ) {
                multiAddress = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                
                for (NSString* typeStr in adrTypeKey)
                {
                    NSArray *dateValue = [addContact.address allValuesForKey:typeStr];
                    for (NSString* valueStr in dateValue)
                    {
                        NSInteger dictionaryNum = [[adrType objectForKey:typeStr] intValue];
                        NSArray *adrComponents = [valueStr componentsSeparatedByString:@";"];
                        NSMutableDictionary *addressDictionary = [[NSMutableDictionary alloc] init];
                        NSString *streetTemp = [adrComponents objectAtIndex:0];
                        NSString * AddressStreet = [streetTemp stringByReplacingOccurrencesOfString: @" " withString:@"\n"];
                        
                        [addressDictionary setObject: AddressStreet forKey:(NSString *) kABPersonAddressStreetKey];
                        [addressDictionary setObject:[adrComponents objectAtIndex:1] forKey:(NSString *) kABPersonAddressCityKey];
                        [addressDictionary setObject:[adrComponents objectAtIndex:2] forKey:(NSString *) kABPersonAddressStateKey];
                        [addressDictionary setObject:[adrComponents objectAtIndex:3] forKey:(NSString *) kABPersonAddressZIPKey];
                        [addressDictionary setObject:[adrComponents objectAtIndex:4] forKey:(NSString *) kABPersonAddressCountryKey];
                        
                        switch (dictionaryNum)
                        {
                            case 1:
                                ABMultiValueAddValueAndLabel(multiAddress, addressDictionary, kABHomeLabel, NULL);
                                break;
                            case 2:
                                ABMultiValueAddValueAndLabel(multiAddress, addressDictionary, kABWorkLabel, NULL);
                                break;
                            case 3:
                                ABMultiValueAddValueAndLabel(multiAddress, addressDictionary, kABOtherLabel, NULL);
                                break;
                            default:
                                ABMultiValueAddValueAndLabel(multiAddress, addressDictionary, (CFStringRef)typeStr, NULL);
                                break;
                        }
                        [addressDictionary release];
                    }
                }
            }
            
            if ([addContact.im count] > 0) {
                multiMessageService = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                
                for (int i = 0 ; i < [addContact.im count]; i++)
                {
                    
                    NSMutableDictionary *imDict = [[NSMutableDictionary alloc] init];
                    NSMutableString *imNameStr =[addContact.im objectAtIndex:i];
                    i++;
                    NSMutableString *imTypeStr = [addContact.im objectAtIndex:i];
                    i++;
                    NSString *imValueStr = [addContact.im objectAtIndex:i];
                    
                    NSInteger dictionaryNum = [[imNameType objectForKey:imNameStr] intValue];
                    
                    switch (dictionaryNum)
                    {
                        case 1:
                            imNameStr = (NSString*)kABPersonInstantMessageServiceQQ;
                            break;
                        case 2:
                            imNameStr = (NSString*)kABPersonInstantMessageServiceSkype;
                            break;
                        case 3:
                            imNameStr = (NSString*)kABPersonInstantMessageServiceMSN;
                            break;
                        case 4:
                            imNameStr = (NSString*)kABPersonInstantMessageServiceGoogleTalk;
                            break;
                        case 5:
                            imNameStr = (NSString*)kABPersonInstantMessageServiceFacebook;
                            break;
                        case 6:
                            imNameStr = (NSString*)kABPersonInstantMessageServiceAIM;
                            break;
                        case 7:
                            imNameStr = (NSString*)kABPersonInstantMessageServiceYahoo;
                            break;
                        case 8:
                            imNameStr = (NSString*)kABPersonInstantMessageServiceICQ;
                            break;
                        case 9:
                            imNameStr = (NSString*)kABPersonInstantMessageServiceJabber;
                            break;
                        case 10:
                            imNameStr = (NSString*)kABPersonInstantMessageServiceGaduGadu;
                            break;
                        default:
                            break;
                    }
                    
                    dictionaryNum = [[imType objectForKey:imTypeStr] intValue];
                    
                    switch (dictionaryNum)
                    {
                        case 1:
                            // ABMultiValueAddValueAndLabel(multiUrl,valueStr, kABHomeLabel, NULL);
                            imTypeStr = (NSString*)kABHomeLabel;
                            break;
                        case 2:
                            imTypeStr = (NSString*)kABWorkLabel;
                            break;
                        case 3:
                            imTypeStr = (NSString*)kABOtherLabel;
                            break;
                        default:
                            break;
                    }
                    
                    [imDict setObject:imNameStr forKey:(NSString*)kABPersonInstantMessageServiceKey];
                    [imDict setObject:imValueStr forKey:(NSString*)kABPersonInstantMessageUsernameKey];
                    ABMultiValueAddValueAndLabel(multiMessageService, imDict, imTypeStr, NULL);
                    // ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiMessageService, &error);
                    [imDict release];
                }
            }
            
            NSArray *serverTypeKey = [addContact.server allKeys];
            if ( [serverTypeKey count] > 0 ) {
                multiSocials = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                
                for (NSString* typeStr in serverTypeKey)
                {
                    NSArray *dateValue = [addContact.server allValuesForKey:typeStr];
                    for (NSString* valueStr in dateValue)
                    {
                        NSInteger dictionaryNum = [[serverType objectForKey:typeStr] intValue];
                        //  NSMutableDictionary *imDict = [[NSMutableDictionary alloc] init];
                        switch (dictionaryNum)
                        {
                            case 1:
                            {
                                CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
                                    kABPersonSocialProfileURLKey }, valuestw[] = { kABPersonSocialProfileServiceSinaWeibo,
                                        (CFStringRef)valueStr, CFSTR("http://www.weibo.com/") }, valuesfb[] = {
                                            kABPersonSocialProfileServiceSinaWeibo,  (CFStringRef)valueStr,
                                            CFSTR("http://www.weibo.com/") };
                                ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
                                                                                              (void*)valuestw, 3, NULL, NULL), NULL, NULL);
                                break;
                            }
                            case 2:
                            {
                                CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
                                    kABPersonSocialProfileURLKey }, valuestw[] = { kABPersonSocialProfileServiceTwitter,
                                        (CFStringRef)valueStr, CFSTR("http://www.twitter.com/") }, valuesfb[] = {
                                            kABPersonSocialProfileServiceTwitter,  (CFStringRef)valueStr,
                                            CFSTR("http://www.twitter.com/") };
                                ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
                                                                                              (void*)valuestw, 3, NULL, NULL), NULL, NULL);
                                break;
                            }
                            case 3:
                            {
                                CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
                                    kABPersonSocialProfileURLKey }, valuestw[] = { kABPersonSocialProfileServiceFacebook,
                                        (CFStringRef)valueStr, CFSTR("http://www.facebook.com/") }, valuesfb[] = {
                                            kABPersonSocialProfileServiceFacebook,  (CFStringRef)valueStr,
                                            CFSTR("http://www.facebook.com/") };
                                ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
                                                                                              (void*)valuestw, 3, NULL, NULL), NULL, NULL);
                                break;
                            }
                            case 4:
                            {
                                CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
                                    kABPersonSocialProfileURLKey }, valuestw[] = { kABPersonSocialProfileServiceFlickr,
                                        (CFStringRef)valueStr, CFSTR("http://www.flickr.com/") }, valuesfb[] = {
                                            kABPersonSocialProfileServiceFlickr,  (CFStringRef)valueStr,
                                            CFSTR("http://www.flickr.com/") };
                                ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
                                                                                              (void*)valuestw, 3, NULL, NULL), NULL, NULL);
                                break;
                            }
                            case 5:
                            {
                                CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
                                    kABPersonSocialProfileURLKey }, valuestw[] = { kABPersonSocialProfileServiceLinkedIn,
                                        (CFStringRef)valueStr, CFSTR("http://www.linkedin.com/") }, valuesfb[] = {
                                            kABPersonSocialProfileServiceLinkedIn,  (CFStringRef)valueStr,
                                            CFSTR("http://www.linkedin.com/") };
                                ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
                                                                                              (void*)valuestw, 3, NULL, NULL), NULL, NULL);
                                break;
                            }
                            case 6:
                            {
                                CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
                                    kABPersonSocialProfileURLKey }, valuestw[] = { (CFStringRef)typeStr,
                                        (CFStringRef)valueStr, CFSTR("http://www.myspace.com/") }, valuesfb[] = {
                                            kABPersonSocialProfileServiceMyspace,  (CFStringRef)valueStr,
                                            CFSTR("http://www.myspace.com/") };
                                ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
                                                                                              (void*)valuestw, 3, NULL, NULL), NULL, NULL);
                                break;
                            }
                                
                            default:
                            {
                                CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
                                    kABPersonSocialProfileURLKey }, valuestw[] = { (CFStringRef)typeStr,
                                        (CFStringRef)valueStr, CFSTR("") }, valuesfb[] = {
                                            (CFStringRef)valueStr,(CFStringRef)typeStr,
                                            CFSTR("") };
                                ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
                                                                                              (void*)valuestw, 3, NULL, NULL), NULL, NULL);
                                break;
                            }
                        }
                        //[imDict release];
                    }
                }
            }
            NSArray *relatedTypeKey = [addContact.related allKeys];
            if ( [relatedTypeKey count ] > 0 ) {
                multiRelated = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                
                for (NSString* typeStr in relatedTypeKey)
                {
                    NSArray *dateValue = [addContact.related allValuesForKey:typeStr];
                    for (NSString* valueStr in dateValue)
                    {
                        NSInteger dictionaryNum = [[relateType objectForKey:typeStr] intValue];
                        
                        switch (dictionaryNum)
                        {
                            case 1:
                                ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonMotherLabel, NULL);
                                break;
                            case 2:
                                ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonFatherLabel, NULL);
                                break;
                            case 3:
                                ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonParentLabel, NULL);
                                break;
                            case 4:
                                ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonBrotherLabel, NULL);
                                break;
                            case 5:
                                ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonSisterLabel, NULL);
                                break;
                            case 6:
                                ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonChildLabel, NULL);
                                break;
                            case 7:
                                ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonFriendLabel, NULL);
                                break;
                            case 8:
                                ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonSpouseLabel, NULL);
                                break;
                            case 9:
                                ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonPartnerLabel, NULL);
                                break;
                            case 10:
                                ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonAssistantLabel, NULL);
                                break;
                            case 11:
                                ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonManagerLabel, NULL);
                                break;
                            case 12:
                                ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABOtherLabel, NULL);
                                break;
                            default:
                                ABMultiValueAddValueAndLabel(multiRelated,valueStr, (CFStringRef)typeStr, NULL);
                                break;
                        }
                    }
                }
            }
            if(multiPhone)
            {
                ABRecordSetValue(newPerson, kABPersonPhoneProperty, multiPhone, &error );
            }
            if(multiEmail)
            {
                ABRecordSetValue(newPerson, kABPersonEmailProperty, multiEmail, &error );
            }
            if (multiUrl)
            {
                ABRecordSetValue(newPerson, kABPersonURLProperty, multiUrl, &error );
            }
            if (multiDate)
            {
                ABRecordSetValue(newPerson, kABPersonDateProperty, multiDate, &error );
            }
            if (multiSocials)
            {
                ABRecordSetValue(newPerson, kABPersonSocialProfileProperty, multiSocials, &error);
            }
            if (multiMessageService)
            {
                ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiMessageService, &error);
            }
            if (multiRelated)
            {
                ABRecordSetValue(newPerson, kABPersonRelatedNamesProperty, multiRelated, &error);
            }
            if (multiAddress)
            {
                ABRecordSetValue(newPerson, kABPersonAddressProperty, multiAddress, &error);
            }
            //将新的记录，添加到通讯录中
            ABAddressBookAddRecord(addressBook, newPerson, NULL);
            //NSArray *groupArray = (NSArray *)ABAddressBookCopyArrayOfAllGroups(addressBook);
            if([addContact.group length] >0)
            {
                if (0 == [groupArray  count])
                {
                    CFErrorRef error;
                    ABRecordRef group = ABGroupCreate();
                    ABRecordSetValue(group, kABGroupNameProperty,addContact.group , &error);
                    ABAddressBookAddRecord(addressBook, group, &error);
                    ABAddressBookSave(addressBook, &error);
                    
                    ABGroupAddMember(group, newPerson, &error);
                }
                else
                {
                    
                    for ( int i = 0 ; i < [groupArray count]; i++ )
                    {
                        ABRecordRef group = [groupArray objectAtIndex:i];
                        CFTypeRef groupNameRef = ABRecordCopyValue(group, kABGroupNameProperty);
                        NSString *groupNameStr = [[NSString alloc] initWithFormat:@"%@" ,(NSString *)groupNameRef];
                        
                        if ( NSOrderedSame == [groupNameStr compare:addContact.group])
                        {
                            ABGroupAddMember(group, newPerson, &error);
                            CFRelease(groupNameRef);
                            [groupNameStr release];
                            break;
                        }
                        else if ( NSOrderedSame != [groupNameStr compare:addContact.group] && i == [groupArray count]-1 )
                        {
                            CFErrorRef error;
                            ABRecordRef newGroup = ABGroupCreate();
                            ABRecordSetValue(newGroup, kABGroupNameProperty,addContact.group, &error);
                            ABAddressBookAddRecord(addressBook, newGroup, &error);
                            ABAddressBookSave(addressBook, &error);
                            
                            ABGroupAddMember(newGroup, newPerson, &error);
                            
                            CFRelease(groupNameRef);
                            CFRelease(newGroup);
                            
                            break;
                            
                        }
                        else
                        {
                            [groupNameStr release];
                            CFRelease(groupNameRef);
                        }
                        //  [groupNames addObject:groupNameStr];
                        
                    }
                    
                }
                
            }
            
            if (multiPhone)
                CFRelease(multiPhone);
            if (multiEmail)
                CFRelease(multiEmail);
            if (multiDate)
                CFRelease(multiDate);
            if (multiUrl)
                CFRelease(multiUrl);
            if(multiAddress)
                CFRelease(multiAddress);
            if (multiSocials)
                CFRelease(multiSocials);
            if (multiMessageService)
                CFRelease(multiMessageService);
            if (multiRelated)
                CFRelease(multiRelated);
            CFRelease(newPerson);
            
            [telType release];
            [emailType release];
            [dateType release];
            [urlType release];
            [adrType release];
            [serverType release];
            [relateType release];
            [imType release];
            [imNameType release];
        }
        
        [groupArray release];
        count++;
        tempNum++;
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( tempNum >= progressGraininess )
            {
                progressFloat += 0.01;
                [_delegate updateProgress:progressFloat title:[NSString stringWithFormat:@"正在导入联系人数据 %d/%d",count,serverContactArray.count] mode:MBProgressHUDModeDeterminate];
                tempNum = 0;
            }
        });
        
        if( 0 == (count % SAVE_CONTACT_INTERVAl) )
        {
            BOOL isSuccess;
            isSuccess = ABAddressBookSave(addressBook, nil);
            if (NO == isSuccess)
            {
                NSLog(@"address book save fail");
            }
        }
        
    }
    if ( 0 != ( count % SAVE_CONTACT_INTERVAl ) ) {
        BOOL isSuccess;
        //通讯录执行保存
        isSuccess = ABAddressBookSave(addressBook, nil);
        if (NO == isSuccess)
        {
            NSLog(@"address book save fail");
        }
    }
    
    
    CFRelease(addressBook);
    
    for (int j=0; j<[systemContactArray count]; j++)
    {
        [[systemContactArray objectAtIndex:j] release];
    }
    for (int j=0; j<[serverContactArray count]; j++)
    {
        [[serverContactArray objectAtIndex:j] release];
    }
    [systemContactArray removeAllObjects];
    [serverContactArray removeAllObjects];
    [systemContactArray release];
    [serverContactArray release];
    return count;
}
//-(void) addContact:(CustomContactData *) addContact ABAddBookRef:(ABAddressBookRef)addressBook groupNameArray:(NSArray *) groupArray
//{
//
//    ABRecordRef newPerson = ABPersonCreate();
//    CFErrorRef error;
//
//    ABMutableMultiValueRef multiPhone = nil;
//    ABMutableMultiValueRef multiEmail = nil;
//    ABMutableMultiValueRef multiUrl = nil;
//    ABMutableMultiValueRef multiAddress = nil;
//    ABMutableMultiValueRef multiDate = nil;
//    ABMutableMultiValueRef multiSocials = nil;
//    ABMutableMultiValueRef multiMessageService = nil;
//    ABMutableMultiValueRef multiRelated = nil;
//
//
//
//    NSDictionary *telType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"MOBIlE",@"2",@"iPhone",@"3",@"HOME",@"4",@"WORK",@"5",@"MAIN",@"6",@"HOME FAX",@"7",@"WORK FAX",@"8",@"OTHER FAX",@"9",@"PAGER",@"10",@"OTHER",nil];
//    NSDictionary *emailType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"HOME",@"2",@"WORK",@"3",@"OTHER",nil];
//    NSDictionary *dateType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"ANNIVERSARY",@"2",@"OTHER",nil];
//    NSDictionary *urlType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"HOME",@"2",@"WORK",@"3",@"OTHER",@"4",@"HOME PAGE",nil];
//    NSDictionary *adrType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"HOME",@"2",@"WORK",@"3",@"OTHER",nil];
//
//    NSDictionary *imNameType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"QQ",@"2",@"Skype",@"3",@"MSN",@"4",@"GoogleTalk",@"5",@"Facebook",@"6",@"AIM",@"7",@"Yahoo",@"9",@"ICQ",@"10",@"Jabber",@"11",@"Gadu-Gadu",nil];
//    NSDictionary *imType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"HOME",@"2",@"WORK",@"3",@"OTHER",nil];
//     NSDictionary *serverType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"SinaWeibo",@"2",@"twitter",@"3",@"Facebook",@"4",@"Flickr",@"5",@"LinkedIn",@"6",@"Myspace",nil];
//     NSDictionary *relateType = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"mother",@"2",@"father",@"3",@"parent",@"4",@"brother",@"5",@"sister",@"6",@"child",@"7",@"friend",@"8",@"spouse",@"9",@"partner",@"10",@"assistant",@"11",@"manager",@"12",@"other",nil];
//
//    NSString * lastName = [addContact.name objectAtIndex:0];
//    NSString * firstName = [addContact.name objectAtIndex:1];
//    NSString * middleName = [addContact.name objectAtIndex:2];
//    NSString * prefix = [addContact.name objectAtIndex:3];
//    NSString * suffix = [addContact.name objectAtIndex:4];
//
//    if (0 != [lastName length])
//    {
//        ABRecordSetValue(newPerson, kABPersonLastNameProperty, lastName, &error);
//    }
//
//    if (0 != [firstName length])
//    {
//        ABRecordSetValue(newPerson, kABPersonFirstNameProperty, firstName, &error);
//    }
//
//    if (0 != [middleName length])
//    {
//        ABRecordSetValue(newPerson, kABPersonMiddleNameProperty, middleName, &error);
//    }
//
//    if (0 != [prefix length])
//    {
//        ABRecordSetValue(newPerson, kABPersonPrefixProperty, prefix, &error);
//    }
//
//    if (0 != [suffix length])
//    {
//        ABRecordSetValue(newPerson, kABPersonSuffixProperty, suffix, &error);
//    }
//
//   if (0 !=[addContact.nickname length])
//   {
//       ABRecordSetValue(newPerson, kABPersonNicknameProperty, addContact.nickname, &error);
//   }
//
//    if (0 !=[addContact.org length])
//    {
//        ABRecordSetValue(newPerson, kABPersonOrganizationProperty, addContact.org, &error);
//    }
//    if (0 !=[addContact.department length])
//    {
//        ABRecordSetValue(newPerson, kABPersonDepartmentProperty, addContact.department, &error);
//    }
//
//    if(0 !=[addContact.title length])
//    {
//        ABRecordSetValue(newPerson, kABPersonJobTitleProperty, addContact.title, &error);
//    }
//    if(0 !=[addContact.firstNamePhonetic length])
//    {
//        ABRecordSetValue(newPerson, kABPersonFirstNamePhoneticProperty, addContact.firstNamePhonetic, &error);
//    }
//    if(0 !=[addContact.lastNamePhonetic length])
//    {
//        ABRecordSetValue(newPerson, kABPersonLastNamePhoneticProperty, addContact.lastNamePhonetic, &error);
//    }
//    if (0 != [addContact.note length])
//    {
//        ABRecordSetValue(newPerson, kABPersonNoteProperty, addContact.note, &error);
//    }
//    NSArray *telTypeKey = [addContact.tel allKeys];
//    if ([telTypeKey count] > 0)
//    {
//        multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//        for (NSString* typeStr in telTypeKey)
//        {
//            NSArray *telValue = [addContact.tel allValuesForKey:typeStr];
//            for (NSString* valueStr in telValue)
//            {
//                NSInteger dictionaryNum = [[telType objectForKey:typeStr] intValue];
//
//                switch (dictionaryNum)
//                {
//                    case 1:
//                        ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABPersonPhoneMobileLabel, NULL);
//                        break;
//                    case 2:
//                        ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABPersonPhoneIPhoneLabel, NULL);
//                        break;
//                    case 3:
//                        ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABHomeLabel, NULL);
//                        break;
//                    case 4:
//                        ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABWorkLabel, NULL);
//                        break;
//                    case 5:
//                        ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABPersonPhoneMainLabel, NULL);
//                        break;
//                    case 6:
//                        ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABPersonPhoneHomeFAXLabel, NULL);
//                        break;
//                    case 7:
//                        ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABPersonPhoneWorkFAXLabel, NULL);
//                        break;
//                    case 8:
//                        ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABPersonPhoneOtherFAXLabel, NULL);
//                        break;
//                    case 9:
//                        ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABPersonPhonePagerLabel, NULL);
//                        break;
//                    case 10:
//                        ABMultiValueAddValueAndLabel(multiPhone,valueStr, kABOtherLabel, NULL);
//                        break;
//
//                    default:
//                        ABMultiValueAddValueAndLabel(multiPhone,valueStr, (CFStringRef)typeStr, NULL);
//                        break;
//                }
//            }
//        }
//    }
//
//    NSArray *emailTypeKey = [addContact.email allKeys];
//    if ([emailTypeKey count] > 0) {
//        multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//        for (NSString* typeStr in emailTypeKey)
//        {
//            NSArray *emailValue = [addContact.email allValuesForKey:typeStr];
//            for (NSString* valueStr in emailValue)
//            {
//                NSInteger dictionaryNum = [[emailType objectForKey:typeStr] intValue];
//
//                switch (dictionaryNum)
//                {
//                    case 1:
//                        ABMultiValueAddValueAndLabel(multiEmail,valueStr, kABHomeLabel, NULL);
//                        break;
//                    case 2:
//                         ABMultiValueAddValueAndLabel(multiEmail,valueStr, kABWorkLabel, NULL);
//                        break;
//                    case 3:
//                         ABMultiValueAddValueAndLabel(multiEmail,valueStr, kABOtherLabel, NULL);
//                        break;
//                    default:
//                        ABMultiValueAddValueAndLabel(multiEmail,valueStr, (CFStringRef)typeStr, NULL);
//                        break;
//                }
//            }
//        }
//    }
//
//    if( 0 != addContact.bday)
//    {
//        NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
//        [formatter setDateFormat:@"yyyy-MM-dd"];
//        NSDate *dateComponent=[formatter dateFromString:addContact.bday];
//        [formatter release];
//        ABRecordSetValue(newPerson, kABPersonBirthdayProperty,(CFDataRef)dateComponent, &error);
//    }
//
//    NSArray *dateTypeKey = [addContact.date allKeys];
//    if ( [dateTypeKey count] > 0 ) {
//        multiDate = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//
//        for (NSString* typeStr in dateTypeKey)
//        {
//            NSArray *dateValue = [addContact.date allValuesForKey:typeStr];
//
//            for (NSString* valueStr in dateValue)
//            {
//                NSInteger dictionaryNum = [[dateType objectForKey:typeStr] intValue];
//                NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
//                [formatter setDateFormat:@"yyyy-MM-dd"];
//                NSDate *dateComponent=[formatter dateFromString:valueStr];
//
//
//                switch (dictionaryNum)
//                {
//                    case 1:
//                        ABMultiValueAddValueAndLabel(multiDate,(CFDataRef)dateComponent, kABPersonAnniversaryLabel, NULL);
//                        break;
//                    case 2:
//                        ABMultiValueAddValueAndLabel(multiDate,(CFDataRef)dateComponent, kABOtherLabel, NULL);
//                        break;
//                    default:
//                         ABMultiValueAddValueAndLabel(multiDate,(CFDataRef)dateComponent, (CFStringRef)typeStr, NULL);
//                        break;
//                }
//                [formatter release];
//            }
//        }
//    }
//
//    NSArray *urlTypeKey = [addContact.url allKeys];
//    if ([urlTypeKey count] > 0) {
//        multiUrl = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//
//        for (NSString* typeStr in urlTypeKey)
//        {
//            NSArray *dateValue = [addContact.url allValuesForKey:typeStr];
//            for (NSString* valueStr in dateValue)
//            {
//                NSInteger dictionaryNum = [[urlType objectForKey:typeStr] intValue];
//
//                switch (dictionaryNum)
//                {
//                    case 1:
//                        ABMultiValueAddValueAndLabel(multiUrl,valueStr, kABHomeLabel, NULL);
//                        break;
//                    case 2:
//                        ABMultiValueAddValueAndLabel(multiUrl,valueStr, kABWorkLabel, NULL);
//                        break;
//                    case 3:
//                        ABMultiValueAddValueAndLabel(multiUrl,valueStr, kABOtherLabel, NULL);
//                        break;
//                    case 4:
//                        ABMultiValueAddValueAndLabel(multiUrl,valueStr, kABPersonHomePageLabel, NULL);
//                        break;
//                    default:
//                        ABMultiValueAddValueAndLabel(multiUrl,valueStr, (CFStringRef)typeStr, NULL);
//                        break;
//                }
//            }
//        }
//    }
//
//    NSArray *adrTypeKey = [addContact.address allKeys];
//    if ( [adrTypeKey count] > 0 ) {
//        multiAddress = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//
//        for (NSString* typeStr in adrTypeKey)
//        {
//            NSArray *dateValue = [addContact.address allValuesForKey:typeStr];
//            for (NSString* valueStr in dateValue)
//            {
//                NSInteger dictionaryNum = [[adrType objectForKey:typeStr] intValue];
//                NSArray *adrComponents = [valueStr componentsSeparatedByString:@";"];
//                NSMutableDictionary *addressDictionary = [[NSMutableDictionary alloc] init];
//                NSString *streetTemp = [adrComponents objectAtIndex:0];
//                NSString * AddressStreet = [streetTemp stringByReplacingOccurrencesOfString: @" " withString:@"\n"];
//
//                [addressDictionary setObject: AddressStreet forKey:(NSString *) kABPersonAddressStreetKey];
//                [addressDictionary setObject:[adrComponents objectAtIndex:1] forKey:(NSString *) kABPersonAddressCityKey];
//                [addressDictionary setObject:[adrComponents objectAtIndex:2] forKey:(NSString *) kABPersonAddressStateKey];
//                [addressDictionary setObject:[adrComponents objectAtIndex:3] forKey:(NSString *) kABPersonAddressZIPKey];
//                [addressDictionary setObject:[adrComponents objectAtIndex:4] forKey:(NSString *) kABPersonAddressCountryKey];
//
//                switch (dictionaryNum)
//                {
//                    case 1:
//                        ABMultiValueAddValueAndLabel(multiAddress, addressDictionary, kABHomeLabel, NULL);
//                        break;
//                    case 2:
//                        ABMultiValueAddValueAndLabel(multiAddress, addressDictionary, kABWorkLabel, NULL);
//                        break;
//                    case 3:
//                        ABMultiValueAddValueAndLabel(multiAddress, addressDictionary, kABOtherLabel, NULL);
//                        break;
//                    default:
//                        ABMultiValueAddValueAndLabel(multiAddress, addressDictionary, (CFStringRef)typeStr, NULL);
//                        break;
//                }
//                [addressDictionary release];
//            }
//        }
//    }
//
//    if ([addContact.im count] > 0) {
//        multiMessageService = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//
//        for (int i = 0 ; i < [addContact.im count]; i++)
//        {
//
//            NSMutableDictionary *imDict = [[NSMutableDictionary alloc] init];
//            NSMutableString *imNameStr =[addContact.im objectAtIndex:i];
//            i++;
//            NSMutableString *imTypeStr = [addContact.im objectAtIndex:i];
//            i++;
//            NSString *imValueStr = [addContact.im objectAtIndex:i];
//
//            NSInteger dictionaryNum = [[imNameType objectForKey:imNameStr] intValue];
//
//            switch (dictionaryNum)
//            {
//                case 1:
//                    imNameStr = (NSString*)kABPersonInstantMessageServiceQQ;
//                    break;
//                case 2:
//                   imNameStr = (NSString*)kABPersonInstantMessageServiceSkype;
//                    break;
//                case 3:
//                    imNameStr = (NSString*)kABPersonInstantMessageServiceMSN;
//                    break;
//                case 4:
//                    imNameStr = (NSString*)kABPersonInstantMessageServiceGoogleTalk;
//                    break;
//                case 5:
//                    imNameStr = (NSString*)kABPersonInstantMessageServiceFacebook;
//                    break;
//                case 6:
//                    imNameStr = (NSString*)kABPersonInstantMessageServiceAIM;
//                    break;
//                case 7:
//                    imNameStr = (NSString*)kABPersonInstantMessageServiceYahoo;
//                    break;
//                case 8:
//                    imNameStr = (NSString*)kABPersonInstantMessageServiceICQ;
//                    break;
//                case 9:
//                    imNameStr = (NSString*)kABPersonInstantMessageServiceJabber;
//                    break;
//                case 10:
//                    imNameStr = (NSString*)kABPersonInstantMessageServiceGaduGadu;
//                    break;
//                default:
//                    break;
//            }
//
//            dictionaryNum = [[imType objectForKey:imTypeStr] intValue];
//
//            switch (dictionaryNum)
//            {
//                case 1:
//                    // ABMultiValueAddValueAndLabel(multiUrl,valueStr, kABHomeLabel, NULL);
//                    imTypeStr = (NSString*)kABHomeLabel;
//                    break;
//                case 2:
//                    imTypeStr = (NSString*)kABWorkLabel;
//                    break;
//                case 3:
//                    imTypeStr = (NSString*)kABOtherLabel;
//                    break;
//                default:
//                    break;
//            }
//
//            [imDict setObject:imNameStr forKey:(NSString*)kABPersonInstantMessageServiceKey];
//            [imDict setObject:imValueStr forKey:(NSString*)kABPersonInstantMessageUsernameKey];
//            ABMultiValueAddValueAndLabel(multiMessageService, imDict, imTypeStr, NULL);
//           // ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiMessageService, &error);
//            [imDict release];
//        }
//    }
//
//    NSArray *serverTypeKey = [addContact.server allKeys];
//    if ( [serverTypeKey count] > 0 ) {
//         multiSocials = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//
//        for (NSString* typeStr in serverTypeKey)
//        {
//            NSArray *dateValue = [addContact.server allValuesForKey:typeStr];
//            for (NSString* valueStr in dateValue)
//            {
//                NSInteger dictionaryNum = [[serverType objectForKey:typeStr] intValue];
//              //  NSMutableDictionary *imDict = [[NSMutableDictionary alloc] init];
//                switch (dictionaryNum)
//                {
//                    case 1:
//                    {
//                        CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
//                            kABPersonSocialProfileURLKey }, valuestw[] = { kABPersonSocialProfileServiceSinaWeibo,
//                                (CFStringRef)valueStr, CFSTR("http://www.weibo.com/") }, valuesfb[] = {
//                                    kABPersonSocialProfileServiceSinaWeibo,  (CFStringRef)valueStr,
//                                    CFSTR("http://www.weibo.com/") };
//                        ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
//                                                                                      (void*)valuestw, 3, NULL, NULL), NULL, NULL);
//                        break;
//                    }
//                    case 2:
//                    {
//                        CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
//                            kABPersonSocialProfileURLKey }, valuestw[] = { kABPersonSocialProfileServiceTwitter,
//                                (CFStringRef)valueStr, CFSTR("http://www.twitter.com/") }, valuesfb[] = {
//                                    kABPersonSocialProfileServiceTwitter,  (CFStringRef)valueStr,
//                                    CFSTR("http://www.twitter.com/") };
//                        ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
//                                                                                      (void*)valuestw, 3, NULL, NULL), NULL, NULL);
//                        break;
//                    }
//                    case 3:
//                    {
//                        CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
//                            kABPersonSocialProfileURLKey }, valuestw[] = { kABPersonSocialProfileServiceFacebook,
//                                (CFStringRef)valueStr, CFSTR("http://www.facebook.com/") }, valuesfb[] = {
//                                    kABPersonSocialProfileServiceFacebook,  (CFStringRef)valueStr,
//                                    CFSTR("http://www.facebook.com/") };
//                        ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
//                                                                                      (void*)valuestw, 3, NULL, NULL), NULL, NULL);
//                        break;
//                    }
//                    case 4:
//                    {
//                        CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
//                            kABPersonSocialProfileURLKey }, valuestw[] = { kABPersonSocialProfileServiceFlickr,
//                                (CFStringRef)valueStr, CFSTR("http://www.flickr.com/") }, valuesfb[] = {
//                                    kABPersonSocialProfileServiceFlickr,  (CFStringRef)valueStr,
//                                    CFSTR("http://www.flickr.com/") };
//                        ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
//                                                                                      (void*)valuestw, 3, NULL, NULL), NULL, NULL);
//                        break;
//                    }
//                    case 5:
//                    {
//                        CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
//                            kABPersonSocialProfileURLKey }, valuestw[] = { kABPersonSocialProfileServiceLinkedIn,
//                                (CFStringRef)valueStr, CFSTR("http://www.linkedin.com/") }, valuesfb[] = {
//                                    kABPersonSocialProfileServiceLinkedIn,  (CFStringRef)valueStr,
//                                    CFSTR("http://www.linkedin.com/") };
//                        ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
//                                                                                      (void*)valuestw, 3, NULL, NULL), NULL, NULL);
//                        break;
//                    }
//                    case 6:
//                    {
//                        CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
//                            kABPersonSocialProfileURLKey }, valuestw[] = { (CFStringRef)typeStr,
//                                (CFStringRef)valueStr, CFSTR("http://www.myspace.com/") }, valuesfb[] = {
//                                    kABPersonSocialProfileServiceMyspace,  (CFStringRef)valueStr,
//                                    CFSTR("http://www.myspace.com/") };
//                        ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
//                                                                                      (void*)valuestw, 3, NULL, NULL), NULL, NULL);
//                        break;
//                    }
//
//                    default:
//                    {
//                        CFStringRef keys[] = { kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey,
//                            kABPersonSocialProfileURLKey }, valuestw[] = { (CFStringRef)typeStr,
//                           (CFStringRef)valueStr, CFSTR("") }, valuesfb[] = {
//                                     (CFStringRef)valueStr,(CFStringRef)typeStr,
//                                    CFSTR("") };
//                        ABMultiValueAddValueAndLabel(multiSocials, CFDictionaryCreate(kCFAllocatorDefault, (void*)keys,
//                                                                                      (void*)valuestw, 3, NULL, NULL), NULL, NULL);
//                        break;
//                    }
//                }
//                //[imDict release];
//            }
//        }
//    }
//    NSArray *relatedTypeKey = [addContact.related allKeys];
//    if ( [relatedTypeKey count ] > 0 ) {
//        multiRelated = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//
//        for (NSString* typeStr in relatedTypeKey)
//        {
//            NSArray *dateValue = [addContact.related allValuesForKey:typeStr];
//            for (NSString* valueStr in dateValue)
//            {
//                NSInteger dictionaryNum = [[relateType objectForKey:typeStr] intValue];
//
//                switch (dictionaryNum)
//                {
//                    case 1:
//                        ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonMotherLabel, NULL);
//                        break;
//                    case 2:
//                        ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonFatherLabel, NULL);
//                        break;
//                    case 3:
//                        ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonParentLabel, NULL);
//                        break;
//                    case 4:
//                        ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonBrotherLabel, NULL);
//                        break;
//                    case 5:
//                        ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonSisterLabel, NULL);
//                        break;
//                    case 6:
//                        ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonChildLabel, NULL);
//                        break;
//                    case 7:
//                        ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonFriendLabel, NULL);
//                        break;
//                    case 8:
//                        ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonSpouseLabel, NULL);
//                        break;
//                    case 9:
//                        ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonPartnerLabel, NULL);
//                        break;
//                    case 10:
//                        ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonAssistantLabel, NULL);
//                        break;
//                    case 11:
//                        ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABPersonManagerLabel, NULL);
//                        break;
//                    case 12:
//                        ABMultiValueAddValueAndLabel(multiRelated,valueStr, kABOtherLabel, NULL);
//                        break;
//                    default:
//                        ABMultiValueAddValueAndLabel(multiRelated,valueStr, (CFStringRef)typeStr, NULL);
//                        break;
//                }
//            }
//        }
//    }
//    if(multiPhone)
//    {
//        ABRecordSetValue(newPerson, kABPersonPhoneProperty, multiPhone, &error );
//    }
//    if(multiEmail)
//    {
//        ABRecordSetValue(newPerson, kABPersonPhoneProperty, multiEmail, &error );
//    }
//    if (multiUrl)
//    {
//        ABRecordSetValue(newPerson, kABPersonURLProperty, multiUrl, &error );
//    }
//    if (multiDate)
//    {
//        ABRecordSetValue(newPerson, kABPersonDateProperty, multiDate, &error );
//    }
//    if (multiSocials)
//    {
//        ABRecordSetValue(newPerson, kABPersonSocialProfileProperty, multiSocials, &error);
//    }
//    if (multiMessageService)
//    {
//        ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiMessageService, &error);
//    }
//    if (multiRelated)
//    {
//        ABRecordSetValue(newPerson, kABPersonRelatedNamesProperty, multiRelated, &error);
//    }
//    if (multiAddress)
//    {
//        ABRecordSetValue(newPerson, kABPersonAddressProperty, multiAddress, &error);
//    }
//    //将新的记录，添加到通讯录中
//    ABAddressBookAddRecord(addressBook, newPerson, NULL);
//    //NSArray *groupArray = (NSArray *)ABAddressBookCopyArrayOfAllGroups(addressBook);
//    if([addContact.group length] >0)
//    {
//        if (0 == [groupArray  count])
//        {
//            //CFTypeRef groupNameRef = ABRecordCopyValue(group, kABGroupNameProperty);
//            CFErrorRef error;
//            ABRecordRef group = ABGroupCreate();
//            ABRecordSetValue(group, kABGroupNameProperty,addContact.group , &error);
//            ABAddressBookAddRecord(addressBook, group, &error);
//            ABAddressBookSave(addressBook, &error);
//
//            ABGroupAddMember(group, newPerson, &error);
//
//            CFRelease(group);
//        }
//        else
//        {
//
//            for (int i = 0 ; i < [groupArray count]; i++)
//            {
//                ABRecordRef group = [groupArray objectAtIndex:i];
//                CFTypeRef groupNameRef = ABRecordCopyValue(group, kABGroupNameProperty);
//                NSString *groupNameStr = [NSString stringWithFormat:@"%@", (NSString *)groupNameRef];
//                if (NSOrderedSame== [groupNameStr compare:addContact.group])
//                {
//                    ABGroupAddMember(group, newPerson, &error);
//                    CFRelease(groupNameRef);
//                    break;
//                }
//                else if (NSOrderedSame!= [groupNameStr compare:addContact.group] && i == [groupArray count]-1)
//                {
//                    CFErrorRef error;
//                    ABRecordRef group = ABGroupCreate();
//                    ABRecordSetValue(group, kABGroupNameProperty,addContact.group, &error);
//                    ABAddressBookAddRecord(addressBook, group, &error);
//                    ABAddressBookSave(addressBook, &error);
//
//                    ABGroupAddMember(group, newPerson, &error);
//
//                    CFRelease(groupNameRef);
//                }
//                //  [groupNames addObject:groupNameStr];
//
//            }
//
//        }
//
//    }
//    BOOL isSuccess;
//    //通讯录执行保存
//    isSuccess = ABAddressBookSave(addressBook, error);
//    if (NO == isSuccess)
//    {
//        NSLog(@"address book save fail");
//    }
//
//    if (multiPhone)
//        CFRelease(multiPhone);
//    if (multiEmail)
//        CFRelease(multiEmail);
//    if (multiDate)
//        CFRelease(multiDate);
//    if (multiUrl)
//        CFRelease(multiUrl);
//    if(multiAddress)
//        CFRelease(multiAddress);
//    if (multiSocials)
//        CFRelease(multiSocials);
//    if (multiMessageService)
//        CFRelease(multiMessageService);
//    if (multiRelated)
//        CFRelease(multiRelated);
//
//    [telType release];
//    [emailType release];
//    [dateType release];
//    [urlType release];
//    [adrType release];
//    [serverType release];
//    [relateType release];
//    [imType release];
//    [imNameType release];
//}
-(void)parseVCardStrToArray:(NSString*)vcardString array:(NSMutableArray *) contactArray
{
    NSArray *lines = [vcardString componentsSeparatedByString:@"\n"];
    
    CustomContactData *contactInfo = nil;
    
    for(NSString* line in lines)
    {
        if ([line hasPrefix:@"BEGIN"])
        {
            //NSLog(@"parse start");
            
            //newPerson = ABPersonCreate();
            contactInfo = [[CustomContactData alloc]init];
        } else if ([line hasPrefix:@"END"])
        {
            [contactArray addObject:contactInfo];
        } else if ([line hasPrefix:@"N:"])
        {
            NSArray *upperComponents = [line componentsSeparatedByString:@":"];
            NSArray *components = [[upperComponents objectAtIndex:1] componentsSeparatedByString:@";"];
            
            if (5 == [components count])
            {
                NSMutableArray *nameArray =[[NSMutableArray alloc]init];
                [nameArray addObject:[components objectAtIndex:1]];
                [nameArray addObject:[components objectAtIndex:0]];
                [nameArray addObject:[components objectAtIndex:2]];
                [nameArray addObject:[components objectAtIndex:3]];
                [nameArray addObject:[components objectAtIndex:4]];
                
                [contactInfo.name addObjectsFromArray:nameArray];
                [nameArray release];
            }
            else
            {
                [contactInfo.name addObject:@""];
                [contactInfo.name addObject:@""];
                [contactInfo.name addObject:@""];
                [contactInfo.name addObject:@""];
                [contactInfo.name addObject:@""];
            }
            
        }else if([line hasPrefix:@"NICKNAME:"])
        {
            NSArray *upperComponents = [line componentsSeparatedByString:@":"];
            NSString * nickname = [upperComponents objectAtIndex:1];
            // [contactInfo setData:@"NICKNAME" data:nickname];
            [contactInfo.nickname appendString:nickname];
        }else if([line hasPrefix:@"X-GROUP:"])
        {
            NSArray *upperComponents = [line componentsSeparatedByString:@":"];
            //groupName= [upperComponents objectAtIndex:1];
            [contactInfo.group appendString:[upperComponents objectAtIndex:1]];
        }
        else if([line hasPrefix:@"ORG:"])
        {
            NSArray *upperComponents = [line componentsSeparatedByString:@":"];
            NSArray *components = [[upperComponents objectAtIndex:1] componentsSeparatedByString:@";"];
            if (2 == [components count] )
            {
                NSString * org = [components objectAtIndex:0];
                NSString * department = [components objectAtIndex:1];
                [contactInfo.org appendString:org];
                [contactInfo.department appendString:department];
                
            }
            
        }
        else if([line hasPrefix:@"TITLE:"])
        {
            NSArray *upperComponents = [line componentsSeparatedByString:@":"];
            NSString * title = [upperComponents objectAtIndex:1];
            [contactInfo.title appendString:title];
        }
        else if([line hasPrefix:@"X-PHONETIC-FIRST-NAME:"])
        {
            NSArray *upperComponents = [line componentsSeparatedByString:@":"];
            NSString * phoneticFirstName = [upperComponents objectAtIndex:1];
            [contactInfo.firstNamePhonetic appendString:phoneticFirstName];
        }
        else if([line hasPrefix:@"X-PHONETIC-LAST-NAME:"])
        {
            NSArray *upperComponents = [line componentsSeparatedByString:@":"];
            NSString * phoneticFirstName = [upperComponents objectAtIndex:1];
            [contactInfo.lastNamePhonetic appendString:phoneticFirstName];
        }
        else if ([line hasPrefix:@"TEL;"])
        {
            NSInteger range = [line rangeOfString:@"=" options:NSBackwardsSearch].location;
            NSInteger rangeNum  = [line rangeOfString:@":" options:NSBackwardsSearch].location;
            NSInteger length = [line length];
            NSString * type = [line substringWithRange:NSMakeRange(range+1,rangeNum-range-1)];
            NSString * telNum = [line substringWithRange:NSMakeRange(rangeNum+1,length-rangeNum-1)];
            NSString *number = [[telNum componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"+0123456789()*#,;"] invertedSet]] componentsJoinedByString:@""];
            
            [contactInfo.tel setMultiValue:number forKey:type];
        }
        else if ([line hasPrefix:@"EMAIL;"])
        {
            
            NSArray *components = [line componentsSeparatedByString:@":"];
            NSString *emailAddress = [components objectAtIndex:1];
            NSString *emailTemp = [components objectAtIndex:0];
            NSInteger rangeType  = [line rangeOfString:@"="].location;
            NSString *emailType = [emailTemp substringWithRange:NSMakeRange(rangeType+1,[emailTemp length]-rangeType-1)];
            
            [contactInfo.email setMultiValue:emailAddress forKey:emailType];
        }
        else if ([line hasPrefix:@"URL;"])
        {
            NSArray *components = [line componentsSeparatedByString:@":"];
            NSString *urlAddress = [components objectAtIndex:1];
            NSString *urlTemp = [components objectAtIndex:0];
            NSInteger rangeType  = [line rangeOfString:@"="].location;
            NSString *urlType = [urlTemp substringWithRange:NSMakeRange(rangeType+1,[urlTemp length]-rangeType-1)];
            //  [urlDictionary setObject:urlType forKey:urlAddress];
            [contactInfo.url setMultiValue:urlAddress forKey:urlType];
            
        }
        else if ([line hasPrefix:@"ADR;"])
        {
            NSInteger range = [line rangeOfString:@"="].location;
            NSInteger rangeType  = [line rangeOfString:@":"].location;
            NSInteger length = [line length];
            NSString *adrType = [line substringWithRange:NSMakeRange(range+1,rangeType-range-1)];
            NSString *adr = [line substringWithRange:NSMakeRange(rangeType+1,length-rangeType-1)];
            [contactInfo.address setMultiValue:adr forKey:adrType];
            
        }
        else if([line hasPrefix:@"BDAY:"])
        {
            NSString * bday = [line substringWithRange:NSMakeRange(5,10)];
            [contactInfo.bday appendString:bday];
        }
        else if([line hasPrefix:@"DATE;"])
        {
            NSInteger typeStart = [line rangeOfString:@"DATE;TYPE="].length;
            NSInteger typeEnd  = [line rangeOfString:@":"].location;
            
            NSString *dateType = [line substringWithRange:NSMakeRange(typeStart,typeEnd-typeStart)];
            NSString *date = [line substringWithRange:NSMakeRange(typeEnd+1,10)];
            [contactInfo.date setMultiValue:date forKey:dateType];
        }
        else if([line hasPrefix:@"X-IM;"])
        {
            NSInteger length = [line length];
            NSInteger serviceStart = [line rangeOfString:@"X-IM;SERVICE="].length;
            NSRange typeRange = [line rangeOfString:@";TYPE="];
            NSString *service;
            NSString *type;
            NSString *username;
            if (typeRange.length == 0)
            {
                // X-IM;SERVICE=%@:%@\n
                NSArray *componmetArray = [[line substringWithRange:NSMakeRange(serviceStart,length-serviceStart)] componentsSeparatedByString:@":"];
                service = [NSString stringWithString:[componmetArray objectAtIndex:0]];
                type = @"OTHER";
                username = [NSString stringWithString:[componmetArray objectAtIndex:1]];
            }
            else
            {
                // X-IM;SERVICE=%@;TYPE=OTHER:%@\n
                NSInteger typeStart = typeRange.location;
                NSArray *componmetArray = [[line substringWithRange:NSMakeRange(typeStart+6,length-typeStart-6)] componentsSeparatedByString:@":"];
                service = [line substringWithRange:NSMakeRange(serviceStart,typeStart-serviceStart)];
                type = [NSString stringWithString:[componmetArray objectAtIndex:0]];
                username = [NSString stringWithString:[componmetArray objectAtIndex:1]];
            }
            [contactInfo.im addObject:service];
            [contactInfo.im addObject:type];
            [contactInfo.im addObject:username];
        }
        else if([line hasPrefix:@"X-SERVER;"])
        {
            NSInteger range = [line rangeOfString:@"="].location;
            NSInteger rangeType  = [line rangeOfString:@":"].location;
            NSInteger length = [line length];
            NSString * type = [line substringWithRange:NSMakeRange(range+1,rangeType-range)];
            NSString *serverUserName = [line substringWithRange:NSMakeRange(rangeType+1,length-rangeType-1)];
            [contactInfo.server setMultiValue:serverUserName forKey:type];
            //  [imDictionary setObject:type forKey:imUserName];
        }
        else if ([line hasPrefix:@"X-RELATED;"])
        {
            NSArray *components = [line componentsSeparatedByString:@":"];
            NSString *relatedName = [components objectAtIndex:1];
            NSString *urlTemp = [components objectAtIndex:0];
            NSInteger rangeType  = [line rangeOfString:@"="].location;
            NSString *relatedType = [urlTemp substringWithRange:NSMakeRange(rangeType+1,[urlTemp length]-rangeType-1)];
            [contactInfo.related setMultiValue:relatedName forKey:relatedType];
        }
        else if ([line hasPrefix:@"NOTE:"])
        {
            NSArray *components = [line componentsSeparatedByString:@":"];
            [contactInfo.note appendString:[[components objectAtIndex:1] stringByReplacingOccurrencesOfString: @"\\n" withString:@"\n"]];
        }
    }
}
-(id )GetPersonCount
{
    ABAddressBookRef addressBook = nil;
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
    {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     dispatch_semaphore_signal(sema);
                                                 });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
        
        
    }
    else
    {
        addressBook = ABAddressBookCreate();
    }
    CFIndex count = ABAddressBookGetPersonCount(addressBook);
    if (addressBook != nil)
    {
        CFRelease(addressBook);
        return count;
    }
    return -1;
    
    
}
-(NSInteger )GetUploadCount
{
    return uploadContactNum;
}

-(void)getSystemContactToClass:(NSMutableArray *)systemContactArray
{
    CFArrayRef contacts = [self readAddressBook];
    CustomContactData *contactInfo = nil;
    
    for(NSInteger i = 0; i < CFArrayGetCount(contacts); i++)
    {
        
        ABRecordRef person = CFArrayGetValueAtIndex(contacts, i);
        contactInfo = [[CustomContactData alloc]init];
        
        NSString *firstName = (NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        firstName = (firstName ? firstName : @"");
        NSString *lastName = (NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        lastName = (lastName ? lastName : @"");
        NSString *middleName = (NSString *)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
        NSString *prefix = (NSString *)ABRecordCopyValue(person, kABPersonPrefixProperty);
        NSString *suffix = (NSString *)ABRecordCopyValue(person, kABPersonSuffixProperty);
        
        
        if (lastName)
        {
            [contactInfo.name addObject:lastName];
        }
        else
        {
            [contactInfo.name addObject:@""];
        }
        if (firstName)
        {
            [contactInfo.name addObject:firstName];
        }
        else
        {
            [contactInfo.name addObject:@""];
        }
        if (middleName)
        {
            [contactInfo.name addObject:middleName];
        }
        else
        {
            [contactInfo.name addObject:@""];
        }
        if (prefix)
        {
            [contactInfo.name addObject:prefix];
        }
        else
        {
            [contactInfo.name addObject:@""];
        }
        if (suffix)
        {
            [contactInfo.name addObject:suffix];
        }
        else
        {
            [contactInfo.name addObject:@""];
        }
        
        /*NSString *nickName = (NSString *)ABRecordCopyValue(person, kABPersonNicknameProperty);
         if (nickName)
         {
         [contactInfo.nickname appendString:nickName];
         }
         
         NSString *firstNamePhonetic = (NSString *)ABRecordCopyValue(person,kABPersonFirstNamePhoneticProperty);
         if (firstNamePhonetic)
         {
         [contactInfo.firstNamePhonetic appendString:firstNamePhonetic];
         }
         
         NSString *lastNamePhonetic = (NSString *)ABRecordCopyValue(person, kABPersonLastNamePhoneticProperty);
         
         if (lastNamePhonetic)
         {
         [contactInfo.lastNamePhonetic appendString:lastNamePhonetic];
         }
         
         NSString *organization = (NSString *)ABRecordCopyValue(person, kABPersonOrganizationProperty);
         if (organization)
         {
         [contactInfo.org appendString:organization];
         }
         
         NSString *jobTitle = (NSString *)ABRecordCopyValue(person, kABPersonJobTitleProperty);
         if (jobTitle)
         {
         [contactInfo.title appendString:jobTitle];
         }
         
         NSString *department = (NSString *)ABRecordCopyValue(person, kABPersonDepartmentProperty);
         if (department)
         {
         [contactInfo.department appendString:department];
         }
         
         */
        //  NSString *compositeName = [NSString stringWithFormat:@"%@%@",lastName,firstName];
        
        
        ABRecordID recId = ABRecordGetRecordID(person);
        NSString *stringId = [NSString stringWithFormat:@"%d",recId];
        NSString *groupString = [groupInfo containObjectAllkey:stringId];
        if (groupString)
        {
            [contactInfo.group appendString:groupString];
        }
        
        
        // Tel
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        if(phoneNumbers)
        {
            for (int k = 0; (k < ABMultiValueGetCount(phoneNumbers)&& k < ABMULTIVALUESUM ); k++)
            {
                NSString *label = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(phoneNumbers, k));
                NSString *numberTemp = (NSString *)ABMultiValueCopyValueAtIndex(phoneNumbers, k);
                
                NSString *number = [[numberTemp componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"+0123456789()*#,;"] invertedSet]] componentsJoinedByString:@""];
                [numberTemp release];
                NSString *labelLower = [label lowercaseString];
                
                if ([labelLower isEqualToString:@"mobile"] ||[labelLower isEqualToString:@"移动"])
                    [contactInfo.tel setMultiValue:number forKey:@"MOBIlE"];
                else if ([labelLower isEqualToString:@"iphone"])
                    [contactInfo.tel setMultiValue:number forKey:@"iPhone"];
                else if ([labelLower isEqualToString:@"home"] ||[labelLower isEqualToString:@"住宅"])
                    [contactInfo.tel setMultiValue:number forKey:@"HOME"];
                else if ([labelLower isEqualToString:@"work"] ||[labelLower isEqualToString:@"工作"])
                    [contactInfo.tel setMultiValue:number forKey:@"WORK"];
                else if ([labelLower isEqualToString:@"main"] ||[labelLower isEqualToString:@"主要"])
                    [contactInfo.tel setMultiValue:number forKey:@"MAIN"];
                else if ([labelLower isEqualToString:@"home fax"] ||[labelLower isEqualToString:@"住宅传真"])
                    [contactInfo.tel setMultiValue:number forKey:@"HOME FAX"];
                else if ([labelLower isEqualToString:@"work fax"] || [labelLower isEqualToString:@"工作传真"])
                    [contactInfo.tel setMultiValue:number forKey:@"WORK FAX"];
                else if ([labelLower isEqualToString:@"other fax"]||[labelLower isEqualToString:@"其他传真"])
                    [contactInfo.tel setMultiValue:number forKey:@"OTHER FAX"];
                else if ([labelLower isEqualToString:@"pager"]||[labelLower isEqualToString:@"传呼"])
                    [contactInfo.tel setMultiValue:number forKey:@"PAGER"];
                else if([labelLower isEqualToString:@"other"] ||[labelLower isEqualToString:@"其他"])
                    [contactInfo.tel setMultiValue:number forKey:@"OTHER"];
                else
                { //类型解析不出来的
                    [contactInfo.tel setMultiValue:number forKey:label];
                }
                [label release];
            }
        }
        
        /*
         // Mail
         ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
         if(emails)
         {
         for (int k = 0; (k < ABMultiValueGetCount(emails) && k < ABMULTIVALUESUM ); k++)
         {
         NSString *label = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(emails, k));
         NSString *email = (NSString *)ABMultiValueCopyValueAtIndex(emails, k);
         NSString *labelLower = [label lowercaseString];
         
         // vcard = [vcard stringByAppendingFormat:@"EMAIL;type=WORK:%@\n",email];
         
         if ([labelLower isEqualToString:@"home"] || [labelLower isEqualToString:@"家庭"])
         [contactInfo.email setMultiValue:email forKey:@"HOME"];
         else if ([labelLower isEqualToString:@"work"] || [labelLower isEqualToString:@"工作"])
         [contactInfo.email setMultiValue:email forKey:@"WORK"];
         else if ([labelLower isEqualToString:@"other"] || [labelLower isEqualToString:@"其他"])
         [contactInfo.email setMultiValue:email forKey:@"OTHER"];
         else
         {//类型解析不出来的
         [contactInfo.email setMultiValue:email forKey:label];
         }
         }
         }
         
         // url
         ABMultiValueRef urls = ABRecordCopyValue(person, kABPersonURLProperty);
         if(urls)
         {
         for (int k = 0; (k < ABMultiValueGetCount(urls) && k < ABMULTIVALUESUM ); k++)
         {
         NSString *label = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(urls, k));
         NSString *url = (NSString *)ABMultiValueCopyValueAtIndex(urls, k);
         NSString *labelLower = [label lowercaseString];
         
         // vcard = [vcard stringByAppendingFormat:@"EMAIL;type=WORK:%@\n",email];
         
         if ([labelLower isEqualToString:@"home page"] || [labelLower isEqualToString:@"首页"])
         [contactInfo.url setMultiValue:url forKey:@"HOME PAGE"];
         else if ([labelLower isEqualToString:@"home"] || [labelLower isEqualToString:@"住宅"])
         [contactInfo.url setMultiValue:url forKey:@"HOME"];
         else if ([labelLower isEqualToString:@"work"] || [labelLower isEqualToString:@"工作"])
         [contactInfo.url setMultiValue:url forKey:@"WORK"];
         else if ([labelLower isEqualToString:@"other"] || [labelLower isEqualToString:@"其他"])
         [contactInfo.url setMultiValue:url forKey:@"OTHER"];
         else
         {//类型解析不出来的
         [contactInfo.url setMultiValue:url forKey:label];
         }
         }
         }
         
         
         // Address
         ABMultiValueRef address = ABRecordCopyValue(person, kABPersonAddressProperty);
         if(address) {
         for (int k = 0; (k < ABMultiValueGetCount(address) && k < ABMULTIVALUESUM ); k++)
         {
         //获取地址Label
         NSString *label = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(address, k));
         // textView.text = [textView.text stringByAppendingFormat:@"%@\n",addressLabel];
         //获取該label下的地址6属性
         NSDictionary * dic =(NSDictionary*) ABMultiValueCopyValueAtIndex(address, k);
         NSString *labelLower = [label lowercaseString];
         
         NSString * country = [dic valueForKey:(NSString *)kABPersonAddressCountryKey];
         
         NSString * city = [dic valueForKey:(NSString *)kABPersonAddressCityKey];
         
         NSString * state = [dic valueForKey:(NSString *)kABPersonAddressStateKey];
         
         NSString * streetTemp = [dic valueForKey:(NSString *)kABPersonAddressStreetKey ];
         
         NSString * street = [streetTemp stringByReplacingOccurrencesOfString: @"\n" withString:@" "];
         
         NSString * zip = [dic valueForKey:(NSString *)kABPersonAddressZIPKey];
         
         //   NSString* countryCode = [dic valueForKey:(NSString *)kABPersonAddressCountryCodeKey];
         
         NSString *type = @"";
         //NSString *labelField = @"";
         if([labelLower isEqualToString:@"work"] ||[labelLower isEqualToString:@"工作"]) type = @"WORK";
         else if([labelLower isEqualToString:@"home"] ||[labelLower isEqualToString:@"住宅"]) type = @"HOME";
         else if([labelLower isEqualToString:@"other"]||[labelLower isEqualToString:@"其他"]) type = @"OTHER";
         else type = labelLower;
         
         NSString *temp =[NSString stringWithFormat:@"ADR;TYPE=%@:%@;%@;%@;%@;%@\n",type,street ,city,state,zip,country];
         //[temp appendFormat:@"ADR;TYPE=%@:%@;%@;%@;%@;%@\n",type,street ,city,state,zip,country];
         
         [contactInfo.address setMultiValue:temp forKey:type];
         }
         }
         NSString *Birthday = (NSString *)ABRecordCopyValue(person, kABPersonBirthdayProperty);
         if(Birthday)
         {
         //   [contactInfo.bday appendString:Birthday];
         }
         
         //获取dates多值
         ABMultiValueRef dates = ABRecordCopyValue(person, kABPersonDateProperty);
         if(dates)
         {
         for (int k = 0; (k < ABMultiValueGetCount(dates) && k < ABMULTIVALUESUM ); k++)
         {
         NSString *label = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(dates, k));
         NSString *date = (NSString *)ABMultiValueCopyValueAtIndex(dates, k);
         //NSString *date =[dateTemp substringToIndex:7];
         NSString *labelLower = [label lowercaseString];
         
         if ([labelLower isEqualToString:@"anniversary"] || [labelLower isEqualToString:@"周年"])
         [contactInfo.date setMultiValue:date forKey:@"ANNIVERSARY"];
         else if ([labelLower isEqualToString:@"other"] || [labelLower isEqualToString:@"其他"])
         [contactInfo.date setMultiValue:date forKey:@"OTHER"];
         else
         {//类型解析不出来的
         [contactInfo.date setMultiValue:date forKey:label];
         }
         
         
         }
         }
         
         // im
         ABMultiValueRef IMs = ABRecordCopyValue(person, kABPersonInstantMessageProperty);
         if(urls)
         {
         for (int k = 0; (k < ABMultiValueGetCount(IMs) && k < ABMULTIVALUESUM ); k++)
         {
         NSString *label = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(IMs, k));
         NSDictionary* instantMessageContent =(NSDictionary*) ABMultiValueCopyValueAtIndex(IMs, k);
         NSString *labelLower = [label lowercaseString];
         
         NSString* username = [instantMessageContent valueForKey:(NSString *)kABPersonInstantMessageUsernameKey];
         NSString* service = [instantMessageContent valueForKey:(NSString *)kABPersonInstantMessageServiceKey];
         if (nil == service)
         {
         service = @"";
         }
         if (nil == username)
         {
         username = @"";
         }
         if ([labelLower isEqualToString:@"home"] || [labelLower isEqualToString:@"住宅"])
         {
         [contactInfo.im addObject:service];
         [contactInfo.im addObject:@"HOME"];
         [contactInfo.im addObject:username];
         }
         else if ([labelLower isEqualToString:@"work"] || [labelLower isEqualToString:@"工作"])
         {
         [contactInfo.im addObject:service];
         [contactInfo.im addObject:@"WORK"];
         [contactInfo.im addObject:username];
         }
         else if ([labelLower isEqualToString:@"other"] || [labelLower isEqualToString:@"其他"])
         {
         [contactInfo.im addObject:service];
         [contactInfo.im addObject:@"OTHER"];
         [contactInfo.im addObject:username];
         }
         else
         {
         [contactInfo.im addObject:service];
         [contactInfo.im addObject:labelLower];
         [contactInfo.im addObject:username];
         }
         
         }
         }
         //  ABRecordCopyValue(person, kABPersonSocialProfileServiceTwitter);
         //  CFIndex socialsCount = ABMultiValueGetCount(socials);
         ABMultiValueRef socials = ABRecordCopyValue(person, kABPersonSocialProfileProperty);
         if (socials)
         {
         for (int k = 0 ; (k<ABMultiValueGetCount(socials)&& k < ABMULTIVALUESUM ) ; k++)
         {
         CFDictionaryRef socialValue = ABMultiValueCopyValueAtIndex(socials, k);
         
         if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceTwitter, 0)==kCFCompareEqualTo)
         {
         NSString *twitterUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
         [contactInfo.server setMultiValue:twitterUsername forKey:@"twitter"];
         }
         else if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceSinaWeibo, 0)==kCFCompareEqualTo)
         {
         NSString *SinaWeiboUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
         [contactInfo.server setMultiValue:SinaWeiboUsername forKey:@"SinaWeibo"];
         }
         else if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceFacebook, 0)==kCFCompareEqualTo)
         {
         NSString *FacebookUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
         [contactInfo.server setMultiValue:FacebookUsername forKey:@"Facebook"];
         }
         else if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceMyspace, 0)==kCFCompareEqualTo)
         {
         NSString *MyspaceUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
         [contactInfo.server setMultiValue:MyspaceUsername forKey:@"Myspace"];
         }
         else if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceLinkedIn, 0)==kCFCompareEqualTo)
         {
         NSString *LinkedInUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
         [contactInfo.server setMultiValue:LinkedInUsername forKey:@"LinkedIn"];
         }
         else if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), kABPersonSocialProfileServiceFlickr, 0)==kCFCompareEqualTo)
         {
         NSString *FlickrInUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
         [contactInfo.server setMultiValue:FlickrInUsername forKey:@"Flickr"];
         }
         else
         {
         NSString *InUsername = (NSString*) CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey);
         [contactInfo.server setMultiValue:InUsername forKey:(NSString *)CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey)];
         }
         CFRelease(socialValue);
         }
         }
         
         ABMultiValueRef related = ABRecordCopyValue(person, kABPersonRelatedNamesProperty);
         for (int y = 0; (y < ABMultiValueGetCount(related) && y < ABMULTIVALUESUM ); y++)
         {
         NSString* relatedLabel = (NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(related, y));
         NSString* relatedContent = (NSString*)ABMultiValueCopyValueAtIndex(related, y);
         if ([relatedLabel isEqualToString:@"mother"] || [relatedLabel isEqualToString:@"母亲"])
         [contactInfo.server setMultiValue:relatedContent forKey:@"mother"];
         //[vcard appendFormat:@"X-RELATED;TYPE=mother:%@\n",relatedContent];
         else if ([relatedLabel isEqualToString:@"father"] || [relatedLabel isEqualToString:@"父亲"])
         [contactInfo.server setMultiValue:relatedContent forKey:@"father"];
         //[vcard appendFormat:@"X-RELATED;TYPE=father:%@\n",relatedContent];
         else if ([relatedLabel isEqualToString:@"parent"] || [relatedLabel isEqualToString:@"父母"])
         [contactInfo.server setMultiValue:relatedContent forKey:@"parent"];
         //[vcard appendFormat:@"X-RELATED;TYPE=parent:%@\n",relatedContent];
         else if ([relatedLabel isEqualToString:@"brother"] || [relatedLabel isEqualToString:@"兄弟"])
         [contactInfo.server setMultiValue:relatedContent forKey:@"brother"];
         //[vcard appendFormat:@"X-RELATED;TYPE=brother:%@\n",relatedContent];
         else if ([relatedLabel isEqualToString:@"sister"] || [relatedLabel isEqualToString:@"姐妹"])
         [contactInfo.server setMultiValue:relatedContent forKey:@"sister"];
         //[vcard appendFormat:@"X-RELATED;TYPE=sister:%@\n",relatedContent];
         else if ([relatedLabel isEqualToString:@"child"] || [relatedLabel isEqualToString:@"子女"])
         [contactInfo.server setMultiValue:relatedContent forKey:@"child"];
         //[vcard appendFormat:@"X-RELATED;TYPE=child:%@\n",relatedContent];
         else if ([relatedLabel isEqualToString:@"friend"] || [relatedLabel isEqualToString:@"朋友"])
         [contactInfo.server setMultiValue:relatedContent forKey:@"friend"];
         else if ([relatedLabel isEqualToString:@"spouse"] || [relatedLabel isEqualToString:@"配偶"])
         [contactInfo.server setMultiValue:relatedContent forKey:@"spouse"];
         else if ([relatedLabel isEqualToString:@"partner"] || [relatedLabel isEqualToString:@"搭档"])
         [contactInfo.server setMultiValue:relatedContent forKey:@"partner"];
         else if ([relatedLabel isEqualToString:@"assistant"] || [relatedLabel isEqualToString:@"助理"])
         [contactInfo.server setMultiValue:relatedContent forKey:@"assistant"];
         else if ([relatedLabel isEqualToString:@"manager"] || [relatedLabel isEqualToString:@"上司"])
         [contactInfo.server setMultiValue:relatedContent forKey:@"manager"];
         else if ([relatedLabel isEqualToString:@"other"] || [relatedLabel isEqualToString:@"其他"])
         [contactInfo.server setMultiValue:relatedContent forKey:@"other"];
         else
         //[vcard appendFormat:@"X-RELATED;TYPE=%@:%@\n",relatedLabel,relatedContent];
         [contactInfo.server setMultiValue:relatedContent forKey:relatedLabel];
         }
         
         NSString *note = (NSString *)ABRecordCopyValue(person, kABPersonNoteProperty);
         if (note)
         {
         [contactInfo.note appendString:[note stringByReplacingOccurrencesOfString: @"\n" withString:@"\r"]];
         NSLog(@"note: %@",note);
         }
         */
        [systemContactArray addObject:contactInfo];
        //[contactInfo release];
    }
    CFRelease(contacts);
    
}
@end
