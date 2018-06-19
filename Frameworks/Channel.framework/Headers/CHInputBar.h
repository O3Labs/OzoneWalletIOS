//
//  CHInputBar.h
//  Channel
//
//  Created by Apisit Toompakdee on 1/7/17.
//  Copyright © 2017 Mogohichi, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHTextView.h"
#import "CHMessage.h"

@protocol CHInputBarDelegate <NSObject>

- (void)inputBar:(id _Nonnull)inputBar didTapLeftButton:(id _Nullable)sender;
- (void)inputBar:(id _Nonnull)inputBar didTapSend:(CHMessage* _Nonnull)message;
- (void)inputBar:(id _Nonnull)inputBar didBegineEditing:(id _Nullable)sender;
- (void)inputBar:(id _Nonnull)inputBar didStartTyping:(id _Nullable)sender;

@end

@interface CHInputBar : UIToolbar<CHTextViewDelegate>

@property (nonatomic, nonnull) UIBarButtonItem *rightButton;
@property (nonatomic, nonnull) CHTextView *textView;
@property (nonatomic, nullable) UIBarButtonItem *leftButton;

@property (nonatomic, nullable) id<CHInputBarDelegate> inputBarDelegate;

- (void)resignTextViewResponder;

@end
