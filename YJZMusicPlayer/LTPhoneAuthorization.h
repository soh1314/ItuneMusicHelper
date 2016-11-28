

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
