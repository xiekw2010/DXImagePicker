//
//  DXPageViewController.m
//  DXPhotoSelectBrowser
//
//  Created by zhoujiuhai on 14/12/12.
//  Copyright (c) 2014年 xiekw. All rights reserved.
//

#import "DXPhotoBrowser.h"

@interface DXPhotoBrowser () <UIPageViewControllerDataSource,UIPageViewControllerDelegate>

@property (nonatomic, strong)UIPageViewController *pageViewController;

@end

@implementation DXPhotoBrowser

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.dataSource = self;
    self.pageViewController.view.frame = self.view.frame;
    
    photoViewController *initialViewController = [self viewControllerAtIndex:self.currentPhotoIndex];
    
    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
    
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:self.pageViewController];
    [[self view] addSubview:[self.pageViewController view]];
    [self.pageViewController didMoveToParentViewController:self];
    
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.pageViewController.view.frame = self.view.frame;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(photoViewController *)viewController index];
    
    if (index == 0) {
        return nil;
    }
    
    index--;
    
    return [self viewControllerAtIndex:index];
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(photoViewController *)viewController index];
    NSUInteger totalCount = [self.delegate numberOfPhotosInPhotoBrowser:self];
    
    index++;
    if (index == totalCount) {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
    
}

- (photoViewController *)viewControllerAtIndex:(NSUInteger)index {
    
    photoViewController *childViewController = [[photoViewController alloc] initWithNibName:nil bundle:nil];
    childViewController.index = index;
    childViewController.image = [self.delegate photoBrowser:self photoAtIndex:index];
    return childViewController;
}

@end



@interface photoViewController() <UIScrollViewDelegate>

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation photoViewController

-(void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _scrollView = [UIScrollView new];
    _scrollView.minimumZoomScale = 1.0;
    _scrollView.maximumZoomScale = 3.0;
    _scrollView.delegate = self;
    _scrollView.contentInset = UIEdgeInsetsMake(64, 10, 44, 10);
    [self.view addSubview:_scrollView];
    
    _imageView = [UIImageView new];
    _imageView.image = self.image;
    //_imageView.backgroundColor = [UIColor yellowColor];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_scrollView addSubview:_imageView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(taped:)];
    tapGesture.numberOfTapsRequired = 2;
    tapGesture.numberOfTouchesRequired = 1;
    [_scrollView addGestureRecognizer:tapGesture];

}

- (void)taped:(UITapGestureRecognizer *)gesture
{
    CGPoint point = [gesture locationInView:_scrollView];
    if (_scrollView.zoomScale == _scrollView.minimumZoomScale) {
        [_scrollView zoomToRect:CGRectMake(point.x, point.y, 1, 1) animated:YES];
    }
    else {
        [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:YES];
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    CGRect bounds = self.view.bounds;
    _scrollView.frame = bounds;
    
    CGFloat imageViewSideOffset = 10;
    CGFloat imageViewTopOffset = 64;
    CGFloat imageViewBottompOffset = 44;
    CGFloat imageViewWidth = bounds.size.width - imageViewSideOffset * 2;
    CGFloat imageViewHeight = bounds.size.height - imageViewTopOffset - imageViewBottompOffset;
//    CGSize imageSize = self.image.size;
//    if (imageSize.width / imageSize.height > imageViewWidth / imageViewHeight) {
//        CGFloat zoomImageHeight = imageViewWidth * imageSize.height / imageSize.width;
//        _imageView.frame = CGRectMake(imageViewSideOffset, imageViewTopOffset + (imageViewHeight - zoomImageHeight) * 0.5, imageViewWidth,zoomImageHeight);
//    }
//    else {
//        CGFloat zoomImageWidth = imageViewHeight * imageSize.width / imageSize.height ;
//        _imageView.frame = CGRectMake(imageViewSideOffset + (imageViewWidth - zoomImageWidth) * 0.5, imageViewTopOffset, zoomImageWidth,imageViewHeight);
//    }
    //_imageView.frame = CGRectMake(imageViewSideOffset, imageViewTopOffset, imageViewWidth,imageViewHeight);
    _imageView.frame = CGRectMake(0, 0, imageViewWidth,imageViewHeight);
    
    
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageView;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_scrollView setZoomScale:1.0 animated:NO];
}



@end