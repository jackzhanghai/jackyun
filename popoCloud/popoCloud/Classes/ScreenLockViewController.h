//
//  ScreenLockViewController.h
//  popoCloud
//
//  Created by ice on 13-11-18.
//
//
typedef enum
{
    ScreenLockTypeSetNewPasscode,
    ScreenLockTypeEnter,
    ScreenLockTypeClose,
    ScreenLockTypeReStore,
}
ScreenLockType;
#import <UIKit/UIKit.h>

@interface ScreenLockViewController : UIViewController <UITextFieldDelegate>
{
    UITextField *screenLockField;
    NSMutableArray *numArray;
    NSString *screenLockStr;
    BOOL isShow;
    BOOL shouldRotate;
}
@property (nonatomic,retain) IBOutlet UITextField *num1;
@property (nonatomic,retain) IBOutlet UITextField *num2;
@property (nonatomic,retain) IBOutlet UITextField *num3;
@property (nonatomic,retain) IBOutlet UITextField *num4;
@property (nonatomic,assign) ScreenLockType lockType;
@property (nonatomic,retain) IBOutlet UILabel *desLabel1;
@property (nonatomic,retain) IBOutlet UILabel *desLabel2;
@property (nonatomic,retain) IBOutlet UILabel *titleLabel;
-(BOOL)isOnScreen;
+(void)show;//ScreenLockTypeReStore状态显示锁屏界面
+(ScreenLockViewController *)sharedLock;
-(void)show;
-(void)clearInput;
@end
