//
//  Sport1PlayerLivestreamAge.m
//  Sport1Player
//
//  Created by Oliver Stowell on 30/08/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import "Sport1PlayerLivestreamAge.h"

static NSString *const kLivestreamURL = @"livestream_url";
static NSString *const kAgeRestrictionEnd = @"ageRestrictionEnd";
static NSString *const kAgeRestrictionStart = @"ageRestrictionStart";
static NSString *const kEPG = @"epg";
static NSString *const kLivestreamEnd = @"end";
static NSString *const kLivestreamStart = @"start";

@interface Sport1PlayerLivestreamPin ()
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSString *livestreamURL;
@property (nonatomic) NSDate *ageRestrictionEnd;
@property (nonatomic) NSDate *ageRestrictionStart;
@property (nonatomic) NSDate *livestreamEnd;
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
    NSURL *url = [NSURL URLWithString:self.livestreamURL];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                         timeoutInterval:10.0];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                                     if (error != nil) {
                                                                         NSLog(@"<ERROR>Sport1Player: %@", error.localizedDescription);
                                                                         completionHandler(NO);
                                                                     }
                                                                     
                                                                     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                                         [self updateWithData:data];
                                                                         completionHandler(YES);
                                                                     }];
                                                                 }];
    [task resume];
}

- (void)updateWithData:(NSData*)data {
    NSError *error = nil;
    NSDictionary *livestreamJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error != nil) {
        NSLog(@"<ERROR>Sport1Player: %@", error.localizedDescription);
        return;
    }
    if (livestreamJSON == nil) {return;}
    
    NSNumber *restrictionEnd = livestreamJSON[kAgeRestrictionEnd];
    NSNumber *restrictionStart = livestreamJSON[kAgeRestrictionStart];
    
    self.ageRestrictionEnd = [NSDate dateWithTimeIntervalSince1970:restrictionEnd.intValue];
    self.ageRestrictionStart = [NSDate dateWithTimeIntervalSince1970:restrictionStart.intValue];
    
    NSDictionary *current = [self currentLivestreamFromJSON:livestreamJSON];
    if (current) {
        self.livestreamEnd = [self dateFromString:current[kLivestreamEnd]];
        
        if (self.timer != nil) {
            [self.timer invalidate];
            self.timer = nil;
            
            if (self.currentPlayerAdapter == nil || self.currentPlayerAdapter.currentPlayerState == ZPPlayerStateStopped) {
                return;
            }
        }
        __weak Sport1PlayerLivestreamPin *weakSelf = self;
        self.timer = [[NSTimer alloc] initWithFireDate:weakSelf.livestreamEnd
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
    dateFormatter.dateFormat = @"EEE, dd MM yyyy HH:mm:SS ZZZ"; //Matches the `end` & `start` string in the JSON - the only one with time zone.
    
    return [dateFormatter dateFromString:dateString];
}

-(NSDictionary* _Nullable)currentLivestreamFromJSON:(NSDictionary*)livestreamJSON {
    NSArray *epg = livestreamJSON[kEPG];
    NSDate *now = [NSDate date];
    
    for (NSDictionary *livestream in epg) {
        NSDate *start = [self dateFromString:livestream[kLivestreamStart]];
        NSDate *end = [self dateFromString:livestream[kLivestreamEnd]];
        
        if ([end compare:now] == NSOrderedDescending &
            [start compare:now] == NSOrderedAscending) {
            return livestream;
        }
    }
    
    return nil;
}

-(BOOL)shouldDisplayPin {
    NSDate *now = [NSDate date];
    if ([self.ageRestrictionEnd compare:now] == NSOrderedDescending &&
        [self.ageRestrictionStart compare:now] == NSOrderedAscending) {
        return YES;
    } else { return NO; }
}

@end
