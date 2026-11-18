// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEAIWordSearchViewModel.h"

@class NELottieAnimationView;

NS_ASSUME_NONNULL_BEGIN

@interface NEAIWordSearchViewController : UIViewController <NEAIWordSearchViewModelDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@property (nonatomic, strong) NEAIWordSearchViewModel *viewModel;
@property (nonatomic, copy, nullable) NSString *searchText;
@property (nonatomic, assign) CGFloat margin;
@property (nonatomic, assign) CGFloat titleBarBottomLineHeight;
@property (nonatomic, assign) CGFloat backButtonWidth;
@property (nonatomic, assign) CGFloat moreButtonWidth;
@property (nonatomic, strong) UIColor *themeColor;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) NELottieAnimationView *loadingView;
@property (nonatomic, strong) UILabel *navTitle;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIView *titleBarBottomLine;
@property (nonatomic, strong) UIView *titleBarView;

/// 列内嵌入（作为聊天页子控制器）时的遮罩；只在右列范围内覆盖。
@property (nonatomic, weak, nullable) UIView *columnDimView;
@property (nonatomic, assign) BOOL isEmbeddedInColumn;
/// 嵌入模式下由宿主移除子视图；为 nil 时走 modal dismiss。
@property (nonatomic, copy, nullable) void (^columnDismissHandler)(void);

- (instancetype)init:(nullable NSString *)searchText;
- (instancetype)initWithSearchText:(nullable NSString *)searchText;
- (void)setupUI;
- (void)tableViewReload:(BOOL)isLoading;

@end

NS_ASSUME_NONNULL_END
