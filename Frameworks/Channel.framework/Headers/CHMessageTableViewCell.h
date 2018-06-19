//
//  CHMessageTableViewCell.h
//  Channel
//
//  Created by Apisit Toompakdee on 1/8/17.
//  Copyright © 2017 Mogohichi, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHMessage.h"
#import "CHLabel.h"
#import "CHApplication.h"

@interface CHMessageTableViewCell : UITableViewCell
@property (strong, nonatomic, nonnull) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic, nullable) IBOutlet CHLabel *messageLabel;
@property (strong, nonatomic, nullable) IBOutlet UILabel *timeLabel;

@property (strong, nonatomic,nonnull) IBOutlet UIImageView *profileImageView;

@property (nonatomic, nonnull) CHMessage* message;
@property (nonatomic, nonnull) CHApplication* application;
@end
