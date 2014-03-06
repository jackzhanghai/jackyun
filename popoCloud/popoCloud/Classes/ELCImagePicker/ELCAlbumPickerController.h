//
//  AlbumPickerController.h
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ELCAlbumPickerController : UITableViewController
{
	NSMutableArray *assetGroups;
	id parent;
    
    ALAssetsLibrary *library;
    UIDeviceOrientation oldOrientation;
}

@property (nonatomic, assign) id parent;
@property (atomic, retain) NSMutableArray *assetGroups;

-(void)selectedAssets:(NSArray*)_assets;

@end

