//
//  DeviceInfo.m
//  popoCloud
//
//  Created by leijun on 13-9-13.
//
//

#import "DeviceInfo.h"
#import "PCUtility.h"

@implementation DeviceInfo
@synthesize hardwareVersion;
@synthesize _id;
@synthesize jid;
@synthesize localIP;
@synthesize localPort;
@synthesize serNum;
@synthesize natIP;
@synthesize natPort;
@synthesize nickName;
@synthesize versionCode;
@synthesize online;
@synthesize isUpgrading;
@synthesize type;

-(id)initWithDic:(NSDictionary *)dic
{
    self = [super init];
    if (self)
    {
        self.hardwareVersion = [dic objectForKey:@"hardwareVersion"];
        self._id = [dic objectForKey:@"id"];
        self.jid = [dic objectForKey:@"jid"];
        self.localIP = [dic objectForKey:@"localIP"];
        self.localPort = [dic objectForKey:@"localPort"];
        self.serNum = [dic objectForKey:@"name"];//序列号
        self.natIP = [dic objectForKey:@"natIP"];
        self.natPort = [dic objectForKey:@"natPort"];
        if ([dic objectForKey:@"nickName"]) {
            
            self.nickName = [PCUtility unescapeHTML:[dic objectForKey:@"nickName"]];
        }
        if ([dic objectForKey:@"nickname"]) {
            self.nickName = [PCUtility unescapeHTML:[dic objectForKey:@"nickname"]];
        }
        
        self.type = [dic objectForKey:@"type"];
        self.versionCode = [dic objectForKey:@"versionCode"];
        self.online = [[dic objectForKey:@"online"] boolValue];
        
        NSString *strStatus = [dic objectForKey:@"status"];
        if ([strStatus isEqualToString:@"upgrading"]) {
            self.isUpgrading = YES;
        }
    }
    return self;
}
-(void)dealloc
{
    self.hardwareVersion = nil;
    self._id = nil;
    self.jid = nil;
    self.localIP = nil;
    self.localPort = nil;
    self.serNum = nil;
    self.natIP = nil;
    self.natPort = nil;
    self.nickName = nil;
    self.versionCode = nil;
    self.type = nil;
    [super dealloc];
}
@end
