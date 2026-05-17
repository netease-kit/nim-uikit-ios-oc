// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "PhotoBrowserCell.h"
#import <NEChatKitOC/NEConstant.h>
#import <SDWebImage/SDWebImage.h>

@interface PhotoBrowserCell () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) UIScrollView *backScroll;
@property (nonatomic, strong, readwrite) UIImageView *imgView;
@property (nonatomic, strong) UIActivityIndicatorView *loading;
@property (nonatomic, assign) CGFloat imageWidth;
@property (nonatomic, assign) CGFloat imageHeight;

@end

@implementation PhotoBrowserCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = UIColor.clearColor;
    self.contentView.backgroundColor = UIColor.clearColor;
    [self.contentView addSubview:self.backScroll];
    [self.backScroll addSubview:self.imgView];
    [self addTapGestureWithImageView:self.imgView scroll:self.backScroll];
    [self addPanGesture:self.imgView];

    [self.contentView addSubview:self.loading];
    [NSLayoutConstraint activateConstraints:@[
      [self.loading.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
      [self.loading.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
      [self.loading.widthAnchor constraintEqualToConstant:30.0],
      [self.loading.heightAnchor constraintEqualToConstant:30.0],
    ]];
  }
  return self;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  self.backScroll.zoomScale = 1.0;
  self.backScroll.contentOffset = CGPointZero;
  self.image = nil;
  self.imgUrl = nil;
  self.imgView.image = nil;
}

- (void)setImgUrl:(NSString *)imgUrl {
  _imgUrl = [imgUrl copy];
  if (imgUrl.length == 0) {
    return;
  }

  [self.loading startAnimating];
  if ([imgUrl hasPrefix:@"http"]) {
    SDWebImageContext *context = @{
      SDWebImageContextImageThumbnailPixelSize : [NSValue valueWithCGSize:CGSizeMake(1000, 1000)]
    };
    __weak typeof(self) weakSelf = self;
    [self.imgView sd_setImageWithURL:[NSURL URLWithString:imgUrl]
                    placeholderImage:[UIImage imageWithContentsOfFile:imgUrl]
                             options:SDWebImageAllowInvalidSSLCertificates
                             context:context
                            progress:nil
                           completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf || !image) {
        return;
      }
      strongSelf.imageWidth = image.size.width;
      strongSelf.imageHeight = image.size.height;
      [strongSelf.loading stopAnimating];
      [strongSelf resizeImage];
    }];
  } else {
    UIImage *image = [UIImage imageWithContentsOfFile:imgUrl];
    self.imgView.image = image;
    self.imageWidth = image.size.width;
    self.imageHeight = image.size.height;
    [self.loading stopAnimating];
    [self resizeImage];
  }
}

- (void)setImage:(UIImage *)image {
  _image = image;
  if (!image) {
    return;
  }
  self.imgView.image = image;
  CGFloat imageWidth = image.size.width ?: 1.0;
  CGFloat imageHeight = image.size.height ?: 1.0;
  CGFloat width = NEConstant.screenWidth;
  CGFloat height = NEConstant.screenWidth / (imageWidth / imageHeight);

  if (height > NEConstant.screenHeight) {
    self.backScroll.contentSize = CGSizeMake(NEConstant.screenWidth, height);
    self.backScroll.contentOffset = CGPointZero;
    self.imgView.frame = CGRectMake(0, 0, width, height);
  } else {
    CGFloat originY = (NEConstant.screenHeight - height) / 2.0;
    self.backScroll.contentSize = CGSizeMake(NEConstant.screenWidth, NEConstant.screenHeight);
    self.backScroll.contentOffset = CGPointZero;
    self.imgView.frame = CGRectMake(0, originY, width, height);
  }
}

- (void)resizeImage {
  if (self.imageWidth <= 0 || self.imageHeight <= 0) {
    return;
  }
  CGFloat width = NEConstant.screenWidth;
  CGFloat height = NEConstant.screenWidth / (self.imageWidth / self.imageHeight);
  if (height > NEConstant.screenHeight) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.backScroll.contentSize = CGSizeMake(NEConstant.screenWidth, height);
      self.backScroll.contentOffset = CGPointZero;
      self.imgView.frame = CGRectMake(0, 0, width, height);
    });
  } else {
    CGFloat originY = (NEConstant.screenHeight - height) / 2.0;
    dispatch_async(dispatch_get_main_queue(), ^{
      self.backScroll.contentSize = CGSizeMake(NEConstant.screenWidth, NEConstant.screenHeight);
      self.backScroll.contentOffset = CGPointZero;
      self.imgView.frame = CGRectMake(0, originY, width, height);
    });
  }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
  return self.imgView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
  CGFloat centerX = self.backScroll.center.x;
  CGFloat centerY = self.backScroll.center.y;
  centerX = scrollView.contentSize.width > scrollView.frame.size.width ? scrollView.contentSize.width / 2.0 : centerX;
  centerY = scrollView.contentSize.height > scrollView.frame.size.height ? scrollView.contentSize.height / 2.0 : centerY;
  self.imgView.center = CGPointMake(centerX, centerY);
}

- (void)imageClick:(UITapGestureRecognizer *)tap {
  UIScrollView *scroll = (UIScrollView *)tap.view.superview;
  if (![scroll isKindOfClass:[UIScrollView class]]) {
    return;
  }
  CGFloat newScale = scroll.zoomScale == 1.0 ? 3.0 : 1.0;
  CGRect zoomRect = [self zoomRectForScale:scroll scale:newScale center:[tap locationInView:tap.view]];
  [scroll zoomToRect:zoomRect animated:YES];
}

- (void)viewClick:(UITapGestureRecognizer *)tap {
  if (self.backScroll.zoomScale != 1.0) {
    CGRect zoomRect = [self zoomRectForScale:self.backScroll scale:1.0 center:self.center];
    [self.backScroll zoomToRect:zoomRect animated:YES];
    return;
  }
  if (tap.state == UIGestureRecognizerStateRecognized) {
    !self.tapMoveCallBack ?: self.tapMoveCallBack(self.imgView);
  }
}

- (CGRect)zoomRectForScale:(UIScrollView *)scrollView scale:(CGFloat)scale center:(CGPoint)center {
  CGRect zoomRect = CGRectZero;
  zoomRect.size.height = scrollView.frame.size.height / scale;
  zoomRect.size.width = scrollView.frame.size.width / scale;
  zoomRect.origin.x = center.x - zoomRect.size.width / 2.0;
  zoomRect.origin.y = center.y - zoomRect.size.height / 2.0;
  return zoomRect;
}

- (void)addTapGestureWithImageView:(UIView *)imageView scroll:(UIScrollView *)scroll {
  imageView.userInteractionEnabled = YES;
  scroll.userInteractionEnabled = YES;

  UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageClick:)];
  doubleTap.numberOfTapsRequired = 2;
  [imageView addGestureRecognizer:doubleTap];

  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewClick:)];
  tap.numberOfTapsRequired = 1;
  tap.numberOfTouchesRequired = 1;
  [imageView addGestureRecognizer:tap];
  [scroll addGestureRecognizer:tap];
  [tap requireGestureRecognizerToFail:doubleTap];
}

- (void)addPanGesture:(UIView *)imgView {
  UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panRecognizerAction:)];
  pan.delegate = self;
  [imgView addGestureRecognizer:pan];
  imgView.userInteractionEnabled = YES;
}

- (void)panRecognizerAction:(UIPanGestureRecognizer *)pan {
  UIView *imageView = pan.view;
  UIView *superView = imageView.superview;
  if (!imageView || !superView) {
    return;
  }
  CGPoint translation = [pan translationInView:imageView];
  if (pan.state == UIGestureRecognizerStateChanged) {
    imageView.center = CGPointMake(imageView.center.x, imageView.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:superView];
    CGFloat alphaScale = fabs(imageView.center.y - NEConstant.screenHeight / 2.0);
    !self.changeAlphaCallBack ?: self.changeAlphaCallBack((NEConstant.screenHeight - alphaScale) / NEConstant.screenHeight);
  } else if (pan.state == UIGestureRecognizerStateEnded) {
    if (imageView.center.y > NEConstant.screenHeight / 2.0 + 60.0) {
      [self imagePanRemoveAnimation:NO imageView:imageView];
    } else if (imageView.center.y < NEConstant.screenHeight / 2.0 - 60.0) {
      [self imagePanRemoveAnimation:YES imageView:imageView];
    } else {
      CGFloat imageWidth = NEConstant.screenWidth;
      CGFloat imageHeight = NEConstant.screenWidth * imageView.frame.size.height / imageView.frame.size.width;
      CGFloat originY = (NEConstant.screenHeight - imageHeight) / 2.0;
      [UIView animateWithDuration:0.3 animations:^{
        !self.changeAlphaCallBack ?: self.changeAlphaCallBack(1.0);
        imageView.frame = CGRectMake(0, originY, imageWidth, imageHeight);
      }];
    }
  }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  UIView *panView = gestureRecognizer.view;
  if (!panView) {
    return NO;
  }
  if (panView.frame.size.width != NEConstant.screenWidth) {
    return NO;
  }
  if (panView.frame.size.height > NEConstant.screenHeight) {
    return NO;
  }
  if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
    UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *)gestureRecognizer;
    CGPoint offset = [panGesture translationInView:panView];
    if (offset.x == 0 && offset.y != 0) {
      return YES;
    }
  }
  return NO;
}

- (void)imagePanRemoveAnimation:(BOOL)isTop imageView:(UIView *)imageView {
  CGFloat duration = 0.4;
  CGFloat imageWidth = NEConstant.screenWidth;
  CGFloat imageHeight = NEConstant.screenWidth * imageView.frame.size.height / imageView.frame.size.width;
  if (isTop) {
    [UIView animateWithDuration:duration animations:^{
      imageView.frame = CGRectMake(0, -imageHeight, imageWidth, imageHeight);
    }];
  } else {
    [UIView animateWithDuration:duration animations:^{
      imageView.frame = CGRectMake(0, NEConstant.screenHeight, imageWidth, imageHeight);
    }];
  }
  !self.backRemoveCallBack ?: self.backRemoveCallBack();
}

- (UIScrollView *)backScroll {
  if (!_backScroll) {
    _backScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, NEConstant.screenWidth, NEConstant.screenHeight)];
    _backScroll.delegate = self;
    _backScroll.pagingEnabled = NO;
    _backScroll.minimumZoomScale = 1.0;
    _backScroll.maximumZoomScale = 4.0;
    _backScroll.showsHorizontalScrollIndicator = NO;
    _backScroll.showsVerticalScrollIndicator = NO;
  }
  return _backScroll;
}

- (UIImageView *)imgView {
  if (!_imgView) {
    _imgView = [[UIImageView alloc] init];
    _imgView.contentMode = UIViewContentModeScaleAspectFit;
  }
  return _imgView;
}

- (UIActivityIndicatorView *)loading {
  if (!_loading) {
    _loading = [[UIActivityIndicatorView alloc] init];
    _loading.translatesAutoresizingMaskIntoConstraints = NO;
    _loading.backgroundColor = UIColor.clearColor;
    _loading.color = UIColor.whiteColor;
    _loading.hidesWhenStopped = YES;
    [_loading stopAnimating];
  }
  return _loading;
}

@end
