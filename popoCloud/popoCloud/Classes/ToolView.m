//
//  ToolView.m
//  popoCloud
//
//  Created by ice on 13-11-14.
//
//

#import "ToolView.h"



@implementation ToolView

@synthesize toolViewType;
@synthesize toolViewDelegate;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
-(void)awakeFromNib
{
    self.delegate = self;
    if (IS_IPAD && IS_IOS7) {
        self.barTintColor = [UIColor blackColor];
        self.backgroundColor = [UIColor blackColor];
    }
    else{
            UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, 0, 0);
            self.backgroundImage = [[UIImage imageNamed:@"menu_btn_normal.png"] resizableImageWithCapInsets:insets];
    }

    [self customToolView];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
-(void)enableBtnDownloadAndDelete:(BOOL)enable
{
    for (UITabBarItem *item in self.items)
    {
        if (item.tag == QuanXuanTag || item.tag == QuanBuXuanTag)
        {
            continue;
        }
        if (item.enabled != enable)
        {
            item.enabled = enable;
        }
    }
}
-(void)defaultToolView//默认toolview 样式（全选，下载，删除）
{
    UITabBarItem *quanxuan = [[UITabBarItem alloc] initWithTitle:@"全选" image:[UIImage imageNamed:@"icon_quanxuan"] tag:QuanXuanTag];
    UITabBarItem *xiazai = [[UITabBarItem alloc] initWithTitle:@"下载" image:[UIImage imageNamed:@"icon_xiazai"] tag:XiaZaiTag];
    UITabBarItem *shanchu = [[UITabBarItem alloc] initWithTitle:@"删除" image:[UIImage imageNamed:@"icon_shanchu"] tag:ShanChuTag];
    [self setItems:[NSArray arrayWithObjects:quanxuan,xiazai,shanchu, nil] animated:YES];
    [quanxuan release];
    [xiazai release];
    [shanchu release];
    
    [self layoutSubviews];
}
-(void)twoBtnToolView //全选和删除
{
    UITabBarItem *quanxuan = [[UITabBarItem alloc] initWithTitle:@"全选" image:[UIImage imageNamed:@"icon_quanxuan"] tag:QuanXuanTag];
    UITabBarItem *shanchu = [[UITabBarItem alloc] initWithTitle:@"删除" image:[UIImage imageNamed:@"icon_shanchu"] tag:ShanChuTag];
    [self setItems:[NSArray arrayWithObjects:quanxuan,shanchu, nil] animated:YES];
    [quanxuan release];
    [shanchu release];
    [self layoutSubviews];
}

-(void)twoBtnWoxihuanToolView //全选和移除我喜欢
{
    UITabBarItem *quanxuan = [[UITabBarItem alloc] initWithTitle:@"全选" image:[UIImage imageNamed:@"icon_quanxuan"] tag:QuanXuanTag];
    UITabBarItem *removeWoxihuan = [[UITabBarItem alloc] initWithTitle:@"移除我喜欢" image:[UIImage imageNamed:@"icon_shanchu"] tag:RemoveWoxihuanTag];
    [self setItems:[NSArray arrayWithObjects:quanxuan,removeWoxihuan, nil] animated:YES];
    [quanxuan release];
    [removeWoxihuan release];
    [self layoutSubviews];
}

-(void)otherToolView//全选  删除 我喜欢
{

    UITabBarItem *quanxuan = [[UITabBarItem alloc] initWithTitle:@"全选" image:[UIImage imageNamed:@"icon_quanxuan"] tag:QuanXuanTag];
    UITabBarItem *shanchu = [[UITabBarItem alloc] initWithTitle:@"删除" image:[UIImage imageNamed:@"icon_shanchu"] tag:ShanChuTag];
    UITabBarItem *woxihuan = [[UITabBarItem alloc] initWithTitle:@"添加到我喜欢" image:[UIImage imageNamed:@"icon_xihuan"] tag:WoXiHuanTag];
    [self setItems:[NSArray arrayWithObjects:quanxuan,shanchu,woxihuan, nil] animated:YES];
    [quanxuan release];
    [woxihuan release];
    [shanchu release];
    [self layoutSubviews];
}
-(void)customToolView
{
    switch (toolViewType)
    {
        case QuanXuanShanChuXiaZai://全选删除下载
        {
            [self defaultToolView];
        }
        break;
            
        case QuanXuanShanChuWoXiHuan://全选删除我喜欢
        {
            [self otherToolView];
        }
        break;
            
        case QuanXuanShanChu://全选删除
        {
            [self twoBtnToolView];
        }
        break;
            case QuanXuanRemoveWoxihuan:
        {
            [self twoBtnWoxihuanToolView];
        }
            break;
            
        default:
        {
            [self defaultToolView];
        }
        break;
    }
}
-(void)dealloc
{
    [super dealloc];
}
-(void)setToolViewType:(ToolViewType)newType
{
    if (toolViewType != newType)
    {
        toolViewType = newType;
        [self customToolView];
    }
}
-(void)resetTitleAndStatus
{
    [self setSelectedItem:nil];
    UITabBarItem *item = [self.items objectAtIndex:0];
    if (item)
    {
        item.tag = QuanXuanTag;
        item.title = @"全选";
    }
}
-(void)changeTitleOfSelectAll
{
    UITabBarItem *item = [self.items objectAtIndex:0];
    if (item.tag == QuanBuXuanTag)
    {
        item.tag = QuanXuanTag;
        item.title = @"全选";
        return;
    }
    if (item.tag == QuanXuanTag)
    {
        item.tag = QuanBuXuanTag;
        item.title = @"取消全选";
    }
}
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (self.hidden) {
        return;
    }
    if (toolViewDelegate && [toolViewDelegate respondsToSelector:@selector(didSelectBtn:)]) {
        [toolViewDelegate didSelectBtn:item.tag];
        if (item.tag == QuanBuXuanTag)
        {
            item.tag = QuanXuanTag;
            item.title = @"全选";
            return;
        }
        if (item.tag == QuanXuanTag)
        {
            item.tag =QuanBuXuanTag;
            item.title = @"取消全选";
        }
    }
}
@end
