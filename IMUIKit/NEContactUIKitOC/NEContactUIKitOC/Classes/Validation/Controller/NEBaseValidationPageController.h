// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEContactBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class NEPagingViewController;

@interface NEBaseValidationPageController : NEContactBaseViewController

/// 内容controller集合
@property (nonatomic, strong) NSMutableArray<NEContactBaseViewController *> *contentControllers;

/// 顶部内容区域约束，showSegment 时指向 segment top，否则指向 container top
@property (nonatomic, strong, nullable) NSLayoutConstraint *pagingViewControllerTopAnchor;

/// 内容分页控制器
@property (nonatomic, strong) NEPagingViewController *pagingViewController;

- (instancetype)init;
- (void)getContentControllers;
- (void)setupPageContent;
- (void)initNav;

@end

NS_ASSUME_NONNULL_END
