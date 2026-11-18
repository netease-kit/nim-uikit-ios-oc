// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEUserHeaderView;

@interface TextBaseCell : UITableViewCell

@property (nonatomic, strong, nullable) NSLayoutConstraint *titleLabelTopAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *titleLabelCenterYAnchor;
@property (nonatomic, strong, readonly) NEUserHeaderView *headImageView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subTitleLabel;

- (void)setupSubviews;

@end

NS_ASSUME_NONNULL_END
