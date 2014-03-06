//
//  CustomMediaPlayerViewController.h
//  popoCloud
//
//  Created by Kortide on 13-11-13.
//
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface CustomMediaPlayerViewController : UIViewController
{
    NSURL *mUrl;
}
@property (retain, nonatomic) NSURL *mUrl;
@property (retain, nonatomic) MPMoviePlayerController *currentController;
- (MPMoviePlayerController*) moviePlayer;
- (id)initWithContentURL:(NSURL*)url;
@end
