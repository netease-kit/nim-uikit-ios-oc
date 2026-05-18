// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import "AIChatCellModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AIChatTableViewCellDelegate <NSObject>
- (void)didClickEditButton:(nullable NSString *)text;
@end

/// AI助聊 Cell
@interface AIChatTableViewCell : UITableViewCell

@property (nonatomic, weak, nullable) id<AIChatTableViewCellDelegate> delegate;

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UILabel *tagLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) ExpandButton *editButton;

- (void)commonUI;
- (void)editButtonAction;
- (void)setModel:(AIChatCellModel *)model;

@end

NS_ASSUME_NONNULL_END
