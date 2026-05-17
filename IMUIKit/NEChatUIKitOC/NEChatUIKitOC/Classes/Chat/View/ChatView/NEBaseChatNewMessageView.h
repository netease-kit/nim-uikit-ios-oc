// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseChatNewMessageView : UIView

@property (nonatomic, strong) UIImageView *jumpDownImageView;
@property (nonatomic, strong, nullable) NSLayoutConstraint *messageCountLabelRightAnchor;
@property (nonatomic, strong) UILabel *messageCountLabel;

- (void)setupUI;
- (void)updateMessageCount:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
