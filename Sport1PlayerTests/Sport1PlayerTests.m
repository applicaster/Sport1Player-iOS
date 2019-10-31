//
//  Sport1PlayerTests.m
//  Sport1PlayerTests
//
//  Created by Oliver Stowell on 28/08/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "MockZPPluginManager.h"
#import "MockPluginPresenter.h"
#import "Sport1PlayerAdapter.h"
#import "Sport1PlayerLivestreamAge.h"

@interface Sport1PlayerTests : XCTestCase

@end

@implementation Sport1PlayerTests

- (void)setUp {
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

-(void)testPinPresenterNeededForVOD {
    MockPluginPresenter *pluginPresenter = [[MockPluginPresenter alloc] initWithConfigurationJSON:nil];
    
    //setup playable item
    APAtomEntryPlayable *playableItem = [[APAtomEntryPlayable alloc] init];
    NSDictionary *extensions = [[NSDictionary alloc] initWithObjectsAndKeys:@{kFSKKey: kFSK16,kAgeRatingKey: @"16"}, kTrackingInfoKey, nil];
    playableItem.extensionsDictionary = extensions;
    
    NSDictionary *config = [[NSDictionary alloc] initWithObjectsAndKeys:
                            @"",@"jw_skin_url",
                            @"",@"live_ad_type",
                            @"",@"live_midroll_ad_url",
                            @"",@"live_midroll_offset",
                            @"",@"live_preroll_ad_url",
                            @"https://stage-oz.sport1.de/api/ottv1/1/livestream/teaser",@"livestream_url",
                            @"",@"lock_landscape",
                            @"InPlayerWebviewPinVerification",@"pin_validation_plugin_id",
                            @"25ZmaqJ+q4clikN2rhBlpZ+adUHg+ZT2zpmhwA==",@"playerKey",
                            @"",@"vod_ad_type",
                            @"",@"vod_midroll_ad_url",
                            @"",@"vod_midroll_offset",
                            @"",@"vod_preroll_ad_url",
                            nil];
    
    Sport1PlayerAdapter *sut = (Sport1PlayerAdapter*)[Sport1PlayerAdapter pluggablePlayerInitWithPlayableItems:@[playableItem]
                                                                                             configurationJSON:config];
    sut.pluginManager = [MockZPPluginManager class];
    //send foreground notification
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification
                                                        object:nil];
    //check the presenter
    XCTAssertTrue(pluginPresenter.didPresentPlugin);
}

@end
