// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class JoinTeamViewModel;

@interface NEBaseJoinTeamViewController : NETeamBaseViewController <UITextFieldDelegate>

@property (nonatomic, strong, readonly) JoinTeamViewModel *viewModel;
@property (nonatomic, strong, readonly) UITextField *searchInput;
@property (nonatomic, assign) BOOL isRequesting;
@property (nonatomic, strong, nullable) NSLayoutConstraint *searchBackViewTopAnchor;
@property (nonatomic, strong, readonly) UIView *searchBackView;
@property (nonatomic, strong, readonly) UIImageView *searchImageView;

- (void)setupUI;
- (void)textFieldChange;
- (void)startSearch:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
