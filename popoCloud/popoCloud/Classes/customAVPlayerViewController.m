//
//  customAVPlayerViewController.m
//  popoCloud
//
//  Created by Kortide on 13-11-19.
//
//

#import "customAVPlayerViewController.h"
#import "PCUtilityUiOperate.h"

@interface customAVPlayerViewController ()

@end

@implementation customAVPlayerViewController
@synthesize   mp4Player;
@synthesize   mp4PlayerItem;
@synthesize   audioMix;
@synthesize   volumeMixInput;


- (void)playerItemDidReachEnd:(NSNotification *)notification {
    //AVPlayerItem *p = [notification object];
    //[p seekToTime:kCMTimeZero];
    
    self.mp4Player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
}

- (void)startplay:(id)sender
{
    [self.mp4Player play];
}

- (id)initWithContentUrl:(NSURL*)url
{
    self = [super init];
    if (self) {
        // Custom initialization
        AVURLAsset *movieAsset    = [[[AVURLAsset alloc]initWithURL:url options:nil]autorelease];
        
        self.mp4PlayerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
        [self.mp4PlayerItem addObserver:self forKeyPath:@"status" options:0 context:NULL];
        self.mp4Player = [AVPlayer playerWithPlayerItem:self.mp4PlayerItem];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.mp4Player];
        playerLayer.frame = self.view.layer.bounds;
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [self.view.layer addSublayer:playerLayer];
        [self.mp4Player setAllowsExternalPlayback:YES];
        self.mp4Player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        playBeginState = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:[self.mp4Player currentItem]];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(200, 4, 70, 39);
        button.titleLabel.font = [UIFont systemFontOfSize:15.0];
        [button setBackgroundImage:[[UIImage imageNamed:@"btn_a"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)] forState:UIControlStateNormal];
        
        [button setTitle:@"开始" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(startplay:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"])
    {
        int status = self.mp4Player.currentItem.status;
        if (AVPlayerItemStatusReadyToPlay == status)
        {
            [self.mp4Player play];
        }
        else
        {
            [PCUtilityUiOperate showErrorAlert:@"播放失败" delegate:nil];
        }
    }
}


-(void) setVolume:(float)volume{
    //作品音量控制
    NSMutableArray *allAudioParams = [NSMutableArray array];
    AVMutableAudioMixInputParameters *audioInputParams =[AVMutableAudioMixInputParameters audioMixInputParameters];
    [audioInputParams setVolume:volume atTime:kCMTimeZero];
    [audioInputParams setTrackID:1];
    [allAudioParams addObject:audioInputParams];
    audioMix = [AVMutableAudioMix audioMix];
    [audioMix setInputParameters:allAudioParams];
    [self.mp4PlayerItem setAudioMix:audioMix]; // Mute the player item
    
    [self.mp4Player setVolume:volume];
}


- (NSTimeInterval) playableDuration
{
    AVPlayerItem * item = self.mp4Player.currentItem;
    if (item.status == AVPlayerItemStatusReadyToPlay) {
        return CMTimeGetSeconds(self.mp4Player.currentItem.duration);
    }
    else
    {
        return(CMTimeGetSeconds(kCMTimeInvalid));
    }
}
- (NSTimeInterval) playableCurrentTime
{
    AVPlayerItem * item = self.mp4Player.currentItem;
    
    if (item.status == AVPlayerItemStatusReadyToPlay) {
        NSLog(@"%f\n",CMTimeGetSeconds(self.mp4Player.currentItem.currentTime));
        if (!playBeginState&&CMTimeGetSeconds(self.mp4Player.currentItem.currentTime)==CMTimeGetSeconds(self.mp4Player.currentItem.duration)) {
            [self.mp4Player pause];
        }
        playBeginState = NO;
        return CMTimeGetSeconds(self.mp4Player.currentItem.currentTime);
    }
    else
    {
        return(CMTimeGetSeconds(kCMTimeInvalid));
    }
}


- (void)dealloc
{
    self.mp4Player = nil;
    self.mp4PlayerItem = nil;
    self.audioMix = nil;
    self.volumeMixInput = nil;
    [super dealloc];
}

@end
