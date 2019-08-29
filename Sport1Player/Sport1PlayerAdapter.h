//
//  Sport1PlayerAdapter.h
//  Sport1Player
//
//  Created by Oliver Stowell on 28/08/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import <JWPlayerPlugin/JWPlayerPlugin.h>
#import <JWPlayerPlugin/ZappJWPlayerAdapter.h>

NS_ASSUME_NONNULL_BEGIN

@interface Sport1PlayerAdapter : ZappJWPlayerAdapter

- (void)playInline:(UIViewController *)rootViewController
         container:(UIView *)container
     configuration:(ZPPlayerConfiguration *)configuration
        completion:(void (^)(void))completion;
- (void)playFullScreen:(UIViewController *)rootViewController
         configuration:(ZPPlayerConfiguration *)configuration
            completion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
