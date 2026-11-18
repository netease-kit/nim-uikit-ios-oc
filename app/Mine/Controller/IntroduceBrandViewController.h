// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/NEBaseViewController.h>

NS_ASSUME_NONNULL_BEGIN

@class SettingCellModel;

typedef NS_ENUM(NSInteger, IntroduceCellType) {
  IntroduceCellTypeVersion = 0,
  IntroduceCellTypeProductIntroduce,
};

@interface VersionCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, assign) IntroduceCellType cellType;
- (void)configData:(SettingCellModel *)model;
@end

@interface IntroduceBrandViewController : NEBaseViewController

@end

NS_ASSUME_NONNULL_END
