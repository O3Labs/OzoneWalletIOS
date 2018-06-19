//
//  CHApplication.h
//  Channel
//
//  Created by Apisit Toompakdee on 4/3/17.
//  Copyright © 2017 Mogohichi, Inc. All rights reserved.
//

#import "CHBase.h"

@interface CHApplicationSettings : CHBase

@property (nonatomic) NSDictionary* publicChat;

- (instancetype)initWithJSON:(NSDictionary*)json;

@end

@interface CHApplication : CHBase

@property (nonatomic) NSString* name;
@property (nonatomic) CHApplicationSettings* settings;

- (instancetype)initWithJSON:(NSDictionary*)json;

@end
