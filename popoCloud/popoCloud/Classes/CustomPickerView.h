//
//  CustomPickerView.h
//  popoCloud
//
//  Created by xy  on 13-5-20.
//
//

#import <UIKit/UIKit.h>
@class CustomPickerView;
@protocol CustomPickerViewDelegate <NSObject>
-(void)customPickerViewClickCancelButton:(CustomPickerView *)picker;
-(void)customPickerViewClickOKButton:(CustomPickerView *)picker;
@end
@interface CustomPickerView : UIView <UIPickerViewDataSource, UIPickerViewDelegate> {
    
    NSMutableArray *contactFileName;
    UIPickerView *selectPicker;
    int        selectedContactFile;
}
- (NSInteger)getResult;
- (void)updateContactFileName:(NSArray *)fileName;
@property (nonatomic,assign) id<CustomPickerViewDelegate> delegate;
@end