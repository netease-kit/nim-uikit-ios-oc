// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import "NEPinMessageModel.h"
#import "ChatMessageHelper.h"
#import "ChatCellConstantValue.h"

NS_ASSUME_NONNULL_BEGIN

@class NEBasePinMessageCell;
@class NEPinMessageModel;

@protocol PinMessageCellDelegate <NSObject>
@required
- (void)didClickMore:(nullable NEPinMessageModel *)model;
- (void)didClickContent:(nullable NEPinMessageModel *)model cell:(NEBasePinMessageCell *)cell;

@optional
- (void)didTapDetectedLink:(nullable NEPinMessageModel *)model cell:(NEBasePinMessageCell *)cell url:(nullable NSURL *)url;
@end

@interface NEBasePinMessageCell : UITableViewCell

@property (nonatomic, strong, nullable) NSLayoutConstraint *contentWidth;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentHeight;
@property (nonatomic, strong, nullable) NEPinMessageModel *pinModel;
@property (nonatomic, weak, nullable) id<PinMessageCellDelegate> delegate;
@property (nonatomic, strong, nullable) UITapGestureRecognizer *contentGesture;

@property (nonatomic, strong) NEUserHeaderView *headerView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIView *line;
@property (nonatomic, strong, nullable) NSLayoutConstraint *backLeftConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *backRightConstraint;

- (void)setupUI;
- (void)configure:(NEPinMessageModel *)item;
- (void)moreClick;
- (void)contentClick;

@end

NS_ASSUME_NONNULL_END
