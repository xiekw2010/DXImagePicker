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
 *  @param An array of ALAsset. Notice: Do not try to retain this assets array. It will pass pass the lifetime of its owning ALAssetsLbirary. Do anything image event in this delegate method.
 */
- (void)dx_imagePickerController:(DXImagePicker *)picker didSelectAssets:(NSArray *)assets didCamptureImage:(UIImage *)image;

- (void)dx_imagePickerController:(DXImagePicker *)picker didSelectAlbumName:(NSString *)albumName;

- (void)dx_imagePickerController:(DXImagePicker *)picker didReachMaxSelectedCount:(NSInteger)maxCount;

@end




@interface DXImagePicker : UIViewController

/**
 *  Default is @[@(ALAssetsGroupSavedPhotos), @(ALAssetsGroupAlbum)], The all version is @[@(ALAssetsGroupSavedPhotos), @(ALAssetsGroupAlbum), @(ALAssetsGroupEvent), @(ALAssetsGroupFaces), @(ALAssetsGroupPhotoStream)].
 
    @Note this array keeps the index the selected albums. Avoid using ALAssetsGroupAll, if you use, use this @[@(ALAssetsGroupAll)]
 */
@property (nonatomic, strong) NSArray *groupTypes;

@property (nonatomic, weak) id<DXImagePickerDelegate> delegate;


/**
 *  The color affects the Picker;
 */
@property (nonatomic, strong) UIColor *themeColor;

/**
 *  The navigation bar style and photo grids color(white or black);
 */
@property (nonatomic, assign) BOOL themeBlack;

@property (nonatomic, assign) NSInteger maxSelectedCount;


/**
 *  Because the ALAsset will pass the lifetime of its owning ALAssetsLbirary, so here we use the names as the key to asset
 
 Use getAssetNamesByAssets: to get the names of the delegate's assets
 */
@property (nonatomic, strong) NSArray *shouldSelectedAssetFileNames;

/**
 *  The on screen showing Album.
 */
@property (nonatomic, strong) NSString *shouldSelectAlbumName;

/**
 *  Make the assets array into the assetsName array(Strings)
 *
 *  @param assets
 *
 *  @return assetsNameArray
 */
+ (NSArray *)getAssetNamesByAssets:(NSArray *)assets;

@end
