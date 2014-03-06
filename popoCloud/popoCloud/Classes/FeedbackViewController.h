//
//  FeedbackViewController.h
//  popoCloud
//
//  Created by suleyu on 13-6-17.
//
//

#import <UIKit/UIKit.h>
#import "UIPlaceholderTextView.h"
@class KTURLRequest;

@interface FeedbackViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIPlaceholderTextView *textFeedback;
@property (strong, nonatomic) IBOutlet UIImageView *bgFeedback;
@property (strong, nonatomic) IBOutlet UIButton *buttonSubmit;
@property (strong, nonatomic)  KTURLRequest *currentRequest;

- (IBAction)hideKeyboard:(id)sender;
- (IBAction)submit:(id)sender;

@end
