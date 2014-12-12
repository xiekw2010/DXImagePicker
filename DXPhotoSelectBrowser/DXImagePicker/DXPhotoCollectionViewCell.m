//
//  DXPhotoCollectionViewCell.m
//  DXPhotoSelectBrowser
//
//  Created by xiekw on 12/10/14.
//  Copyright (c) 2014 xiekw. All rights reserved.
//

#import "DXPhotoCollectionViewCell.h"


@implementation DXCellSelectedNumberView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.textAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[UIFont systemFontOfSize:10.0]};
    }
    return self;
}

- (void)setIndex:(NSUInteger)index
{
    _index = MAX(1, index);
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGSize const size = self.bounds.size;
    CGFloat const lineWidth = 5.0;

    UIColor *strokeColor = self.normalColor;

    CGSize const rightCornerSize = CGSizeMake(21.0, 21.0);
    UIBezierPath* rectPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(size.width-rightCornerSize.width, 0, rightCornerSize.width, rightCornerSize.height) cornerRadius:2.0];
    [strokeColor setFill];
    [rectPath fill];
    
    NSString *text = [NSString stringWithFormat:@"%lu", (unsigned long)self.index];
    CGSize textSize = [text boundingRectWithSize:CGSizeMake(1000, 100) options:NSStringDrawingUsesLineFragmentOrigin attributes:self.textAttributes context:nil].size;
    [text drawInRect:CGRectMake(size.width-textSize.width-lineWidth, lineWidth*0.5, textSize.width, textSize.height) withAttributes:self.textAttributes];

    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.bounds];
    path.lineWidth = lineWidth;
    [strokeColor setStroke];
    [path stroke];
}

@end

@interface DXPhotoCollectionViewCell ()


@end


@implementation DXPhotoCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self.contentView addSubview:self.imageView];
        
        self.numberView = [[DXCellSelectedNumberView alloc] initWithFrame:self.bounds];
    }
    return self;
}

- (void)setSelected:(BOOL)selected
{
    if (selected) {
        [self.contentView addSubview:self.numberView];
    }else {
        [self.numberView removeFromSuperview];
    }
    [super setSelected:selected];
}

- (void)prepareForReuse
{
    self.numberView.index = 5;

    [super prepareForReuse];
}

- (void)bounce
{
    self.transform = CGAffineTransformMakeScale(0.97, 0.97);
    [UIView animateWithDuration:0.8 delay:0.0 usingSpringWithDamping:0.3 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:nil];

}


@end
