//
//  Sport1PlayerLivestreamAge.m
//  Sport1Player
//
//  Created by Oliver Stowell on 30/08/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import "Sport1PlayerLivestreamAge.h"

static NSString *const kLivestreamURL = @"livestream_url";
static NSString *const kEPG = @"epg";
static NSString *const kLivestreamEnd = @"end";
static NSString *const kLivestreamStart = @"start";

@interface Sport1PlayerLivestreamPin ()
@property (nonatomic, strong) NSDictionary *nextLivestream;
@property (nonatomic, strong) NSDictionary *currentLivestream;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSString *livestreamURL;
@property (nonatomic, strong) NSString *networkResponse;
@property (nonatomic) NSDate *livestreamEnd;
@property (nonatomic) BOOL ageRestricted;
@end

@implementation Sport1PlayerLivestreamPin

-(instancetype)initWithConfigurationJSON:(NSDictionary *)configurationJSON currentPlayerAdapter:(Sport1PlayerAdapter *)currentPlayerAdapter {
    if (self = [super init]) {
        self.livestreamURL = configurationJSON[kLivestreamURL];
        self.currentPlayerAdapter = currentPlayerAdapter;
    }
    return self;
}

-(void)updateLivestreamAgeDataWithCompletion:(void (^)(BOOL success))completionHandler {
    if (self.livestreamURL.length == 0) {completionHandler(NO);}
    BOOL ranCompletion = NO;
    NSDate *now = [NSDate date];
    if (self.nextLivestream != nil && [self isCurrent:self.nextLivestream withNow:now]) {
        [self updateAgeRestriction:self.nextLivestream];
        completionHandler(YES);
        ranCompletion = YES;
    } else {
        self.ageRestricted = NO;
    }
    NSURL *url = [NSURL URLWithString:self.livestreamURL];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                         timeoutInterval:10.0];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                                     NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                                                     
                                                                     if (error != nil) {
                                                                         self.networkResponse = [NSString stringWithFormat:@"%ld", (long)httpResponse.statusCode];
                                                                         NSLog(@"<ERROR>Sport1Player: %@", error.localizedDescription);
                                                                         NSLog(@"Retrying connection");
                                                                         NSDictionary *liveData = [self livestreamData];
                                                                         [[NSNotificationCenter defaultCenter] postNotificationName:@"LivestreamData"                          object:liveData];
                                                                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                                             [self updateLivestreamAgeDataWithCompletion:completionHandler];
                                                                         });
                                                                         return;
                                                                     }
                                                                     
                                                                     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                                         [self updateWithData:data];
                                                                         NSDictionary *liveData = [self livestreamData];
                                                                         [[NSNotificationCenter defaultCenter] postNotificationName:@"LivestreamData"                          object:liveData];
                                                                         if (!ranCompletion) {completionHandler(YES);}
                                                                     }];
                                                                 }];
    [task resume];
}

- (void)updateWithData:(NSData*)data {
    NSError *error = nil;
    NSDictionary *livestreamJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    self.networkResponse = livestreamJSON.description;
    
    if (error != nil) {
        NSLog(@"<ERROR>Sport1Player: %@", error.localizedDescription);
        return;
    }
    if (livestreamJSON == nil) {return;}
    
    NSDictionary *current = [self currentLivestreamFromJSON:livestreamJSON];
    if (current) {
        self.currentLivestream = current;
        self.nextLivestream = [self livestreamFromJSON:livestreamJSON
                                             withStart:current[kLivestreamEnd]];
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
        self.timer = [[NSTimer alloc] initWithFireDate:[weakSelf.livestreamEnd dateByAddingTimeInterval:2]
                                              interval:0
                                               repeats:NO
                                                 block:^(NSTimer * _Nonnull timer) {
                                                     [weakSelf.currentPlayerAdapter shouldPresentPin];
                                                 }];
        [[NSRunLoop mainRunLoop] addTimer:self.timer
                                     forMode:NSRunLoopCommonModes];
    }
}

-(NSDate*)dateFromString:(NSString*)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.calendar = NSCalendar.currentCalendar;
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    dateFormatter.dateFormat = @"EEE, dd MM yyyy HH:mm:SS ZZZ"; //Matches the `end` & `start` string in the JSON - the only one with time zone.
    
    return [dateFormatter dateFromString:dateString];
}

-(NSDictionary* _Nullable)currentLivestreamFromJSON:(NSDictionary*)livestreamJSON {
    NSArray *epg = livestreamJSON[kEPG];
    NSDate *now = [NSDate date];
    
    for (NSDictionary *livestream in epg) {
        if ([self isCurrent:livestream withNow:now]) {return livestream;}
    }
    
    return nil;
}

-(BOOL)isCurrent:(NSDictionary*)livestream withNow:(NSDate*)now {
    NSDate *start = [self dateFromString:livestream[kLivestreamStart]];
    NSDate *end = [self dateFromString:livestream[kLivestreamEnd]];
    
    if ([end compare:now] == NSOrderedDescending &
        [start compare:now] == NSOrderedAscending ||
        [start compare:now] == NSOrderedSame) {
        return YES;
    } else {
        return NO;
    }
}

-(NSDictionary* _Nullable)livestreamFromJSON:(NSDictionary*)livestreamJSON withStart:(NSString*)start {
    NSArray *epg = livestreamJSON[kEPG];
    
    for (NSDictionary *livestream in epg) {
        NSString *nextStart = livestream[kLivestreamStart];
        
        if ([nextStart isEqualToString:start]) {
            return livestream;
        }
    }
    
    return nil;
}

-(void)updateAgeRestriction:(NSDictionary*)currentLivestream {
    if ([currentLivestream.allKeys containsObject:kFSKKey]) {
        if ([[currentLivestream[kFSKKey] stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:kFSK16]) {
            self.ageRestricted = YES;
        } else {
            self.ageRestricted = NO;
        }
    } else {
        self.ageRestricted = NO;
    }
    NSDictionary *data = [self livestreamData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LivestreamData"
                                                        object:data];
}

-(BOOL)shouldDisplayPin {
    return self.ageRestricted;
}

-(NSDictionary *)livestreamData {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    NSDate *start = [self dateFromString:self.currentLivestream[kLivestreamStart]];
    NSDate *end = [self dateFromString:self.currentLivestream[kLivestreamEnd]];
    if (start) { [data setObject:start forKey:@"start"]; }
    if (end) { [data setObject:end forKey:@"end"]; }
    [data setObject:[NSNumber numberWithBool:self.ageRestricted] forKey:@"fsk"];
    if (self.networkResponse) {  [data setObject:self.networkResponse forKey:@"network"]; }
    return data;
}

@end
