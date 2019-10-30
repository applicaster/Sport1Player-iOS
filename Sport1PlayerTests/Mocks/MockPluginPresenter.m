//
//  MockPluginPresenter.m
//  Sport1PlayerTests
//
//  Created by Oliver Stowell on 30/10/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import "MockPluginPresenter.h"

@implementation MockPluginPresenter

@synthesize configurationJSON;
@synthesize didPresentPlugin;

- (nonnull instancetype)initWithConfigurationJSON:(NSDictionary * _Nullable)configurationJSON {
    if (self = [super init]) {
        didPresentPlugin = NO;
    }
    return self;
}

- (void)presentPluginWithParentViewController:(UIViewController * _Nonnull)parentViewController extraData:(id _Nullable)extraData completion:(void (^ _Nullable)(BOOL, id _Nullable))completion {
    didPresentPlugin = YES;
}

@end
