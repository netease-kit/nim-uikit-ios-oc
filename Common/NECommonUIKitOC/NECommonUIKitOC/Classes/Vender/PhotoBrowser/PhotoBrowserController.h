// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhotoBrowserController : UIViewController

@property (nonatomic, copy, nullable) dispatch_block_t onDismiss;

- (instancetype)initWithImgs:(NSArray<UIImage *> *)imgs img:(UIImage *)img;
- (instancetype)initWithUrls:(NSArray<NSString *> *)urls url:(NSString *)url;
- (instancetype)initWithUrls:(NSArray<NSString *> *)urls url:(NSString *)url currentIndex:(NSInteger)currentIndex;
- (instancetype)initWithUrls:(NSArray<NSString *> *)urls url:(NSString *)url currenIndex:(NSInteger)currenIndex;

@end

NS_ASSUME_NONNULL_END
