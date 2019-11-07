//
//  JWPlayerViewController+Public.h
//  Sport1Player
//
//  Created by Oliver Stowell on 12/09/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#ifndef JWPlayerViewController_Public_h
#define JWPlayerViewController_Public_h

#import <JWPlayerPlugin/JWPlayerViewController.h>

@interface JWPlayerViewController (Public)

- (void)dismiss:(NSObject *)sender;
- (void) setCloseButtonConstraints:(UIView *) parentView;

@end

#endif /* JWPlayerViewController_Public_h */
