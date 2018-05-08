//
//  AppDelegate.h
//  iOS Example Obj-C
//
//  Created by Hamilton Chapman on 09/09/2016.
//  Copyright © 2016 Eventflit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventflitSwift/EventflitSwift-Swift.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong, readwrite) Eventflit *eventflit;


@end
