

#import "TableViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "LTPhoneAuthorization.h"
#import "TableViewCell.h"
#import "Reachability.h"
#import "LTMusicConvertor.h"
#define IPODMUSICURL @"ipod-library://item/item.mp3?id="
@interface TableViewController ()<MPPlayableContentDataSource>
{
    AVPlayer *player;
}
@property (strong, nonatomic) MPMusicPlayerController *musicPlayerController;
@property (strong, nonatomic) id routerController;
@property (strong, nonatomic) NSMutableArray *musicArray;
@property (nonatomic, assign) BOOL isPlayMusic;
@property (nonatomic, assign) MPMoviePlaybackState musicPlaybackState;
@property (nonatomic, assign) NSInteger  currentIndex;
@property (nonatomic, strong) AVAudioSession *session;

@property (nonatomic, assign) BOOL user;

@end

@implementation TableViewController

- (void)dealloc
{
    [self.musicPlayerController endGeneratingPlaybackNotifications];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNavigationBar];

    Reachability* reach = [Reachability reachabilityWithHostName:@"www.hamedata.com"];
    
    // Tell the reachability that we DON'T want to be reachable on 3G/EDGE/CDMA

    [reach startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    [self checkAuthorizationStatus];
    [self addNotification];
    
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.currentIndex = -1;
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0) {
        self.musicPlayerController =  [MPMusicPlayerController systemMusicPlayer];//初始化系统音乐播放器
    }else{
        self.musicPlayerController =  [MPMusicPlayerController applicationMusicPlayer];
        
    }
    [self.musicPlayerController beginGeneratingPlaybackNotifications];
    self.musicPlaybackState = self.musicPlayerController.playbackState;
    
//
//    AVAudioPlayer * player = [[AVAudioPlayer alloc]initWithContentsOfURL:file error:nil];
//    [player play];
    [self getMusicListFromMusicLibrary];
    [self fetchRouterArray];
    _isPlayMusic = YES;
   
}

- (void)fetchRouterArray {
    NSLog(@"%@",self.session.inputDataSource);
    NSLog(@"%@",self.session.availableInputs);

    NSArray<AVAudioSessionDataSourceDescription *>  * routerArray = self.session.outputDataSources;
    for (AVAudioSessionDataSourceDescription *router in routerArray) {
        NSLog(@"%@",[router dataSourceName]);
    }
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(playbackStateChanged:) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(serviceLost:) name:AVAudioSessionMediaServicesWereLostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionRouteChangeHandle:) name:AVAudioSessionRouteChangeNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartServer:) name:AVAudioSessionMediaServicesWereResetNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaLibraryChanged:) name:MPMediaLibraryDidChangeNotification object:nil];
}

- (void)mediaLibraryChanged:(NSNotification *)noti {
    NSLog(@"mediaLibrary changed");
}

- (void)restartServer:(NSNotification *)noti {
    NSLog(@"--------------------重启服务");
}

- (void)serviceLost:(NSNotification *)noti {
    NSLog(@"%@",noti.object);
    NSLog(@"service lost");
}

- (void)audioSessionRouteChangeHandle:(NSNotification*)noti {
    
    NSLog(@"%@",self.session.currentRoute.outputs[0].portName);
    NSLog(@"%@",noti.userInfo[AVAudioSessionRouteChangeReasonKey]);
}

- (void)setNavigationBar {
    MPVolumeView *myVolumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0,0, 45, 33)];
    myVolumeView.showsVolumeSlider = NO;
    myVolumeView.showsRouteButton = YES;
    [myVolumeView setRouteButtonImage:[UIImage imageNamed:@"airPlay-29"] forState:UIControlStateNormal];
    [myVolumeView setRouteButtonImage:[UIImage imageNamed:@"airPlay-29"]  forState:UIControlStateNormal];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:myVolumeView];
    self.navigationItem.leftBarButtonItem = button;
    self.navigationController.navigationBar.translucent = YES;

}

- (void)checkAuthorizationStatus {
    [LTPhoneAuthorization requestItunesMediaAuthorization:^(LTPhoneAuthorizationStatus status) {
        if (status == LTAuthorizationStatusDenied) {
            NSLog(@"媒体库权限拒绝");
        }
        else if (status == LTAuthorizationStatusAuthorized) {
            NSLog(@"媒体库权限通过");
        }
        else {
            NSLog(@"媒体库权限未知");
        }
    }];
}

- (void)playbackStateChanged:(NSNotification *)noti {
    NSLog(@"%@",noti.object);
    MPMusicPlayerController *weakSelf = noti.object;
    NSLog(@"%ld",weakSelf.playbackState);
    
}


- (void)reachabilityChanged:(NSNotification *)noti {
    Reachability *currReach = [noti object];
    NSParameterAssert([currReach isKindOfClass:[Reachability class]]);
    
    NetworkStatus status = [currReach currentReachabilityStatus];
    switch (status)
    {
        case NotReachable:        {
            NSLog(@"网络监测 ----- 无法连接");
            break;
        }
            
        case ReachableViaWWAN:        {
            NSLog(@"网络监测--------蜂窝");
            break;
        }
        case ReachableViaWiFi:        {
            NSLog(@"网络监测--------wifi");
            break;
        }
    }

}




- (BOOL)isPlayingItem {
    if ([self.musicPlayerController indexOfNowPlayingItem] == NSNotFound) {
        return NO;
    } else {
        return YES;
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (MPMediaItemCollection *)getMusicListFromMusicLibrary {
    MPMediaQuery *allMp3 = [[MPMediaQuery alloc] init];
    // 读取条件
    MPMediaPropertyPredicate *albumNamePredicate =
    [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInt:MPMediaTypeMusic ] forProperty: MPMediaItemPropertyAlbumTitle];
    [allMp3 addFilterPredicate:albumNamePredicate];
    
    NSLog(@"Logging items from a generic query...");
    for (MPMediaItem *song in  [allMp3 items]) {
        //            NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
        NSString *songTitle = song.title;
        NSLog (@"%@, %@, %@", songTitle, song.assetURL,song.artist);
    }
    MPMediaQuery *mediaQueue = [MPMediaQuery artistsQuery];
    for (MPMediaItemCollection * collection in mediaQueue.collections) {
        NSLog(@"%ld",mediaQueue.collections.count);
        for (MPMediaItem *item in collection.items) {
            NSLog(@"%@",item.title);
        }
        NSLog(@"-------------");
    }
    // 申明一个Collection便于下面给musicPlayerController赋值
    MPMediaItemCollection *mediaItemCollection;
    if (mediaQueue.items.count == 0) {
        return 0;
    } else {
        //获取本地音乐库文件
        [self.musicArray removeAllObjects];
        for(MPMediaItem *item in mediaQueue.items) {
            [self.musicArray addObject:item];
            NSLog(@"%@--%@%@",item.title,item.assetURL,[item valueForProperty:MPMediaItemPropertyPodcastPersistentID]);
            if ([[item valueForProperty:MPMediaItemPropertyHasProtectedAsset] integerValue]== 0) {
                NSURL *assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
                NSString *path = [LTMusicConvertor wavFormatefilePathForSongName:[item valueForProperty:MPMediaItemPropertyTitle]];
                [LTMusicConvertor convetItuneMusicToWavFormate:assetURL destUrl:[NSURL fileURLWithPath:path]];
//                [LTMusicConvertor convertToMp4:item];
                break;
            }
        }
        
        // 将音乐信息赋值给musicPlayerController
        mediaItemCollection = [[MPMediaItemCollection alloc] initWithItems:[self.musicArray copy]];
        [self.musicPlayerController setQueueWithItemCollection:mediaItemCollection];
    }
   
    return mediaItemCollection;
}

- (NSMutableArray *)musicArray
{
    if (!_musicArray) {
        _musicArray = [NSMutableArray array];
    }
    return _musicArray;
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"音乐计数:%ld",self.musicArray.count);
    return self.musicArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"musicListCell";
    
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[TableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    
    MPMediaItem *item = self.musicArray[indexPath.row];
    NSString *musicName = [item valueForKey:MPMediaItemPropertyTitle];
    NSString *musicSinger = [item valueForKey:MPMediaItemPropertyAlbumArtist];
    // 专辑图片
    MPMediaItemArtwork *artwork= [item valueForKey:MPMediaItemPropertyArtwork];
    UIImage *image=[artwork imageWithSize:CGSizeMake(100, 100)];
    
    cell.musicImageView.image = image;
    cell.musicTitleLabel.text = musicName;
    cell.musicSingerLabel.text = musicSinger;
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"%@",[self.musicArray[indexPath.row] artist] );
//    [self.musicPlayerController setNowPlayingItem:self.musicArray[indexPath.row]];
//    NSLog(@"%lu",(unsigned long)self.musicPlayerController.indexOfNowPlayingItem);
//    if (self.musicPlaybackState == MPMusicPlaybackStatePlaying) {
//        [self.musicPlayerController pause];//暂停
//        self.musicPlaybackState = MPMusicPlaybackStatePaused;
//        
//    }else if (self.musicPlaybackState == MPMusicPlaybackStateStopped || self.musicPlaybackState == MPMusicPlaybackStatePaused || self.musicPlaybackState == MPMusicPlaybackStateInterrupted) {
//        [self.musicPlayerController play]; //播放
//        self.musicPlaybackState = MPMusicPlaybackStatePlaying;
//        
//    }
//    if (self.currentIndex != indexPath.row) {
//        self.currentIndex = indexPath.row;
//        if (self.musicPlaybackState == MPMusicPlaybackStatePlaying) {
//            [self.musicPlayerController pause];
//        }
//    }
    MPMediaItem * item = self.musicArray[0];
    
    AVAudioPlayer * player = [[AVAudioPlayer alloc]initWithContentsOfURL:[LTMusicConvertor wavFormatefilePathForSongName:item.title] error:nil];
    [player play];
//    [self.musicPlayerController setNowPlayingItem:self.musicArray[indexPath.row]];
//    [self.musicPlayerController play]; //播放
//    self.musicPlaybackState = MPMusicPlaybackStatePlaying;
//     NSLog(@"%@",self.session.currentRoute.outputs);

}



- (void)musicPlay{
    
    NSLog(@"%lu",(unsigned long)self.musicPlayerController.indexOfNowPlayingItem);
    if (self.musicPlaybackState == MPMusicPlaybackStatePlaying) {
        [self.musicPlayerController pause];//暂停
        self.musicPlaybackState = MPMusicPlaybackStatePaused;
        
    }else if (self.musicPlaybackState == MPMusicPlaybackStateStopped || self.musicPlaybackState == MPMusicPlaybackStatePaused || self.musicPlaybackState == MPMusicPlaybackStateInterrupted) {
        [self.musicPlayerController play]; //播放
        self.musicPlaybackState = MPMusicPlaybackStatePlaying;
        
    }
    
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
