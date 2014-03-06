//
//  AlbumPickerController.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAlbumPickerController.h"
#import "ELCImagePickerController.h"
#import "ELCAssetTablePicker.h"
#import "MBProgressHUD.h"
#import "MobClick.h"
@implementation ELCAlbumPickerController

@synthesize parent, assetGroups;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.tableView.rowHeight = 57;
    self.title = NSLocalizedString(@"PhotoAlbum", nil);
    
    if (IS_IOS7)
    {
        UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
        temporaryBarButtonItem.title = NSLocalizedString(@"PhotoAlbum", nil);
        
        NSDictionary *normalTextAttributes = [NSDictionary dictionaryWithObject:self.navigationController.navigationBar.tintColor forKey:UITextAttributeTextColor];
        [temporaryBarButtonItem setTitleTextAttributes:normalTextAttributes forState:UIControlStateNormal];
        
        self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
        [temporaryBarButtonItem release];
    }
    
    if (!IS_IPAD)
    {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.parent action:@selector(cancelImagePicker)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        [cancelButton release];
    }
    
	self.assetGroups = [NSMutableArray array];
    
    oldOrientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadData:)
                                                 name:IS_IOS5 ? UIApplicationDidBecomeActiveNotification : ALAssetsLibraryChangedNotification
                                               object:nil];
    
    library = [[ALAssetsLibrary alloc] init];
    [self loadData:nil];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [assetGroups release];
    [library release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (IS_IPAD || (interfaceOrientation == UIInterfaceOrientationPortrait));
}

- (void)viewWillAppear:(BOOL)animated
{
    if (IS_IPAD)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationDidChange:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"PhotoAlbumView"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (IS_IPAD)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIDeviceOrientationDidChangeNotification
                                                      object:nil];
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    }
    
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"PhotoAlbumView"];
}

//该controller在ipad设备是UIPopoverController上显示的，旋转设备时该函数不会被执行，只能通过注册事件侦听的方式获得通知；
//而在iphone上需要该函数，而不需要侦听，又是因为时间侦听的函数调用后，列表的view的y坐标会往上移一些，导致导航栏会遮住一部分界面
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [parent performSelector:@selector(layoutSubviews)];
}

#pragma mark - callback methods

- (void)orientationDidChange:(NSNotification *)note
{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    
    if (orientation < UIDeviceOrientationPortrait ||
        orientation > UIDeviceOrientationLandscapeRight ||
        oldOrientation == orientation)
        return;
    
    oldOrientation = orientation;
    
    [parent performSelector:@selector(layoutSubviews)];
}

- (void)loadData:(NSNotification *)note
{
    BOOL needPostEvent = [note.name isEqualToString:UIApplicationDidBecomeActiveNotification] &&
            [self.navigationController.topViewController isKindOfClass:[ELCAssetTablePicker class]];
    if (needPostEvent)
    {
        [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window
                                 text:NSLocalizedString(@"Refreshing", nil)
                      showImmediately:YES
                          isMultiline:NO];
    }
    
    // Load Albums into assetGroups
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSMutableArray *groups = [NSMutableArray array];
        void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
        {
            if (group == nil)
            {
                if (needPostEvent)
                {
                    ELCAssetTablePicker *picker = (ELCAssetTablePicker *)self.navigationController.topViewController;
                    NSString *groupID = [picker.assetGroup valueForProperty:ALAssetsGroupPropertyPersistentID];
                    ALAssetsGroup *pickGroup = nil;
                    
                    for (ALAssetsGroup *assetGroup in self.assetGroups) {
                        if ([[assetGroup valueForProperty:ALAssetsGroupPropertyPersistentID] isEqualToString:groupID]) {
                            pickGroup = assetGroup;
                            break;
                        }
                    }
                    
                    NSDictionary *dic = pickGroup ? @{@"group": pickGroup} : nil;
                    [[NSNotificationCenter defaultCenter] postNotificationName:ALAssetsLibraryChangedNotification object:self userInfo:dic];
                }
                return;
            }
           
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            
            if (groups) {
                [groups addObject:group];
                
                // Reload albums
                [self performSelectorOnMainThread:@selector(reloadTableView:) withObject:groups waitUntilDone:YES];
            }
            else {
                *stop = YES;
            }
        };
       
        // Group Enumerator Failure Block
        void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error)
        {
            if (needPostEvent)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:ALAssetsLibraryChangedNotification object:self userInfo:nil];
            }
            DLogError(@"upload photo get assets error:%@", [error localizedDescription]);
        };
       
        // Enumerate Albums
        [library enumerateGroupsWithTypes:ALAssetsGroupAll
                               usingBlock:assetGroupEnumerator 
                             failureBlock:assetGroupEnumberatorFailure];
       
        [pool release];
    });
}

#pragma mark - private methods

-(void)reloadTableView:(NSMutableArray *)array
{
    self.assetGroups = array;
    [self.tableView reloadData];
}

#pragma mark - public methods

-(void)selectedAssets:(NSArray*)_assets
{	
	[(ELCImagePickerController*)parent selectedAssets:_assets];
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
    return assetGroups.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Get count
    ALAssetsGroup *g = (ALAssetsGroup*)[assetGroups objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)",[g valueForProperty:ALAssetsGroupPropertyName], [g numberOfAssets]];
    cell.imageView.image = [UIImage imageWithCGImage:[g posterImage]];
	
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	ELCAssetTablePicker *picker = [[ELCAssetTablePicker alloc] init];
	picker.parent = self;  
    picker.assetGroup = [assetGroups objectAtIndex:indexPath.row];
    
	[self.navigationController pushViewController:picker animated:YES];
	[picker release];
}

@end

