// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "PhotoBrowserCell.h"
#import <NEChatKit/NEConstant.h>
#import <SDWebImage/SDWebImage.h>
#import "NEAdaptiveDeviceGate.h"

@interface PhotoBrowserCell ()

@property (nonatomic, strong, readwrite) UIScrollView *backScroll;
@property (nonatomic, strong, readwrite) UIImageView *imgView;
@property (nonatomic, strong) UIActivityIndicatorView *loading;
@property (nonatomic, assign) BOOL didSetupUI;
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, copy) NSString *imageRequestIdentifier;
- (void)setupUI;
- (void)resizeImageWithSize:(CGSize)size;

@end

@implementation PhotoBrowserCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  if (self.didSetupUI) return;
  self.didSetupUI = YES;
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

- (void)setImgUrl:(NSString *)imgUrl {
  _imgUrl = [imgUrl copy];
  self.imageRequestIdentifier = [NSUUID UUID].UUIDString;
  NSString *requestIdentifier = self.imageRequestIdentifier;
  [self.imgView sd_cancelCurrentImageLoad];
  [self.backScroll setZoomScale:1.0 animated:NO];
  if (imgUrl.length == 0) {
    [self.loading stopAnimating];
    self.imgView.image = nil;
    self.imageSize = CGSizeZero;
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
      if (!strongSelf ||
          ![strongSelf.imageRequestIdentifier isEqualToString:requestIdentifier] ||
          ![strongSelf.imgUrl isEqualToString:imgUrl]) return;
      [strongSelf.loading stopAnimating];
      if (!image) return;
      strongSelf.imageSize = image.size;
      [strongSelf resizeImageWithSize:image.size];
    }];
  } else {
    NSURL *fileURL = [NSURL fileURLWithPath:imgUrl];
    if ([fileURL.pathExtension.lowercaseString isEqualToString:@"webp"]) {
      __weak typeof(self) weakSelf = self;
      [self.imgView sd_setImageWithURL:fileURL
                      placeholderImage:nil
                               options:SDWebImageAllowInvalidSSLCertificates
                             completed:^(UIImage * _Nullable image, NSError * _Nullable error,
                                         SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf ||
            ![strongSelf.imageRequestIdentifier isEqualToString:requestIdentifier] ||
            ![strongSelf.imgUrl isEqualToString:imgUrl]) return;
        [strongSelf.loading stopAnimating];
        if (image) {
          strongSelf.imageSize = image.size;
          [strongSelf resizeImageWithSize:image.size];
        }
      }];
    } else {
      UIImage *loadedImage = [UIImage imageWithContentsOfFile:imgUrl];
      self.imgView.image = loadedImage;
      [self.loading stopAnimating];
      if ([self.imageRequestIdentifier isEqualToString:requestIdentifier] &&
          [self.imgUrl isEqualToString:imgUrl] && loadedImage) {
        self.imageSize = loadedImage.size;
        [self resizeImageWithSize:loadedImage.size];
      }
    }
  }
}

- (void)setImage:(UIImage *)image {
  _image = image;
  self.imageRequestIdentifier = [NSUUID UUID].UUIDString;
  [self.imgView sd_cancelCurrentImageLoad];
  [self.loading stopAnimating];
  [self.backScroll setZoomScale:1.0 animated:NO];
  if (!image) {
    self.imgView.image = nil;
    self.imageSize = CGSizeZero;
    return;
  }
  self.imgView.image = image;
  self.imageSize = image.size;
  [self resizeImageWithSize:image.size];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.backScroll.frame = self.contentView.bounds;
  if (self.imageSize.width > 0 && self.imageSize.height > 0) {
    [self resizeImageWithSize:self.imageSize];
  }
}

- (void)prepareForReuse {
  [super prepareForReuse];
  self.imageRequestIdentifier = [NSUUID UUID].UUIDString;
  [self.imgView sd_cancelCurrentImageLoad];
  _imgUrl = nil;
  _image = nil;
  self.imageSize = CGSizeZero;
  self.imgView.image = nil;
  [self.loading stopAnimating];
  [self.backScroll setZoomScale:1.0 animated:NO];
  self.backScroll.contentOffset = CGPointZero;
  self.backScroll.contentSize = self.backScroll.bounds.size;
  self.imgView.frame = CGRectZero;
  self.backRemoveCallBack = nil;
  self.tapMoveCallBack = nil;
  self.changeAlphaCallBack = nil;
}

- (void)resizeImage {
  [self resizeImageWithSize:self.imageSize];
}

- (void)resizeImageWithSize:(CGSize)size {
  dispatch_block_t applyLayout = ^{
    if (size.width <= 0 || size.height <= 0) return;
    CGFloat viewportWidth = CGRectGetWidth(self.backScroll.bounds) > 0 ? CGRectGetWidth(self.backScroll.bounds) : NEConstant.screenWidth;
    CGFloat viewportHeight = CGRectGetHeight(self.backScroll.bounds) > 0 ? CGRectGetHeight(self.backScroll.bounds) : NEConstant.screenHeight;
    CGFloat imageHeight = viewportWidth * size.height / size.width;
    self.backScroll.contentOffset = CGPointZero;
    if (NEAdaptiveDeviceGate.adaptiveHostActive) {
      // DUO 上大图预览的 viewport 可能比来源聊天列更宽；按完整图片等比适配，
      CGFloat scale = MIN(viewportWidth / size.width, viewportHeight / size.height);
      CGFloat fitWidth = size.width * scale;
      CGFloat fitHeight = size.height * scale;
      self.backScroll.contentSize = CGSizeMake(viewportWidth, viewportHeight);
      self.imgView.frame = CGRectMake((viewportWidth - fitWidth) / 2.0,
                                      (viewportHeight - fitHeight) / 2.0,
                                      fitWidth, fitHeight);
    } else if (imageHeight > viewportHeight) {
      self.backScroll.contentSize = CGSizeMake(viewportWidth, imageHeight);
      self.imgView.frame = CGRectMake(0, 0, viewportWidth, imageHeight);
    } else {
      CGFloat originY = (viewportHeight - imageHeight) / 2.0;
      self.backScroll.contentSize = CGSizeMake(viewportWidth, viewportHeight);
      self.imgView.frame = CGRectMake(0, originY, viewportWidth, imageHeight);
    }
  };
  if (NSThread.isMainThread) applyLayout();
  else dispatch_async(dispatch_get_main_queue(), applyLayout);
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
  return self.imgView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView
                       withView:(UIView *)view
                        atScale:(CGFloat)scale {}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
  CGFloat centerX = self.backScroll.center.x;
  CGFloat centerY = self.backScroll.center.y;
  centerX = scrollView.contentSize.width > scrollView.frame.size.width ? scrollView.contentSize.width / 2.0 : centerX;
  centerY = scrollView.contentSize.height > scrollView.frame.size.height ? scrollView.contentSize.height / 2.0 : centerY;
  self.imgView.center = CGPointMake(centerX, centerY);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {}

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
