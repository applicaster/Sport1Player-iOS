//
//  Sport1HTTPClient.h
//  Sport1Player
//
//  Created by Pablo Rueda on 26/11/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSInteger, Sport1HTTPClientErrors){
    Sport1HTTPClientErrorDefault = 0,
    Sport1HTTPClientErrorNoURL,
    Sport1HTTPClientErrorBadParsing,
    Sport1HTTPClientErrorNoJSON
};

@protocol Sport1HTTPClient <NSObject>

- (instancetype)initWithConfigurationJSON:(NSDictionary*)configurationJSON;

- (void)getStreamTokenFromAPI:(NSString *)authId success:(void (^)(NSString *streamToken))success
                      failure:(void (^)(NSNumber *statusCode))failure;

- (void)livestreamEPGWithSuccess:(void (^)(NSDictionary *livestreamEPG))success failure:(void (^)(NSNumber *errorCode))failure;

@end

@interface Sport1HTTPClientImplementation : NSObject <Sport1HTTPClient>

@end

NS_ASSUME_NONNULL_END
