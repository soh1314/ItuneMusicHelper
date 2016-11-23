//
//  LTAirPlay.m
//  YJZMusicPlayer
//
//  Created by ios_dev100 on 16/11/23.
//  Copyright © 2016年 颜镜圳. All rights reserved.
//

#import "LTAirPlay.h"

@implementation LTAirPlay

- (id)init {
    if (self = [super init]) {
        [self defaultSetting];
    }
    return self;
}

- (void)defaultSetting {
    
}

- (MPVolumeView *)myVolumeView
{
    if (!_myVolumeView) {
        _myVolumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0,0, 45, 33)];
        _myVolumeView.showsVolumeSlider = NO;
        _myVolumeView.showsRouteButton = YES;
        [_myVolumeView setRouteButtonImage:[UIImage imageNamed:@"airPlay-29"] forState:UIControlStateNormal];
        [_myVolumeView setRouteButtonImage:[UIImage imageNamed:@"airPlay-29"]  forState:UIControlStateNormal];
    }
    return _myVolumeView;
}

@end
