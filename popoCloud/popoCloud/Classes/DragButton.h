//
//  DragButton.h
//  popoCloud
//
//  Created by Kortide on 14-2-26.
//
//

#import <UIKit/UIKit.h>

@class DragButton;
@protocol dragLocationDelegate <NSObject>

@optional
-(void)startDragBtn:(DragButton *)btn dragPoint:(CGPoint)point;
-(void)dragBtn:(DragButton *)btn dragPoint:(CGPoint)point;
-(void)endDragBtn:(DragButton *)btn dragPoint:(CGPoint)point;
-(void)cancelDragBtn:(DragButton *)btn dragPoint:(CGPoint)point;
@end


@interface DragButton : UIImageView
{
    
}

@property(nonatomic, assign) id <dragLocationDelegate> delegate ;

@end
