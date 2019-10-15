//
//  Sport1PlayerLivestreamAge.h
//  Sport1Player
//
//  Created by Oliver Stowell on 30/08/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sport1PlayerAdapter.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kFSKKey = @"fsk";
static NSString *const kFSK16 = @"FSK16";

@interface Sport1PlayerLivestreamPin : NSObject

@property (nonatomic, weak) Sport1PlayerAdapter *currentPlayerAdapter;

-(instancetype)initWithConfigurationJSON:(NSDictionary*)configurationJSON currentPlayerAdapter:(Sport1PlayerAdapter* _Nullable)currentPlayerAdapter;
-(void)updateLivestreamAgeDataWithCompletion:(void (^)(BOOL success))completionHandler;
-(BOOL)shouldDisplayPin;

@end

NS_ASSUME_NONNULL_END
