//
//  CHCardTableViewCell.h
//  Channel
//
//  Created by Apisit Toompakdee on 3/11/17.
//  Copyright © 2017 Mogohichi, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHMessage.h"

@interface CHCardTableViewCell : UITableViewCell
@property (strong, nonatomic, nonnull) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic, nonnull) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic, nullable) IBOutlet UIImageView *profileImageView;

@property (nonatomic, nonnull) CHMessage* message;
- (void)setupView:(CHMessage* _Nonnull)data;

@end
