//
//  LTItunesItemUtil.m
//  YJZMusicPlayer
//
//  Created by ios_dev100 on 16/11/22.
//  Copyright © 2016年 颜镜圳. All rights reserved.
//

#import "LTItunesItemUtil.h"

@implementation LTItunesItemUtil

+ (NSString *)wavFormatefilePathForSongName:(NSString *)songName
{
    NSString *documentDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *exportFile = [documentDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.wav",songName]];
    return exportFile;
}

+ (NSString *)m4aFormatefilePathForSongName:(NSString *)songName
{
    NSString *documentDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *exportFile = [documentDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3",songName]];
    return exportFile;
}

+ (void)convetM4aToWav:(NSURL *)originalUrl  destUrl:(NSURL *)destUrl {
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:originalUrl options:nil];    //读取原始文件信息
    NSError *error = nil;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:songAsset error:&error];
    if (error) {
        NSLog (@"error: %@", error);
        return;
    }
    AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderAudioMixOutput                                                assetReaderAudioMixOutputWithAudioTracks:songAsset.tracks                                                audioSettings: nil];
    if (![assetReader canAddOutput:assetReaderOutput]) {
        NSLog (@"can't add reader output... die!");
        return;
    }
    [assetReader addOutput:assetReaderOutput];
    
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:destUrl                                                            fileType:AVFileTypeCoreAudioFormat                                                               error:&error];
    if (error) {
        NSLog (@"error: %@", error);
        return;
    }
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:                                     [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,                                     [NSNumber numberWithFloat:16000.0], AVSampleRateKey,                                     [NSNumber numberWithInt:2], AVNumberOfChannelsKey,                                     [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,                                     [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,                                     [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,                                     [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,                                     [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,                                    nil];
    
    AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio                                                                                outputSettings:outputSettings];
    if ([assetWriter canAddInput:assetWriterInput]) {
        [assetWriter addInput:assetWriterInput];
    } else {
        NSLog (@"can't add asset writer input... die!");
        return;
    }
    assetWriterInput.expectsMediaDataInRealTime = NO;
    [assetWriter startWriting];
    [assetReader startReading];
    AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
    CMTime startTime = CMTimeMake (0, soundTrack.naturalTimeScale);
    [assetWriter startSessionAtSourceTime:startTime];
    __block UInt64 convertedByteCount = 0;
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    [assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue                                             usingBlock: ^      {
        while (assetWriterInput.readyForMoreMediaData) {
            CMSampleBufferRef nextBuffer = [assetReaderOutput copyNextSampleBuffer];
            if (nextBuffer) {
                // append buffer
                [assetWriterInput appendSampleBuffer: nextBuffer];
                
                NSLog (@"appended a buffer (%zu bytes)",                                      CMSampleBufferGetTotalSampleSize (nextBuffer));
                convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
            } else {
                [assetWriterInput markAsFinished];
                [assetWriter finishWritingWithCompletionHandler:^{
                }];
                [assetReader cancelReading];
                
                NSDictionary *outputFileAttributes = [[NSFileManager defaultManager]                                                        attributesOfItemAtPath:[destUrl path]                                                        error:nil];
                NSLog (@"FlyElephant %lld",[outputFileAttributes fileSize]);
                
                break;
            }
        }       
    }]; 
}


+ (void)convertToMp4: (MPMediaItem*)song
{
    
    NSURL*url = [song valueForProperty:MPMediaItemPropertyAssetURL];
    AVURLAsset*songAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    NSFileManager*fileManager = [NSFileManager defaultManager];
    
    
    NSLog(@"compatible presets for songAsset: %@",[AVAssetExportSession exportPresetsCompatibleWithAsset:songAsset]);
    
    NSArray*ar = [AVAssetExportSession exportPresetsCompatibleWithAsset: songAsset];
    
    NSLog(@"%@", ar);
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
                                     
                                     initWithAsset: songAsset
                                     
                                     presetName:AVAssetExportPresetAppleM4A];
    
    NSLog(@"created exporter. supportedFileTypes: %@", exporter.supportedFileTypes);
    
    exporter.outputFileType=@"com.apple.m4a-audio";
    
    NSString*exportFile = [self m4aFormatefilePathForSongName:[song valueForProperty:MPMediaItemPropertyTitle]];;
    
    NSError*error1;
    
    if([fileManager fileExistsAtPath:exportFile])
        
    {
        
        [fileManager removeItemAtPath:exportFile error:&error1];
        
    }
    NSURL *urlPath ;
    urlPath= [NSURL fileURLWithPath:exportFile];
    exporter.outputURL=urlPath;
    
    NSLog(@"---------%@",urlPath);
    
    // do the export
    
    [exporter exportAsynchronouslyWithCompletionHandler:^
     
    {
        
//        NSData*data1 = [NSData dataWithContentsOfFile:exportFile];
        
//        NSLog(@"==================data1:%@",data1);
        
        int exportStatus = exporter.status;
        
        switch(exportStatus) {
                
            case AVAssetExportSessionStatusFailed: {
                
                // log error to text view
                
                NSError*exportError = exporter.error;
                
                NSLog(@"AVAssetExportSessionStatusFailed: %@", exportError);
                
                break;
                
            }
                
            case AVAssetExportSessionStatusCompleted: {
                
                NSLog(@"AVAssetExportSessionStatusCompleted");
                
                break;
                
            }
                
            case AVAssetExportSessionStatusUnknown: {
                
                NSLog(@"AVAssetExportSessionStatusUnknown");
                
                break;
                
            }
                
            case AVAssetExportSessionStatusExporting: {
                
                NSLog(@"AVAssetExportSessionStatusExporting");
                
                break;
                
            }
                
            case AVAssetExportSessionStatusCancelled: {
                
                NSLog(@"AVAssetExportSessionStatusCancelled");
                
                break;
                
            }
                
            case AVAssetExportSessionStatusWaiting: {
                
                NSLog(@"AVAssetExportSessionStatusWaiting");
                
                break;
                
            }
                
            default:
                
            {NSLog(@"didn't get export status");
                
                break;
                
            }
                
        }
        
    }];
    
}
+ (MPMediaQuery *)mediaQueryWithType:(LTMediaQueryType)type filterPredicate:(MPMediaPropertyPredicate *)predicate {
    MPMediaQuery *query = nil;
    switch (type) {
        case 0:
            query = [MPMediaQuery songsQuery];
            break;
        case 1:
            query = [MPMediaQuery artistsQuery];
            break;
        case 2:
            query = [MPMediaQuery albumsQuery];
            break;
        default:
            break;
    }
    if (predicate) {
        [query addFilterPredicate:predicate];
    }
    return query;
    
}

+ (NSArray<MPMediaItem *> *)mediaItemCollectionWithQuery:(MPMediaQuery *)query {
    NSMutableArray *mediaItemArray = [NSMutableArray array];
    for (MPMediaItem *item in query.items) {
        [mediaItemArray addObject:item];
    }
    return mediaItemArray;
}



@end
