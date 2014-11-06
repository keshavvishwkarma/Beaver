//
//  EditPhotoViewController.m
//  Beaver
//
//  Created by xuzhaocheng on 14/11/5.
//  Copyright (c) 2014年 Zhejiang University. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <objc/runtime.h>
#import "EditPhotoViewController.h"
#import "ToolCell.h"
#import "ToolCellInfo.h"

#import "UIImageView+Cropping.h"


@interface EditPhotoViewController () <UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIImage *image;
@property (nonatomic) BOOL allowZooming;

@property (strong, nonatomic) NSArray *toolCellInfos;

@property (weak, nonatomic) IBOutlet UIScrollView *imageScrollView;
@property (weak, nonatomic) IBOutlet UICollectionView *toolsView;

@end


@implementation EditPhotoViewController


#pragma mark - Properties

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;
    self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    
    [self configureImageScrollView];
}

- (UIImage *)image
{
    return self.imageView.image;
}

- (void)setImageScrollView:(UIScrollView *)imageScrollView
{
    _imageScrollView = imageScrollView;
    [self configureImageScrollView];
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
    }
    return _imageView;
}

- (void)setPhotoAsset:(ALAsset *)photoAsset
{
    _photoAsset = photoAsset;
    self.image = [UIImage imageWithCGImage:[[_photoAsset defaultRepresentation] fullResolutionImage]];
}

- (NSArray *)toolCellInfos
{
    if (!_toolCellInfos) {
        NSMutableArray *aMutableArray = [[NSMutableArray alloc] init];
        [aMutableArray addObject:[[ToolCellInfo alloc] initWithTitle:@"Cropping" icon:@""]];
        _toolCellInfos = aMutableArray;
    }
    return _toolCellInfos;
}

#pragma mark - View Controller

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.allowZooming = YES;
    [self.imageScrollView addSubview:self.imageView];
    self.toolsView.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateScrollViewContentInsets];
    [self centeredFrame:self.imageView forScrollView:self.imageScrollView];
}


#pragma mark - Helpers

- (void)updateUI
{

}

// 设置scrollView的contentInsets
- (void)updateScrollViewContentInsets
{
    UIEdgeInsets insets = self.imageScrollView.contentInset;
    
    insets.bottom = self.toolsView.bounds.size.height;
    if (!UIEdgeInsetsEqualToEdgeInsets(insets, self.imageScrollView.contentInset)) {
        self.imageScrollView.contentInset = insets;
        CGSize contentSize = self.imageScrollView.contentSize;
        contentSize.width -= insets.left + insets.right;
        contentSize.height -= insets.top + insets.bottom;
        self.imageScrollView.contentSize = contentSize;
    }
}

- (void)configureImageScrollView
{
    if (self.imageScrollView) {
        CGRect bounds = self.imageScrollView.bounds;
        CGFloat xScale = bounds.size.width / self.image.size.width;
        CGFloat yScale = bounds.size.height / self.image.size.height;
        
        CGFloat minScale = MIN(xScale, yScale);
        CGFloat maxScale = 3;
        self.imageScrollView.minimumZoomScale = minScale;
        self.imageScrollView.maximumZoomScale = maxScale;
        self.imageScrollView.zoomScale = minScale;
        self.imageScrollView.contentSize = self.imageScrollView.bounds.size;
        NSLog(@"bound size: %@", NSStringFromCGSize(self.imageScrollView.bounds.size));
    }
}

- (void)centeredFrame:(UIView *)view forScrollView:(UIScrollView *)scrollView
{
    CGRect frameToCenter = view.frame;
    CGSize boundsSize = scrollView.bounds.size;
    UIEdgeInsets contentInsets = scrollView.contentInset;
    
    boundsSize.width = boundsSize.width - contentInsets.left - contentInsets.right;
    boundsSize.height = boundsSize.height - contentInsets.top - contentInsets.bottom ;//- self.toolsView.bounds.size.height;
    
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2.0;
    } else {
        frameToCenter.origin.x = 0.f;
    }
    
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2.0;
    } else {
        frameToCenter.origin.y = 0;
    }
    
    view.frame = frameToCenter;
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.allowZooming ? self.imageView : nil;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self centeredFrame:self.imageView forScrollView:scrollView];
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.toolCellInfos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ToolCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Tool Cell" forIndexPath:indexPath];
    ToolCellInfo *cellInfo = self.toolCellInfos[indexPath.row];
    [cell configureCellWithTitle:cellInfo.title image:nil];
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ToolCellInfo *toolCellInfo = self.toolCellInfos[indexPath.row];
    
    NSString *selectorName = [NSString stringWithFormat:@"%@%@Action", [[toolCellInfo.title substringToIndex:1] lowercaseString], [toolCellInfo.title substringFromIndex:1]];
    
    SEL selector = NSSelectorFromString(selectorName);
    
    // http://stackoverflow.com/questions/7017281/performselector-may-cause-a-leak-because-its-selector-is-unknown
    if ([self respondsToSelector:selector]) {
        ((void (*)(id, SEL))[self methodForSelector:selector])(self, selector);
    }
}


#pragma mark -
#pragma mark - Photo Editor
#pragma mark -

#pragma mark - Cropping
- (void)croppingAction
{
    NSLog(@"crop");
    NSLog(@"contentSize: %@", NSStringFromCGSize(self.imageScrollView.contentSize));
//    self.imageScrollView.z, oomScale = self.imageScrollView.minimumZoomScale;
    self.allowZooming = NO;
    
    [self.imageView beginCroppingWithCroppingRect:CGRectZero];
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
