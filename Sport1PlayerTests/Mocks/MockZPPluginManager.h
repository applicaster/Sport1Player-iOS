//
//  MockZPPluginManager.h
//  Sport1PlayerTests
//
//  Created by Oliver Stowell on 30/10/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MockPluginPresenter.h"
@import ZappPlugins;

NS_ASSUME_NONNULL_BEGIN

@interface MockZPPluginManager : NSObject <ZPPluginManagerProtocol>
+(MockPluginPresenter*)getPluginPresenterInstance;
+(void)setPluginPresenterInstance:(MockPluginPresenter* _Nullable)plugin;
@end

NS_ASSUME_NONNULL_END
