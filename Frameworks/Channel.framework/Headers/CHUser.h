//
//  CHUser.h
//  Channel
//
//  Created by Apisit Toompakdee on 11/30/17.
//  Copyright © 2017 Mogohichi, Inc. All rights reserved.
//

#import <Channel/Channel.h>

@interface CHUser : CHBase

@property (nonatomic, strong) NSString* publicID;
@property (nonatomic, strong) NSString* appUserID;
@property (nonatomic, assign) Boolean isActive;
@property (nonatomic, strong) NSDictionary* data;
- (instancetype)initWithJSON:(NSDictionary*)json;


@end

