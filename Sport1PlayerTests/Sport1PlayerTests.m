//
//  Sport1PlayerTests.m
//  Sport1PlayerTests
//
//  Created by Oliver Stowell on 28/08/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
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
    NSDictionary *extensions = [[NSDictionary alloc] initWithObjectsAndKeys:kFSK16, kTrackingInfoKey, nil];
    playableItem.extensionsDictionary = extensions;
    
    Sport1PlayerAdapter *sut = (Sport1PlayerAdapter*)[Sport1PlayerAdapter pluggablePlayerInitWithPlayableItems:@[playableItem]
                                                                                             configurationJSON:nil];
    sut.pluginManager = [MockZPPluginManager class];
    //send foreground notification
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification
                                                        object:nil];
    //check the presenter
    XCTAssertTrue(pluginPresenter.didPresentPlugin);
}

@end
