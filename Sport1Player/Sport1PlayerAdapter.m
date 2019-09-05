//
//  Sport1PlayerAdapter.m
//  Sport1Player
//
//  Created by Oliver Stowell on 28/08/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

@import ZappLoginPluginsSDK;
@import ZappPlugins;
@import PluginPresenter;
#import "Sport1PlayerAdapter.h"
#import <JWPlayer_iOS_SDK/JWPlayerController.h>
#import "Sport1PlayerLivestreamAge.h"

static NSString *const kTrackingInfoKey = @"tracking_info";
static NSString *const kAgeRatingKey = @"age_rating";
static NSString *const kPlayableItemsKey = @"playable_items";
static NSString *const kPluginName = @"age_verification_plugin_id";
static int kWatershedAge = 16;

@implementation Sport1PlayerAdapter

+ (id<ZPPlayerProtocol>)pluggablePlayerInitWithPlayableItems:(NSArray<id<ZPPlayable>> *)items configurationJSON:(NSDictionary *)configurationJSON {
    NSString *playerKey = configurationJSON[@"playerKey"];
    
    if (![playerKey isNotEmptyOrWhiteSpaces]) {
        return nil;
    }
    
    [JWPlayerController setPlayerKey:playerKey];
    
    Sport1PlayerAdapter *instance = [Sport1PlayerAdapter new];
    instance.configurationJSON = configurationJSON;
    instance.playerViewController = [JWPlayerViewController new];
    instance.playerViewController.configurationJSON = configurationJSON;
    instance.currentPlayableItem = items.firstObject;
    instance.currentPlayableItems = items;
    
    [[Sport1PlayerLivestreamAge sharedManager] setConfigurationJSON:configurationJSON];
    [[Sport1PlayerLivestreamAge sharedManager] setCurrentPlayerAdapter:instance];
    
    return instance;
}

- (void)pluggablePlayerAddInline:(UIViewController * _Nonnull)rootViewController container:(UIView * _Nonnull)container {
    [self pluggablePlayerAddInline:rootViewController
                         container:container
                     configuration:nil];
}

- (void)pluggablePlayerAddInline:(UIViewController *)rootViewController container:(UIView *)container configuration:(ZPPlayerConfiguration *)configuration {
    if ([self.currentPlayableItem isFree] == NO) {
        NSObject<ZPLoginProviderUserDataProtocol> *loginPlugin = [[ZPLoginManager sharedInstance] createWithUserData];
        NSDictionary *extensions = [NSDictionary dictionaryWithObject:self.currentPlayableItems
                                                               forKey:kPlayableItemsKey];
        if ([loginPlugin respondsToSelector:@selector(isUserComplyWithPolicies:)]) {
            [self handleUserComply:[loginPlugin isUserComplyWithPolicies:extensions]
                       loginPlugin:loginPlugin
                rootViewController:rootViewController
                         container:container
                     configuration:configuration
                        completion:nil];
        } else if ([loginPlugin respondsToSelector:@selector(isUserComplyWithPolicies:completion:)]) {
            __block typeof(self) blockSelf = self;
            [loginPlugin isUserComplyWithPolicies:extensions
                                       completion:^(BOOL isUserComply) {
                                           [blockSelf handleUserComply:isUserComply
                                                           loginPlugin:loginPlugin
                                                    rootViewController:rootViewController
                                                             container:container
                                                         configuration:configuration
                                                            completion:nil];
                                       }];
        } else {
            // login protocol doesn't handle the checks - let the player go
            [self shouldPresentPinFor:self.currentPlayableItem
                            container:container
                   rootViewController:rootViewController
                  playerConfiguration:configuration];
        }
    } else {
        // item is free
        [self shouldPresentPinFor:self.currentPlayableItem
                        container:container
               rootViewController:rootViewController
              playerConfiguration:configuration];
    }
}

- (void)presentPlayerFullScreen:(UIViewController * _Nonnull)rootViewController configuration:(ZPPlayerConfiguration * _Nullable)configuration {
    [self presentPlayerFullScreen:rootViewController configuration:configuration completion:nil];
}

- (void)presentPlayerFullScreen:(UIViewController *)rootViewController configuration:(ZPPlayerConfiguration *)configuration completion:(void (^)(void))completion {
    if ([self.currentPlayableItem isFree] == NO) {
        NSObject<ZPLoginProviderUserDataProtocol> *loginPlugin = [[ZPLoginManager sharedInstance] createWithUserData];
        NSDictionary *extensions = [NSDictionary dictionaryWithObject:self.currentPlayableItems
                                                               forKey:kPlayableItemsKey];
        
        if ([loginPlugin respondsToSelector:@selector(isUserComplyWithPolicies:)]) {
            [self handleUserComply:[loginPlugin isUserComplyWithPolicies:extensions]
                       loginPlugin:loginPlugin
                rootViewController:rootViewController
                         container:nil
                     configuration:configuration
                        completion:completion];
        } else if ([loginPlugin respondsToSelector:@selector(isUserComplyWithPolicies:completion:)]) {
            __block typeof(self) blockSelf = self;
            [loginPlugin isUserComplyWithPolicies:extensions
                                       completion:^(BOOL isUserComply) {
                                           [blockSelf handleUserComply:isUserComply
                                                           loginPlugin:loginPlugin
                                                    rootViewController:rootViewController
                                                             container:nil
                                                         configuration:configuration
                                                            completion:completion];
                                       }];
        } else {
            // login protocol doesn't handle the checks - let the player go
            [self shouldPresentPinFor:self.currentPlayableItem
                            container:nil
                   rootViewController:rootViewController
                  playerConfiguration:configuration];
        }
    } else {
        // item is free
        [self shouldPresentPinFor:self.currentPlayableItem
                        container:nil
               rootViewController:rootViewController
              playerConfiguration:configuration];
    }
}

- (void)handleUserComply:(BOOL)isUserComply
             loginPlugin:(NSObject<ZPLoginProviderUserDataProtocol> *)plugin
      rootViewController:(UIViewController *)rootViewController
               container:(UIView *)container
           configuration:(ZPPlayerConfiguration *)configuration
              completion:(void (^)(void))completion
{
    if (isUserComply) {
        [self shouldPresentPinFor:self.currentPlayableItem
                        container:container
               rootViewController:rootViewController
              playerConfiguration:configuration];
    } else {
        __block typeof(self) blockSelf = self;
        NSDictionary *playableItems = [NSDictionary dictionaryWithObject:[self currentPlayableItems] forKey:kPlayableItemsKey];
        [plugin login:playableItems
           completion:^(enum ZPLoginOperationStatus status) {
               if (status == ZPLoginOperationStatusCompletedSuccessfully) {
                   [blockSelf shouldPresentPinFor:self.currentPlayableItem
                                        container:container
                               rootViewController:rootViewController
                              playerConfiguration:configuration];
               }
           }];
    }
}

-(void)shouldPresentPinFor:(NSObject <ZPPlayable>*)currentPlayableItem container:(UIView*)container rootViewController:(UIViewController*)rootViewController playerConfiguration:(ZPPlayerConfiguration * _Nullable)configuration {
    NSDictionary *trackingInfo = currentPlayableItem.extensionsDictionary[kTrackingInfoKey];
    
    if (![trackingInfo.allKeys containsObject:kAgeRatingKey]) {
        [[Sport1PlayerLivestreamAge sharedManager] updateLivestreamAgeData];
        
        if ([[Sport1PlayerLivestreamAge sharedManager] shouldDisplayPin]) {
            [self presentPinOn:rootViewController
                     container:container
           playerConfiguration:configuration];
        } else {
            if (container == nil) {
                [super playFullScreen:rootViewController
                        configuration:configuration
                           completion:nil];
            } else {
                [super playInline:rootViewController
                        container:container
                    configuration:configuration
                       completion:nil];
            }
        }
        return;
    }
    
    NSNumber *ageRating = trackingInfo[kAgeRatingKey];
    
    if (ageRating.intValue >= kWatershedAge) {
        [self presentPinOn:rootViewController
                 container:container
       playerConfiguration:configuration];
    } else {
        if (container == nil) {
            [super playFullScreen:rootViewController
                    configuration:configuration
                       completion:nil];
        } else {
            [super playInline:rootViewController
                    container:container
                configuration:configuration
                   completion:nil];
        }
    }
}

-(void)presentPinOn:(UIViewController*)rootViewController container:(UIView*)container playerConfiguration:(ZPPlayerConfiguration * _Nullable)configuration {
    ZPPluginModel *pluginModel = [ZPPluginManager pluginModelById:self.configurationJSON[kPluginName]];
    Class pluginClass = [ZPPluginManager adapterClass:pluginModel];
    if ([pluginClass conformsToProtocol:@protocol(ZPAdapterProtocol)]) {
        NSObject <PluginPresenterProtocol> *plugin = [[pluginClass alloc] initWithConfigurationJSON:[pluginModel configurationJSON]];
        
        if ([plugin conformsToProtocol:@protocol(PluginPresenterProtocol)]) {
            [plugin presentPluginWithParentViewController:rootViewController
                                                extraData:nil completion:^(BOOL success, id _Nullable data) {
                                                    if (success && container == nil) {
                                                        [super playFullScreen:rootViewController
                                                                configuration:configuration
                                                                   completion:nil];
                                                    } else if (success) {
                                                        [super playInline:rootViewController
                                                                container:container
                                                            configuration:configuration
                                                               completion:nil];
                                                    }
                                                }];
        }
    }
}

@end
