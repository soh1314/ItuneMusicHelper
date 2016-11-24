

#import "LTMusicConvertor.h"
#import <AudioToolbox/AudioToolbox.h>
#import <lame/lame.h>

@implementation LTMusicConvertor

+ (NSString *)wavFormatefilePathForSongName:(NSString *)songName
{
    NSString *documentDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *exportFile = [documentDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.wav",songName]];
    return exportFile;
}

+ (NSString *)m4aFormatefilePathForSongName:(NSString *)songName
{
    NSString *documentDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *exportFile = [documentDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.caf",songName]];
    return exportFile;
}

+ (NSString *)mp3FormatefilePathForSongName:(NSString *)songName
{
    NSString *documentDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *exportFile = [documentDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3",songName]];
    return exportFile;
}


+ (void)convetItuneMusicToWavFormate:(NSURL *)originalUrl  destUrl:(NSURL *)destUrl {
    
    [[NSFileManager defaultManager]createFileAtPath:destUrl.absoluteString contents:nil attributes:nil];
    
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
    
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:                                     [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,                                     [NSNumber numberWithFloat:44100], AVSampleRateKey,                                     [NSNumber numberWithInt:2], AVNumberOfChannelsKey,                                     [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,                                     [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,                                     [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,                                     [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,                                     [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,                                    nil];
    
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
                NSLog (@"outputsize %lld",[outputFileAttributes fileSize]);
                
                break;
            }
        }       
    }]; 
}


+ (void)convertItuneMusicToMp4WithMediaItem: (MPMediaItem*)item
{
    
    NSURL*url = [item valueForProperty:MPMediaItemPropertyAssetURL];
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
    
    NSString*exportFile = [self m4aFormatefilePathForSongName:[item valueForProperty:MPMediaItemPropertyTitle]];
    
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
    
    [exporter exportAsynchronouslyWithCompletionHandler:^ {
    
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

+ (void) cafToMP3WithOrigineFile:(NSString *)cafFilePath desFilePath:(NSString *)mp3FilePath
{
    @try {
        
        int read, write;
        
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:4], "rb");//source 被转换的音频文件位置
        
        fseek(pcm, 4*1024, SEEK_CUR);   //skip file header
        
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:4], "wb");//output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        
        const int MP3_SIZE = 8192;
        
        short int pcm_buffer[PCM_SIZE*2];
        
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        
        lame_set_in_samplerate(lame, 44100);
        
        lame_set_VBR(lame, vbr_default);
        
        lame_init_params(lame);
        
        do {
            
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            
            if (read == 0)
                
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            
            else
                
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        
        fclose(mp3);
        
        fclose(pcm);
        
    }
    
    @catch (NSException *exception) {
        
        NSLog(@"%@",[exception description]);
        
    }
    
    @finally {
        
        NSLog(@"MP3 converted: %@",mp3FilePath);
        
    }
    
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
        
        // itunes中有资源协议，有些资源获取不到;
        if (item.assetURL) {
            
            [mediaItemArray addObject:item];
        }
        else{
            
            continue;
            
        }
        
    }
    
    return mediaItemArray;
}



@end
