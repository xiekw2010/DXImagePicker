//
//  DXDetailImageViewController.m
//  DXPhotoSelectBrowser
//
//  Created by xiekw on 12/12/14.
//  Copyright (c) 2014 xiekw. All rights reserved.
//

#import "DXDetailImageViewController.h"

#define PADDING                  10


@interface DXDetailImageViewController ()<UIScrollViewDelegate>
{
    NSMutableSet *_visiblePages;
    NSMutableSet *_recycledPages;
}

@property (nonatomic, strong) UIScrollView *pagingScrollView;

@end

@implementation DXDetailImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    _pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    _pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _pagingScrollView.pagingEnabled = YES;
    _pagingScrollView.delegate = self;
    _pagingScrollView.showsHorizontalScrollIndicator = NO;
    _pagingScrollView.showsVerticalScrollIndicator = NO;
    _pagingScrollView.backgroundColor = [UIColor blackColor];
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    [self.view addSubview:_pagingScrollView];
}

- (CGRect)frameForPagingScrollView {
    CGRect frame = self.view.bounds;// [[UIScreen mainScreen] bounds];
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return CGRectIntegral(frame);
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self assets].count, bounds.size.height);
}

- (void)reloadData {
    
    // Reset
    
}

- (void)performLayout {
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
