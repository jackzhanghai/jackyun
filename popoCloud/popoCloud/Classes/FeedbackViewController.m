//
//  FeedbackViewController.m
//  popoCloud
//
//  Created by suleyu on 13-6-17.
//
//

#import "FeedbackViewController.h"
#import "PCUtility.h"
#import "PCUtilityGetDeviceInfo.h"
#import "PCUtilityUiOperate.h"
#import "PCUtilityStringOperate.h"
#import "PCUserInfo.h"
#import "PCURLRequest.h"

@interface FeedbackViewController ()

@property (retain, nonatomic) NSMutableData *data;

@end

@implementation FeedbackViewController
@synthesize data;
@synthesize currentRequest;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"意见反馈";
    
    self.textFeedback.placeholder = @"您遇到的问题以及建议，发送给我们，泡泡云将努力做得更好！";
    
    [self.bgFeedback setImage:[[UIImage imageNamed:@"textfeild_rect"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)]];
    
    [self.buttonSubmit setBackgroundImage:[[UIImage imageNamed:@"btn_green_3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateNormal];
    [self.buttonSubmit setBackgroundImage:[[UIImage imageNamed:@"btn_green_d3x2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 2)] forState:UIControlStateHighlighted];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"FeedbackView"];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"FeedbackView"];
}

- (void)viewDidUnload {
    [self setTextFeedback:nil];
    [self setBgFeedback:nil];
    [self setButtonSubmit:nil];
    [super viewDidUnload];
}

- (void)dealloc
{
    if (self.currentRequest) {
        [self.currentRequest cancel];
        self.currentRequest = nil;
    }
    [self setTextFeedback:nil];
    [self setBgFeedback:nil];
    [self setButtonSubmit:nil];
    
    [data release];
    [super dealloc];
}

- (IBAction)hideKeyboard:(id)sender
{
    [self.textFeedback resignFirstResponder];
}

- (IBAction)submit:(id)sender {
    NSString *feedback = [self.textFeedback.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (feedback.length == 0) {
        [PCUtilityUiOperate showErrorAlert:@"请先输入您的意见！" delegate:nil];
        return;
    } 
    int feedBackLen = [feedback lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (feedBackLen >MAX_FEED_BACK_LEN) {
        [PCUtilityUiOperate showErrorAlert:@"字数超过限制！" delegate:nil];
        return;
    }

    [self.textFeedback resignFirstResponder];
    [self  submitFeedback:feedback];
}

- (void)submitFeedback:(NSString*)feedback
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    
    PCURLRequest *request = [[PCURLRequest alloc] initWithTarget:self selector:@selector(requestDidGotFeedbackResult:)];
    request.process = @"accounts/saveFeedback";
    request.method = @"POST";
    request.urlServer = SERVER_HOST;
    request.params =     [NSDictionary dictionaryWithObjectsAndKeys:
                          [[PCUserInfo currentUser] userId],  @"username",
                          [[PCUserInfo currentUser] password], @"password",
                          [PCUtilityGetDeviceInfo deviceModel],@"deviceModelNum",
                          [NSNumber numberWithInt:2],@"platform",
                          [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"],@"clientVersion",
                          [PCUtilityStringOperate encodeToPercentEscapeString:feedback],
                          @"content",nil];
    self.currentRequest = request;
    [request start];
    [request release];
}

- (void)requestDidGotFeedbackResult:(KTURLRequest *)request
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;

    if (request.error) {
            [ErrorHandler showErrorAlert:request.error];
    } else {
        DLogInfo(@"ret: %@", [request resultString]);
        NSDictionary *dict = (NSDictionary *)[request resultJSON];
        
        if (dict) {
            int result = [[dict valueForKey:@"result"] intValue];
            if (result == 0) {
                [PCUtilityUiOperate showOKAlert:@"已提交，感谢您的反馈！" delegate:self];
            }
            else {
                if ([dict objectForKey:@"errCode"]) {
                    result = [[dict objectForKey:@"errCode"] intValue];
                }
                NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:result userInfo:dict];
                [ErrorHandler showErrorAlert:error];
            }
        }
        else {
            NSError *error = [NSError errorWithDomain:KTServerErrorDomain code:PC_Err_Unknown userInfo:nil];
            [ErrorHandler showErrorAlert:error];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return  IS_IPAD ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (IS_IPAD || (interfaceOrientation == UIInterfaceOrientationPortrait));
}
@end
