//
//  DXUtilViews.h
//  DXPhotoSelectBrowser
//
//  Created by xiekw on 12/11/14.
//  Copyright (c) 2014 xiekw. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface _ConfirmView : UIView

@property (nonatomic, strong) CAShapeLayer *checkLayer;

- (void)makeGreenAndCheck;
+ (CGSize)standSize;

@end

@interface DXAlbumCell : UITableViewCell

@property (nonatomic, strong) UIColor *normalColor;
@property (nonatomic, strong) _ConfirmView *confirmView;

+ (CGFloat)standHeight;

@end

@interface TriangleButton : UIButton


- (instancetype)initWithFrame:(CGRect)frame themeColor:(UIColor *)color;


@end