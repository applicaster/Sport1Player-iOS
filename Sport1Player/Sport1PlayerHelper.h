//
//  Sport1PlayerHelper.h
//  Sport1Player
//
//  Created by Pablo Rueda on 26/11/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
@import ZappPlugins;
#import "Sport1HTTPClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface Sport1PlayerHelper : NSObject

- (instancetype)initWithHTTPClient:(id<Sport1HTTPClient>)httpClient;

/**
 If the playable is a livestream and the 'auth_id' is defined in the model, it calls a service to retrieve the final URL, overriding the playable model with it.

 @param current Current playable model.
 @param completion Completion block with the playable model with the final URL.
 */
- (void)amendIfLivestreamModified:(NSObject <ZPPlayable>*)current
                         callback:(void (^)(NSObject <ZPPlayable>* amended))completion;

@end

NS_ASSUME_NONNULL_END
