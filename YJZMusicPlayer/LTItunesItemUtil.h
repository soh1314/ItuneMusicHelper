

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
typedef NS_ENUM(NSInteger,LTMediaQueryType) {
    LTMediaSongQuery = 0,
    LTMediaArtistQuery,
    LTMediaAlbumQuery
};
@interface LTItunesItemUtil : NSObject

+ (NSString *)wavFormatefilePathForSongName:(NSString *)songName;
+ (NSString *)m4aFormatefilePathForSongName:(NSString *)songName;

+ (void)convetM4aToWav:(NSURL *)originalUrl  destUrl:(NSURL *)destUrl ;

+ (void)convertToMp4: (MPMediaItem*)song;

+ (MPMediaQuery *)mediaQueryWithType:(LTMediaQueryType)type filterPredicate:(MPMediaPropertyPredicate *)predicate;

+ (NSArray<MPMediaItem *> *)mediaItemCollectionWithQuery:(MPMediaQuery *)query;

@end
