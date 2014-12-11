//
//  DXPhotoCollectionViewCell.h
//  DXPhotoSelectBrowser
//
//  Created by xiekw on 12/10/14.
//  Copyright (c) 2014 xiekw. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DXCellSelectedNumberView : UIView

@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, strong) UIColor *normalColor;
@property (nonatomic, strong) NSDictionary *textAttributes;

@end

@interface DXPhotoCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) DXCellSelectedNumberView *numberView;

- (void)bounce;

@end
