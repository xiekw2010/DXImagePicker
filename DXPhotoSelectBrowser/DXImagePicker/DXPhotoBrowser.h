//
//  DXPageViewController.h
//  DXPhotoSelectBrowser
//
//  Created by zhoujiuhai on 14/12/12.
//  Copyright (c) 2014年 xiekw. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DXPhotoBrowser;

@protocol DXPhotoBrowserDelegate <NSObject>

- (NSUInteger)numberOfPhotosInPhotoBrowser:(DXPhotoBrowser *)photoBrowser;

- (UIImage *)photoBrowser:(DXPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;

@end

@interface DXPhotoBrowser : UIViewController

@property (nonatomic, weak) id<DXPhotoBrowserDelegate> delegate;

@property (nonatomic, assign) NSUInteger currentPhotoIndex;

@end


@interface photoViewController : UIViewController

@property (nonatomic) NSUInteger index;

@property (nonatomic, strong) UIImage *image;

@end


