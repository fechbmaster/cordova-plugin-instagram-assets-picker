//
//  IGAssetsPickerViewController.m
//  InstagramAssetsPicker
//
//  Created by JG on 2/3/15.
//  Copyright (c) 2015 JG. All rights reserved.
//

#import "IGAssetsPickerViewController.h"
#import "IGCropView.h"
#import "IGAssetsCollectionViewCell.h"
#import "IGAssetsPicker.h"

@interface IGAssetsPickerViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate>
{
    CGFloat beginOriginY;
}
@property (strong, nonatomic) UIView *topView;
@property (strong, nonatomic) UIImageView *maskView;
@property (strong, nonatomic) IGCropView *cropView;

@property (strong, nonatomic) NSMutableArray *assets;
@property (strong, nonatomic) PHPhotoLibrary *assetsLibrary;

@property (strong, nonatomic) UICollectionView *collectionView;
@end

@implementation IGAssetsPickerViewController
@synthesize cropAfterSelect;
@synthesize fetchOptions;
@synthesize showGrid;

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];

    [self.view addSubview:self.topView];
    [self.view addSubview:self.collectionView];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self loadPhotos];

}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (NSMutableArray *)assets {
    if (_assets == nil) {
        _assets = [[NSMutableArray alloc] init];
    }
    return _assets;
}

- (PHPhotoLibrary *)assetsLibrary {
    if (_assetsLibrary == nil) {
        _assetsLibrary = [[PHPhotoLibrary alloc] init];
    }
    return _assetsLibrary;
}

- (void)loadPhotos {

    PHFetchResult *allMedia = [PHAsset fetchAssetsWithOptions: self.fetchOptions];
    long mediaCount = [allMedia count];
    [allMedia enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        if (asset) {
            [self.assets insertObject:asset atIndex:0];
        }
        if (mediaCount == idx + 1) {
            if (self.assets.count) {

                PHAsset *asset = [self.assets objectAtIndex:0];
                [self.cropView setPhAsset:asset];
                [self.collectionView reloadData];
            }
        }
    }];

}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIView *)topView {
    if (_topView == nil) {
        CGFloat handleHeight = 44.0f;
        CGRect screen = [[UIScreen mainScreen] bounds];
        CGRect rect = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds)+handleHeight*2);
        self.topView = [[UIView alloc] initWithFrame:rect];
        self.topView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        self.topView.backgroundColor = [UIColor clearColor];
        self.topView.clipsToBounds = YES;

        rect = CGRectMake(0, 0, CGRectGetWidth(self.topView.bounds), handleHeight);
        UIView *navView = [[UIView alloc] initWithFrame:rect];//26 29 33
        navView.backgroundColor = [UIColor whiteColor];
        navView.layer.borderWidth = 1;
        navView.layer.borderColor = UIColor.lightGrayColor.CGColor;
        [self.topView addSubview:navView];

        rect = CGRectMake(0, 0, 60, handleHeight);
        UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        backBtn.frame = rect;
        [backBtn setImage:[UIImage imageNamed:@"InstagramAssetsPicker.bundle/back"] forState:UIControlStateNormal];
        [backBtn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
        [navView addSubview:backBtn];
        
        CGFloat offset = 0.0f;
        if (screen.size.width > screen.size.height) {
            offset = screen.size.height - 45;
        }
        else {
            offset = screen.size.width - 45;
        }
        
        rect = CGRectMake(offset, 2, 40, 40);
        UIButton *cropBtn = [[UIButton alloc] initWithFrame:rect];
        [cropBtn setTitle:@"OK" forState:UIControlStateNormal];
        [cropBtn.titleLabel setFont:[UIFont systemFontOfSize:16.0f]];
        [cropBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [cropBtn addTarget:self action:@selector(cropAction) forControlEvents:UIControlEventTouchUpInside];
        cropBtn.backgroundColor = [UIColor colorWithRed:0.91 green:0.20 blue:0.29 alpha:1.0];
        cropBtn.layer.cornerRadius = 20;
        cropBtn.clipsToBounds = YES;
        [navView addSubview:cropBtn];

        rect = CGRectMake(0, handleHeight, CGRectGetWidth(self.topView.bounds), CGRectGetHeight(self.topView.bounds)-handleHeight*2);
        self.cropView = [[IGCropView alloc] initWithFrame:rect];
        self.cropView.hidden = YES;
        [self.topView insertSubview:self.cropView belowSubview:self.collectionView];
        [self.topView sendSubviewToBack:self.cropView];
    }
    return _topView;
}

- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        CGFloat colum = 4.0, spacing = 2.0;
        CGFloat value = floorf((CGRectGetWidth(self.view.bounds) - (colum - 1) * spacing) / colum);

        UICollectionViewFlowLayout *layout  = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize                     = CGSizeMake(value, value);
        layout.sectionInset                 = UIEdgeInsetsMake(0, 0, 0, 0);
        layout.minimumInteritemSpacing      = spacing;
        layout.minimumLineSpacing           = spacing;

        CGRect rect = CGRectMake(0, 44.0f, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
        _collectionView = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:layout];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.alwaysBounceVertical = YES;

        [_collectionView registerClass:[IGAssetsCollectionViewCell class] forCellWithReuseIdentifier:@"IGAssetsCollectionViewCell"];
    }
    return _collectionView;
}

- (void)backAction {
    [self.cropView stopPlayingIfNecessary];
    [self dismissViewControllerAnimated:YES completion:NULL];
    if(self.delegate && [self.delegate respondsToSelector:@selector(IGAssetsPickerCancel)])
    {
        [self.delegate IGAssetsPickerCancel];
    }
}

- (void)cropAction {
    if (cropAfterSelect)
    {
        if(self.delegate && [self.delegate respondsToSelector:@selector(IGAssetsPickerFinishCroppingToAsset:)])
        {
            [self.cropView cropAsset:^(id asset) {
                [self.delegate IGAssetsPickerFinishCroppingToAsset:asset];
            }];
        }
    }
    else
    {
        if(self.delegate && [self.delegate respondsToSelector:@selector(IGAssetsPickerGetCropRegion: withPhAsset:)])
        {
            [self.cropView getCropRegion:^(CGRect rect) {
                [self.delegate IGAssetsPickerGetCropRegion:rect withPhAsset:self.cropView.phAsset];
            }];
        }
    }

    [self.cropView stopPlayingIfNecessary];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)panGestureAction:(UIPanGestureRecognizer *)panGesture {
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            CGRect topFrame = self.topView.frame;
            CGFloat endOriginY = self.topView.frame.origin.y;
            if (endOriginY > beginOriginY) {
                topFrame.origin.y = (endOriginY - beginOriginY) >= 20 ? 0 : -(CGRectGetHeight(self.topView.bounds)-20-44);
            } else if (endOriginY < beginOriginY) {
                topFrame.origin.y = (beginOriginY - endOriginY) >= 20 ? -(CGRectGetHeight(self.topView.bounds)-20-44) : 0;
            }

            CGRect collectionFrame = self.collectionView.frame;
            collectionFrame.origin.y = CGRectGetMaxY(topFrame);
            collectionFrame.size.height = CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(topFrame);
            [UIView animateWithDuration:.3f animations:^{
                self.topView.frame = topFrame;
                self.collectionView.frame = collectionFrame;
            }];
            break;
        }
        case UIGestureRecognizerStateBegan:
        {
            beginOriginY = self.topView.frame.origin.y;
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [panGesture translationInView:self.view];
            CGRect topFrame = self.topView.frame;
            topFrame.origin.y = translation.y + beginOriginY;

            CGRect collectionFrame = self.collectionView.frame;
            collectionFrame.origin.y = CGRectGetMaxY(topFrame);
            collectionFrame.size.height = CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(topFrame);

            if (topFrame.origin.y <= 0 && (topFrame.origin.y >= -(CGRectGetHeight(self.topView.bounds)-20-44))) {
                self.topView.frame = topFrame;
                self.collectionView.frame = collectionFrame;
            }

            break;
        }
        default:
            break;
    }
}

- (void)cropViewPanGestureAction:(UIPanGestureRecognizer *)panGesture {
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            [self.maskView removeFromSuperview];
            break;
        }
        case UIGestureRecognizerStateBegan:
        {
            [self.topView insertSubview:self.maskView aboveSubview:self.cropView];
            break;
        }
        default:
            break;
    }
}

- (void)tapGestureAction:(UITapGestureRecognizer *)tapGesture {
    CGRect topFrame = self.topView.frame;
    topFrame.origin.y = topFrame.origin.y == 0 ? -(CGRectGetHeight(self.topView.bounds)-20-44) : 0;

    CGRect collectionFrame = self.collectionView.frame;
    collectionFrame.origin.y = CGRectGetMaxY(topFrame);
    collectionFrame.size.height = CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(topFrame);
    [UIView animateWithDuration:.3f animations:^{
        self.topView.frame = topFrame;
        self.collectionView.frame = collectionFrame;

    }];
}

#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"IGAssetsCollectionViewCell";

    IGAssetsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    [cell applyAsset:[self.assets objectAtIndex:indexPath.row]];
    return cell;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{

    PHAsset *asset = [self.assets objectAtIndex:indexPath.row];

    [self.cropView setPhAsset:asset];

    UICollectionViewCell * cell = [collectionView cellForItemAtIndexPath:indexPath];

    [self.collectionView setContentOffset:CGPointMake(0, cell.frame.origin.y - cell.frame.size.height / 2) animated:YES];
    if (self.topView.frame.origin.y != 0) {
        [self tapGestureAction:nil];
    }

}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    NSLog(@"velocity:%f", velocity.y);
    if (velocity.y >= 2.0 && self.topView.frame.origin.y == 0) {
        //[self tapGestureAction:nil];
    }
}


@end
