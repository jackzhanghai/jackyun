//
//  customAVPlayerViewController.h
//  popoCloud
//
//  Created by Kortide on 13-11-19.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface customAVPlayerViewController : UIViewController
{
    AVPlayer *mp4Player;
    AVPlayerItem *mp4PlayerItem;
    id audioMix;
    id volumeMixInput;
    BOOL playBeginState;
}

@property(nonatomic,retain)  AVPlayer *mp4Player;
@property(nonatomic,retain)  AVPlayerItem *mp4PlayerItem;
@property(nonatomic,retain)  id audioMix;
@property(nonatomic,retain)  id volumeMixInput;
- (id)initWithContentUrl:(NSURL*)url;

@end
