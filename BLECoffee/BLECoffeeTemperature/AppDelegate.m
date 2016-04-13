//
//  AppDelegate.m
//  BLETemperatureReader
//
//  Created by Evan Stone on 8/7/15.
//  Copyright (c) 2015 Cloud City. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)logAppStatus {
    NSLog(@"****** ACTIVE: %@ | BACKGROUNDED: %@", self.isActive ? @"YES" : @"NO", self.isBackgrounded ? @"YES" : @"NO");
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    NSLog(@"*** AppDelegate:didFinishLaunchingWithOptions");
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    self.activeMode = ApplicationDeactivated;
    self.active = NO;
    NSLog(@"*** AppDelegate:applicationWillResignActive");
    [self logAppStatus];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    self.activeMode = ApplicationBackgrounded;
    self.backgrounded = YES;
    NSLog(@"*** AppDelegate:applicationDidEnterBackground");
    [self logAppStatus];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    self.backgrounded = NO;
    NSLog(@"*** AppDelegate:applicationWillEnterForeground");
    [self logAppStatus];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    self.active = YES;
    NSLog(@"*** AppDelegate:applicationDidBecomeActive");
    [self logAppStatus];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    self.active = NO;
    self.backgrounded = YES;
    NSLog(@"*** AppDelegate:applicationWillTerminate");
    [self logAppStatus];
}

@end
