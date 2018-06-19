//
//  CHCardWebViewTableViewCell.h
//  Channel
//
//  Created by Apisit Toompakdee on 3/20/17.
//  Copyright © 2017 Mogohichi, Inc. All rights reserved.
//

#import "CHCardTableViewCell.h"

@interface CHCardWebViewTableViewCell : CHCardTableViewCell

@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UIView *containerView;

@end
