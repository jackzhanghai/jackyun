//
//  PCUtilityGetDeviceInfo.m
//  popoCloud
//
//  Created by xy  on 13-8-26.
//
//

#import "PCUtilityGetDeviceInfo.h"
#include <sys/sysctl.h>

@implementation PCUtilityGetDeviceInfo

/**
 *  获取设备名字
 */
+ (NSString *)deviceModel
{
    
#warning Add new device model
    
    NSString *deviceModel = nil;
    
    char buffer[32];
    size_t length = sizeof(buffer);
    if (sysctlbyname("hw.machine", &buffer, &length, NULL, 0) == 0) {
        NSString *platform = [[NSString alloc] initWithCString:buffer encoding:NSASCIIStringEncoding];
        if ([platform isEqualToString:@"iPhone1,1"])        deviceModel = @"iPhone";
        else if ([platform isEqualToString:@"iPhone1,2"])   deviceModel = @"iPhone3G";
        else if ([platform isEqualToString:@"iPhone2,1"])   deviceModel = @"iPhone3GS";
        else if ([platform isEqualToString:@"iPhone3,1"])   deviceModel = @"iPhone4";       //GSM
        else if ([platform isEqualToString:@"iPhone3,2"])   deviceModel = @"iPhone4";       //GSM 8G
        else if ([platform isEqualToString:@"iPhone3,3"])   deviceModel = @"iPhone4";       //CDMA
        else if ([platform isEqualToString:@"iPhone4,1"])   deviceModel = @"iPhone4S";
        else if ([platform isEqualToString:@"iPhone5,1"])   deviceModel = @"iPhone5";       //GSM
        else if ([platform isEqualToString:@"iPhone5,2"])   deviceModel = @"iPhone5";       //Global
        else if ([platform isEqualToString:@"iPhone5,3"])   deviceModel = @"iPhone5c";      //GSM
        else if ([platform isEqualToString:@"iPhone5,4"])   deviceModel = @"iPhone5c";      //Global
        else if ([platform isEqualToString:@"iPhone6,1"])   deviceModel = @"iPhone5s";      //GSM;
        else if ([platform isEqualToString:@"iPhone6,2"])   deviceModel = @"iPhone5s";      //Global

        else if ([platform isEqualToString:@"iPod1,1"])     deviceModel = @"iPodTouch";
        else if ([platform isEqualToString:@"iPod2,1"])     deviceModel = @"iPodTouch2";
        else if ([platform isEqualToString:@"iPod3,1"])     deviceModel = @"iPodTouch3";
        else if ([platform isEqualToString:@"iPod4,1"])     deviceModel = @"iPodTouch4";
        else if ([platform isEqualToString:@"iPod5,1"])     deviceModel = @"iPodTouch5";
        
        else if ([platform isEqualToString:@"iPad1,1"])     deviceModel = @"iPad";
        else if ([platform isEqualToString:@"iPad2,1"])     deviceModel = @"iPad2";            //Wi-Fi only
        else if ([platform isEqualToString:@"iPad2,2"])     deviceModel = @"iPad2";            //GSM
        else if ([platform isEqualToString:@"iPad2,3"])     deviceModel = @"iPad2";            //CDMA
        else if ([platform isEqualToString:@"iPad2,4"])     deviceModel = @"iPad2";            //Re-released Wi-Fi only
        else if ([platform isEqualToString:@"iPad2,5"])     deviceModel = @"iPadMini";         //Wi-Fi only
        else if ([platform isEqualToString:@"iPad2,6"])     deviceModel = @"iPadMini";         //GSM
        else if ([platform isEqualToString:@"iPad2,7"])     deviceModel = @"iPadMini";         //Global
        else if ([platform isEqualToString:@"iPad3,1"])     deviceModel = @"iPad3";            //Wi-Fi only
        else if ([platform isEqualToString:@"iPad3,2"])     deviceModel = @"iPad3";            //CDMA
        else if ([platform isEqualToString:@"iPad3,3"])     deviceModel = @"iPad3";            //GSM
        else if ([platform isEqualToString:@"iPad3,4"])     deviceModel = @"iPad4";            //Wi-Fi only
        else if ([platform isEqualToString:@"iPad3,5"])     deviceModel = @"iPad4";            //GSM
        else if ([platform isEqualToString:@"iPad3,6"])     deviceModel = @"iPad4";            //Global
        else if ([platform isEqualToString:@"iPad4,1"])     deviceModel = @"iPadAir";          //Wi-Fi only
        else if ([platform isEqualToString:@"iPad4,2"])     deviceModel = @"iPadAir";          //Cellular
        else if ([platform isEqualToString:@"iPad4,4"])     deviceModel = @"iPadMini2";        //Wi-Fi only
        else if ([platform isEqualToString:@"iPad4,5"])     deviceModel = @"iPadMini2";        //Cellular
        else if ([platform isEqualToString:@"i386"])        deviceModel = @"Simulator";
        else if ([platform isEqualToString:@"x86_64"])      deviceModel = @"Simulator";
        else deviceModel = [[platform retain] autorelease];
        [platform release];
    }
    
    return deviceModel;
}


@end
