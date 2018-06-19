//
//  CHAPI.h
//  Channel
//
//  Created by Apisit Toompakdee on 1/30/17.
//  Copyright © 2017 Mogohichi, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHBlock.h"




@interface CHAPI : NSObject

typedef NS_ENUM(NSUInteger,METHOD){
    GET = 0 ,
    POST = 1,
    PUT = 2,
    DELETE = 3,
};


+ (void)get:(NSString*)path params:(NSDictionary*)params block:(Completion)block;
+ (void)post:(NSString*)path params:(NSDictionary*)params block:(Completion)block;
+ (void)put:(NSString*)path params:(NSDictionary*)params block:(Completion)block;
+ (void)del:(NSString*)path params:(NSDictionary*)params block:(Completion)block;

@end
