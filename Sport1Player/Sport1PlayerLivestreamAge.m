//
//  Sport1PlayerLivestreamAge.m
//  Sport1Player
//
//  Created by Oliver Stowell on 30/08/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import "Sport1PlayerLivestreamAge.h"
#import "Sport1HTTPClient.h"

static NSString *const kEPG = @"epg";
static NSString *const kLivestreamEnd = @"end";
static NSString *const kLivestreamStart = @"start";
static NSString *const kLivestreamCurrentTime = @"currentTime";
static NSInteger const kRetryTime = 5;

@interface Sport1PlayerLivestreamPin ()
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong, readonly) id<Sport1HTTPClient> httpClient;
@end

@implementation Sport1PlayerLivestreamPin

#pragma mark - Publich methods

- (instancetype)initWithConfigurationJSON:(NSDictionary *)configurationJSON currentPlayerAdapter:(Sport1PlayerAdapter *)currentPlayerAdapter httpClient:(id<Sport1HTTPClient>)httpClient {
    if (self = [super init]) {
        _currentPlayerAdapter = currentPlayerAdapter;
        _httpClient = httpClient;
    }
    return self;
}

- (void)updateLivestreamAgeWithCompletion:(void (^)(NSError *error, BOOL shouldShowPin))completionHandler {
    [self.httpClient livestreamEPGWithSuccess:^(NSDictionary *livestreamEPG) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSDictionary *currentLivestream = [self currentLivestreamFromJSON:livestreamEPG];
            if (currentLivestream) {
                [self triggerTimerWithLivestreamEPG:livestreamEPG];
                
                BOOL isAgeRestricted = [self isAgeRestricted:currentLivestream];
                completionHandler(nil, isAgeRestricted);
            }else {
                [self retryWithCompletion:completionHandler];
            }
        }];
    } failure:^(NSNumber *statusCode) {
        [self retryWithCompletion:completionHandler];
    }];
}

#pragma mark - Private methods

- (void)retryWithCompletion:(void (^)(NSError *error, BOOL shouldShowPin))completionHandler {
    NSLog(@"Retrying connection");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kRetryTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateLivestreamAgeWithCompletion:completionHandler];
    });
}

- (void)triggerTimerWithLivestreamEPG:(NSDictionary *)livestreamEPG {
    //We calculate the firedate as: livestreamEnd = end + (now - serverNow)
    NSDictionary *currentLivestream = [self currentLivestreamFromJSON:livestreamEPG];
    NSDate *livestreamEnd = [self dateFromString:currentLivestream[kLivestreamEnd]];
    NSDate *serverTime = [self dateFromString:livestreamEPG[kLivestreamCurrentTime]];
    NSTimeInterval interval = [serverTime timeIntervalSinceDate:[NSDate date]];
    livestreamEnd = [livestreamEnd dateByAddingTimeInterval:interval];
    
    if (self.timer != nil) {
        [self.timer invalidate];
        self.timer = nil;
        
        if (self.currentPlayerAdapter == nil || self.currentPlayerAdapter.currentPlayerState == ZPPlayerStateStopped) {
            return;
        }
    }
    __weak Sport1PlayerLivestreamPin *weakSelf = self;
    self.timer = [[NSTimer alloc] initWithFireDate:livestreamEnd interval:0 repeats:NO block:^(NSTimer *timer) {
         [weakSelf.currentPlayerAdapter presentPinIfNecessary];
     }];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (NSDate*)dateFromString:(NSString*)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.calendar = NSCalendar.currentCalendar;
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    dateFormatter.dateFormat = @"EEE, dd MM yyyy HH:mm:ss ZZZ"; //Matches the `end` & `start` string in the JSON - the only one with time zone.
    
    return [dateFormatter dateFromString:dateString];
}

- (NSDictionary* _Nullable)currentLivestreamFromJSON:(NSDictionary*)livestreamJSON {
    NSArray *epg = livestreamJSON[kEPG];
    NSDate *now = [self dateFromString:livestreamJSON[kLivestreamCurrentTime]];
    
    for (NSDictionary *livestream in epg) {
        if ([self isCurrent:livestream now:now]) {
            return livestream;
        }
    }
    
    return nil;
}

- (BOOL)isCurrent:(NSDictionary*)livestream now:(NSDate*)now {
    if (!now) {
        return NO;
    }
    
    NSDate *start = [self dateFromString:livestream[kLivestreamStart]];
    NSDate *end = [self dateFromString:livestream[kLivestreamEnd]];
    
    if (([end compare:now] == NSOrderedDescending &&
        [start compare:now] == NSOrderedAscending) ||
        [start compare:now] == NSOrderedSame) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isAgeRestricted:(NSDictionary*)currentLivestream {
    if ([currentLivestream.allKeys containsObject:kFSKKey]) {
        if ([[currentLivestream[kFSKKey] stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:kFSK16]) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

@end
