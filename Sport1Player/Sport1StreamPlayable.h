//
//  Sport1StreamPlayable.h
//  Sport1Player
//
//  Created by Oliver Stowell on 13/09/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
@import ZappPlugins;

NS_ASSUME_NONNULL_BEGIN

@interface Sport1StreamPlayable : NSObject <ZPPlayable>

@property (nonatomic, strong) NSObject <ZPPlayable> * originalObject;
@property (nonatomic, strong) NSString * _Nullable amendedStreamURL;

-(instancetype)initWithOriginal:(NSObject <ZPPlayable>*)original andAmendedURL:(NSString*)amendedURL;

@end

NS_ASSUME_NONNULL_END
