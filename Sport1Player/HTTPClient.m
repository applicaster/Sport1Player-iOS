//
//  HTTPClient.m
//  Sport1Player
//
//  Created by Pablo Rueda on 26/11/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

@import ZappLoginPluginsSDK;
#import "HTTPClient.h"

@implementation HTTPClientImplementation

- (void)getStreamTokenFromAPI:(NSString *)authId
                      success:(void (^)(NSString *streamToken))success
                      failure:(void (^)(NSNumber *statusCode))failure {
    
    NSString *userToken = [[ZPLoginManager.sharedInstance createWithUserData] getUserToken];
    
    if (!userToken) {
        failure(nil);
        return;
    }
    
    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat:@"https://services.inplayer.com/items/%@/access", authId]];
    
    NSMutableURLRequest *request =
    [NSMutableURLRequest requestWithURL:url
                            cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                        timeoutInterval:10.0];
    request.allHTTPHeaderFields = @{@"Authorization": [NSString stringWithFormat:@"Bearer %@", userToken]};
    request.HTTPMethod = @"GET";
    
    NSURLSessionDataTask *task =
    [[NSURLSession sharedSession] dataTaskWithRequest:request
                                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                        
                                        if (error != nil) {
                                            NSLog(@"<ERROR>Sport1Player: %@", error.localizedDescription);
                                            
                                            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                                failure(@( ((NSHTTPURLResponse *)response).statusCode));
                                                return;
                                            }
                                            
                                            failure(nil);
                                            return;
                                        }
                                        
                                        NSString *streamToken = [HTTPClientImplementation parseStreamTokenResponse:data];
                                        if (!streamToken) {
                                            failure(nil);
                                            return;
                                        }
                                        
                                        [NSOperationQueue.mainQueue addOperationWithBlock:^{
                                            success(streamToken);
                                        }];
                                    }];
    [task resume];
}

+ (NSString *)parseStreamTokenResponse:(NSData *)data {
    
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error != nil || json == nil) {
        NSLog(@"<ERROR>Sport1Player: %@", error.localizedDescription);
        return nil;
    }
    
    NSString *content = json[@"item"][@"content"];
    NSData * tokenData = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *tokenDict = [NSJSONSerialization JSONObjectWithData:tokenData options:0 error:&error];
    NSString *token = tokenDict[@"token"];
    
    return token;
}

@end
