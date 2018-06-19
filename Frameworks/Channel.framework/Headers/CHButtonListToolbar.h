//
//  CHButtonListToolbar.h
//  Channel
//
//  Created by Apisit Toompakdee on 3/22/17.
//  Copyright © 2017 Mogohichi, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHButton.h"

@protocol CHButtonListToolbarDelegate <NSObject>

- (void)buttonListToolbar:(id _Nonnull)butonListToolbar didTapButton:(CHButton* _Nonnull)sender;

@end

@interface CHButtonListToolbar : UIToolbar

@property (nonatomic, nullable) id<CHButtonListToolbarDelegate> toolbarDelegate;
@property (nonatomic, nonnull) NSArray* buttons;

@end
