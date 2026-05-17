// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NECommonUIKitOC/NECommonUIKitOC.h>

@class NElanguageCellModel;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseLanguageCell : CornerCell

@property (nonatomic, strong) UILabel *languageLabel;
@property (nonatomic, strong) UIImageView *selectedImageView;

- (void)setupLanguageCellUI;
- (void)configureData:(NElanguageCellModel *)model;

@end

NS_ASSUME_NONNULL_END
