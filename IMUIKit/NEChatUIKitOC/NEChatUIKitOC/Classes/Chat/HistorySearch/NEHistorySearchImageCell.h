// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEHistorySearchImageCell : UICollectionViewCell

@property(nonatomic, strong) UIImageView *imageView;

- (void)setupUI;
- (void)configureWithModel:(id)model;

@end

NS_ASSUME_NONNULL_END
