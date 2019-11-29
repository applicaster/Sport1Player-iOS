//
//  Sport1HTTPClient.m
//  Sport1Player
//
//  Created by Pablo Rueda on 26/11/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

@import ZappLoginPluginsSDK;
#import "Sport1HTTPClient.h"

static NSString *const kLivestreamURL = @"livestream_url";

@interface Sport1HTTPClientImplementation ()
@property (nonatomic, copy, readonly) NSString *livestreamURL;
@end

@implementation Sport1HTTPClientImplementation

#pragma mark - Public methods

- (instancetype)initWithConfigurationJSON:(NSDictionary*)configurationJSON {
    if (self = [super init]) {
        _livestreamURL = configurationJSON[kLivestreamURL];
    }
    return self;
}

- (void)getStreamTokenFromAPI:(NSString *)authId
                      success:(void (^)(NSString *streamToken))success
                      failure:(void (^)(NSNumber *statusCode))failure {
    
    NSString *userToken = [[ZPLoginManager.sharedInstance createWithUserData] getUserToken];
    
    if (!userToken) {
        failure(nil);
        return;
    }
    
    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat:@"https://services.inplayer.com/items/%@/access", authId]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10.0];
    request.allHTTPHeaderFields = @{@"Authorization": [NSString stringWithFormat:@"Bearer %@", userToken]};
    request.HTTPMethod = @"GET";
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            NSLog(@"<ERROR>Sport1Player: %@", error.localizedDescription);
            
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                failure(@( ((NSHTTPURLResponse *)response).statusCode));
                return;
            }
            
            failure(nil);
            return;
        }
        
        NSString *streamToken = [Sport1HTTPClientImplementation parseStreamTokenResponse:data];
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

- (void)livestreamEPGWithSuccess:(void (^)(NSDictionary *livestreamEPG))success failure:(void (^)(NSNumber *errorCode))failure {
    if (self.livestreamURL.length == 0) {
        failure(@(Sport1HTTPClientErrorNoURL));
        return;
    }
    
    NSURL *url = [NSURL URLWithString:self.livestreamURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                         timeoutInterval:10.0];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
         if (error != nil) {
             NSLog(@"<ERROR>Sport1Player: %@", error.localizedDescription);
             failure(@( ((NSHTTPURLResponse *)response).statusCode));
         }else {
             NSError *parseError = nil;
             NSDictionary *livestreamJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
             
             if (parseError != nil) {
                 NSLog(@"<ERROR>Sport1Player: %@", parseError.localizedDescription);
                 failure(@(Sport1HTTPClientErrorBadParsing));
             }else if (livestreamJSON == nil) {
                 failure(@(Sport1HTTPClientErrorNoJSON));
             }else {
                 success(livestreamJSON);
             }
         }
    }];
    [task resume];
}

#pragma mark - Private methods

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
