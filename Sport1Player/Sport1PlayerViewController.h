//
//  Sport1PlayerViewController.h
//  Sport1Player
//
//  Created by Oliver Stowell on 06/11/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

//#import <JWPlayerPlugin/JWPlayerViewController.h>
#import "JWPlayerViewController+Public.h"

NS_ASSUME_NONNULL_BEGIN

@interface Sport1PlayerViewController : JWPlayerViewController
@property IBOutlet UILabel *dateLabelCurrent;
@property IBOutlet UILabel *dateLabelCET;
@property IBOutlet UIStackView *contianerStackView;
@end

NS_ASSUME_NONNULL_END
