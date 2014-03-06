//
//  PCCheckUpdate.m
//  popoCloud
//
//  Created by Chen Dongxiao on 11-11-16.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "PCCheckUpdate.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#import "Constants.h"
#import "PCAppDelegate.h"
#import "ScreenLockViewController.h"

@implementation PCCheckUpdate

@synthesize isChecking;
@synthesize delegate;
@synthesize isUpdate;
@synthesize isForceUpdate;
@synthesize version;
@synthesize updateMsg;

static PCCheckUpdate *g_sharedInstance = nil;

+ (PCCheckUpdate *)sharedInstance
{
    if (g_sharedInstance == nil)
    {
        g_sharedInstance = [[PCCheckUpdate alloc] init];
    }
    
    return g_sharedInstance;
}

- (void) dealloc
{
	[version release];
    [updateMsg release];
    [data release];
	[super dealloc];
}

- (BOOL) checkUpdateSynchronous
{
    self.isChecking = YES;
    self.isUpdate = NO;
    self.delegate = nil;
    
    NSString* url = [NSString stringWithFormat:@"http://%@/update?os=ios&lang=cn&appid=478792524&version=%@",
                     UPGRADE_SERVER_HOST,
                     [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    NSLog(@"checkUpdate: %@", url);
    
    NSURL *nsUrl = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:nsUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:3.0f];
    
    NSHTTPURLResponse *response = nil;
    NSError *err = nil;
    NSData *resultData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    [request release];
    
    if (err) {
        DLogError(@"checkUpdate %@", err);
        self.isChecking = NO;
        return NO;
    }
    
    NSInteger rc = [response statusCode];
    if (rc != 200) {
        DLogError(@"checkUpdate status: %d %@", rc, [NSHTTPURLResponse localizedStringForStatusCode:rc]);
        self.isChecking = NO;
        return NO;
    }
    
    NSString *ret = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    NSLog(@"checkUpdate return: %@", ret);
    [ret release];
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:resultData];
    [parser setDelegate:self];
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
    if (![parser parse]) {
        DLogError(@"checkUpdate parse %@", [parser parserError]);
    }
    [parser release];
    
    if (self.isUpdate)
    {
        if ([[PCSettings sharedSettings] screenLock])
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUpdateAlert) name:@"ScreenLockCorrect" object:nil];
        }
        else
        {
            [self showUpdateAlert];
        }
    }
    else
    {
        self.isChecking = NO;
    }
    
    return self.isUpdate;
}

- (void) checkUpdate:(id)_delegate {
    self.delegate = _delegate;
    
    if (self.isChecking) return;
    
    self.isChecking = YES;
    self.isUpdate = NO;
    
    NSString* url = [NSString stringWithFormat:@"http://%@/update?os=ios&lang=cn&appid=478792524&version=%@",
                     UPGRADE_SERVER_HOST,
                     [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    NSURL *nsUrl = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:nsUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0f];
    
    NSLog(@"checkUpdate:%@", url);
    
    [NSURLConnection connectionWithRequest:request delegate:self];
    [request release];
    return;
}


-(void)connection:(NSURLConnection *)_connection didReceiveResponse:(NSURLResponse *)response {
    if (data == nil) {
        data = [[NSMutableData data] retain];
    }
    else {
        [data setLength:0];
    }
    
    NSInteger rc = [(NSHTTPURLResponse*)response statusCode];
    NSLog(@"status code: %d", rc);
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)incomingData {
    
    [data appendData:incomingData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@", ret);
    [ret release];
    
     NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
    [parser parse];
    [parser release];
    
    if (self.isUpdate)
    {
        if ([[PCSettings sharedSettings] screenLock] && [[ScreenLockViewController sharedLock] isOnScreen])
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUpdateAlert) name:@"ScreenLockCorrect" object:nil];
        }
        else
        {
            [self showUpdateAlert];
        }
    }
    else
    {
        self.isChecking = NO;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    DTLogWarn(@"PCCheckUpdate", @"Fail with error: %@", [error localizedDescription]);
    if (delegate && [delegate respondsToSelector:@selector(checkUpadteFailed:withError:)]) {
        [delegate checkUpadteFailed:self withError:error];
    }
    
    self.isChecking = NO;
}

//--------------------------------------------------------------
-(void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    NSLog(@"%@, %@", elementName, attributeDict); 
    if ([elementName compare:@"updatecheck"] == NSOrderedSame) {
        NSString *status = [attributeDict objectForKey:@"status"];
        if (status && ([status compare:@"noupdate"]  == NSOrderedSame)) {
            self.isUpdate = NO;
        }
        else {
            self.isUpdate = YES;
            self.isForceUpdate = [[attributeDict objectForKey:@"isForce"] boolValue];
            self.version = [attributeDict objectForKey:@"version"];
            self.updateMsg = [attributeDict objectForKey:@"updateMsg"];
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (delegate && [delegate respondsToSelector:@selector(checkUpadteFinish:isUpdate:)]) {
        [delegate checkUpadteFinish:self isUpdate:self.isUpdate];
    }
    else if (!self.isForceUpdate) {
        NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:@"ingoreUpgradeDate"];
        if (date != nil && [PCUtilityStringOperate isSameDay:date second:[NSDate date]]) {
            NSLog(@"Ingore update");
            self.isUpdate = NO;
        }
    }
}

-(void)showUpdateAlert
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ScreenLockCorrect" object:nil];
    if (IS_IOS7)
    {
        TSAlertView *view = [[TSAlertView alloc] initWithTitle:@"版本更新啦！"
                                                       message:self.updateMsg
                                                      delegate:self
                                             cancelButtonTitle:(self.isForceUpdate ? @"退出应用" : @"忽略")
                                             otherButtonTitles:(self.isForceUpdate ? @"立即升级" : @"去升级"), nil];
        [view show];
        [view release];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"版本更新啦！"
                                                            message:self.updateMsg
                                                           delegate:self
                                                  cancelButtonTitle:(self.isForceUpdate ? @"退出应用" : @"忽略")
                                                  otherButtonTitles:(self.isForceUpdate ? @"立即升级" : @"去升级"), nil];
        [alertView show];
        [alertView release];
    }
}

- (void)willPresentAlertView:(UIAlertView *)alertView // before animation and showing view
{
    for (UIView * view in alertView.subviews)
    {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel* label = (UILabel*)view;
            if (![label.text isEqualToString:@"版本更新啦！"]) {
                label.textAlignment = UITextAlignmentLeft;
                break;
            }
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        if (self.isForceUpdate) {
            exit(1);
        }
        else {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"ingoreUpgradeDate"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            self.isUpdate = NO;
            self.isChecking = NO;
            
            if (delegate && [delegate respondsToSelector:@selector(checkUpadteFinish:)]) {
                [delegate checkUpadteFinish:self];
            }
        }
    }
    else {
        NSString *webLink = @"https://itunes.apple.com/cn/app/pao-pao-yun/id478792524?mt=8";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:webLink]];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"版本更新啦！"
                                                            message:self.updateMsg
                                                           delegate:self
                                                  cancelButtonTitle:(self.isForceUpdate ? @"退出应用" : @"忽略")
                                                  otherButtonTitles:(self.isForceUpdate ? @"立即升级" : @"去升级"), nil];
        [alertView show];
        [alertView release];
    }
}
- (void)tsAlertView:(TSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex)
    {
        if (self.isForceUpdate)
        {
            exit(1);
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"ingoreUpgradeDate"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            self.isUpdate = NO;
            self.isChecking = NO;
            
            if (delegate && [delegate respondsToSelector:@selector(checkUpadteFinish:)])
            {
                [delegate checkUpadteFinish:self];
            }
        }
    }
    else
    {
        NSString *webLink = @"https://itunes.apple.com/cn/app/pao-pao-yun/id478792524?mt=8";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:webLink]];
        TSAlertView *view = [[TSAlertView alloc] initWithTitle:@"版本更新啦！"
                                                       message:self.updateMsg
                                                      delegate:self
                                             cancelButtonTitle:(self.isForceUpdate ? @"退出应用" : @"忽略")
                                             otherButtonTitles:(self.isForceUpdate ? @"立即升级" : @"去升级"), nil];
        [view show];
        [view release];
    }

}

@end
