// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BrowserToolsBar;
@class ToastImageView;

@interface PhotoBrowserController : UIViewController

@property (nonatomic, copy, nullable) dispatch_block_t onDismiss;
@property (nonatomic, strong) BrowserToolsBar *toolsBar;
@property (nonatomic, strong) ToastImageView *successView;

- (instancetype)initWithImgs:(NSArray<UIImage *> *)imgs img:(UIImage *)img;
- (instancetype)initWithUrls:(NSArray<NSString *> *)urls url:(NSString *)url;
- (instancetype)initWithUrls:(NSArray<NSString *> *)urls url:(NSString *)url currentIndex:(NSInteger)currentIndex;
- (instancetype)initWithUrls:(NSArray<NSString *> *)urls url:(NSString *)url currenIndex:(NSInteger)currenIndex;
- (void)didCloseClick;
- (void)didSaveClick;

@end

NS_ASSUME_NONNULL_END
