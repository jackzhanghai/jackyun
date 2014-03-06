//
//  PCProgressView.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-10-19.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "PCProgressView.h"

@implementation PCProgressView

- (void) initProgressLabel
{
    if (lblProgress) return;
        
//    stringExt = @"";
    
    CGRect frame = CGRectMake(0, -5, self.frame.size.width, 20);
    lblProgress = [[UILabel alloc] initWithFrame:frame];
    lblProgress.backgroundColor = [UIColor clearColor];
    lblProgress.textAlignment = UITextAlignmentCenter;
    lblProgress.textColor = [UIColor blackColor];
    lblProgress.text = [NSString stringWithFormat:@"%.1f%%",  self.progress * 100];
    [self addSubview:lblProgress];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    lblProgress.frame = CGRectMake(0, -5, self.frame.size.width, 20);
}

//- (void) setLabelExt:(NSString*)strExt {
//    if (strExt) {
//        stringExt = [strExt copy];
//    }
//}

- (void)setProgress:(float)progress {
    if (lblProgress) {
        [lblProgress setHidden:NO];
        float lblProgressText = progress * 100.0;
        if (lblProgressText < 0) lblProgressText = 0.0;
        else if (lblProgressText > 100.0) lblProgressText = 100.0;
        lblProgress.text = [NSString stringWithFormat:@"%.1f%%", lblProgressText];
//        lblProgress.text = [NSString stringWithFormat:@"%.1f%%%@",  lblProgressText, stringExt];
    }
    [super setProgress:progress];
}

- (void) setTip:(NSString*)tip
{
    if (lblProgress) {
        [lblProgress setHidden:NO];
        lblProgress.text = tip;
    }
     [super setProgress:1];
}
@end
