//
//  MockZPPluginManager.m
//  Sport1PlayerTests
//
//  Created by Oliver Stowell on 30/10/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import "MockZPPluginManager.h"

@implementation MockZPPluginManager
static MockPluginPresenter *mockPluginPresenter;

+ (ZPPluginModel *)pluginModelById:(NSString *)pluginID {
    return [[ZPPluginModel alloc] initWithObject:@{@"plugin": @{@"type":@"general", @"identifier": pluginID}}];
}

+ (Class)adapterClass:(ZPPluginModel *)pluginModel {
    return [MockPluginPresenter class];
}

+ (id<ZPAdapterProtocol>)adapter:(ZPPluginModel *)pluginModel {
    return mockPluginPresenter;
}

+ (MockPluginPresenter *)getPluginPresenterInstance {
    return mockPluginPresenter;
}

+(void)setPluginPresenterInstance:(MockPluginPresenter*)plugin {
    mockPluginPresenter = plugin;
}

@end
