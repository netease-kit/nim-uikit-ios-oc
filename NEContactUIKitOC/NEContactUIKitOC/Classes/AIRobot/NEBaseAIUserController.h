// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEContactBaseViewController.h"

@class AIUserViewModel;
@class NEAIUserModel;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseAIUserController : NEContactBaseViewController <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) AIUserViewModel *viewModel;
@property(nonatomic, strong) UITextField *searchAIUserTextField;
@property(nonatomic, strong) UITableView *aiUserTableView;
@property(nonatomic, strong) NEEmptyDataView *aiUserEmptyView;
@property(nonatomic, strong, nullable) NSLayoutConstraint *backViewTopAnchor;
@property(nonatomic, strong) UIView *backView;
@property(nonatomic, strong) UIImageView *searchIconImageView;

- (Class)aiUserCellClass;
- (CGFloat)aiUserCellHeight;
- (void)setupAIUserListUI;
- (BOOL)isLastAIUser:(NSInteger)index;
- (nullable NEAIUserModel *)getRealAIUserModel:(NSInteger)index;
- (void)addTextFiledObserver;
- (void)textChange;
- (void)refreshTableView;

@end

NS_ASSUME_NONNULL_END
