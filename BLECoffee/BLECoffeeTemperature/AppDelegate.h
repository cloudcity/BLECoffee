//
//  AppDelegate.h
//  BLETemperatureReader
//
//  Created by Evan Stone on 8/7/15.
//  Copyright (c) 2015 Cloud City. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, assign) ApplicationModes activeMode;

@property (nonatomic, assign, getter=isActive) BOOL active;
@property (nonatomic, assign, getter=isBackgrounded) BOOL backgrounded;

@end

