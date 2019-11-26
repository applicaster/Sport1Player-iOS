//
//  HTTPClient.h
//  Sport1Player
//
//  Created by Pablo Rueda on 26/11/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HTTPClient <NSObject>

- (void)getStreamTokenFromAPI:(NSString *)authId
                      success:(void (^)(NSString *streamToken))success
                      failure:(void (^)(NSNumber *statusCode))failure;
@end

@interface HTTPClientImplementation : NSObject <HTTPClient>

@end

NS_ASSUME_NONNULL_END
