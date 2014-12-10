//
//  DXPhotoSelectBrowser.m
//  DXPhotoSelectBrowser
//
//  Created by xiekw on 12/10/14.
//  Copyright (c) 2014 xiekw. All rights reserved.
//

#import "DXImagePicker.h"
#import "DXPhotoCollectionViewCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "DXPopover.h"

static NSString * const CollectionCellId = @"dxCellid";
static CGFloat const tableViewRowHeight = 55.0;
static NSString * const CameraButton = @"CameraButton";

@interface DXImagePicker ()<UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) ALAssetsLibrary *assetLibrary;
@property (nonatomic, strong) NSMutableArray *albums; // the array of ALAssetsGroup;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ALAssetsGroup *currentAlbum;
@property (nonatomic, strong) UIButton *titleButton;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableDictionary *albumsAssetMap;
@property (nonatomic, strong) DXPopover *popover;
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, strong) NSMutableDictionary *selectedOrderMap;
@property (nonatomic, assign) NSInteger loadAssetCounter;

@end

@implementation DXImagePicker

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.assetLibrary = [ALAssetsLibrary new];
        self.albums = [NSMutableArray array];
        self.albumsAssetMap = [NSMutableDictionary dictionary];
        self.groupTypes = @[@(ALAssetsGroupSavedPhotos), @(ALAssetsGroupAlbum)];
        self.selectedAssets = [NSMutableArray array];
        self.selectedOrderMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)_loadAssets
{
    ALAssetsLibrary *al = self.assetLibrary;
    for (NSNumber *groupTye in self.groupTypes) {
        if (groupTye.integerValue > ALAssetsGroupAll) {
            NSParameterAssert(@"Invalid group type you set!");
        }
        [al enumerateGroupsWithTypes:groupTye.integerValue usingBlock:
         ^(ALAssetsGroup *group, BOOL *stop) {
             if (group == nil) {
                 return;
             }
             
             NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
             [group setAssetsFilter:[ALAssetsFilter allPhotos]];
             [self.albums addObject:group];
             
             NSMutableArray *array = [NSMutableArray array];
             [group enumerateAssetsWithOptions:0 usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                 if (!result) {
                     return;
                 }
                 
                 [array addObject:result];
             }];
             
             self.albumsAssetMap[sGroupPropertyName] = array;
             
             self.loadAssetCounter ++;
             if (self.loadAssetCounter == self.groupTypes.count) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     [self.albums enumerateObjectsUsingBlock:^(ALAssetsGroup *obj, NSUInteger idx, BOOL *stop) {
                         
                         //find camera roll and insert button into it
                         NSUInteger nType = [[obj valueForProperty:ALAssetsGroupPropertyType] intValue];
                         if (nType == ALAssetsGroupSavedPhotos) {
                             NSMutableArray *mArray = self.albumsAssetMap[[obj valueForProperty:ALAssetsGroupPropertyName]];
                             [mArray insertObject:CameraButton atIndex:0];
                             
                             self.currentAlbum = obj;
                         }
                     }];
                     
                     
                     if (!self.currentAlbum) {
                         self.currentAlbum = [self.albums firstObject];
                     }
                     self.tableView.bounds = (CGRect){CGPointZero, CGSizeMake(CGRectGetWidth(self.view.bounds), tableViewRowHeight*self.albums.count)};

                     // add the camera button into it

                     
                 });
             }

             
         } failureBlock:^(NSError *error) {
             self.loadAssetCounter ++;
             if (self.loadAssetCounter == self.groupTypes.count) {
                 NSLog(@"There was an error with the ALAssetLibrary: %@", error);
             }
         }];
    }
    
}

- (void)setCurrentAlbum:(ALAssetsGroup *)currentAlbum
{
    if (![[_currentAlbum valueForProperty:ALAssetsGroupPropertyName] isEqualToString:[currentAlbum valueForProperty:ALAssetsGroupPropertyName]]) {
        _currentAlbum = currentAlbum;
        if ([NSThread isMainThread]) {
            [self _reload];
        }else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _reload];
            });
        }
    }
}

- (void)_reload
{
    [self.selectedAssets removeAllObjects];
    [self.titleButton setTitle:[self.currentAlbum valueForProperty:ALAssetsGroupPropertyName] forState:UIControlStateNormal];
    [self.collectionView reloadData];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self _loadAssets];

    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStylePlain target:self action:@selector(done)];
    
#warning We need a triangle image here
    self.titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.titleButton setTitle:[self.currentAlbum valueForProperty:ALAssetsGroupPropertyName] forState:UIControlStateNormal];
    self.navigationItem.titleView = self.titleButton;
    [self.titleButton addTarget:self action:@selector(showAlbums) forControlEvents:UIControlEventTouchUpInside];
    
    self.tableView = [[UITableView alloc] initWithFrame:(CGRect){CGPointZero, CGSizeMake(CGRectGetWidth(self.view.bounds), 100)} style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = tableViewRowHeight;
    
    CGFloat const inset = 5.0;
    CGFloat const eachLineCount = 3;
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
    [cv registerClass:[DXPhotoCollectionViewCell class] forCellWithReuseIdentifier:CollectionCellId];
    self.collectionView = cv;
    self.collectionView.allowsMultipleSelection = YES;
    
    [self.view addSubview:cv];
}

- (void)showAlbums
{
    if (!self.popover) {
        self.popover = [DXPopover popover];
        self.popover.cornerRadius = 4.0;
        self.popover.animationIn = 0.6;
    }
    [self.popover showAtPoint:CGPointMake(CGRectGetMidX(self.titleButton.frame), CGRectGetMaxY(self.titleButton.frame) + 30) popoverPostion:DXPopoverPositionDown withContentView:self.tableView inView:self.navigationController.view];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)done
{
    if ([self.delegate respondsToSelector:@selector(dx_imagePickerController:didSelectImages:)]) {
        [self.delegate dx_imagePickerController:self didSelectImages:self.selectedAssets];
    }
    [self dismiss];
}

#pragma -mark CollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSString *key = [self.currentAlbum valueForProperty:ALAssetsGroupPropertyName];
    NSArray *assets = self.albumsAssetMap[key];
    return assets.count;
}

- (ALAsset *)_assetForIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [self.currentAlbum valueForProperty:ALAssetsGroupPropertyName];
    NSArray *assets = self.albumsAssetMap[key];
    return assets[indexPath.row];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DXPhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CollectionCellId forIndexPath:indexPath];
    
    if ([[self.currentAlbum valueForProperty:ALAssetsGroupPropertyType] integerValue]==ALAssetsGroupSavedPhotos) {
        if (indexPath.row == 0) {
            cell.imageView.image = [UIImage imageNamed:@"camera"];
            return cell;
        }
    }
    cell.imageView.image = [UIImage imageWithCGImage:[self _assetForIndexPath:indexPath].thumbnail];

    NSInteger supposeIndex = [self.selectedOrderMap[indexPath] integerValue];
    cell.numberView.index = supposeIndex;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.currentAlbum valueForProperty:ALAssetsGroupPropertyType] integerValue]==ALAssetsGroupSavedPhotos) {
        if (indexPath.row == 0) {
            [collectionView deselectItemAtIndexPath:indexPath animated:NO];
            [self _showCamera];
            return;
        }
    }
    ALAsset *asset = [self _assetForIndexPath:indexPath];
    [self.selectedAssets addObject:asset];
    DXPhotoCollectionViewCell *cell = (DXPhotoCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    NSInteger supposeIndex = self.selectedAssets.count;
    cell.numberView.index = supposeIndex;
    [cell bounce];
    self.selectedOrderMap[indexPath] = @(supposeIndex);
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DXPhotoCollectionViewCell *cell = (DXPhotoCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if (cell.numberView.index < self.selectedAssets.count){
        
        //update visible cells
        NSArray *visibleCells = [collectionView visibleCells];
        for (DXPhotoCollectionViewCell *vcell in visibleCells) {
            if (vcell.numberView.index > cell.numberView.index) {
                vcell.numberView.index -= 1;
            }
        }
        
        //update selectMap
        NSDictionary *copyDic = [self.selectedOrderMap copy];
        [copyDic enumerateKeysAndObjectsUsingBlock:^(id key, NSNumber *number, BOOL *stop) {
            if (number.integerValue > cell.numberView.index) {
                self.selectedOrderMap[key] = @(number.integerValue-1);
            }
        }];
    }
    ALAsset *asset = [self _assetForIndexPath:indexPath];
    [self.selectedAssets removeObject:asset];
    
    
    
    [cell bounce];
}

- (void)_showCamera
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    // Try getting the edited image first. If it doesn't exist then you get the original image.
    UIImage* image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image) {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    if (image) {
        [self.selectedAssets addObject:image];
    }
    
    [picker dismissViewControllerAnimated:YES completion:^{
        [self done];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma -mark TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.albums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }

    ALAssetsGroup *group = self.albums[indexPath.row];
    cell.imageView.image = [[UIImage alloc] initWithCGImage:group.posterImage];
    cell.textLabel.text = [group valueForProperty:ALAssetsGroupPropertyName];
    NSInteger photoCount = [group numberOfAssets];
    NSString *format = photoCount > 1 ? NSLocalizedString(@"%d photos", nil) : NSLocalizedString(@"%d photo", nil);
    cell.detailTextLabel.text = [NSString stringWithFormat:format, photoCount];
    cell.textLabel.font = [UIFont systemFontOfSize:15.0];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13.0];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ALAssetsGroup *album = self.albums[indexPath.row];
    self.currentAlbum = album;
    [self.popover dismiss];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
