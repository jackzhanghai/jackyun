//
//  ShareDetailViewController.m
//  ECloud
//
//  Created by Chen Dongxiao on 11-9-20.
//  Copyright 2011年 Kortide. All rights reserved.
//

#import "ShareDetailViewController.h"
#import "PCUtility.h"
#import "FileCache.h"
#import "PCOpenFile.h"
#import "PCLogin.h"
#import "FileListViewController.h"

#define STATUS_DELETE_SHARE 1
#define STATUS_CHECK_SHARE_OPEN 2
#define STATUS_CHECK_SHARE_URL 3
@implementation ShareDetailViewController

@synthesize detail;
@synthesize shareManagerViewController;
@synthesize lblUrl;
@synthesize lblPath;
@synthesize btnPath;
@synthesize btnUrl;
@synthesize imgLine;
@synthesize scrollView;
@synthesize dicatorView;
@synthesize mStatus;
@synthesize fileCacheArr;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        mStatus = STATUS_DELETE_SHARE;
         fileCacheArr = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    if (shareUrl)
    {
     [shareUrl release];
    }
    [data release];
     data = nil;
     [super dealloc];
}


#pragma mark - View lifecycle

- (void)viewWillDisappear:(BOOL)animated
{
    for (FileCache *cache in fileCacheArr) {
        cache.delegate = nil;
        [cache cancel];
    }
    
    [fileCacheArr removeAllObjects];
    [fileCacheArr  release];
    fileCacheArr = nil;
    
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    /*
    lblUrl.text = [detail objectForKey:@"url"];
    lblUrl.lineBreakMode = UILineBreakModeWordWrap;
    lblUrl.numberOfLines =  0;
    [lblUrl sizeToFit];
    
    lblPath.text = [detail objectForKey:@"location"];
    lblPath.lineBreakMode = UILineBreakModeWordWrap;
    lblPath.numberOfLines =0;
    [lblPath sizeToFit];
   */
    shareUrl = nil;
   /* 
    dicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(144, 196, 32, 32)];
    [dicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:dicatorView]; 
    */
    
    int offset = 0;
    lblUrl.text = NSLocalizedString(@"ShareURL", nil);
    lblPath.text = NSLocalizedString(@"ShareFile", nil);
    
    [btnUrl setTitle:[detail objectForKey:@"url"] forState:UIControlStateNormal];
    btnUrl.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
    btnUrl.titleLabel.numberOfLines =  0;
    [btnUrl.titleLabel sizeToFit];
    
    CGRect frame = btnUrl.frame;
    
    if (btnUrl.titleLabel.frame.size.height > 20) {
        frame.size.height = btnUrl.titleLabel.frame.size.height;
        btnUrl.frame = frame;
    }
    
    if (frame.size.height > 60) {
        offset = frame.size.height - 60;
        
        frame = imgLine.frame;
        frame.origin.y = frame.origin.y + offset;
        imgLine.frame = frame;
        
        frame = lblPath.frame;
        frame.origin.y = frame.origin.y + offset;
        lblPath.frame = frame;
        
        frame = btnPath.frame;
        frame.origin.y = frame.origin.y + offset;
        btnPath.frame = frame;
    }
    else {
        
    }
    
    [btnPath setTitle:[detail objectForKey:@"location"] forState:UIControlStateNormal];
    btnPath.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
    btnPath.titleLabel.numberOfLines =  0;
    [btnPath.titleLabel sizeToFit];
    
    frame = btnPath.frame;
    if (btnPath.titleLabel.frame.size.height > 20) {
        frame.size.height = btnPath.titleLabel.frame.size.height;
        btnPath.frame = frame;
    }
    
    [scrollView setContentOffset:CGPointMake(0, 0)];
    [scrollView setContentSize:CGSizeMake(frame.size.width, frame.origin.y + frame.size.height + 12)];
    [scrollView setFrame:[[UIScreen mainScreen] bounds]];
    
    data = [[NSMutableData data] retain];
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES; // (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//-------
-(IBAction) btnShareClicked: (id) sender {
/*
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"ShareLink", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ContinueShare", nil), NSLocalizedString(@"StopShare", nil), NSLocalizedString(@"Download", nil), nil];
    
    [actionSheet showInView:self.parentViewController.tabBarController.view];
    [actionSheet release]; 
*/
    //检查一下分享还在不在  bug  52499
    //发个请求
    NSString* url = @"GetShares";
    [PCUtility httpGetWithURL:url headers:nil delegate:self];
    mStatus = STATUS_CHECK_SHARE_URL;
    //bug 53556  连续快速点击 会多次弹出操作提示框
    //将按钮状态设置为no无法点击。当http请求结束后恢复成yes
    btnUrl.enabled = NO;
    btnPath.enabled = NO;
}


-(IBAction) btnStopClicked: (id) sender {
//    if ([ModalAlert confirm:NSLocalizedString(@"ConfirmStopShare", nil)]) {
        [dicatorView startAnimating];
        
        NSString* url = [NSString stringWithFormat:@"DeleteShare?id=%@", [detail objectForKey:@"id"]];
        [PCUtility httpGetWithURL:url headers:nil delegate:self];  
        shareManagerViewController.isNeedRefresh = YES;
    mStatus = STATUS_DELETE_SHARE;
//    }
}

-(IBAction) btnOpenFileClicked: (id) sender {
    //检查一下分享还在不在  bug  52499
    //发个请求
    NSString* url = @"GetShares";
    [PCUtility httpGetWithURL:url headers:nil delegate:self];
    mStatus = STATUS_CHECK_SHARE_OPEN;
    btnUrl.enabled = NO;
    btnPath.enabled = NO;
}

//---------------------------------------------------------------

-(void)pcConnection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    [data setLength:0];
    NSInteger rc = [(NSHTTPURLResponse*)response statusCode];
    NSLog(@"status code: %d", rc);
    
}

-(void)pcConnection:(NSURLConnection *)connection didReceiveData:(NSData *)incomingData {
    [data appendData:incomingData];
}

- (void)pcConnectionDidFinishLoading:(NSURLConnection *)connection {
    if (mStatus == STATUS_DELETE_SHARE)
    {
        if (dicatorView) [dicatorView stopAnimating];
        [self.navigationController popViewControllerAnimated:YES];
        
        NSString *key = [detail objectForKey:@"location"];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:NO forKey:key];
        [defaults synchronize];

    }
    else if(mStatus == STATUS_CHECK_SHARE_OPEN)
    {
         NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
          NSDictionary *dict = [ret JSONValue];
        if (dict && [dict isKindOfClass:[NSDictionary class]])
        {
            NSArray * nodeArray = [dict objectForKey:@"data"];
            if ([nodeArray containsObject:detail])
            {
                    if (![[detail objectForKey:@"isdir"] intValue]) {
                        FileCache* fileCache = [[[FileCache alloc] init] autorelease];
                         [fileCacheArr addObject:fileCache];
                        if ([fileCache cacheFile:[detail objectForKey:@"location"] viewType:TYPE_CACHE_SHARE_DETAIL_FILE viewController:self fileSize:[[detail objectForKey:@"size"] floatValue] modifyGTMTime:[[detail objectForKey:@"modifyTime"] longLongValue] showAlert:YES])  {
                            [dicatorView startAnimating];
                        }
                    }
                    else {
                        FileListViewController *fileListView = [[[FileListViewController alloc] initWithNibName:[PCUtility getXibName:@"FileListView"] bundle:nil] autorelease];
                        fileListView.navigationItem.title = [detail objectForKey:@"name"];
                        fileListView.dirPath = [detail objectForKey:@"location"];
                        fileListView.mStatus = STATUS_GET_FILELIST;
                        fileListView.isFromShare = YES;
                        [self.navigationController pushViewController:fileListView animated:YES];        
                    }
            }
            else
            {
                [PCUtility showErrorAlert:NSLocalizedString(@"NoFileForShare", nil) delegate:self];
                 [self.navigationController popViewControllerAnimated:YES];
            }

        }
        else
        {
            [PCUtility showErrorAlert:NSLocalizedString(@"NoFileForShare", nil) delegate:self];
             [self.navigationController popViewControllerAnimated:YES];
        }
        
        [ret release];
    }
    else
    {
        NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSDictionary *dict = [ret JSONValue];
        [ret release];
        if (dict && [dict isKindOfClass:[NSDictionary class]])
        {
            NSArray * nodeArray = [dict objectForKey:@"data"];
            if ([nodeArray containsObject:detail])
            {
                if (shareUrl) [shareUrl release];
                
                shareUrl = [[PCShareUrl alloc] init];
                [shareUrl shareUrl:[detail objectForKey:@"url"] hostPath:[detail objectForKey:@"location"] actionType:TYPE_SHARE_DETAIL viewController:self];
                //    [shareUrl release];
                
                CGRect frame = btnUrl.titleLabel.frame;
                frame.origin.x = 0;
                frame.origin.y = 0;
                btnUrl.titleLabel.frame = frame;

            }
            else
            {
                [PCUtility showErrorAlert:NSLocalizedString(@"NoFileForShare", nil) delegate:self];
                 [self.navigationController popViewControllerAnimated:YES];
            }
        }
        else
        {
            [PCUtility showErrorAlert:NSLocalizedString(@"NoFileForShare", nil) delegate:self];
             [self.navigationController popViewControllerAnimated:YES];
        }
    }
    btnUrl.enabled = YES;
    btnPath.enabled = YES;
    
}

- (void)pcConnection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (dicatorView) [dicatorView stopAnimating];
    [PCUtility showErrorAlert:NSLocalizedString(@"ConnetError", nil) delegate:self];
    btnUrl.enabled = YES;
    btnPath.enabled = YES;
}

- (NSURLRequest *)pcConnection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    if ([redirectResponse URL]) {
        [connection cancel];
        PCLogin *pcLogin = [[PCLogin alloc] init];
        [pcLogin logIn:self];  
        return nil;
    }
    return request;
}

//-----------------------------------------------------------
- (void) loginFail:(PCLogin*)pcLogin error:(NSString*)error {
    if (dicatorView) [dicatorView stopAnimating];
    [PCUtility showErrorAlert:error delegate:self];
    [pcLogin release];
}

- (void) loginFinish:(PCLogin*)pcLogin
{
    [pcLogin release];
    if(mStatus == STATUS_DELETE_SHARE)
    {
        NSString* url = [NSString stringWithFormat:@"DeleteShare?id=%@", [detail objectForKey:@"id"]];
        [PCUtility httpGetWithURL:url headers:nil delegate:self];
    }
    else if(mStatus == STATUS_CHECK_SHARE_OPEN)
    {
        NSString* url = @"GetShares";
        [PCUtility httpGetWithURL:url headers:nil delegate:self];
    }
    else
    {
        NSString* url = @"GetShares";
        [PCUtility httpGetWithURL:url headers:nil delegate:self];
    }
 
    
}

- (void) shareUrlFail:(NSString*)error {
    if (dicatorView) [dicatorView stopAnimating];
    [PCUtility showErrorAlert:error delegate:self];  
}

- (void) networkNoReachableFail:(NSString*)error {
    if (dicatorView) [dicatorView stopAnimating];
    [PCUtility showErrorAlert:error delegate:self];
}
//----------------------------------------------------------

- (void)openFile:(NSString*)localPath {
    if (dicatorView) [dicatorView stopAnimating];
    PCOpenFile *openFile = [[PCOpenFile alloc] init];
    [openFile openFile:localPath viewType:TYPE_OPEN_FILE_DEFAULT viewController:self];
}

- (void) cacheFileFinish:(FileCache*)fileCache {
    [self openFile:fileCache.localPath];
    [fileCacheArr removeObject:fileCache];
}

- (void) cacheFileFail:(FileCache*)fileCache hostPath:(NSString *)hostPath error:(NSString*)error {
    if (dicatorView) [dicatorView stopAnimating];
    [PCUtility showErrorAlert:error delegate:self];
    [fileCacheArr removeObject:fileCache];
}

- (void) cacheFileProgress:(float)progress hostPath:(NSString *)hostPath {
    
}

@end
