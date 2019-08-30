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

@interface Sport1PlayerLivestreamAge ()
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSString *livestreamURL;
@property (nonatomic) NSDate *ageRestrictionEnd;
@property (nonatomic) NSDate *ageRestrictionStart;
@property (nonatomic) NSDate *livestreamEnd;
@end

@implementation Sport1PlayerLivestreamAge

+ (id)sharedManager {
    static Sport1PlayerLivestreamAge *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)setConfigurationJSON:(NSDictionary *)configurationJSON
{
    self.livestreamURL = configurationJSON[kLivestreamURL];
}

- (void)updateLivestreamAgeData {
    NSLog(@"[!]: update livestream");
    //TODO: remove hardcoding
    self.livestreamURL = @"https://stage-oz.sport1.de/api/ottv1/1/livestream/teaser";
    NSURL *url = [NSURL URLWithString:self.livestreamURL];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSError *error = nil;
    NSDictionary *livestreamJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    NSNumber *restrictionEnd = livestreamJSON[kAgeRestrictionEnd];
    NSNumber *restrictionStart = livestreamJSON[kAgeRestrictionStart];
    
    self.ageRestrictionEnd = [NSDate dateWithTimeIntervalSince1970:restrictionEnd.intValue];
    self.ageRestrictionStart = [NSDate dateWithTimeIntervalSince1970:restrictionStart.intValue];
    
    NSDictionary *current = [self currentLivestreamFromJSON:livestreamJSON];
    if (current) {
        NSLog(@"[!]: current.title: %@", current[@"title"]);
        self.livestreamEnd = [self dateFromString:current[kLivestreamEnd]];
        NSLog(@"[!]: livestreamEnd: %@", self.livestreamEnd);
        self.livestreamEnd = [NSDate dateWithTimeIntervalSinceNow:30];
        NSLog(@"[!]: livestreamEnd: %@", self.livestreamEnd);
        
        if (self.timer != nil) {
            NSLog(@"[!]: invalidating previous timer.");
            [self.timer invalidate];
            self.timer = nil;
            
            if (self.currentPlayerAdapter == nil || self.currentPlayerAdapter.currentPlayerState == ZPPlayerStateStopped) {
                NSLog(@"[!]: player adapter stopped or nil - removing timer.");
                return;
            }
            NSLog(@"[!]: playerState: %li", self.currentPlayerAdapter.currentPlayerState);
        }
        __block typeof(self) blockSelf = self;
        self.timer = [[NSTimer alloc] initWithFireDate:self.livestreamEnd
                                              interval:0
                                               repeats:NO
                                                 block:^(NSTimer * _Nonnull timer) {
                                                     NSLog(@"[!]: timer run!");
                                                     [blockSelf updateLivestreamAgeData];
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
    } else {
        return NO;
    }
}

@end
