//
//  Sport1PlayerViewController.m
//  Sport1Player
//
//  Created by Oliver Stowell on 06/11/2019.
//  Copyright © 2019 Applicaster Ltd. All rights reserved.
//

#import "Sport1PlayerViewController.h"
#import "JWPlayer_iOS_SDK/JWPlayerController.h"

@interface Sport1PlayerViewController () <JWPlayerDelegate>
@property (nonatomic, strong) JWPlayerController *player;
@end

@implementation Sport1PlayerViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [super initWithNibName:@"Sport1PlayerViewController"
                           bundle:[NSBundle bundleForClass:[Sport1PlayerViewController class]]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self changeSize];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size
          withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {}
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                                     [self changeSize];
                                 }];
}

-(void)changeSize {
    [self.view setNeedsLayout];
    if (@available(iOS 11.0, *)) {
        _player.view.frame = self.view.safeAreaLayoutGuide.layoutFrame;
    } else {
        _player.view.frame = self.view.frame;
    }
    [self.view setNeedsLayout];
}

- (void)setPlayer:(JWPlayerController *)player {
    if (_player) {
        // If we already have a player - first dismiss it
        _player.delegate = nil;
        [_player.view removeFromSuperview];
        _player = nil;
    }
    
    player.delegate = self;
    if (@available(iOS 11.0, *)) {
        player.view.frame = self.view.safeAreaLayoutGuide.layoutFrame;
    } else {
        player.view.frame = self.view.frame;
    }
    
    if (self.closeButton.allTargets.count == 0) {
        [self.closeButton addTarget:self
                             action:@selector(dismiss:)
                   forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.closeButton removeFromSuperview];
    self.closeButton.alpha = 1.0;
    
    [player.view addSubview:self.closeButton];
    self.closeButton.frame = CGRectZero;
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self setCloseButtonConstraints:player.view];
    
    [self.view addSubview:player.view];
    [player.view matchParent];
    
    player.fullscreen                 = NO;
    player.forceFullScreenOnLandscape = NO;
    player.forceLandscapeOnFullScreen = NO;
    
    _player = player;
}

@end
