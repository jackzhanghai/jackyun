//
//  SecurityProtectionViewController.m
//  popoCloud
//
//  Created by suleyu on 13-5-30.
//
//

#import "SecurityProtectionViewController.h"
#import "PCUtility.h"
#import "PCUtilityUiOperate.h"
#import "PCUserInfo.h"
#define  ERR_LONG_ANSWER                 @"答案字数超过限制！"
@interface SecurityProtectionViewController ()
{
    PCAccountManagement *accountManagement;
}
@property (retain, nonatomic) NSArray *questions;
@property (retain, nonatomic) NSMutableDictionary *answers;

@end

@implementation SecurityProtectionViewController
@synthesize questions;
@synthesize answers;
@synthesize historyAlertViewTag;
@synthesize historyAnswer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"安全问题设置";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [self orientationDidChange:self.interfaceOrientation];
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"SecurityProtectionView"];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (accountManagement == nil)
    {
        accountManagement = [[PCAccountManagement alloc] init];
        accountManagement.delegate = self;
    }
    [accountManagement getSecurityQuestions];

}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (accountManagement)
    {
        [accountManagement cancelAllRequests];
    }
    [MobClick endLogPageView:@"SecurityProtectionView"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [self setBgTableView:nil];
    [self setButtonSubmit:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    [self setTableView:nil];
    [self setBgTableView:nil];
    [self setButtonSubmit:nil];
    self.historyAnswer = nil;
    if (accountManagement)
    {
        [accountManagement release];
    }
    [questions release];
    [answers release];
    [super dealloc];
}

#pragma mark -  OrientationChange

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

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self orientationDidChange:interfaceOrientation];
}

- (void)orientationDidChange:(UIInterfaceOrientation)interfaceOrientation
{
    if (!IS_IPAD) return;
    
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        self.bgTableView.image = [UIImage imageNamed:@"question_bg_l"];
        self.bgTableView.frame = CGRectMake(43, 60, 938, 368);
        self.buttonSubmit.frame = CGRectMake(890, 65, 81, 34);
        self.tableView.frame = CGRectMake(54, 60, 916, 368);
    }
    else {
        self.bgTableView.image = [UIImage imageNamed:@"question_bg"];
        self.bgTableView.frame = CGRectMake(31, 60, 705, 368);
        self.buttonSubmit.frame = CGRectMake(645, 65, 81, 34);
        self.tableView.frame = CGRectMake(42, 60, 682, 368);
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.questions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= self.questions.count) {
        return nil;
    }
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
        cell.backgroundColor = [UIColor clearColor];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.textLabel.font = [UIFont systemFontOfSize:14.0f];
    }
    
    NSDictionary *question = self.questions[indexPath.row];
    cell.textLabel.text = [question valueForKey:@"question"];
    cell.detailTextLabel.text = self.answers[[NSNumber numberWithInteger:indexPath.row]];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIAlertView * inputAnswerAlert = [[UIAlertView alloc] initWithTitle:@"请输入您的答案"
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                      otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    inputAnswerAlert.tag = indexPath.row;
    inputAnswerAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *textField = [inputAnswerAlert textFieldAtIndex:0];
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.text = self.answers[[NSNumber numberWithInteger:indexPath.row]];
    //[textField addTarget:self action:@selector(textFieldDidChanged:) forControlEvents:UIControlEventEditingChanged];
    
    [inputAnswerAlert show];
    [inputAnswerAlert release];
}

- (void)textFieldDidChanged:(UITextField *)textField
{
    if ([textField.text isEqualToString:@" "]) {
        textField.text = nil;
    }
}

- (IBAction)submit:(id)sender
{
    if (self.answers.count < 2) {
        [ErrorHandler showAlert:PC_Err_Unknown description:@"请至少填写两个问题的答案"];
        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:answers.count];
    for(NSNumber *aKey in answers)
    {
        NSDictionary *question = questions[[aKey integerValue]];
        params[[question valueForKey:@"id"]] = answers[aKey];
    }
    
    if (accountManagement)
    {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.navigationController.navigationBar.userInteractionEnabled = NO;
        //提交安全问题
        [accountManagement submitSecurityQuestionsAndAnswer:params];
    }

}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput) {
        if (buttonIndex == [alertView firstOtherButtonIndex]) {
            NSString *answer = [[alertView textFieldAtIndex:0] text];
            answer = [answer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            int feedBackLen = [answer lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            if (feedBackLen >MAX_ANSWER_LEN) {
                self.historyAlertViewTag = alertView.tag;
                self.historyAnswer =  answer;
                [PCUtilityUiOperate showErrorAlert:ERR_LONG_ANSWER delegate:self];
            }
            else{
                if (answer.length > 0) {
                    self.answers[[NSNumber numberWithInteger:alertView.tag]] = answer;
                }
                else {
                    [self.answers removeObjectForKey:[NSNumber numberWithInteger:alertView.tag]];
                }
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:alertView.tag inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }
    else if ([alertView.message isEqualToString:ERR_LONG_ANSWER]) {
        UIAlertView * inputAnswerAlert = [[UIAlertView alloc] initWithTitle:@"请输入您的答案"
                                                                    message:nil
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        inputAnswerAlert.tag = self.historyAlertViewTag;
        inputAnswerAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        
        UITextField *textField = [inputAnswerAlert textFieldAtIndex:0];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        //[textField addTarget:self action:@selector(textFieldDidChanged:) forControlEvents:UIControlEventEditingChanged];
        textField.text = self.historyAnswer;
        [inputAnswerAlert show];
        [inputAnswerAlert release];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - PCAccountManagementDelegate
-(void)getSecurityQuestionsSuccess:(PCAccountManagement *)pcAccountManagement withQuestions:(NSArray *)questionsArray
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.questions = questionsArray;
    self.answers = [NSMutableDictionary dictionaryWithCapacity:self.questions.count];
    [self.tableView reloadData];
}

-(void)getSecurityQuestionsFailed:(PCAccountManagement *)pcAccountManagement withError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [ErrorHandler showErrorAlert:error delegate:self];
}

-(void)submitSecurityQuestionsSuccess:(PCAccountManagement *)pcAccountManagement
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [PCUserInfo currentUser].setSecurityQuestion = YES;
    [MobClick event:UM_QUESTION_SUBMIT_SUCCESS];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)submitSecurityQuestionsFailed:(PCAccountManagement *)pcAccountManagement withError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [ErrorHandler showErrorAlert:error];
}
@end
