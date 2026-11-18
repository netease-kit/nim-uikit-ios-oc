// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

@class TeamDetailItem;

NS_ASSUME_NONNULL_BEGIN

@interface TeamBaseTextCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *line;

- (void)setModel:(TeamDetailItem *)model;

@end

NS_ASSUME_NONNULL_END
