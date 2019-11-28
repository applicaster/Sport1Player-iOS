//
//  Sport1PlayerLivestreamAge.m
//  Sport1Player
//
//  Created by Oliver Stowell on 30/08/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import "Sport1PlayerLivestreamAge.h"

static NSString *const kEPG = @"epg";
static NSString *const kLivestreamEnd = @"end";
static NSString *const kLivestreamStart = @"start";
static NSInteger const kRetryTime = 5;

@interface Sport1PlayerLivestreamPin ()
@property (nonatomic, strong) NSDictionary *nextLivestream;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSDate *livestreamEnd;
@property (nonatomic, assign) BOOL ageRestricted;
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

- (void)updateLivestreamAgeDataWithCompletion:(void (^)(BOOL success))completionHandler {
    BOOL ranCompletion = NO;
    NSDate *now = [NSDate date];
    if (self.nextLivestream != nil && [self isCurrent:self.nextLivestream withNow:now]) {
        [self updateAgeRestriction:self.nextLivestream];
        completionHandler(YES);
        ranCompletion = YES;
    } else {
        self.ageRestricted = NO;
    }
    
    [self.httpClient livestreamEPGWithSuccess:^(NSDictionary *livestreamEPG) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self updateWithLivestreamEPG:livestreamEPG];
            if (!ranCompletion) {
                completionHandler(YES);
            }
        }];
    } failure:^(NSNumber *statusCode) {
        NSLog(@"Retrying connection");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kRetryTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateLivestreamAgeDataWithCompletion:completionHandler];
        });
    }];
}

- (BOOL)shouldDisplayPin {
    return self.ageRestricted;
}

#pragma mark - Private methods

- (void)updateWithLivestreamEPG:(NSDictionary *)livestreamEPG {
    NSDictionary *current = [self currentLivestreamFromJSON:livestreamEPG];
    if (current) {
        self.nextLivestream = [self livestreamFromJSON:livestreamEPG withStart:current[kLivestreamEnd]];
        self.livestreamEnd = [self dateFromString:current[kLivestreamEnd]];
        
        [self updateAgeRestriction:current];
        
        if (self.timer != nil) {
            [self.timer invalidate];
            self.timer = nil;
            
            if (self.currentPlayerAdapter == nil || self.currentPlayerAdapter.currentPlayerState == ZPPlayerStateStopped) {
                return;
            }
        }
        __weak Sport1PlayerLivestreamPin *weakSelf = self;
        self.timer = [[NSTimer alloc] initWithFireDate:weakSelf.livestreamEnd interval:0 repeats:NO block:^(NSTimer *timer) {
             [weakSelf.currentPlayerAdapter presentPinIfNecessary];
         }];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
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
    NSDate *now = [NSDate date];
    
    for (NSDictionary *livestream in epg) {
        if ([self isCurrent:livestream withNow:now]) {
            return livestream;
        }
    }
    
    return nil;
}

- (BOOL)isCurrent:(NSDictionary*)livestream withNow:(NSDate*)now {
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

- (NSDictionary* _Nullable)livestreamFromJSON:(NSDictionary*)livestreamJSON withStart:(NSString*)start {
    NSArray *epg = livestreamJSON[kEPG];
    
    for (NSDictionary *livestream in epg) {
        NSString *nextStart = livestream[kLivestreamStart];
        
        if ([nextStart isEqualToString:start]) {
            return livestream;
        }
    }
    
    return nil;
}

- (void)updateAgeRestriction:(NSDictionary*)currentLivestream {
    if ([currentLivestream.allKeys containsObject:kFSKKey]) {
        if ([[currentLivestream[kFSKKey] stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:kFSK16]) {
            self.ageRestricted = YES;
        } else {
            self.ageRestricted = NO;
        }
    } else {
        self.ageRestricted = NO;
    }
}

@end
