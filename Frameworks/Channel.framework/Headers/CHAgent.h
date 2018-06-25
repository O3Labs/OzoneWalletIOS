//
//  CHAgent.h
//  Channel
//
//  Created by Apisit Toompakdee on 4/3/17.
//  Copyright © 2017 Mogohichi, Inc. All rights reserved.
//

#import "CHBase.h"

@interface CHAgent : CHBase

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* imageUrl;

- (instancetype)initWithJSON:(NSDictionary*)json;
@end
