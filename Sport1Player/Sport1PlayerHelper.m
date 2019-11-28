//
//  Sport1PlayerHelper.m
//  Sport1Player
//
//  Created by Pablo Rueda on 26/11/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

@import ZappLoginPluginsSDK;
#import "Sport1PlayerHelper.h"
#import "Sport1StreamPlayable.h"

static NSString *const kAuthIdKey = @"auth_id";

@interface Sport1PlayerHelper()
@property (nonatomic, strong, readonly) id<Sport1HTTPClient> httpClient;
@end

@implementation Sport1PlayerHelper

- (instancetype)initWithHTTPClient:(id<Sport1HTTPClient>)httpClient {
    self = [super init];
    if (self) {
        _httpClient = httpClient;
    }
    return self;
}

- (void)amendIfLivestreamModified:(NSObject <ZPPlayable>*)current
                         callback:(void (^)(NSObject <ZPPlayable>* amended))completion {
    NSString *authIdKey = current.extensionsDictionary[kAuthIdKey];
    NSString *authIdKeyFirstPart = [authIdKey componentsSeparatedByString:@"_"].firstObject;
    
    if (!current.isLive || !authIdKeyFirstPart) {
        completion(current);
        return;
    }
    
    [self.httpClient getStreamTokenFromAPI:authIdKeyFirstPart success:^(NSString *streamToken) {
        NSString *amendedURL = [NSString stringWithFormat:@"%@?access_token=%@", current.contentVideoURLPath, streamToken];
        Sport1StreamPlayable *amended = [Sport1StreamPlayable.new initWithOriginal:current andAmendedURL:amendedURL];
        completion(amended);
     }failure:^(NSNumber *statusCode) {
        if (statusCode.integerValue == 401 || statusCode.integerValue == 403) {
            
            // trying to get token one more time if status code 401, 403
            NSObject<ZPLoginProviderUserDataProtocol> *loginPlugin = [[ZPLoginManager sharedInstance] createWithUserData];
            [loginPlugin logout:^(enum ZPLoginOperationStatus signOutStatus) {
                if (signOutStatus != ZPLoginOperationStatusCompletedSuccessfully) {
                    NSLog(@"<ERROR>Sport1Player: Can't sign out, error type = %li", (long)signOutStatus);
                    completion(current);
                    return;
                }
                
                [loginPlugin login:@{} completion:^(enum ZPLoginOperationStatus result) {
                    if (result != ZPLoginOperationStatusCompletedSuccessfully) {
                        NSLog(@"<ERROR>Sport1Player: Can't refresh token, error type = %li", (long)result);
                        completion(current);
                        return;
                    }
                    
                    [self amendIfLivestreamModified:current callback:completion];
                    return;
                }];
            }];
            
            return;
        }
        
        completion(current);
    }];
}

@end
