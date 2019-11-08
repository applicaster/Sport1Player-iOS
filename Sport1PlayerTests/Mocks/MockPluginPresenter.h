//
//  MockPluginPresenter.h
//  Sport1PlayerTests
//
//  Created by Oliver Stowell on 30/10/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
@import ZappPlugins;
@import PluginPresenter;

NS_ASSUME_NONNULL_BEGIN

@interface MockPluginPresenter : NSObject <ZPAdapterProtocol, PluginPresenterProtocol>
@property (assign) BOOL didPresentPlugin;
@end

NS_ASSUME_NONNULL_END
