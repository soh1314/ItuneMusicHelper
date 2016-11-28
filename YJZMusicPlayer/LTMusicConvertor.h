/*
 
 负责音频文件的转码；
 负责获取itunes下载的音乐资源 （有itunes协议的除掉）
 
 */

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger,LTMediaQueryType) {
    LTMediaSongQuery = 0,
    LTMediaArtistQuery,
    LTMediaAlbumQuery
};

@interface LTMusicConvertor : NSObject



+ (NSString *)wavFormatefilePathForSongName:(NSString *)songName;

+ (NSString *)m4aFormatefilePathForSongName:(NSString *)songName;


//转换成wav格式
+ (void)convetItuneMusicToWavFormate:(NSURL *)originalUrl destUrl:(NSURL *)destUrl ;

// itunes资源转成MP4
+ (void)convertItuneMusicToMp4WithMediaItem: (MPMediaItem*)item;

/// wav 转成 mp3
+ (void)cafToMP3WithOrigineFile:(NSString *)cafFilePath desFilePath:(NSString *)mp3FilePath;


#pragma mark ---- 获得apple music 资源的方法

+ (MPMediaQuery *)mediaQueryWithType:(LTMediaQueryType)type filterPredicate:(MPMediaPropertyPredicate *)predicate;

+ (NSArray<MPMediaItem *> *)mediaItemCollectionWithQuery:(MPMediaQuery *)query;



@end
