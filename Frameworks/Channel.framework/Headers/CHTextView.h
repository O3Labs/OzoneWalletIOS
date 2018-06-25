//
//  CHTextView.h
//  Channel
//
//  Created by Apisit Toompakdee on 12/18/16.
//  Copyright © 2016 Mogohichi, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CHTextViewDelegate <NSObject>

- (void)textView:(id _Nonnull)textView didType:(NSString* _Nonnull)text;

- (void)textViewDidBeginEditing:(id _Nonnull)textView;

@end

@interface CHTextView : UITextView<UITextViewDelegate>

@property (nonatomic, nullable) id<CHTextViewDelegate> textViewDelegate;

@end
