//
//  CHConfiguration.h
//  Channel
//
//  Created by Apisit Toompakdee on 12/18/16.
//  Copyright © 2016 Mogohichi, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CHConfiguration : NSObject<NSCopying>

+ (instancetype)sharedConfiguration;

@property(nonatomic, copy) NSString *applicationId;

@end
