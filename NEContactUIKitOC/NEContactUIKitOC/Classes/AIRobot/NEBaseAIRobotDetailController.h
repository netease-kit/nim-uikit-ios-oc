// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEContactBaseViewController.h"
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class AIRobotDetailViewModel;
@class NEUserHeaderView;

@interface NEBaseAIRobotDetailController : NEContactBaseViewController <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) AIRobotDetailViewModel *viewModel;

@property(nonatomic, strong) UIView *headerView;
@property(nonatomic, strong) NEUserHeaderView *avatarView;
@property(nonatomic, strong) UILabel *nameLabel;
@property(nonatomic, strong) UIImageView *headerArrow;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UIView *chatSeparatorBlock;
@property(nonatomic, strong) UIView *chatRowView;
@property(nonatomic, strong) UILabel *chatLabel;
@property(nonatomic, strong) UIView *chatDeleteSeparator;
@property(nonatomic, strong) UIButton *deleteButton;
@property(nonatomic, copy) NSArray<NSString *> *operationTitles;

- (instancetype)initWithBot:(V2NIMUserAIBot *)bot;

- (void)setupDetailUI;
- (void)configHeader;

- (UIColor *)pageBackgroundColor;
- (CGFloat)cardHorizontalMargin;
- (CGFloat)headerTopMargin;
- (CGFloat)headerHeight;
- (CGFloat)avatarRowHeight;
- (CGFloat)nicknameRowHeight;
- (CGFloat)avatarSize;
- (CGFloat)avatarCornerRadius;
- (CGFloat)sectionSpacing;
- (CGFloat)rowHeight;

/// 操作行右侧箭头的统一实现：贴在 cell 内容区右边缘，不跟随 readable-content guide。
- (void)configureOperationArrowInCell:(UITableViewCell *)cell;
- (CGFloat)chatSeparatorHeight;
- (CGFloat)chatRowHeight;
- (CGFloat)deleteSeparatorHeight;
- (CGFloat)deleteRowHeight;
- (UIColor *)chatTextColor;
- (UIFont *)chatLabelFont;
- (UIFont *)deleteLabelFont;
- (UIColor *)confirmButtonColor;

- (void)setupHeaderStyle;
- (void)setupTableStyle;
- (void)setupChatRowStyle;

- (void)didTapHeader;
- (void)didTapEdit;
- (void)didTapViewConfig;
- (void)didTapRefreshToken;
- (void)showRefreshTokenConfirmAlert;
- (void)confirmRefreshToken;
- (void)performRefreshToken;
- (void)didTapChat;
- (void)didTapDelete;
- (void)showDeleteConfirmAlert;
- (void)performDelete;

- (void)showConfirmAlertWithTag:(NSInteger)tag
                          title:(NSString *)title
                           desc:(NSString *)desc
                   confirmTitle:(NSString *)confirmTitle
                   confirmColor:(UIColor *)confirmColor
                      onConfirm:(void (^)(void))onConfirm;

- (UIImageView *)makeArrowView;

@end

NS_ASSUME_NONNULL_END
