//
//  Sport1PlayerAdapter.h
//  Sport1Player
//
//  Created by Oliver Stowell on 28/08/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import <JWPlayerPlugin/JWPlayerPlugin.h>
#import "ZappJWPlayer+Public.h"
@import ZappPlugins;

NS_ASSUME_NONNULL_BEGIN
static NSString *const kTrackingInfoKey = @"tracking_info";

@interface Sport1PlayerAdapter : ZappJWPlayerAdapter
@property (nonatomic, assign) Class<ZPPluginManagerProtocol> pluginManager;

- (void)presentPinIfNecessary;

@end

NS_ASSUME_NONNULL_END
