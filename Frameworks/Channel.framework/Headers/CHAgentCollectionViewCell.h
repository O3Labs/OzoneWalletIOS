//
//  CHAgentCollectionViewCell.h
//  Channel
//
//  Created by Apisit Toompakdee on 4/3/17.
//  Copyright © 2017 Mogohichi, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHCircularImageView.h"
#import "CHAgent.h"

@interface CHAgentCollectionViewCell : UICollectionViewCell
@property (strong, nonatomic) IBOutlet CHCircularImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) CHAgent* agent;

@end
