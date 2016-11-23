//
//  LTPhoneAuthorization.h
//  YJZMusicPlayer
//
//  Created by ios_dev100 on 16/11/21.


// before set itunes authorization ,please set info key Privacy - Media Library Usage Description;

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,LTPhoneAuthorizationStatus) {
    LTAuthorizationStatusNotDetermined = 0,
    LTAuthorizationStatusDenied,
    LTAuthorizationStatusRestricted,
    LTAuthorizationStatusAuthorized,
};
typedef void(^Handler)(LTPhoneAuthorizationStatus status) ;

@interface LTPhoneAuthorization : NSObject

+ (void)requestItunesMediaAuthorization:(Handler)handler;

@end
