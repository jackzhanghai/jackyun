//
//  ManagementViewController.m
//  popoCloud
//
//  Created by xuyang on 13-3-14.
//
//

#import "ManagementViewController.h"
#import "ShareManagerViewController.h"
#import "FileUploadController.h"
#import "PCUtility.h"
#import "PCUtilityFileOperate.h"
#import "FileDownloadManagerViewController.h"
@implementation ManagementViewController

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {
    self = [super initWithNibName:nibName bundle:nibBundle];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setBadge:) name:@"RefreshTableView" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setBadge:)
                                                     name:EVENT_UPLOAD_FILE_NUM
                                                   object:nil];
    }
    return self;
}

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setBadge:) name:@"RefreshTableView" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setBadge:)
                                                 name:EVENT_UPLOAD_FILE_NUM
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EVENT_UPLOAD_FILE_NUM object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RefreshTableView" object:nil];
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.scrollEnabled = NO;
    self.tableView.rowHeight =  44;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:236.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Do any additional setup after loading the view from its nib.
    [self setBadge:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"ManagementView"];
    //第一次显示该controller，这里获取的cell为空，需要在下面的viewDidAppear再次执行；
    //以后cell不为空了都在这里执行，下面的viewDidAppear也不会执行到实际的操作函数体
    [self setCellBadgeNumber];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"ManagementView"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setCellBadgeNumber];
}

#pragma mark - callback methods

- (void)setBadge:(NSNotification *)note
{
//    NSUInteger uploadNum = [[FileUploadManager sharedManager] uploadTotalNum];
//    
//    if (uploadNum)
//    {
//        NSString *str = uploadNum > 99 ? @"..." : [NSString stringWithFormat:@"%d", uploadNum];
//        self.navigationController.tabBarItem.badgeValue = str;
//    }
//    else if (self.navigationController.tabBarItem.badgeValue)
//    {
//        self.navigationController.tabBarItem.badgeValue = nil;
//    }
    
    [self setCellBadgeNumber];
}

#pragma mark - private methods
-(void)setUploadCellBadge
{
    if (!self.tableView)
        return;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    
    if (cell)
    {
        UIView *subView = cell.contentView.subviews.lastObject;
        if (subView.tag == -1)
        {
            [subView removeFromSuperview];
        }
        NSUInteger uploadNum = [[FileUploadManager sharedManager] uploadTotalNum];
        if (uploadNum > 0)
        {
            UIImage *badgeImg = [UIImage imageNamed:[PCUtilityFileOperate getImgName:@"download_new"]];
            UIImageView *badgeView = [[[UIImageView alloc] initWithImage:badgeImg] autorelease];
            badgeView.frame = CGRectMake(27, 3, 15, 15);
            badgeView.tag = -1;
            [cell.contentView addSubview:badgeView];
        }
    }
}
-(void)setDownloadCellBadge
{
    if (!self.tableView)
        return;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    
    if (cell)
    {
        UIView *subView = cell.contentView.subviews.lastObject;
        if (subView.tag == -1)
        {
            [subView removeFromSuperview];
        }
        int badgeValue = [PCUtilityFileOperate downloadManager].tableDownloading.count + [PCUtilityFileOperate downloadManager].tableDownloadingStoped.count;
        if (badgeValue > 0 )
        {
            UIImage *badgeImg = [UIImage imageNamed:[PCUtilityFileOperate getImgName:@"download_new"]];
            UIImageView *badgeView = [[[UIImageView alloc] initWithImage:badgeImg] autorelease];
            badgeView.frame = CGRectMake(27, 3, 15, 15);
            badgeView.tag = -1;
            [cell.contentView addSubview:badgeView];
        }
    }
}
- (void)setCellBadgeNumber
{
    [self setDownloadCellBadge];
    [self setUploadCellBadge];
}

- (void)createBadgeNumberImage:(NSInteger)number
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UIView *subView = cell.contentView.subviews.lastObject;
    if (subView.tag == -1)
    {
        [subView removeFromSuperview];
    }
    
	if (number)
    {
//		UIImage *badgeImg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"number_bg" ofType:@"png"]];
        UIImage *badgeImg = [UIImage imageNamed:[PCUtilityFileOperate getImgName:@"number_bg"]];
		NSInteger width = badgeImg.size.width * badgeImg.scale;
		NSInteger height = badgeImg.size.height * badgeImg.scale;
		
		UIGraphicsBeginImageContext(CGSizeMake(width, height));
		CGContextRef context = UIGraphicsGetCurrentContext();
		
		CGImageRef badge = badgeImg.CGImage;
        
        CGContextSaveGState(context);
        
        CGContextScaleCTM(context, 1, -1);
        CGContextTranslateCTM(context, 0, -height);
		CGContextDrawImage(context, CGRectMake(0, 0, width, height), badge);
        
        CGContextRestoreGState(context);
		
		// Label with a number
        BOOL exceedHundred = number > 99;
		NSString *numstring = exceedHundred ? @"..." : [NSString stringWithFormat:@"%d", number];
		CGPoint point = CGPointMake(width / 2.0f, exceedHundred ? height / 2.0f : height / 2.0f + 2);
		
		CGContextSaveGState(context);
		CGContextSelectFont(context, "Arial-BoldMT", 16, kCGEncodingMacRoman);
		
		// Retrieve the text width without actually drawing anything
		CGContextSaveGState(context);
		CGContextSetTextDrawingMode(context, kCGTextInvisible);
		CGContextShowTextAtPoint(context, 0.0f, 0.0f, numstring.UTF8String, numstring.length);
		CGPoint endpoint = CGContextGetTextPosition(context);
		CGContextRestoreGState(context);
		
		// 画数字
		[[UIColor whiteColor] setFill];        
		CGContextSetTextDrawingMode(context, kCGTextFill);
		CGContextSetTextMatrix (context, CGAffineTransformMakeScale(1, -1));
		CGContextShowTextAtPoint(context, point.x - endpoint.x / 2.0f, point.y, numstring.UTF8String, numstring.length);
		CGContextRestoreGState(context);
		
		UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		UIImageView *badgeView = [[[UIImageView alloc] initWithImage:theImage] autorelease];
		badgeView.frame = CGRectMake(IS_IPAD ? 15 : 13, self.tableView.rowHeight - 30, width, height);
        badgeView.tag = -1;
        [cell.contentView addSubview:badgeView];
	}
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 1) {
        return 1;
    }
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"managementCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    if (indexPath.section ==0)
    {
        if (indexPath.row ==0)
        {
            cell.textLabel.text = NSLocalizedString(@"ShareManager", nil);;
            cell.imageView.image = [UIImage imageNamed:@"share_icon.png"];
        }
        else
        {
            cell.textLabel.text = NSLocalizedString(@"UploadManager", nil);;
            cell.imageView.image = [UIImage imageNamed:@"upload_icon.png"];
        }
    }
    else
    {
        cell.textLabel.text = NSLocalizedString(@"DownloadContent", nil);;
        cell.imageView.image = [UIImage imageNamed:@"download_icon.png"];

    }
   
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section ==0)
    {
        if (indexPath.row == 0)
        {
            ShareManagerViewController *shareManagerViewController = [[ShareManagerViewController alloc] initWithNibName:[PCUtilityFileOperate getXibName:@"ShareManagerView"] bundle:nil] ;
            
            shareManagerViewController.navigationItem.title = @"分享管理";
            
            [self.navigationController pushViewController:shareManagerViewController animated:YES];
            [shareManagerViewController release];
        }
        else
        {
            FileUploadController *uploadController = [[[FileUploadController alloc] init] autorelease];
            [self.navigationController pushViewController:uploadController animated:YES];
        }
    }
    else
    {
        FileDownloadManagerViewController *vc3 = [[[FileDownloadManagerViewController alloc] initWithNibName:
                                                          [PCUtilityFileOperate getXibName:@"FileDownloadManagerView"] bundle:nil] autorelease];
        vc3.title = NSLocalizedString(@"Collect", nil);
        [self.navigationController pushViewController:vc3 animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
