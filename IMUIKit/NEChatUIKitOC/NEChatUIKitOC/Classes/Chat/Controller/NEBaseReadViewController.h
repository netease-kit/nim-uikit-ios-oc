// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEChatBaseViewController.h"
#import "ReadViewModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 消息已读未读页面 - 基类
@interface NEBaseReadViewController : NEChatBaseViewController
    <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIButton *readButton;
@property (nonatomic, strong) UIButton *unreadButton;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bottonBottomLineLeftAnchor;
@property (nonatomic, strong) UIView *bottonBottomLine;
@property (nonatomic, strong, nullable) NSLayoutConstraint *tabViewTopAnchor;
@property (nonatomic, strong) UIView *tabView;
@property (nonatomic, strong) UITableView *readTableView;
@property (nonatomic, strong) UITableView *unreadTableView;

- (instancetype)initWithMessage:(V2NIMMessage *)message teamId:(NSString *)teamId;
- (void)commonUI;
- (void)loadData;
- (void)readButtonEvent:(UIButton *)button;
- (void)unreadButtonEvent:(UIButton *)button;

@end

NS_ASSUME_NONNULL_END
