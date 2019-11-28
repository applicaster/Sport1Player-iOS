//
//  Sport1PlayerAdapter.m
//  Sport1Player
//
//  Created by Oliver Stowell on 28/08/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

@import ZappLoginPluginsSDK;
@import PluginPresenter;
#import "Sport1PlayerAdapter.h"
#import <JWPlayer_iOS_SDK/JWPlayerController.h>
#import "Sport1PlayerLivestreamAge.h"
#import "JWPlayerViewController+Public.h"
#import "Sport1PlayerViewController.h"
#import "Sport1PlayerHelper.h"

static NSString *const kPlayableItemsKey = @"playable_items";
static NSString *const kPluginName = @"pin_validation_plugin_id";

@interface Sport1PlayerAdapter ()
@property (nonatomic, strong) Sport1PlayerLivestreamPin *livestreamPinValidation;
@property (nonatomic, strong) ZPPlayerConfiguration *playerConfiguration;
@property (nonatomic, strong) Sport1PlayerHelper *playerHelper;
@end

@implementation Sport1PlayerAdapter

+ (id<ZPPlayerProtocol>)pluggablePlayerInitWithPlayableItems:(NSArray<id<ZPPlayable>> *)items configurationJSON:(NSDictionary *)configurationJSON {
    NSString *playerKey = configurationJSON[@"playerKey"];

    if (![playerKey isNotEmptyOrWhiteSpaces]) {
        return nil;
    }

    [JWPlayerController setPlayerKey:playerKey];

    Sport1PlayerAdapter *instance = [Sport1PlayerAdapter new];
    instance.configurationJSON = configurationJSON;
    instance.playerViewController = [Sport1PlayerViewController new];
    instance.playerViewController.configurationJSON = configurationJSON;
    instance.currentPlayableItem = items.firstObject;
    instance.currentPlayableItems = items;
    instance.pluginManager = [ZPPluginManager class];
    id<Sport1HTTPClient> httpClient = [[Sport1HTTPClientImplementation alloc] initWithConfigurationJSON:configurationJSON];
    instance.playerHelper = [[Sport1PlayerHelper alloc] initWithHTTPClient:httpClient];
    instance.livestreamPinValidation = [[Sport1PlayerLivestreamPin alloc] initWithConfigurationJSON:configurationJSON
                                                                               currentPlayerAdapter:instance httpClient:httpClient];

    [[NSNotificationCenter defaultCenter] addObserver:instance
                                             selector:@selector(applicationWillEnterForegroundNotificationHandler)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    return instance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ZPPlayerProtocol overrides

- (void)presentPlayerFullScreen:(UIViewController *)rootViewController configuration:(ZPPlayerConfiguration *)configuration {
    [self presentPlayerFullScreen:rootViewController configuration:configuration completion:nil];
}

- (void)presentPlayerFullScreen:(UIViewController *)rootViewController configuration:(ZPPlayerConfiguration *)configuration completion:(void (^)(void))completion {
    self.playerConfiguration = configuration;
    [self sendScreenViewAnalyticsFor:self.currentPlayableItem];
    if ([self.currentPlayableItem isFree] == NO) {
        NSObject<ZPLoginProviderUserDataProtocol> *loginPlugin = [[ZPLoginManager sharedInstance] createWithUserData];
        NSDictionary *extensions = [NSDictionary dictionaryWithObject:self.currentPlayableItems forKey:kPlayableItemsKey];

        if ([loginPlugin respondsToSelector:@selector(isUserComplyWithPolicies:)]) {
            [self handleUserComply:[loginPlugin isUserComplyWithPolicies:extensions]
                       loginPlugin:loginPlugin
                rootViewController:rootViewController
                        completion:completion];
        } else if ([loginPlugin respondsToSelector:@selector(isUserComplyWithPolicies:completion:)]) {
            __block typeof(self) blockSelf = self;
            [loginPlugin isUserComplyWithPolicies:extensions completion:^(BOOL isUserComply) {
               [blockSelf handleUserComply:isUserComply
                               loginPlugin:loginPlugin
                        rootViewController:rootViewController
                                completion:completion];
           }];
        } else {
            // login protocol doesn't handle the checks - let the player go
            [self presentPinIfNecessaryFromRootViewController:rootViewController alreadyDisplayingPlayer:NO];
        }
    } else {
        // item is free
        [self presentPinIfNecessaryFromRootViewController:rootViewController alreadyDisplayingPlayer:NO];
    }
}

#pragma mark - ZPPlayerProtocol overrides - Helpers

- (void)handleUserComply:(BOOL)isUserComply
             loginPlugin:(NSObject<ZPLoginProviderUserDataProtocol> *)plugin
      rootViewController:(UIViewController *)rootViewController
              completion:(void (^)(void))completion {
    if (isUserComply) {
        [self presentPinIfNecessaryFromRootViewController:rootViewController alreadyDisplayingPlayer:NO];
    } else {
        __block typeof(self) blockSelf = self;
        NSDictionary *playableItems = [NSDictionary dictionaryWithObject:[self currentPlayableItems] forKey:kPlayableItemsKey];
        [plugin login:playableItems completion:^(enum ZPLoginOperationStatus status) {
            if (status == ZPLoginOperationStatusCompletedSuccessfully) {
                [blockSelf presentPinIfNecessaryFromRootViewController:rootViewController alreadyDisplayingPlayer:NO];
            }
        }];
    }
}

#pragma mark - Analytics

- (void)sendScreenViewAnalyticsFor:(NSObject <ZPPlayable>*)current {
    if (current.isLive) {
        [[[ZAAppConnector sharedInstance] analyticsDelegate] trackScreenViewWithScreenTitle:@"Livestream"
                                                                                 parameters:[[NSDictionary alloc] init]];
    } else {
        NSDictionary *parameters = [[NSDictionary alloc] initWithObjectsAndKeys:current, @"playable", nil];
        [[[ZAAppConnector sharedInstance] analyticsDelegate] trackScreenViewWithScreenTitle:@"Spiele Video"
                                                                                 parameters:parameters];
    }
}

#pragma mark - Pin

- (void)presentPinIfNecessary {
    [self presentPinIfNecessaryFromRootViewController:self.playerViewController alreadyDisplayingPlayer:YES];
}

- (void)presentPinIfNecessaryFromRootViewController:(UIViewController*)rootViewController
                            alreadyDisplayingPlayer:(BOOL)alreadyDisplayingPlayer {
    NSDictionary *trackingInfo = self.currentPlayableItem.extensionsDictionary[kTrackingInfoKey];
    
    //Livestream
    if (self.currentPlayableItem.isLive) {
        [self.livestreamPinValidation updateLivestreamAgeDataWithCompletion:^(BOOL success) {
            if (success) {
                //Check if player is visible
                if (alreadyDisplayingPlayer && self.playerViewController.viewIfLoaded.window == nil){
                    return;
                }
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if ([self.livestreamPinValidation shouldDisplayPin]) {
                        [self.playerViewController pause];
                        [self presentPinOn:rootViewController alreadyDisplayingPlayer:alreadyDisplayingPlayer];
                    }else if (!alreadyDisplayingPlayer) {
                        [self.playerHelper amendIfLivestreamModified:self.currentPlayableItem callback:^(NSObject<ZPPlayable> *amended) {
                            self.currentPlayableItem = amended;
                            [super playFullScreen:rootViewController configuration:self.playerConfiguration completion:nil];
                        }];
                    }
                }];
            }
        }];
        return;
    }
    
    //VOD
    NSString *ageString = trackingInfo[kFSKKey];
    if ((id)ageString != [NSNull null]) {
        if ([ageString isEqualToString:kFSK16]) {
            [self.playerViewController pause];
            [self presentPinOn:rootViewController alreadyDisplayingPlayer:alreadyDisplayingPlayer];
            return;
        }
    }
    
    if (!alreadyDisplayingPlayer) {
        [super playFullScreen:rootViewController configuration:self.playerConfiguration completion:nil];
    }
}

- (void)presentPinOn:(UIViewController*)rootViewController alreadyDisplayingPlayer:(BOOL)alreadyDisplayingPlayer {
    ZPPluginModel *pluginModel = [self.pluginManager pluginModelById:self.configurationJSON[kPluginName]];
    
    if (pluginModel == nil) {
        //currently this fails without warning & doesn't display player.
        self.livestreamPinValidation = nil;
        return;
    }
    
    id<ZPAdapterProtocol> plugin = [self.pluginManager adapter:pluginModel];
    if ([plugin conformsToProtocol:@protocol(PluginPresenterProtocol)]) {
        [(id<PluginPresenterProtocol>)plugin presentPluginWithParentViewController:rootViewController extraData:nil completion:^(BOOL success, id data) {
            [self.playerHelper amendIfLivestreamModified:self.currentPlayableItem callback:^(NSObject<ZPPlayable> *amended) {
                self.currentPlayableItem = amended;
                if (success && !alreadyDisplayingPlayer) {
                    [super playFullScreen:rootViewController configuration:self.playerConfiguration completion:nil];
                } else if (!success) {
                    [self.playerViewController dismiss:nil];
                    self.livestreamPinValidation = nil;
                    self.playerConfiguration = nil;
                }
            }];
        }];
    }
}

#pragma mark - Handlers

- (void)applicationWillEnterForegroundNotificationHandler {
    [self presentPinIfNecessary];
}

@end
