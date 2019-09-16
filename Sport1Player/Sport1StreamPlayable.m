//
//  Sport1StreamPlayable.m
//  Sport1Player
//
//  Created by Oliver Stowell on 13/09/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import "Sport1StreamPlayable.h"

@implementation Sport1StreamPlayable
@synthesize extensionsDictionary;
@synthesize identifier;

- (instancetype)initWithOriginal:(NSObject<ZPPlayable> *)original andAmendedURL:(NSString *)amendedURL {
    if (self = [super init]) {
        self.originalObject = original;
        self.amendedStreamURL = amendedURL;
    }
    return self;
}

- (NSDictionary * _Null_unspecified)analyticsParams {
    return self.originalObject.analyticsParams;
}

- (AVURLAsset * _Nullable)assetUrl {
    return self.originalObject.assetUrl;
}

- (NSString * _Null_unspecified)contentVideoURLPath {
    return self.amendedStreamURL != nil ? self.amendedStreamURL : self.originalObject.contentVideoURLPath;
}

- (BOOL)isFree {
    return self.originalObject.isFree;
}

- (BOOL)isLive {
    return self.originalObject.isLive;
}

- (NSString * _Null_unspecified)overlayURLPath {
    return self.originalObject.overlayURLPath;
}

- (NSString * _Null_unspecified)playableDescription {
    return self.originalObject.playableDescription;
}

- (NSString * _Null_unspecified)playableName {
    return self.originalObject.playableName;
}

- (NSString * _Null_unspecified)publicPageURLPath {
    return self.originalObject.publicPageURLPath;
}

@end
