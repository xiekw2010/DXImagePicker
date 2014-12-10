//
//  DXPhotoSelectBrowser.h
//  DXPhotoSelectBrowser
//
//  Created by xiekw on 12/10/14.
//  Copyright (c) 2014 xiekw. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DXImagePicker;

@protocol DXImagePickerDelegate <NSObject>

@optional

/**
 *  Call back of did picker image
 *
 *  @param An array of ALAsset. Notice: if you use the caputure image, the last object of this is a UIImage not a ALAsset.
 */
- (void)dx_imagePickerController:(DXImagePicker *)picker didSelectImages:(NSArray *)assets;

@end




@interface DXImagePicker : UIViewController

/**
 *  Default is @[@(ALAssetsGroupSavedPhotos), @(ALAssetsGroupAlbum)]
 */
@property (nonatomic, strong) NSArray *groupTypes;
@property (nonatomic, weak) id<DXImagePickerDelegate> delegate;
@property (nonatomic, strong) NSArray *shouldSelectedAssets;


@end
