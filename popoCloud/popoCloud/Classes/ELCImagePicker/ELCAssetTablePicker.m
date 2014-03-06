//
//  AssetTablePicker.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"
#import "MBProgressHUD.h"
#import "MobClick.h"
@implementation ELCAssetTablePicker

@synthesize parent;
@synthesize assetGroup, elcAssets;

-(void)viewDidLoad
{        
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.allowsSelection = NO;
    self.tableView.rowHeight = 79;

    self.elcAssets = [NSMutableArray array];
    selectPicNum = 0;
    
    picNumPerRow = !IS_IPAD && self.interfaceOrientation != UIInterfaceOrientationPortrait ? 6 : 4;
    oldOrientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadData:)
                                                 name:ALAssetsLibraryChangedNotification
                                               object:nil];
    
    [self loadData:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.assetGroup = nil;
    [elcAssets release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    DLogWarn(@"ELCAssetTablePicker memory warning.");
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (IS_IPAD || (interfaceOrientation == UIInterfaceOrientationPortrait));
}

- (void)viewWillAppear:(BOOL)animated
{
    UIBarButtonItem *uploadBtn = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Upload", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(doneAction:)] autorelease];
    uploadBtn.enabled = selectPicNum != 0;
    self.navigationItem.rightBarButtonItem = uploadBtn;
    
    if (IS_IOS7)
    {
        NSDictionary *normalTextAttributes = [NSDictionary dictionaryWithObject:self.navigationController.navigationBar.tintColor forKey:UITextAttributeTextColor];
        [uploadBtn setTitleTextAttributes:normalTextAttributes forState:UIControlStateNormal];
    }
    
    self.title = [assetGroup valueForProperty:ALAssetsGroupPropertyName];
    
    if (IS_IPAD)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationDidChange:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"AssetTableView"];
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
    [MobClick endLogPageView:@"AssetTableView"];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self layoutSubviews];
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
    [self layoutSubviews];
}

- (void)doneAction:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *selectedAssetsImages = [[[NSMutableArray alloc] init] autorelease];
        
        for(ELCAsset *elcAsset in self.elcAssets)
        {
            if(elcAsset.selected)
                [selectedAssetsImages addObject:[elcAsset asset]];
        }
        
        [(ELCAlbumPickerController*)self.parent selectedAssets:selectedAssetsImages];
    });
}

- (void)loadData:(NSNotification *)note
{
    if (parent == note.object)
    {
        NSDictionary *dic = note.userInfo;
        if (dic)
        {
            self.assetGroup = dic[@"group"];
            [self getAssets];
        }
        else
        {
            self.assetGroup = nil;
            [self.elcAssets removeAllObjects];
            [self reloadTableView];
        }
    }
    else
    {
        MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].delegate.window];
        if (!hud && [UIApplication sharedApplication].applicationState == UIApplicationStateActive)
        {
            [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window
                                     text:NSLocalizedString(@"Refreshing", nil)
                          showImmediately:YES
                              isMultiline:NO];
        }
        
        [self getAssets];
    }
}

#pragma mark - private methods

- (void)getAssets
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        DLogNotice(@"enumerating photos");
        [self.elcAssets removeAllObjects];
        
        [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop)
         {
             if(result == nil)
             {
                 return;
             }
             
             ELCAsset *elcAsset = [[[ELCAsset alloc] initWithAsset:result] autorelease];
             elcAsset.parent = self;
             [self.elcAssets addObject:elcAsset];
         }];
        DLogNotice(@"done enumerating photos");
        
        [self performSelectorOnMainThread:@selector(reloadTableView) withObject:nil waitUntilDone:NO];
        
        [pool release];
    });
}

- (void)layoutSubviews
{
    [((ELCAlbumPickerController *)parent).parent performSelector:@selector(layoutSubviews)];
    picNumPerRow = !IS_IPAD && self.interfaceOrientation != UIInterfaceOrientationPortrait ? 6 : 4;
    [self reloadTableView];
}

- (void)reloadTableView
{
    [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].delegate.window
                         animated:YES];
    [self.tableView reloadData];
}

- (NSArray*)assetsForIndexPath:(NSIndexPath*)_indexPath
{
    NSUInteger count = self.elcAssets.count;
    if (count == 0)
    {
        return nil;
    }
    
	NSInteger index = _indexPath.row * picNumPerRow;
	NSInteger maxIndex = index + picNumPerRow;
    
//	NSLog(@"Getting assets for %d to %d with array count %d", index, maxIndex, count);
    
    while (maxIndex > count) {
        maxIndex--;
    }
    
    if (index >= maxIndex)
    {
        return nil;
    }
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (int i = index; i < maxIndex; i++) {
        [array addObject:self.elcAssets[i]];
    }
    
	return array;
}

#pragma mark - public methods

- (void)notifyClickImage:(BOOL)selected
{
    if (selected)
    {
        selectPicNum++;
    }
    else
    {
        selectPicNum--;
    }
    
    self.navigationItem.rightBarButtonItem.enabled = selectPicNum != 0;
}

#pragma mark - UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    return ceil([self.assetGroup numberOfAssets] / (CGFloat)picNumPerRow);
    return ceil(self.elcAssets.count / (CGFloat)picNumPerRow);
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) 
    {		        
        cell = [[[ELCAssetCell alloc] initWithAssets:[self assetsForIndexPath:indexPath] reuseIdentifier:CellIdentifier] autorelease];
    }	
	else 
    {		
		[cell setAssets:[self assetsForIndexPath:indexPath]];
	}
    
    return cell;
}

@end
