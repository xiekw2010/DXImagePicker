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
#import "DXPhotoCollectionViewCell.h"

static NSString  * const kCellId = @"kCollectionViewCellId";

@interface HomeViewController ()<DXImagePickerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSString *_shouldUserAlbumName;
    BOOL _themeBlack;
    BOOL _checkMark;
    UIColor *_themeColor;
    NSInteger _maxSelectedCount;
}

@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic, strong) NSArray *selectedAssetNames;
@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.images = [NSMutableArray array];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"ShowMyPhotos" style:UIBarButtonItemStylePlain target:self action:@selector(presentPhotoSelectBrowser)];
    
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"Black", @"White"]];
    [seg addTarget:self action:@selector(segDidChanged:) forControlEvents:UIControlEventValueChanged];
    seg.selectedSegmentIndex = 0;
    [self segDidChanged:seg];
    self.navigationItem.titleView = seg;
    
    CGFloat const inset = 5.0;
    CGFloat const eachLineCount = 4.0;
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumInteritemSpacing = inset;
    flowLayout.minimumLineSpacing = inset;
    flowLayout.sectionInset = UIEdgeInsetsMake(inset, inset, inset, inset);
    CGFloat width = (CGRectGetWidth(self.view.bounds)-(eachLineCount+1)*inset)/eachLineCount;
    flowLayout.itemSize = CGSizeMake(width, width);
    UICollectionView *cv = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    cv.alwaysBounceVertical = YES;
    cv.dataSource = self;
    cv.delegate = self;
    cv.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    cv.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:cv];
    [cv registerClass:[DXPhotoCollectionViewCell class] forCellWithReuseIdentifier:kCellId];
    self.collectionView = cv;
}

- (void)segDidChanged:(UISegmentedControl *)seg
{
    self.selectedAssetNames = nil;
    if (seg.selectedSegmentIndex == 0) {
        _themeBlack = NO;
        _checkMark = NO;
        _themeColor = nil;
        _maxSelectedCount = -1;
    }else {
        _themeBlack = NO;
        _checkMark = YES;
        _themeColor = nil;
        _maxSelectedCount = 5;
    }
}

- (void)presentPhotoSelectBrowser
{
    DXImagePicker *browser = [DXImagePicker new];
    browser.themeBlack = _themeBlack;
    browser.checkMark = _checkMark;
    browser.themeColor = _themeColor;
    browser.delegate = self;
    browser.shouldSelectedAssetFileNames = self.selectedAssetNames;
    browser.shouldSelectAlbumName = _shouldUserAlbumName;
    browser.maxSelectedCount = _maxSelectedCount;
    UINavigationController *navcon = [[UINavigationController alloc] initWithRootViewController:browser];
    [self presentViewController:navcon animated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DXPhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellId forIndexPath:indexPath];
    
    cell.imageView.image = self.images[indexPath.row];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}


- (void)dx_imagePickerController:(DXImagePicker *)picker didSelectAssets:(NSArray *)assets didCamptureImage:(UIImage *)image
{

    [self.images removeAllObjects];
    [self.collectionView reloadData];
    
    
    for (ALAsset *asset in assets) {
        UIImage *thumbnail = [[UIImage alloc] initWithCGImage:asset.thumbnail];
        [self.images addObject:thumbnail];
    }
    
    if (image) {
        [self.images addObject:image];
    }
    
    
    [self.collectionView reloadData];
    self.selectedAssetNames = [DXImagePicker getAssetNamesByAssets:assets];
}

- (void)dx_imagePickerController:(DXImagePicker *)picker didSelectAlbumName:(NSString *)albumName
{
    _shouldUserAlbumName = albumName;
}

- (void)dx_imagePickerController:(DXImagePicker *)picker didReachMaxSelectedCount:(NSInteger)maxCount
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:@"You have reach the max count of choose" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
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
