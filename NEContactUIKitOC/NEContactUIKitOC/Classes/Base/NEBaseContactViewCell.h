// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseContactViewCell : UITableViewCell

/// 头像
@property(nonatomic, strong) NEUserHeaderView *userHeaderView;
@property(nonatomic, strong) RedAngleLabel *redAngleView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *optionLabel;
@property(nonatomic, strong, nullable) NSLayoutConstraint *leftConstraint;

- (void)setupCommonCircleHeader;

@end

NS_ASSUME_NONNULL_END
