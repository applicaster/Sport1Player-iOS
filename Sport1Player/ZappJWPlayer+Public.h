//
//  ZappJWPlayer+Public.h
//  Sport1Player
//
//  Created by Oliver Stowell on 30/08/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#ifndef ZappJWPlayer_Public_h
#define ZappJWPlayer_Public_h

#import <JWPlayerPlugin/ZappJWPlayerAdapter.h>

@interface ZappJWPlayerAdapter (Public)

- (void)playInline:(UIViewController *)rootViewController
         container:(UIView *)container
     configuration:(ZPPlayerConfiguration *)configuration
        completion:(void (^)(void))completion;
- (void)playFullScreen:(UIViewController *)rootViewController
         configuration:(ZPPlayerConfiguration *)configuration
            completion:(void (^)(void))completion;

@end


#endif /* ZappJWPlayer_Public_h */
