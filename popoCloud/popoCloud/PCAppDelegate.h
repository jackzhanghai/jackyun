//
//  PCAppDelegate.h
//  popoCloud
//
//  Created by Chen Dongxiao on 11-11-14.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"

#define UMENG_IPHONE_APPKEY @"51788ebb56240b6172009668"
//#define UMENG_IPHONE_APPKEY @"51ad8dc856240ba26b0013a9"
//#define UMENG_IPAD_APPKEY @"51ad8e2956240ba25b0011e1"

@interface UITabBarController2 : UITabBarController

@end

@interface UINavigationController2 : UINavigationController

@end

@class UINavigationController2;

@interface PCAppDelegate : UIResponder <UIApplicationDelegate,UITabBarControllerDelegate,UIAlertViewDelegate>
{
    Reachability* internetReach;
}

//@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain)  UITabBarController2 *tabbarContent;

@property (readonly, retain, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, retain, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, retain, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic, readwrite) BOOL  bNetOffline;
- (void)saveContext;
-(void) loadTabBarController;
@end

