// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEContactBaseViewController.h"
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class AIRobotBindViewModel;

@interface NEBaseAIRobotBindController : NEContactBaseViewController <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) AIRobotBindViewModel *viewModel;
@property(nonatomic, copy) NSString *qrCode;
@property(nonatomic, assign) NSInteger selectedIndex;

@property(nonatomic, strong) UIView *createBotView;
@property(nonatomic, strong) UIView *createBotIconView;
@property(nonatomic, strong) UIView *createBotPlusH;
@property(nonatomic, strong) UIView *createBotPlusV;
@property(nonatomic, strong) UILabel *createBotLabel;
@property(nonatomic, strong) UIView *createBotSeparator;
@property(nonatomic, strong) UIImageView *createBotArrowView;
@property(nonatomic, strong) UILabel *sectionLabel;
@property(nonatomic, strong) UITableView *tableView;

+ (NSDictionary<NSString *, id> *)parseQrCodeJSON:(NSString *)jsonString;

- (void)loadData;
- (void)setupBindUI;

- (UIColor *)pageBackgroundColor;
- (CGFloat)createBotHorizontalMargin;
- (CGFloat)createBotRowHeight;
- (CGFloat)bindRowHeight;
- (UIColor *)confirmButtonColor;
- (CGFloat)dividerBlockHeight;
- (UIFont *)sectionLabelFont;
- (UIColor *)sectionLabelColor;
- (CGFloat)sectionHeaderHeight;

- (void)setupCreateBotViewStyle;
- (void)setupCreateBotIconStyle;

- (void)didTapCreateBot;
- (void)showBindConfirmAlertWithBot:(V2NIMUserAIBot *)bot isRebind:(BOOL)isRebind;
- (void)dismissBindAlert;
- (void)confirmBind;
- (void)performBindWithBot:(V2NIMUserAIBot *)bot;

@end

NS_ASSUME_NONNULL_END
