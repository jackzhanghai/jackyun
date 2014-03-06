//
//  CameraUploadSettingViewController.m
//  popoCloud
//
//  Created by suleyu on 13-2-27.
//
//

#import "CameraUploadSettingViewController.h"
#import "CameraUploadManager.h"
#import "MobClick.h"
#import "umengEventStr.h"
@implementation CameraUploadSettingViewController
@synthesize effectiveImmediately;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.title = NSLocalizedString(@"Camera Upload", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"CameraUploadSetting"];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"CameraUploadSetting"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[PCSettings sharedSettings] autoCameraUpload] ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSInteger rows = 0;
    switch (section) {
        case 0:
            rows = 1;
            break;
            
        case 1:
            rows = 2;
            break;
            
        default:
            break;
    }
    return rows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	if (section == 1)
		return NSLocalizedString(@"Choose upload mode", nil);
    
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    if (indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"Camera Upload", nil);
        cell.detailTextLabel.text = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
        [switchView setOn:[[PCSettings sharedSettings] autoCameraUpload] animated:NO];
        [switchView addTarget:self action:@selector(cameraUploadSwitchStateChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = switchView;
        [switchView release];
    }
    else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = NSLocalizedString(@"Only upload using WiFi", nil);
                cell.detailTextLabel.text = nil;
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                cell.accessoryType = [[PCSettings sharedSettings] useCellularData] ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
                cell.accessoryView = nil;
                break;
            case 1:
                cell.textLabel.text = NSLocalizedString(@"Upload using WiFi or mobile network", nil);
                //cell.detailTextLabel.text = NSLocalizedString(@"We will not use 3G to upload files greater than 20M", nil);
                //cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0f];
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                cell.accessoryType = [[PCSettings sharedSettings] useCellularData] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                cell.accessoryView = nil;
                break;
            default:
                break;
        }
    }

    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    
    if (indexPath.section == 1 && [[PCSettings sharedSettings] useCellularData] != (indexPath.row == 1)) {
        [[PCSettings sharedSettings] setUseCellularData:(indexPath.row == 1)];
        
        NSArray *indexPaths = [NSArray arrayWithObjects:indexPath, [NSIndexPath indexPathForRow:(1 - indexPath.row) inSection:1], nil];
        [tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        
        if (effectiveImmediately) {
            [[CameraUploadManager sharedManager] setUseCellularData:(indexPath.row == 1)];
        }
    }
    else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)cameraUploadSwitchStateChanged:(UISwitch *)switchControl
{
    [[PCSettings sharedSettings] setAutoCameraUpload:switchControl.on];
    [self.tableView reloadData];
    
    if (effectiveImmediately) {
        if (switchControl.on) {
            [MobClick event:UM_AUTO_UPLOAD_OPEN]; 
            [[CameraUploadManager sharedManager] startCameraUpload];
        } else {
            [MobClick event:UM_AUTO_UPLOAD_CLOSE]; 
            [[CameraUploadManager sharedManager] stopCameraUpload];
        }
    }
}

@end
