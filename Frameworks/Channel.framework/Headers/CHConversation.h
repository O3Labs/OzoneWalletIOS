//
//  CHConversation.h
//  Channel
//
//  Created by Apisit Toompakdee on 11/28/17.
//  Copyright © 2017 Mogohichi, Inc. All rights reserved.
//

#import "CHBase.h"

@class CHThread;
@class CHMessage;
@class CHUser;

@interface CHConversation : CHBase

@property (nonatomic, strong) CHThread* _Nonnull thread;
@property (nonatomic, strong) CHMessage* _Nullable latestMessage;
@property (nonatomic, strong) NSArray<CHUser*>* _Nullable participants;
@property (nonatomic, assign) Boolean isAccepted;

- (instancetype _Nonnull )initWithJSON:(NSDictionary*_Nullable)json;

@end
