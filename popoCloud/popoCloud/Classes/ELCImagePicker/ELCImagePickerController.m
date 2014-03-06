//
//  ELCImagePickerController.m
//  ELCImagePickerDemo
//
//  Created by Collin Ruffenach on 9/9/10.
//  Copyright 2010 ELC Technologies. All rights reserved.
//

#import "ELCImagePickerController.h"
#import "ELCAsset.h"
#import "ELCAssetCell.h"
#import "ELCAlbumPickerController.h"
#import "PCUtility.h"

@implementation ELCImagePickerController

@synthesize delegate;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [self.view removeObserver:self forKeyPath:@"frame" context:NULL];
    [footerView release];
    [super dealloc];
}

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self)
    {
        self.navigationBar.translucent = NO;
        if (IS_IOS7 && !IS_IPAD)
        {
            self.navigationBar.barTintColor = [UIColor colorWithRed:0 green:144 / 255.0 blue:211 / 255.0 alpha:1];
            self.navigationBar.tintColor = [UIColor whiteColor];
            self.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor];
        }
    }
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"frame"])
    {
        [self layoutSubviews];
    }
}
-(void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
}
- (void)viewWillAppear:(BOOL)animated
{
    //在这里创建UILabel，最初放在viewDidLoad里调用，发现在ipad上UIPopoverController里显示的label处于列表界面
    //的后面去了，导致无法看见，放在这里创建就没问题
    [self createFooterView];
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"ELCImagePickerView"];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"ELCImagePickerView"];
}
#pragma mark - private methods

- (void)layoutSubviews
{
    //NSLog(@"self.view.frame=%@",NSStringFromCGRect(self.view.frame));
    
    CGSize viewSize = [UIScreen mainScreen].bounds.size;
    NSInteger height = 21;
    
    NSInteger viewWidth = viewSize.width;
    NSInteger viewHeight = viewSize.height;
    if (IS_IPAD)
    {
        //旋转屏幕时，该函数会被调用，但打印出来self.view.frame的值对应横竖屏正好相反，所以这里直接数字写死了
        viewWidth = 320;
        viewHeight = [UIApplication sharedApplication].statusBarOrientation > UIInterfaceOrientationPortraitUpsideDown ?
                        712 : 828;
    }
    else if (self.interfaceOrientation > UIInterfaceOrientationPortraitUpsideDown)
    {
        viewWidth = viewSize.height;
        viewHeight = viewSize.width;
    }
    NSInteger yCoordinate = self.view.bounds.size.height - height;
    footerView.frame = CGRectMake(0, yCoordinate, viewWidth, height);
}

- (void)createFooterView
{
    if (footerView == nil)
    {
        footerView = [[UILabel alloc] init];
        [self layoutSubviews];
        
        footerView.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:.8f];
        footerView.textAlignment = IS_IOS6 ? NSTextAlignmentCenter : UITextAlignmentCenter;
        footerView.textColor = [UIColor whiteColor];
        footerView.text = NSLocalizedString(@"UploadToPopoCloud", nil);
        
        [self.view addSubview:footerView];
    }
}

#pragma mark - public methods

- (void)cancelImagePicker
{
	if([delegate respondsToSelector:@selector(elcImagePickerControllerDidCancel:)]) {
        [delegate elcImagePickerControllerDidCancel:self];
	}
}

- (void)selectedAssets:(NSArray*)_assets
{
	NSMutableArray *returnArray = [[[NSMutableArray alloc] init] autorelease];
    
    [_assets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ALAsset *asset = obj;
        ALAssetRepresentation *present = asset.defaultRepresentation;
        NSDictionary *urls = [asset valueForProperty:ALAssetPropertyURLs];
        if (urls.count > 0) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            dic[UIImagePickerControllerReferenceURL] = [urls valueForKey:[[urls allKeys] objectAtIndex:0]];
            dic[@"imageName"] = present.filename;
            dic[@"imageSize"] = [NSNumber numberWithLongLong:present.size];
            //dic[@"UIImagePickerControllerMediaType"] = [asset valueForProperty:ALAssetPropertyType];
            
            [returnArray addObject:dic];
        }
    }];
    [MobClick event:UM_UPLOAD acc:[returnArray count]];
    dispatch_async(dispatch_get_main_queue(), ^{
        if([delegate respondsToSelector:@selector(elcImagePickerController:
                                                  didFinishPickingMediaWithInfo:)])
        {
            [delegate elcImagePickerController:self
                 didFinishPickingMediaWithInfo:[NSArray arrayWithArray:returnArray]];
        }
    });
}
-(BOOL)shouldAutorotate
{
    return IS_IPAD;
}
- (NSUInteger)supportedInterfaceOrientations
{
    return IS_IPAD ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (IS_IPAD || toInterfaceOrientation == UIInterfaceOrientationPortrait);
}
@end
