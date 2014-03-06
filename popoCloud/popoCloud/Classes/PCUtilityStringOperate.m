//
//  PCUtilityStringOperate.m
//  popoCloud
//
//  Created by xy  on 13-8-26.
//
//

#import "PCUtilityStringOperate.h"

@implementation PCUtilityStringOperate

/**
 *   日期比较
 */

+ (BOOL)isSameDay:(NSDate*)fistDate second:(NSDate*)secondDate
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    
    NSDateComponents* firstComp = [calendar components:unitFlags fromDate:fistDate];
    NSDateComponents* secondComp = [calendar components:unitFlags fromDate:secondDate];
    
    return [firstComp day] == [secondComp day] && [firstComp month] == [secondComp month] && [firstComp year]  == [secondComp year];
}

/**
 *   检查sn
 */
+ (BOOL)checkValidSerialNumber:(NSString *)sn
{
    NSString *snRegex = @"[0-9a-fA-F]{16}";
    NSPredicate *snTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", snRegex];
    return [snTest evaluateWithObject:sn];
}

/**
 *   检查是否是有效的手机号码
 */
+ (BOOL)checkValidMobileNumber:(NSString *)mobileNum
{
    NSString *mobileRegex = @"^(\\+86)*1[3458]\\d{9}$";
    NSPredicate *regexTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", mobileRegex];
    return [regexTest evaluateWithObject:mobileNum];
}

/**
 *   检查是否是有效的密码
 */
+ (BOOL)checkValidPassword:(NSString *)password
{
    NSString *passwordRegex = @"[0-9a-zA-Z]{6,16}";
    NSPredicate *passwordTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", passwordRegex];
    return [passwordTest evaluateWithObject:password];
}

/**
 *   检查是否是有效的email
 */
+ (BOOL)checkValidEmail:(NSString*)emailAdderss
{
    if (( emailAdderss == nil ) || ([emailAdderss length] < 1 ))
    {
        return NO;
    }

    NSString *expression = @"^[a-zA-Z0-9][\\w\\.\\-]*[a-zA-Z0-9]+@[a-zA-Z0-9][a-zA-Z0-9\\.\\-]*[a-zA-Z0-9]\\.[a-zA-Z][a-zA-Z\\.]*[a-zA-Z]$";
    NSError *error = NULL;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:emailAdderss options:0 range:NSMakeRange(0, [emailAdderss length])];
    
    if (match){
        return YES;
    }else{
        return NO;;
    }
}

/**
 *  格式化日期
 */
+ (NSString *)formatDate:(NSDate *)date formatString:(NSString*)formatString
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:formatString];
    NSString *ret = [dateFormat stringFromDate:date];
    [dateFormat release];
    return ret;
}

/**
 *  格式化时间
 */
+ (NSString*) formatTime:(float)time formatString:(NSString*)formatString
{
    NSDate *nd = [NSDate dateWithTimeIntervalSince1970:time];
    return [PCUtilityStringOperate formatDate:nd formatString:formatString];
}

/**
 *  格式化时间
 */
+ (NSDate*) formatTimeString:(NSString*)time formatString:(NSString*)formatString
{
    NSDate *nd;
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [dateFormat setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]autorelease]];
    [dateFormat setDateFormat:formatString];
    nd = [dateFormat dateFromString:time];
    [dateFormat release];
    return nd;
}

+ (NSString *)encodeToPercentEscapeString: (NSString *)input
{
    //stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding
    
    // Encode all the reserved characters, per RFC 3986
    // (<http://www.ietf.org/rfc/rfc3986.txt>)
    CFStringRef str = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)input,
                                                              NULL,
                                                              (CFStringRef)@" !*'();:@&=+$,/?%#[]",
                                                              kCFStringEncodingUTF8);
    NSString *outputStr = [(NSString*)str copy];
    if (str)
    {
        CFRelease(str);
    }
    
    return [outputStr autorelease];
}

+ (NSString *)decodeFromPercentEscapeString: (NSString *) input
{
    NSMutableString *outputStr = [NSMutableString stringWithString:input];
    [outputStr replaceOccurrencesOfString:@"+"
                               withString:@" "
                                  options:NSLiteralSearch
                                    range:NSMakeRange(0, [outputStr length])];
    
    return [outputStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}
@end
