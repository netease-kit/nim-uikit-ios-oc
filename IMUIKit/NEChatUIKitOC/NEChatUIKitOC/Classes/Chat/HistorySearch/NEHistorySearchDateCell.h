// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEHistorySearchDateCell : UICollectionViewCell

@property(nonatomic, strong) UIColor *selectButtonBackgroundColor;
@property(nonatomic, strong) UILabel *dayLabel;
@property(nonatomic, strong) UILabel *todayLabel;
@property(nonatomic, strong) UIView *selectionView;

- (void)setupUI;
- (void)configureWithDay:(nullable NSNumber *)day
                 isToday:(BOOL)isToday
              isSelected:(BOOL)isSelected
                isFuture:(BOOL)isFuture;

@end

NS_ASSUME_NONNULL_END
