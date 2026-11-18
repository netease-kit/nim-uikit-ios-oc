// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhotoBrowserCell : UICollectionViewCell <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, copy, nullable) NSString *imgUrl;
@property (nonatomic, strong, nullable) UIImage *image;
@property (nonatomic, copy, nullable) dispatch_block_t backRemoveCallBack;
@property (nonatomic, copy, nullable) void (^tapMoveCallBack)(UIView *view);
@property (nonatomic, copy, nullable) void (^changeAlphaCallBack)(CGFloat value);
@property (nonatomic, strong, readonly) UIScrollView *backScroll;
@property (nonatomic, strong, readonly) UIImageView *imgView;

- (void)resizeImage;

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView
                       withView:(nullable UIView *)view
                        atScale:(CGFloat)scale;
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view;
- (void)scrollViewDidZoom:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;

@end

NS_ASSUME_NONNULL_END
