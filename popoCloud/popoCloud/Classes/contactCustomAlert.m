//
//  
//  contactCustomAlert.h
//
//  Created by  on 13-5-29.
//  Copyright (c) 2012年 //

#import "contactCustomAlert.h"

@interface contactCustomAlert ()
    @property(nonatomic, retain) NSMutableArray *_buttonArrays;
    @property(nonatomic, assign) BOOL _firstInit;
@end

@implementation contactCustomAlert

@synthesize backgroundImage,contentImage,_buttonArrays,CustomAlertdelegate;

- (id)initWithImage:(UIImage *)image contentImage:(UIImage *)content  //Rect:(CGRect)drawInRect
{
    if (self = [super initWithFrame:CGRectZero]) {
		//drawRect = drawInRect;
        self.backgroundImage = image;
        self.contentImage = content;
        self._buttonArrays = [NSMutableArray arrayWithCapacity:4];
        self._firstInit = YES;
	    }
    return self;
}

-(void) addButtonWithUIButton:(UIButton *) btn
{
    [_buttonArrays addObject:btn];
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    //CGSize imageSize = self.backgroundImage.size;
   // [self.backgroundImage drawInRect:drawRect];
    //[self.backgroundImage drawInRect:CGRectMake(0, 0, imageSize.width/2, imageSize.height/2)];
    
}

- (void) layoutSubviews {
    self.center = self.superview.center;
    if (self._firstInit)
    {
        //只初始化一次
        self._firstInit = NO;
        //屏蔽系统的ImageView 和 UIButton
        for (UIView *v in [self subviews]) {
            if ([v class] == [UIImageView class]){
                [v setHidden:YES];
            }
            
            
            if ([v isKindOfClass:[UIButton class]] ||
                [v isKindOfClass:NSClassFromString(@"UIThreePartButton")]) {
                
                [v setHidden:YES];
                
            }
        }
        if (backgroundImage)
        {
            UIImageView *background = [[UIImageView alloc] initWithImage:self.backgroundImage];
            background.frame = CGRectMake(0, 0, backgroundImage.size.width/2, backgroundImage.size.height/2);
            [self addSubview:background];
            //add by libing 2013-6-24
            [background release];
            //
        }
        for (int i=0;i<[_buttonArrays count]; i++) {
            UIButton *btn = [_buttonArrays objectAtIndex:i];
            btn.tag = i;
            [self addSubview:btn];
            [btn addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        }
        if (contentImage) {
            UIImageView *contentview = [[UIImageView alloc] initWithImage:self.contentImage];
            contentview.frame = CGRectMake(0, 0, backgroundImage.size.width/2, backgroundImage.size.height/2);
            [self addSubview:contentview];
            [contentview release];
        }
    }
    CGSize imageSize = self.backgroundImage.size;
    self.bounds = CGRectMake(0, 0, imageSize.width/2, imageSize.height/2);
}

-(void) buttonClicked:(id)sender
{
    UIButton *btn = (UIButton *) sender;
    
    if (CustomAlertdelegate) {
        if ([CustomAlertdelegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)])
        {
            [CustomAlertdelegate customAlertView:self clickedButtonAtIndex:btn.tag];
        }
    }
    
    [self dismissWithClickedButtonIndex:0 animated:YES];

}

- (void) show {
        [super show];
        //CGSize imageSize = self.backgroundImage.size;
        //self.bounds = CGRectMake(0, 0, imageSize.width, imageSize.height);
        

}


- (void)dealloc {
    [_buttonArrays removeAllObjects];
    [backgroundImage release];
    if (contentImage) {
        [contentImage release];
        contentImage = nil;
    }
   
    [super dealloc];
}


@end


