//
//  LTAirPlay.h
//  YJZMusicPlayer
//
//  Created by ios_dev100 on 16/11/23.


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface LTAirPlay : NSObject


@property (nonatomic,assign)BOOL airPlay;
@property (nonatomic,strong)MPMusicPlayerController *musciPlayer;
@property (nonatomic,strong)MPVolumeView *myVolumeView;


@end
