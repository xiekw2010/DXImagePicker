//
//  HomeViewController.m
//  DXPhotoSelectBrowser
//
//  Created by xiekw on 12/10/14.
//  Copyright (c) 2014 xiekw. All rights reserved.
//

#import "HomeViewController.h"
#import "DXImagePicker.h"
#import <AssetsLibrary/ALAsset.h>

@interface HomeViewController ()<DXImagePickerDelegate>

@property (nonatomic, strong) NSMutableArray *imageViews;
@property (nonatomic, strong) NSArray *selectedAssets;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.imageViews = [NSMutableArray array];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(100, 100, 100, 100);
    [btn setTitle:@"Phto" forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor redColor];
    [self.view addSubview:btn];
    
    [btn addTarget:self action:@selector(presentPhotoSelectBrowser) forControlEvents:UIControlEventTouchUpInside];
}

- (void)presentPhotoSelectBrowser
{
    DXImagePicker *browser = [DXImagePicker new];
    browser.delegate = self;
    UINavigationController *navcon = [[UINavigationController alloc] initWithRootViewController:browser];
    [self presentViewController:navcon animated:YES completion:nil];
}

- (void)dx_imagePickerController:(DXImagePicker *)picker didSelectImages:(NSArray *)assets
{
    for (UIImageView *igv in self.imageViews) {
        [igv removeFromSuperview];
    }
    [self.imageViews removeAllObjects];
    
    
    CGFloat const imageWidth = 50.0;
    CGFloat const imageSide = 5.0;
    
    [assets enumerateObjectsUsingBlock:^(ALAsset *asset, NSUInteger idx, BOOL *stop) {
        UIImageView *imageV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 64 + (imageSide+imageWidth)*idx, imageWidth, imageWidth)];
        UIImage *image;
        if ([asset isKindOfClass:[ALAsset class]]) {
            image = [UIImage imageWithCGImage:asset.thumbnail];
        }else {
            image = (UIImage *)asset;
        }
        imageV.image = image;
        [self.view addSubview:imageV];
        [self.imageViews addObject:imageV];
    }];
    
    self.selectedAssets = assets;
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
