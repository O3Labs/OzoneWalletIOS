//
//  CHCardTypeImageTableViewCell.h
//  Channel
//
//  Created by Apisit Toompakdee on 3/11/17.
//  Copyright © 2017 Mogohichi, Inc. All rights reserved.
//

#import "CHCardTableViewCell.h"

@protocol CHCardTypeImageTableViewCellDelegate <NSObject>

- (void)cardTypeImageTableViewCell:(UITableViewCell* _Nonnull)cell imageView:(UIImageView* _Nonnull)imageView message:(CHMessage* _Nonnull)message;

@end

@interface CHCardTypeImageTableViewCell : CHCardTableViewCell

@property (strong, nonatomic, nullable) IBOutlet UIImageView *payloadImageView;
@property (nonatomic, assign, nullable) id<CHCardTypeImageTableViewCellDelegate> delegate;


@end
