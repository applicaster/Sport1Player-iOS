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
#import "JWPlayerViewController+Public.h"
#import "Sport1StreamPlayable.h"

static NSString *const kTrackingInfoKey = @"tracking_info";
static NSString *const kAgeRatingKey = @"age_rating";
static NSString *const kPlayableItemsKey = @"playable_items";
static NSString *const kPluginName = @"pin_validation_plugin_id";
static NSString *const kTokenName = @"stream_token";
static NSString *const kNameSpace = @"InPlayer.v1";
static int kWatershedAge = 16;

@interface Sport1PlayerAdapter ()
@property (nonatomic, strong) Sport1PlayerLivestreamPin *livestreamPinValidation;
@property (nonatomic, weak) UIView * container;
@property (nonatomic, strong) ZPPlayerConfiguration * playerConfiguration;
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
    instance.playerViewController = [JWPlayerViewController new];
    instance.playerViewController.configurationJSON = configurationJSON;
    instance.currentPlayableItem = items.firstObject;
    instance.currentPlayableItems = items;
    
    return instance;
}
#pragma mark - Livestream
-(void)createLivestreamPinCheck {
    self.livestreamPinValidation = [[Sport1PlayerLivestreamPin alloc] initWithConfigurationJSON:self.configurationJSON
                                                                           currentPlayerAdapter:self];
}

-(void)setContainer:(UIView*)container andPlayerConfiguration:(ZPPlayerConfiguration*)playerConfiguration {
    self.container = container;
    self.playerConfiguration = playerConfiguration;
}

#pragma mark - Add Player
- (void)pluggablePlayerAddInline:(UIViewController * _Nonnull)rootViewController container:(UIView * _Nonnull)container {
    [self createLivestreamPinCheck];
    [self setContainer:container
andPlayerConfiguration:nil];
    [self pluggablePlayerAddInline:rootViewController
                         container:container
                     configuration:nil];
}

- (void)pluggablePlayerAddInline:(UIViewController *)rootViewController container:(UIView *)container configuration:(ZPPlayerConfiguration *)configuration {
    [self createLivestreamPinCheck];
    [self setContainer:container
andPlayerConfiguration:configuration];
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
#pragma mark - Present Player
- (void)presentPlayerFullScreen:(UIViewController * _Nonnull)rootViewController configuration:(ZPPlayerConfiguration * _Nullable)configuration {
    [self createLivestreamPinCheck];
    [self setContainer:nil
andPlayerConfiguration:configuration];
    [self presentPlayerFullScreen:rootViewController configuration:configuration completion:nil];
}

- (void)presentPlayerFullScreen:(UIViewController *)rootViewController configuration:(ZPPlayerConfiguration *)configuration completion:(void (^)(void))completion {
    [self createLivestreamPinCheck];
    [self setContainer:nil
andPlayerConfiguration:configuration];
    [self sendScreenViewAnalyticsFor:self.currentPlayableItem];
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
#pragma mark - Login & Pin
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
        [self.livestreamPinValidation updateLivestreamAgeData];
        
        if ([self.livestreamPinValidation shouldDisplayPin]) {
            [self presentPinOn:rootViewController
                     container:container
           playerConfiguration:configuration
             fromLivestreamPin:NO];
        } else {
            self.currentPlayableItem = [self amendIfLivestream:self.currentPlayableItem];
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
    
    NSString *ageString = trackingInfo[kFSKKey];
    if ((id)ageString != [NSNull null]) {
        int ageRating = 0;
        if (ageString.length > 0 && [ageString containsString:@" "]) {
            NSArray *splitString = [ageString componentsSeparatedByString:@" "];
            if (splitString.count > 1) {
                ageRating = [(NSString*)splitString[1] intValue];
            }
        }
        if (ageRating >= kWatershedAge) {
            [self presentPinOn:rootViewController
                     container:container
           playerConfiguration:configuration
             fromLivestreamPin:NO];
            return;
        }
    }
    
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

-(void)presentPinOn:(UIViewController*)rootViewController container:(UIView*)container playerConfiguration:(ZPPlayerConfiguration * _Nullable)configuration fromLivestreamPin:(BOOL)fromLivestreamPin {
    ZPPluginModel *pluginModel = [ZPPluginManager pluginModelById:self.configurationJSON[kPluginName]];
    
    if (pluginModel == nil) {
        //currently this fails without warning & doesn't display player.
        self.livestreamPinValidation = nil;
        return;
    }
    
    Class pluginClass = [ZPPluginManager adapterClass:pluginModel];
    if ([pluginClass conformsToProtocol:@protocol(ZPAdapterProtocol)]) {
        NSObject <PluginPresenterProtocol> *plugin = [[pluginClass alloc] initWithConfigurationJSON:[pluginModel configurationJSON]];
        
        if ([plugin conformsToProtocol:@protocol(PluginPresenterProtocol)]) {
            [plugin presentPluginWithParentViewController:rootViewController
                                                extraData:nil completion:^(BOOL success, id _Nullable data) {
                                                    self.currentPlayableItem = [self amendIfLivestream:self.currentPlayableItem];
                                                    if (success && container == nil && !fromLivestreamPin) {
                                                        [super playFullScreen:rootViewController
                                                                configuration:configuration
                                                                   completion:nil];
                                                    } else if (success && !fromLivestreamPin) {
                                                        [super playInline:rootViewController
                                                                container:container
                                                            configuration:configuration
                                                               completion:nil];
                                                    } else if (!success) {
                                                        [self.playerViewController dismiss:nil];
                                                        self.livestreamPinValidation = nil;
                                                        self.container = nil;
                                                        self.playerConfiguration = nil;
                                                    }
                                                }];
        }
    }
}
#pragma mark - Livestream Pin Presentation
-(void)shouldPresentPin {
    NSDictionary *trackingInfo = self.currentPlayableItem.extensionsDictionary[kTrackingInfoKey];
    if (![trackingInfo.allKeys containsObject:kFSKKey]) {
        [self.livestreamPinValidation updateLivestreamAgeData];
        
        if ([self.livestreamPinValidation shouldDisplayPin]) {
            [self presentPinOn:self.playerViewController
                     container:self.container
           playerConfiguration:self.playerConfiguration
             fromLivestreamPin:YES];
        }
        return;
    }
}
#pragma mark - Livestream Token
-(NSObject <ZPPlayable>*)amendIfLivestream:(NSObject <ZPPlayable>*)current {
    if (current.isLive) {
        NSString *streamToken = [[[ZAAppConnector sharedInstance] storageDelegate] sessionStorageValueFor:kTokenName
                                                                                                namespace:kNameSpace];
        
        if (streamToken == nil) {return current;}
        
        NSString *url = current.contentVideoURLPath;
        NSString *amendedURL = [[NSString alloc] initWithFormat:@"%@?access_token=%@", url, streamToken];
        Sport1StreamPlayable *amended = [[Sport1StreamPlayable alloc] initWithOriginal:current
                                                                         andAmendedURL:amendedURL];
        return amended;
    } else {return current;}
}

@end
