//
//  UIApplicationDelegate+Channel.h
//  Channel
//
//  Created by Apisit Toompakdee on 4/22/17.
//  Copyright © 2017 Mogohichi, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface ChannelAppDelegate : NSObject

- (void) setChannelDelegate:(id<UIApplicationDelegate>)delegate;

@end
