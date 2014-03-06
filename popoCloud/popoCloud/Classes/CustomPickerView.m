//
//  CustomPickerView.m
//  popoCloud
//
//  Created by xy  on 13-5-20.
//
//

#import "CustomPickerView.h"
#import "PCUtility.h"
#import "PCUtilityStringOperate.h"
#define componentCount 1
#define majorComponent 0


@implementation CustomPickerView
@synthesize delegate;
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame])
    {
        UIImageView *bg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        bg.image = [[UIImage imageNamed: @"TSAlertViewBackground.png"] stretchableImageWithLeftCapWidth: 15 topCapHeight: 30];
        [self addSubview:bg];
        [bg release];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, frame.size.width, 30)];
        title.backgroundColor = [UIColor clearColor];
        title.textColor = [UIColor whiteColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.text = NSLocalizedString(@"Please select the address book you want to import", nil);
        [self addSubview:title];
        [title release];
        
        contactFileName=[[NSMutableArray alloc]init];
        if (IS_IPAD)
        {
            selectPicker = [[UIPickerView alloc] initWithFrame:CGRectMake((frame.size.width - 480)/2,title.frame.origin.y + title.frame.size.height + 5,480,216)];
            
        }
        else
        {
            selectPicker = [[UIPickerView alloc] initWithFrame:CGRectMake((frame.size.width - 235)/2,title.frame.origin.y + title.frame.size.height + 5,235,216)];
        }
        selectPicker.backgroundColor = [UIColor whiteColor];
        selectPicker.showsSelectionIndicator = YES;
        selectPicker.delegate = self;
        selectPicker.dataSource = self;
        selectPicker.opaque = YES;
        [self addSubview:selectPicker];
        
        UIImage* buttonBgNormal = [UIImage imageNamed: @"TSAlertViewButtonBackground.png"];
        buttonBgNormal = [buttonBgNormal stretchableImageWithLeftCapWidth: buttonBgNormal.size.width / 2.0 topCapHeight: buttonBgNormal.size.height / 2.0];
        
        
        
        UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [cancelBtn setBackgroundImage: buttonBgNormal forState: UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(cancelBtnAction) forControlEvents:UIControlEventTouchUpInside];
        cancelBtn.frame = CGRectMake(10, selectPicker.frame.size.height + selectPicker.frame.origin.y + 10, (frame.size.width - 30)/2 , (frame.size.height -  selectPicker.frame.size.height - selectPicker.frame.origin.y)/2);
        [cancelBtn setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        [self addSubview:cancelBtn];
        
        UIButton *okBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [okBtn setBackgroundImage: buttonBgNormal forState: UIControlStateNormal];
        [okBtn addTarget:self action:@selector(okBtnAction) forControlEvents:UIControlEventTouchUpInside];
        okBtn.frame = CGRectMake(cancelBtn.frame.origin.x + cancelBtn.frame.size.width + 10, selectPicker.frame.size.height + selectPicker.frame.origin.y + 10, (frame.size.width - 30)/2 , (frame.size.height -  selectPicker.frame.size.height - selectPicker.frame.origin.y)/2);
        [okBtn setTitle:NSLocalizedString(@"OK", nil) forState:UIControlStateNormal];
        [self addSubview:okBtn];
    }
    return self;
}
-(void)okBtnAction
{
    if (delegate && [delegate respondsToSelector:@selector(customPickerViewClickOKButton:)]) {
        [delegate customPickerViewClickOKButton:self];
    }
}
-(void)cancelBtnAction
{
    if (delegate && [delegate respondsToSelector:@selector(customPickerViewClickCancelButton:)]) {
        [delegate customPickerViewClickCancelButton:self];
    }
}
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return componentCount;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component==majorComponent) {
        return [contactFileName count];
    }
    return 0;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    
    UITextView *printString = nil;
    
    if (IS_IPAD)
        printString = [[UITextView alloc] initWithFrame:CGRectMake(5,0,460,40)];
    else
        printString = [[UITextView alloc] initWithFrame:CGRectMake(10,0,215,40)];
    NSString *text = [contactFileName objectAtIndex:row];
    printString.editable = NO;
    
    NSString *drawStr =  [PCUtilityStringOperate decodeFromPercentEscapeString:text];
    printString.text = [drawStr substringToIndex:[drawStr length] -4];
    [printString setFont:[UIFont fontWithName:@"contactFileName" size:15.0f]];
    
    [printString autorelease];
    printString.backgroundColor=[UIColor clearColor];
    printString.textAlignment=NSTextAlignmentLeft;
    
    return printString;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 45.0;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    if (component==majorComponent) {
        //return majorComponentWidth;
        if (IS_IPAD)
            return 460;
        else
            return 215;
    }
    return 0;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    selectedContactFile = [pickerView selectedRowInComponent:majorComponent];
}

//- (void)setFrame:(CGRect)rect {
//    CGRect mainRect = [[UIScreen mainScreen] bounds];
//    self.center = CGPointMake(mainRect.size.width/2, mainRect.size.height/2);
//    if (IS_IPAD)
//    {
//        if ([[UIScreen mainScreen] applicationFrame].size.height==1024)
//        {
//            [super setFrame:CGRectMake(mainRect.size.height/2-284,mainRect.size.width/2 -180, 568, 360)];
//        }
//        else
//        {
//            [super setFrame:CGRectMake(mainRect.size.width/2 -284,  mainRect.size.height/2-180, 568, 360)];
//        }
//    }
//    else
//    {
//        [super setFrame:CGRectMake(20, 50, 284, 330)];
//    }
//
//    //[super setFrame:rect];
//}
//
//- (void)layoutSubviews {
//    if(IS_IPAD)
//    {
//        selectPicker.frame = CGRectMake(15,48,540,800);
//    }
//    else
//    {
//        if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
//        {
//            selectPicker.frame = CGRectMake(10,45,self.frame.size.width - 48,self.frame.size.height-50);
//        }
//        else
//        {
//            selectPicker.frame = CGRectMake(8,45,self.frame.size.width - 16,self.frame.size.height-50);
//        }
//
//    }
//
//    for (UIView *view in self.subviews) {
//        if ([[[view class] description] isEqualToString:@"UIAlertButton"])
//        {
//            if ([[UIScreen mainScreen] applicationFrame].size.height==1024)
//            {
//                view.frame = CGRectMake(view.frame.origin.x-132, self.bounds.size.height - view.frame.size.height - 15, view.frame.size
//                                        .width, view.frame.size.height);
//            }
//            else
//            {
//                view.frame = CGRectMake(view.frame.origin.x, self.bounds.size.height - view.frame.size.height - 15, view.frame.size
//                                        .width, view.frame.size.height);
//            }
//
//        }
//    }
//}

- (NSInteger)getResult
{
    return selectedContactFile;
}

- (void)dealloc
{
    [contactFileName release];
    if (selectPicker)
    {
        [selectPicker release];
    }
    [super dealloc];
}
- (void)updateContactFileName:(NSArray *)fileName
{
    for (NSString *name in fileName)
    {
        [contactFileName addObject:name];
    }
    [selectPicker reloadAllComponents];
}

@end
