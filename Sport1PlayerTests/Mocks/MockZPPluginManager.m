//
//  MockZPPluginManager.m
//  Sport1PlayerTests
//
//  Created by Oliver Stowell on 30/10/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import "MockZPPluginManager.h"
#import "MockPluginPresenter.h"

@implementation MockZPPluginManager

+ (ZPPluginModel *)pluginModelById:(NSString *)pluginID {
    return [[ZPPluginModel alloc] initWithObject:nil];
}

+ (Class)adapterClass:(ZPPluginModel *)pluginModel {
    return [MockPluginPresenter class];
}

@end
