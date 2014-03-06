//
//  DragButton.m
//  popoCloud
//
//  Created by Kortide on 14-2-26.
//
//

#import "DragButton.h"

@implementation DragButton
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint point=[touch locationInView:self.superview];
    if (delegate && [delegate respondsToSelector:@selector(startDragBtn:dragPoint:)]) {
            [delegate startDragBtn:self dragPoint:point];
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint point=[touch locationInView:self.superview];
    if (delegate && [delegate respondsToSelector:@selector(dragBtn:dragPoint:)]) {
            [delegate dragBtn:self dragPoint:point];
    }
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
      UITouch *touch=[touches anyObject];
      CGPoint point=[touch locationInView:self.superview];
        if (delegate && [delegate respondsToSelector:@selector(endDragBtn:dragPoint:)])
        {
            [delegate endDragBtn:self dragPoint:point];
        }
        [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
       if (delegate && [delegate respondsToSelector:@selector(cancelDragBtn:dragPoint:)])
       {
            [delegate cancelDragBtn:self dragPoint:CGPointMake(0, 0)];
        }
        [super touchesCancelled:touches withEvent:event];
}

//- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
//{
//    CGPoint point=[touch locationInView:self.superview];
//    if (delegate && [delegate respondsToSelector:@selector(startDragBtn:dragPoint:)]) {
//        [delegate startDragBtn:self dragPoint:point];
//    }
//    return [super beginTrackingWithTouch:touch withEvent:event];
//}
//
//- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
//{
//    CGPoint point=[touch locationInView:self.superview];
//
//    if (delegate && [delegate respondsToSelector:@selector(dragBtn:dragPoint:)]) {
//        [delegate dragBtn:self dragPoint:point];
//    }
//    return [super continueTrackingWithTouch:touch withEvent:event];
//}
//
//- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
//{
//    CGPoint point=[touch locationInView:self.superview];
//    if (delegate && [delegate respondsToSelector:@selector(endDragBtn:dragPoint:)]) {
//        [delegate endDragBtn:self dragPoint:point];
//    }
//    [super endTrackingWithTouch:touch withEvent:event];
//}
//
//- (void)cancelTrackingWithEvent:(UIEvent *)event
//{
//    if (delegate && [delegate respondsToSelector:@selector(cancelDragBtn:dragPoint:)]) {
//        [delegate cancelDragBtn:self dragPoint:CGPointMake(0, 0)];
//    }
//    [super cancelTrackingWithEvent:event];
//}

@end;
