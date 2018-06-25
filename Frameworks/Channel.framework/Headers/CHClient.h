//
//  CHClient.h
//  Channel
//
//  Created by Apisit Toompakdee on 1/26/17.
//  Copyright © 2017 Mogohichi, Inc. All rights reserved.
//

#import <Channel/Channel.h>
#import "CHAPI.h"
#import "CHThread.h"
#import "CHMessage.h"
#import "CHNotification.h"
#import "CHApplication.h"
#import "CHAgent.h"
#import "CHTopic.h"
#import "CHConversation.h"
#import "CHUser.h"

@class CHClient;
@class CHConversation;

@protocol CHClientDelegate <NSObject>

- (void)client:(CHClient*)client messageFromServer:(CHMessage*)message;

@end

typedef void (^DidCheckNewMessages)(NSInteger numberOfNewMesages);
typedef void (^DidConnectClient)(NSError* error);
typedef void (^DidLoadActiveThread)(CHThread* thread,NSError* error);
typedef void (^DidSendMessage)(CHThread* thread,CHMessage* sentMessage,NSError* error);
typedef void (^DidLoadMessages)(CHThread* thread, NSArray<CHMessage*>* messages,NSError* error);
typedef void (^DidFinishUploadImage)(NSURL* imageURL, NSError* error);
typedef void (^DidGetUpdateFromServer)();
typedef void (^DidLoadCardTemplate)(NSString* templateString);
typedef void (^DidGetApplicationInfo) (CHApplication* application, NSArray<CHAgent *>* agents);
typedef void (^DidCheckNotification) (CHNotification* notification, NSError* error);
typedef void (^DidLoadSubscribedTopics) (NSArray<CHTopic*>* topics, NSError* error);
typedef void (^DidSubscribeToTopic) (CHTopic* topics, NSError* error);
typedef void (^DidUnsubscribeFromTopic) (CHTopic* topics, NSError* error);

typedef void (^DidSearchUser) (CHUser* user, NSError* error);
typedef void (^DidLoadConversations) (NSArray<CHConversation*>* conversations, NSError* error);
typedef void (^DidLoadConversationThread) (CHThread* thread, NSError* error);
typedef void (^DidStartConversationThread) (CHThread* thread, NSError* error);
typedef void (^DidJoinConversationThread) (NSError* error);
typedef void (^DidLeaveConversationThread) (NSError* error);


@interface CHClient : CHBase

@property (nonatomic, strong) NSString* clientID;
@property (nonatomic, strong) NSString* userID;
@property (nonatomic, strong) NSDictionary* userData;
@property (nonatomic) id<CHClientDelegate> delegate;

+(void)connectClientwithUserID:(NSString*)userID userData:(NSDictionary*)userData block:(DidConnectClient)block;
+ (void)connectClient:(DidConnectClient)block;

+ (CHClient*)currentClient;

-(void)updateClientDataWithUserID:(NSString*)userID userData:(NSDictionary*)userData block:(DidConnectClient)block;

- (void)applicationInfo:(DidGetApplicationInfo)block;

- (void)sendMessage:(CHMessage*)message block:(DidSendMessage)block;
- (void)activeThread:(DidLoadActiveThread)block;
- (void)loadMoreMessage:(CHThread*)thread block:(DidLoadMessages)block;

- (void)startTyping;

- (void)subscribeUpdateFromServerWithDelegate:(id<CHClientDelegate>)delegate;

- (void)subscribeUpdateFromServerWithNSNotification;

- (void)unsubscribe;
- (void)uploadImage:(UIImage*)image block:(DidFinishUploadImage)block;

- (void)checkNewMessages:(DidCheckNewMessages)block;

- (void)updateActiveStatus:(Boolean)active;

- (void)loadCardTemplate:(CHCardPayloadTemplate*)payload block:(DidLoadCardTemplate)block;

- (void)checkNewNotification:(DidCheckNotification)block;

- (void)postbackNotification:(CHNotification*)notification button:(CHNotificationButton*)button;

- (void)presentWebViewWithURL:(NSURL*)url inViewController:(UIViewController*)viewController;

- (void)saveDeviceToken:(NSData*)deviceToken;

- (void)markOpenFromPushNotification:(NSString*)notificationPublicID;

- (void)pushNotificationEnabled:(BOOL)enabled;

- (void)appendTags:(NSDictionary*)tags;

- (void)subscribeToTopic:(NSString*)topic block:(DidSubscribeToTopic)block;

- (void)unsubscribeFromTopic:(NSString*)topic block:(DidUnsubscribeFromTopic)block;

- (void)subscribedTopicsWithBlock:(DidLoadSubscribedTopics)block;


//New APIs added for User <--> User communication
- (void)searchUserByID:(NSString*)query block:(DidSearchUser)block;
- (void)conversations:(DidLoadConversations)block;
- (void)sendMessage:(CHMessage*)message thread:(CHThread*)thread block:(DidSendMessage)block;
- (void)startConversation:(NSArray<CHUser*>*)users block:(DidStartConversationThread)block;
- (void)loadConversationThread:(CHThread*)thread block:(DidLoadConversationThread)block;
- (void)joinThread:(CHThread*)thread block:(DidJoinConversationThread)block;
- (void)leaveThread:(CHThread*)thread block:(DidLeaveConversationThread)block;
- (void)subscribeToThreadUpdate:(CHThread*)thread;

@end
