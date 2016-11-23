//
//  LTPhoneAuthorization.m
//  YJZMusicPlayer
//
//  Created by ios_dev100 on 16/11/21.
//  Copyright © 2016年 颜镜圳. All rights reserved.
//

#import "LTPhoneAuthorization.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation LTPhoneAuthorization

+ (void)requestItunesMediaAuthorization:(Handler)handler
{
    [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
        if (status == MPMediaLibraryAuthorizationStatusAuthorized) {
            handler(LTAuthorizationStatusAuthorized);
        }
        else if (status == MPMediaLibraryAuthorizationStatusNotDetermined) {
            handler(LTAuthorizationStatusNotDetermined);
        }
        else
        {
            handler(LTAuthorizationStatusDenied);
        }
    }];
}

@end
