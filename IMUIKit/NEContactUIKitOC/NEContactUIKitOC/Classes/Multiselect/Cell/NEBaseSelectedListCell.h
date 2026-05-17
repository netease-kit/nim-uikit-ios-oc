// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEBaseSelectCell.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@class MultiSelectModel;

NS_ASSUME_NONNULL_BEGIN

@protocol NEBaseSelectedListCellDelegate <NSObject>
- (void)removeButtonAction:(nullable MultiSelectModel *)model;
@end

@interface NEBaseSelectedListCell : NEBaseSelectCell
@property (nonatomic, weak, nullable) id<NEBaseSelectedListCellDelegate> delegate;
@property (nonatomic, strong) ExpandButton *removeButton;
@property (nonatomic, strong) UIView *bottomLine;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bottomLineLeftConstraint;
- (void)removeButtonAction:(ExpandButton *)sender;
@end

NS_ASSUME_NONNULL_END
