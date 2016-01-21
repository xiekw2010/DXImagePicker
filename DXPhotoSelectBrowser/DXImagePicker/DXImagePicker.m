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
#import "DXUtilViews.h"
#import "DXPhotoBrowser.h"

static NSString * const CollectionCellId = @"dxCellid";
static NSString * const CameraButton = @"CameraButton";

@interface DXImagePicker ()<UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DXPhotoBrowserDelegate>
{
    UIImage *_captureImage;
    BOOL _shouldPreLoadIndex;
    NSInteger _shouldSelectAlbumIndex;
    ALAssetsGroup *_cameraGroup;
    BOOL _isUpdatingAlbums;
}

@property (nonatomic, strong) ALAssetsLibrary *assetLibrary;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ALAssetsGroup *currentAlbum;
@property (nonatomic, strong) TriangleButton *titleButton;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) DXPopover *popover;
@property (nonatomic, assign) NSInteger loadAssetCounter;

@property (nonatomic, strong) NSMutableArray *albums; // the array of ALAssetsGroup;
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, strong) NSMutableDictionary *albumsAssetMap;
@property (nonatomic, strong) NSMutableDictionary *selectedOrderMap;//@{assetName1:@(1), assetName2:@(2)}


@end

@implementation DXImagePicker

#pragma -mark private method

- (void)_loadAssets
{
    self.groupTypes = self.groupTypes ? : @[@(ALAssetsGroupSavedPhotos), @(ALAssetsGroupAlbum)];

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
             [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                 if (!result) {
                     return;
                 }
                 
                 [array addObject:result];
             }];
             
             self.albumsAssetMap[sGroupPropertyName] = array;
             
             self.loadAssetCounter ++;
             if (self.loadAssetCounter == self.groupTypes.count) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     _shouldSelectAlbumIndex = 0;
                     [self.albums enumerateObjectsUsingBlock:^(ALAssetsGroup *obj, NSUInteger idx, BOOL *stop) {
                         
                         //find camera roll and insert button into it
                         NSUInteger nType = [[obj valueForProperty:ALAssetsGroupPropertyType] intValue];
                         if (nType == ALAssetsGroupSavedPhotos) {
                             NSMutableArray *mArray = self.albumsAssetMap[[obj valueForProperty:ALAssetsGroupPropertyName]];
                             [mArray insertObject:CameraButton atIndex:0];
                             _cameraGroup = obj;
                         }
                         
                         
                         NSString *ablumName = [obj valueForProperty:ALAssetsGroupPropertyName];
                         if ([ablumName isEqualToString:self.shouldSelectAlbumName]) {
                             _shouldSelectAlbumIndex = idx;
                         }
                     }];
                     
                     
                     
                     if (!self.currentAlbum) {
                         self.currentAlbum = [self.albums objectAtIndex:_shouldSelectAlbumIndex];
                     }
                     CGFloat tbHeight = MIN(275, [DXAlbumCell standHeight]*self.albums.count);
                     self.tableView.bounds = (CGRect){CGPointZero, CGSizeMake(CGRectGetWidth(self.view.bounds), tbHeight)};
                     
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

- (void)_reload
{
    [self.selectedAssets removeAllObjects];
    self.navigationItem.rightBarButtonItem.enabled = self.selectedAssets.count > 0;
    [self.titleButton setTitle:[self.currentAlbum valueForProperty:ALAssetsGroupPropertyName] forState:UIControlStateNormal];
    [self.collectionView reloadData];
    
    if (_shouldPreLoadIndex) {
        //Pre load table view
        NSInteger indexOfCurrentKeyInAlums = [self.albums indexOfObject:self.currentAlbum];
        if (indexOfCurrentKeyInAlums != NSNotFound) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:indexOfCurrentKeyInAlums inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        }
        
        _shouldPreLoadIndex = NO;
        
        //Pre load collection view
        if (self.shouldSelectedAssetFileNames.count) {
            NSString *currentKey = [self.currentAlbum valueForProperty:ALAssetsGroupPropertyName];
            NSArray *currentAlbumAsset = self.albumsAssetMap[currentKey];
            NSArray *currentAlbumAssetNames = [[self class] getAssetNamesByAssets:currentAlbumAsset];
            
            NSMutableDictionary *nameIndexMap = [NSMutableDictionary dictionaryWithCapacity:currentAlbumAssetNames.count];
            [currentAlbumAssetNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                nameIndexMap[obj] = @(idx);
            }];
            
            [self.shouldSelectedAssetFileNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                NSInteger shouldInexCurrentAlbumAssets = [nameIndexMap[obj] integerValue];
           
                if ([self _isCameraRoll]) {
                    shouldInexCurrentAlbumAssets += 1;
                }
                
                [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:shouldInexCurrentAlbumAssets inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
                [self collectionView:self.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForRow:shouldInexCurrentAlbumAssets inSection:0]];
            }];
            
            self.shouldSelectedAssetFileNames = nil;
        }
    }
}

- (void)_reloadAblumAssets:(ALAssetsGroup *)ablum
{
    NSString *albumName = [ablum valueForProperty:ALAssetsGroupPropertyName];
    
    NSMutableArray *array = [NSMutableArray array];
    [ablum enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (!result) {
            return;
        }
        [array addObject:result];
    }];
    if ([[ablum valueForProperty:ALAssetsGroupPropertyType] integerValue] == ALAssetsGroupSavedPhotos) {
        [array insertObject:CameraButton atIndex:0];
    }
    self.albumsAssetMap[albumName] = array;
    [self.tableView reloadData];
    
    
    if (ablum == self.currentAlbum) {
        [self _updateSeletedAssets];
        
        _shouldPreLoadIndex = YES;
        self.shouldSelectedAssetFileNames = [[self class] getAssetNamesByAssets:self.selectedAssets];
        [self _reload];
    }
}

- (NSArray *)_updateSeletedAssets
{
    NSSet *currentAssetNameSets = [NSSet setWithArray:[[self class] getAssetNamesByAssets:[self _currentAblumAssets]]];
    NSArray *result = [self.selectedAssets filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(ALAsset *evaluatedObject, NSDictionary *bindings) {
        NSString *fileName = [evaluatedObject defaultRepresentation].filename;
        return [currentAssetNameSets containsObject:fileName] == NO;
    }]];
    
    NSArray *unNeedAssets = result;
    for (ALAsset *asset in unNeedAssets) {
        [self _removeSelectedAsset:asset];
    }

    return result;
}

- (void)_reloadCurrentAlbum:(NSNotification *)noti
{
    if (_isUpdatingAlbums) {
        return;
    }
    NSLog(@"Noti is %@", noti.userInfo);
    
    NSDictionary *userInfo = noti.userInfo;
    if (userInfo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _isUpdatingAlbums = YES;
            NSArray *ablumArray = userInfo[ALAssetLibraryUpdatedAssetGroupsKey];
            if (ablumArray.count) {
                NSMutableSet *set = [NSMutableSet setWithCapacity:self.albums.count];
                for (ALAssetsGroup *group in self.albums) {
                    [set addObject:[group valueForProperty:ALAssetsGroupPropertyURL]];
                }
                NSArray *result = [self.albums filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(ALAssetsGroup *evaluatedObject, NSDictionary *bindings) {
                    NSString *URL = [evaluatedObject valueForProperty:ALAssetsGroupPropertyURL];
                    return [set containsObject:URL];
                }]];
                
                for (ALAssetsGroup *group in result) {
                    [self _reloadAblumAssets:group];
                }
            }
            _isUpdatingAlbums = NO;
        });
    }
}

- (BOOL)_isCameraRoll
{
    return  [[self.currentAlbum valueForProperty:ALAssetsGroupPropertyType] integerValue]==ALAssetsGroupSavedPhotos;
}

- (NSMutableArray *)_currentAblumAssets
{
    NSString *albumName = [self.currentAlbum valueForProperty:ALAssetsGroupPropertyName];
    return self.albumsAssetMap[albumName];
}

- (void)_showAlbums
{
    if (!self.popover) {
        self.popover = [DXPopover popover];
        self.popover.cornerRadius = 4.0;
        self.popover.animationIn = 0.5;
        self.popover.arrowSize = CGSizeMake(10.0, 6.0);
        self.popover.animationOut = 0.3;
    }
    CGRect titleButtonFrame = [self.navigationItem.titleView convertRect:self.titleButton.frame toView:self.navigationController.view];
    
    [self.popover showAtPoint:CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMaxY(titleButtonFrame)-6.0) popoverPostion:DXPopoverPositionDown withContentView:self.tableView inView:self.navigationController.view];
}

- (void)_dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)_done
{
    if ([self.delegate respondsToSelector:@selector(dx_imagePickerController:didSelectAssets:didCamptureImage:)]) {
        [self.delegate dx_imagePickerController:self didSelectAssets:self.selectedAssets didCamptureImage:_captureImage];
    }
    [self _dismiss];
}

- (void)_showCamera
{
    if ([self.delegate respondsToSelector:@selector(dx_imagePickerControllerDidPushCameraButton:)]) {
        [self.delegate dx_imagePickerControllerDidPushCameraButton:self];
        return;
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)_addSelectedAsset:(ALAsset *)asset
{
    NSString *assetName = [asset defaultRepresentation].filename;
    [self.selectedAssets addObject:asset];
    self.selectedOrderMap[assetName] = @(self.selectedAssets.count);

    self.navigationItem.rightBarButtonItem.enabled = self.selectedAssets.count > 0;
}

- (void)_removeSelectedAsset:(ALAsset *)asset
{
    NSString *assetName = [asset defaultRepresentation].filename;
    NSInteger index = [self.selectedOrderMap[assetName] integerValue];
    if (index > 0) {
        if (index < self.selectedAssets.count){
            
            //update visible cells
            NSArray *visibleCells = [self.collectionView visibleCells];
            for (DXPhotoCollectionViewCell *vcell in visibleCells) {
                if (vcell.numberView.index > index) {
                    vcell.numberView.index -= 1;
                }
            }
            
            //update selectMap
            NSDictionary *copyDic = [self.selectedOrderMap copy];
            [copyDic enumerateKeysAndObjectsUsingBlock:^(id key, NSNumber *number, BOOL *stop) {
                if (number.integerValue > index) {
                    self.selectedOrderMap[key] = @(number.integerValue-1);
                }
            }];
        }
        [self.selectedAssets removeObject:asset];
        [self.selectedOrderMap removeObjectForKey:assetName];
        self.navigationItem.rightBarButtonItem.enabled = self.selectedAssets.count > 0;
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.assetLibrary = [ALAssetsLibrary new];
        self.albums = [NSMutableArray array];
        self.albumsAssetMap = [NSMutableDictionary dictionary];
        self.selectedAssets = [NSMutableArray array];
        self.selectedOrderMap = [NSMutableDictionary dictionary];
        self.themeBlack = YES;
        self.checkMark = NO;
        self.maxSelectedCount = -1;
    
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_reloadCurrentAlbum:) name:ALAssetsLibraryChangedNotification object:nil];
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setCurrentAlbum:(ALAssetsGroup *)currentAlbum
{
    NSString *currentAlbumName = [currentAlbum valueForProperty:ALAssetsGroupPropertyName];
    if (currentAlbum && ![[_currentAlbum valueForProperty:ALAssetsGroupPropertyName] isEqualToString:currentAlbumName]) {

        _shouldPreLoadIndex = _currentAlbum == nil;
        
        _currentAlbum = currentAlbum;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(dx_imagePickerController:didSelectAlbumName:)]) {
                [self.delegate dx_imagePickerController:self didSelectAlbumName:[self.currentAlbum valueForProperty:ALAssetsGroupPropertyName]];
            }
            [self _reload];
        });
    }
}

+ (NSArray *)getAssetNamesByAssets:(NSArray *)assets
{
    NSMutableArray *mArray = [NSMutableArray arrayWithCapacity:assets.count];
    for (ALAsset *asset in assets) {
        if (![asset isKindOfClass:[ALAsset class]]) {
            continue;
        }
        NSString *url = [asset defaultRepresentation].filename;
        //        NSLog(@"asset URL is %@", url.absoluteString);
        [mArray addObject:url];
    }
    return mArray;
}

- (void)didTakePhoto:(UIImage *)image
{
    _captureImage = image;
    
    [self _done];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _loadAssets];

    self.themeColor = self.themeColor ? : [UIColor colorWithRed:0.06 green:0.51 blue:1.00 alpha:1.00];

    
    UIBarStyle barStyle;
    UIColor *colletionViewBackColor;
    UIColor *titleColor;

    if (self.themeBlack) {
        barStyle = UIBarStyleBlack;
        colletionViewBackColor = [UIColor blackColor];
        titleColor = [UIColor whiteColor];
    }else {
        barStyle = UIBarStyleDefault;
        colletionViewBackColor = [UIColor whiteColor];
        titleColor = [UIColor darkGrayColor];
    }
    
    self.navigationController.navigationBar.barStyle = barStyle;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(_dismiss)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStylePlain target:self action:@selector(_done)];
    
    self.navigationItem.leftBarButtonItem.tintColor = self.navigationItem.rightBarButtonItem.tintColor = self.themeColor;
    
    self.titleButton = [[TriangleButton alloc] initWithFrame:CGRectMake(0, 0, 200, 44.0) themeColor:titleColor];
    [self.titleButton setTitle:[self.currentAlbum valueForProperty:ALAssetsGroupPropertyName] forState:UIControlStateNormal];
    self.navigationItem.titleView = self.titleButton;
    [self.titleButton addTarget:self action:@selector(_showAlbums) forControlEvents:UIControlEventTouchUpInside];
    
    self.tableView = [[UITableView alloc] initWithFrame:(CGRect){CGPointZero, CGSizeMake(CGRectGetWidth(self.view.bounds), 100)} style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = [DXAlbumCell standHeight];
    
    CGFloat const inset = 3.0;
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
    cv.backgroundColor = colletionViewBackColor;
    self.collectionView = cv;
    self.collectionView.allowsMultipleSelection = YES;
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 3);
    
    [self.view addSubview:cv];
    self.navigationItem.rightBarButtonItem.enabled = self.selectedAssets.count > 0;
    
}

#pragma -mark CollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self _currentAblumAssets].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DXPhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CollectionCellId forIndexPath:indexPath];
    cell.tag = indexPath.row;
    
    //ここでセルのマーク指定を行いたい
    if (self.checkMark) {
        cell.checkMark = true;
    } else {
        cell.checkMark = false;
    }
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressCell:)];
    [cell addGestureRecognizer:longPress];
    
    if ([self _isCameraRoll]) {
        if (indexPath.row == 0) {
            cell.imageView.image = [UIImage imageNamed:@"DXImagePickerImage.bundle/camera"];
            return cell;
        }
    }
    ALAsset *asset = [[self _currentAblumAssets] objectAtIndex:indexPath.row];
    NSString *assetName = [asset defaultRepresentation].filename;
    cell.imageView.image = [UIImage imageWithCGImage:asset.thumbnail];
    cell.numberView.normalColor = self.themeColor;
    cell.checkView.normalColor = self.themeColor;
    NSInteger supposeIndex = [self.selectedOrderMap[assetName] integerValue];
    cell.numberView.index = supposeIndex;
    
    return cell;
}

- (void)longPressCell:(UILongPressGestureRecognizer *)longPress
{
    if (longPress.state == UIGestureRecognizerStateBegan) {
        NSString *currentAssetName = [self.currentAlbum valueForProperty:ALAssetsGroupPropertyName];
        NSArray *assets = self.albumsAssetMap[currentAssetName];
        ALAsset *asset = assets[longPress.view.tag];
        NSLog(@"asset is %@", asset);
        DXPhotoBrowser *detail = [DXPhotoBrowser new];
        detail.delegate = self;
        [detail setCurrentPhotoIndex:longPress.view.tag - 1];
        [self.navigationController pushViewController:detail animated:YES];

    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.selectedAssets.count == self.maxSelectedCount) {
        if ([self.delegate respondsToSelector:@selector(dx_imagePickerController:didReachMaxSelectedCount:)]) {
            [self.delegate dx_imagePickerController:self didReachMaxSelectedCount:self.selectedAssets.count
             ];
            [collectionView deselectItemAtIndexPath:indexPath animated:NO];
            return;
        }
    }
    
    if ([self _isCameraRoll]) {
        if (indexPath.row == 0) {
            [collectionView deselectItemAtIndexPath:indexPath animated:NO];
            [self _showCamera];
            return;
        }
    }
    
    
    ALAsset *asset = [[self _currentAblumAssets] objectAtIndex:indexPath.row];
    [self _addSelectedAsset:asset];
    
    DXPhotoCollectionViewCell *cell = (DXPhotoCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    NSInteger supposeIndex = self.selectedAssets.count;
    cell.numberView.index = supposeIndex;
    [cell bounce];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = [[self _currentAblumAssets] objectAtIndex:indexPath.row];
    [self _removeSelectedAsset:asset];
    DXPhotoCollectionViewCell *cell = (DXPhotoCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell bounce];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    // Try getting the edited image first. If it doesn't exist then you get the original image.
    UIImage *captureImage = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!captureImage) {
        captureImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    [picker dismissViewControllerAnimated:NO completion:^{
        [self didTakePhoto:captureImage];
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
    DXAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[DXAlbumCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    cell.normalColor = self.themeColor;
    ALAssetsGroup *group = self.albums[indexPath.row];
    cell.imageView.image = [[UIImage alloc] initWithCGImage:group.posterImage];
    cell.textLabel.text = [group valueForProperty:ALAssetsGroupPropertyName];
    NSInteger photoCount = [group numberOfAssets];
    NSString *format = photoCount > 1 ? NSLocalizedString(@"%d photos", nil) : NSLocalizedString(@"%d photo", nil);
    cell.detailTextLabel.text = [NSString stringWithFormat:format, photoCount];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ALAssetsGroup *album = self.albums[indexPath.row];
    self.currentAlbum = album;
    [self.popover dismiss];
}

#pragma mark - DXPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(DXPhotoBrowser *)photoBrowser
{
    NSString *currentAssetName = [self.currentAlbum valueForProperty:ALAssetsGroupPropertyName];
    NSArray *assets = self.albumsAssetMap[currentAssetName];
    return assets.count - 1;
}

- (UIImage *)photoBrowser:(DXPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    NSString *currentAssetName = [self.currentAlbum valueForProperty:ALAssetsGroupPropertyName];
    NSArray *assets = self.albumsAssetMap[currentAssetName];
    ALAsset *asset = assets[index + 1];
    //NSLog(@"asset:%@",asset);
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    CGImageRef cgImage = [rep fullResolutionImage];
    UIImage *image= [UIImage imageWithCGImage:cgImage];
    return image;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
