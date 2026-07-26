// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseAIRobotBindController.h"
#import "AIRobotBindViewModel.h"
#import "AIRobotViewModel.h"
#import "ContactConst.h"
#import "FunContactUIColor.h"
#import "NEBaseAIRobotBindCell.h"
#import "NormalContactUIColor.h"
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

static NSInteger const kNEAIRobotBindAlertTag = 9921;
static NSString * const NEAIRobotBindCreateRouterCompat = @"imkit://contact/createAIRobot.page";
static NSString * const NEAIRobotBindDetailRouterCompat = @"imkit://contact/aiRobotDetail.page";

@interface NEBaseAIRobotBindController ()

@property(nonatomic, strong, nullable) V2NIMUserAIBot *pendingBot;

@end

@implementation NEBaseAIRobotBindController

- (instancetype)init {
  self = [super init];
  if (self) {
    _viewModel = [[AIRobotBindViewModel alloc] init];
    _qrCode = @"";
    _selectedIndex = -1;
  }
  return self;
}

+ (NSDictionary<NSString *,id> *)parseQrCodeJSON:(NSString *)jsonString {
  if (jsonString.length == 0) {
    return @{};
  }
  NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
  if (data == nil) {
    return @{};
  }
  NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
  if (![dict isKindOfClass:[NSDictionary class]]) {
    return @{};
  }

  NSString *code = dict[@"qrCode"];
  if (![code isKindOfClass:[NSString class]] || code.length == 0) {
    return @{};
  }

  id expireAtValue = dict[@"expireAt"];
  if ([expireAtValue respondsToSelector:@selector(doubleValue)]) {
    NSTimeInterval expireAt = [expireAtValue doubleValue];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970] * 1000.0;
    if (expireAt > 0 && expireAt < now) {
      return @{@"errorMessage": contactLocalizable(@"scan_qr_expired")};
    }
  }

  return @{@"qrCode": code};
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = contactLocalizable(@"ai_robot_bind_title");
  self.navigationView.moreButton.hidden = YES;
  self.view.backgroundColor = [self pageBackgroundColor];
  [self setupBindUI];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }
  [self loadData];
}

- (void)loadData {
  self.view.userInteractionEnabled = NO;
  __weak typeof(self) weakSelf = self;
  [self.viewModel loadBots:^(NSError * _Nullable error) {
    void (^updateBlock)(void) = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      strongSelf.view.userInteractionEnabled = YES;
      if (error != nil) {
        [strongSelf.view ne_makeToast:robotErrorMessage(error)];
        return;
      }
      NSString *prevAccid = strongSelf.viewModel.previousBoundAccid ?: @"";
      strongSelf.selectedIndex = -1;
      if (prevAccid.length > 0) {
        NSInteger index = [strongSelf.viewModel.bots indexOfObjectPassingTest:^BOOL(V2NIMUserAIBot * _Nonnull obj,
                                                                                     NSUInteger idx,
                                                                                     BOOL * _Nonnull stop) {
          return [obj.accid isEqualToString:prevAccid];
        }];
        strongSelf.selectedIndex = index == NSNotFound ? -1 : index;
      }
      [strongSelf.tableView reloadData];
    };

    if ([NSThread isMainThread]) {
      updateBlock();
    } else {
      dispatch_async(dispatch_get_main_queue(), updateBlock);
    }
  }];
}

- (void)setupBindUI {
  [self.view addSubview:self.createBotView];
  [NSLayoutConstraint activateConstraints:@[
    [self.createBotView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant],
    [self.createBotView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:[self createBotHorizontalMargin]],
    [self.createBotView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-[self createBotHorizontalMargin]],
    [self.createBotView.heightAnchor constraintEqualToConstant:[self createBotRowHeight]],
  ]];
  [self setupCreateBotViewStyle];

  [self.createBotView addSubview:self.createBotIconView];
  [NSLayoutConstraint activateConstraints:@[
    [self.createBotIconView.leftAnchor constraintEqualToAnchor:self.createBotView.leftAnchor constant:16.0],
    [self.createBotIconView.centerYAnchor constraintEqualToAnchor:self.createBotView.centerYAnchor],
    [self.createBotIconView.widthAnchor constraintEqualToConstant:36.0],
    [self.createBotIconView.heightAnchor constraintEqualToConstant:36.0],
  ]];
  [self setupCreateBotIconStyle];

  [self.createBotIconView addSubview:self.createBotPlusH];
  [NSLayoutConstraint activateConstraints:@[
    [self.createBotPlusH.centerXAnchor constraintEqualToAnchor:self.createBotIconView.centerXAnchor],
    [self.createBotPlusH.centerYAnchor constraintEqualToAnchor:self.createBotIconView.centerYAnchor],
    [self.createBotPlusH.widthAnchor constraintEqualToConstant:14.0],
    [self.createBotPlusH.heightAnchor constraintEqualToConstant:1.5],
  ]];

  [self.createBotIconView addSubview:self.createBotPlusV];
  [NSLayoutConstraint activateConstraints:@[
    [self.createBotPlusV.centerXAnchor constraintEqualToAnchor:self.createBotIconView.centerXAnchor],
    [self.createBotPlusV.centerYAnchor constraintEqualToAnchor:self.createBotIconView.centerYAnchor],
    [self.createBotPlusV.widthAnchor constraintEqualToConstant:1.5],
    [self.createBotPlusV.heightAnchor constraintEqualToConstant:14.0],
  ]];

  [self.createBotView addSubview:self.createBotArrowView];
  [NSLayoutConstraint activateConstraints:@[
    [self.createBotArrowView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-22.0],
    [self.createBotArrowView.centerYAnchor constraintEqualToAnchor:self.createBotView.centerYAnchor],
    [self.createBotArrowView.widthAnchor constraintEqualToConstant:14.0],
    [self.createBotArrowView.heightAnchor constraintEqualToConstant:14.0],
  ]];

  [self.createBotView addSubview:self.createBotLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.createBotLabel.leftAnchor constraintEqualToAnchor:self.createBotIconView.rightAnchor constant:12.0],
    [self.createBotLabel.centerYAnchor constraintEqualToAnchor:self.createBotView.centerYAnchor],
    [self.createBotLabel.rightAnchor constraintEqualToAnchor:self.createBotArrowView.leftAnchor constant:-8.0],
  ]];

  [self.createBotView addSubview:self.createBotSeparator];
  [NSLayoutConstraint activateConstraints:@[
    [self.createBotSeparator.leftAnchor constraintEqualToAnchor:self.createBotView.leftAnchor],
    [self.createBotSeparator.rightAnchor constraintEqualToAnchor:self.createBotView.rightAnchor],
    [self.createBotSeparator.bottomAnchor constraintEqualToAnchor:self.createBotView.bottomAnchor],
    [self.createBotSeparator.heightAnchor constraintEqualToConstant:0.5],
  ]];

  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapCreateBot)];
  [self.createBotView addGestureRecognizer:tap];

  UIView *dividerBlock = [[UIView alloc] init];
  dividerBlock.translatesAutoresizingMaskIntoConstraints = NO;
  dividerBlock.backgroundColor = [self pageBackgroundColor];
  [self.view addSubview:dividerBlock];
  [NSLayoutConstraint activateConstraints:@[
    [dividerBlock.topAnchor constraintEqualToAnchor:self.createBotView.bottomAnchor],
    [dividerBlock.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [dividerBlock.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [dividerBlock.heightAnchor constraintEqualToConstant:[self dividerBlockHeight]],
  ]];

  [self.view addSubview:self.tableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.topAnchor constraintEqualToAnchor:dividerBlock.bottomAnchor],
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
  [self.tableView registerClass:[NEBaseAIRobotBindCell class]
         forCellReuseIdentifier:NSStringFromClass([NEBaseAIRobotBindCell class])];
}

- (UIColor *)pageBackgroundColor {
  return [UIColor funContactNavigationBackgroundColor];
}

- (CGFloat)createBotHorizontalMargin {
  return 0.0;
}

- (CGFloat)createBotRowHeight {
  return 60.0;
}

- (CGFloat)bindRowHeight {
  return 60.0;
}

- (UIColor *)confirmButtonColor {
  return [UIColor normalContactThemeColor];
}

- (CGFloat)dividerBlockHeight {
  return 6.0;
}

- (UIFont *)sectionLabelFont {
  return [UIFont systemFontOfSize:14.0];
}

- (UIColor *)sectionLabelColor {
  return [UIColor ne_emptyTitleColor];
}

- (CGFloat)sectionHeaderHeight {
  return 44.0;
}

- (void)setupCreateBotViewStyle {
}

- (void)setupCreateBotIconStyle {
  self.createBotIconView.backgroundColor = [UIColor ne_normalTheme];
  self.createBotIconView.layer.cornerRadius = 18.0;
}

#pragma mark - UITableViewDataSource / UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.viewModel.bots.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NEBaseAIRobotBindCell *cell =
      [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NEBaseAIRobotBindCell class])
                                      forIndexPath:indexPath];
  if (indexPath.row >= 0 && indexPath.row < self.viewModel.bots.count) {
    [cell configureBot:self.viewModel.bots[indexPath.row] isSelected:indexPath.row == self.selectedIndex];
  }
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [self bindRowHeight];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UIView *header = [[UIView alloc] init];
  header.backgroundColor = [UIColor whiteColor];

  UILabel *label = [[UILabel alloc] init];
  label.translatesAutoresizingMaskIntoConstraints = NO;
  label.text = contactLocalizable(@"ai_robot_bind_select_hint");
  label.font = [self sectionLabelFont];
  label.textColor = [self sectionLabelColor];
  [header addSubview:label];
  [NSLayoutConstraint activateConstraints:@[
    [label.leftAnchor constraintEqualToAnchor:header.leftAnchor constant:16.0],
    [label.rightAnchor constraintEqualToAnchor:header.rightAnchor constant:-16.0],
    [label.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
  ]];
  return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return [self sectionHeaderHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  if (indexPath.row < 0 || indexPath.row >= self.viewModel.bots.count) {
    return;
  }

  V2NIMUserAIBot *bot = self.viewModel.bots[indexPath.row];
  NSString *prevAccid = self.viewModel.previousBoundAccid ?: @"";
  BOOL isSameAsPrev = prevAccid.length > 0 && [bot.accid isEqualToString:prevAccid];
  BOOL isRebind = prevAccid.length > 0 && !isSameAsPrev;
  [self showBindConfirmAlertWithBot:bot isRebind:isRebind];
}

- (void)didTapCreateBot {
  if (self.viewModel.bots.count >= [AIRobotViewModel maxRobotCount]) {
    [self.view ne_makeToast:contactLocalizable(@"ai_robot_exceed_limit")];
    return;
  }
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }
  NSString *defaultName = @"Bot_Claw";
  [[Router shared] use:NEAIRobotBindCreateRouterCompat
            parameters:@{
              @"nav": self.navigationController ?: [NSNull null],
              @"animated": @YES,
              @"defaultName": defaultName,
              @"autoBindQrCode": self.qrCode ?: @"",
              @"autoBindSourceVC": self,
            }
               closure:nil];
}

- (void)showBindConfirmAlertWithBot:(V2NIMUserAIBot *)bot isRebind:(BOOL)isRebind {
  UIView *overlay = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
  overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
  overlay.tag = kNEAIRobotBindAlertTag;

  UIView *alertView = [[UIView alloc] init];
  alertView.translatesAutoresizingMaskIntoConstraints = NO;
  alertView.backgroundColor = [UIColor whiteColor];
  alertView.layer.cornerRadius = 14.0;
  alertView.clipsToBounds = YES;
  [overlay addSubview:alertView];
  [NSLayoutConstraint activateConstraints:@[
    [alertView.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
    [alertView.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
    [alertView.widthAnchor constraintEqualToConstant:270.0],
    [alertView.heightAnchor constraintEqualToConstant:160.0],
  ]];

  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  titleLabel.text = contactLocalizable(@"ai_robot_bind_confirm_title");
  titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:17.0] ?: [UIFont systemFontOfSize:17.0];
  titleLabel.textColor = [UIColor blackColor];
  titleLabel.textAlignment = NSTextAlignmentCenter;
  [alertView addSubview:titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [titleLabel.topAnchor constraintEqualToAnchor:alertView.topAnchor constant:19.0],
    [titleLabel.leftAnchor constraintEqualToAnchor:alertView.leftAnchor constant:16.0],
    [titleLabel.rightAnchor constraintEqualToAnchor:alertView.rightAnchor constant:-16.0],
    [titleLabel.heightAnchor constraintEqualToConstant:22.0],
  ]];

  UILabel *descLabel = [[UILabel alloc] init];
  descLabel.translatesAutoresizingMaskIntoConstraints = NO;
  descLabel.text = contactLocalizable(@"ai_robot_bind_confirm_desc");
  descLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13.0] ?: [UIFont systemFontOfSize:13.0];
  descLabel.textColor = [UIColor ne_darkText];
  descLabel.textAlignment = NSTextAlignmentCenter;
  descLabel.numberOfLines = 0;
  [alertView addSubview:descLabel];
  [NSLayoutConstraint activateConstraints:@[
    [descLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:8.0],
    [descLabel.leftAnchor constraintEqualToAnchor:alertView.leftAnchor constant:16.0],
    [descLabel.rightAnchor constraintEqualToAnchor:alertView.rightAnchor constant:-16.0],
  ]];

  UIView *hLine = [[UIView alloc] init];
  hLine.translatesAutoresizingMaskIntoConstraints = NO;
  hLine.backgroundColor = [UIColor colorWithRed:0 green:0 blue:80.0 / 255.0 alpha:0.05];
  [alertView addSubview:hLine];
  [NSLayoutConstraint activateConstraints:@[
    [hLine.leftAnchor constraintEqualToAnchor:alertView.leftAnchor],
    [hLine.rightAnchor constraintEqualToAnchor:alertView.rightAnchor],
    [hLine.bottomAnchor constraintEqualToAnchor:alertView.bottomAnchor constant:-44.0],
    [hLine.heightAnchor constraintEqualToConstant:0.5],
  ]];

  UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
  cancelBtn.translatesAutoresizingMaskIntoConstraints = NO;
  [cancelBtn setTitle:commonLocalizable(@"cancel") forState:UIControlStateNormal];
  [cancelBtn setTitleColor:[UIColor ne_greyText] forState:UIControlStateNormal];
  cancelBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:17.0] ?: [UIFont systemFontOfSize:17.0];
  [alertView addSubview:cancelBtn];
  [NSLayoutConstraint activateConstraints:@[
    [cancelBtn.leftAnchor constraintEqualToAnchor:alertView.leftAnchor],
    [cancelBtn.bottomAnchor constraintEqualToAnchor:alertView.bottomAnchor],
    [cancelBtn.widthAnchor constraintEqualToAnchor:alertView.widthAnchor multiplier:0.5 constant:-0.25],
    [cancelBtn.heightAnchor constraintEqualToConstant:44.0],
  ]];

  UIView *vLine = [[UIView alloc] init];
  vLine.translatesAutoresizingMaskIntoConstraints = NO;
  vLine.backgroundColor = [UIColor colorWithRed:0 green:0 blue:80.0 / 255.0 alpha:0.05];
  [alertView addSubview:vLine];
  [NSLayoutConstraint activateConstraints:@[
    [vLine.leftAnchor constraintEqualToAnchor:cancelBtn.rightAnchor],
    [vLine.bottomAnchor constraintEqualToAnchor:alertView.bottomAnchor],
    [vLine.widthAnchor constraintEqualToConstant:0.5],
    [vLine.heightAnchor constraintEqualToConstant:44.0],
  ]];

  UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
  confirmBtn.translatesAutoresizingMaskIntoConstraints = NO;
  [confirmBtn setTitle:commonLocalizable(@"sure") forState:UIControlStateNormal];
  [confirmBtn setTitleColor:[self confirmButtonColor] forState:UIControlStateNormal];
  confirmBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:17.0] ?: [UIFont systemFontOfSize:17.0];
  [alertView addSubview:confirmBtn];
  [NSLayoutConstraint activateConstraints:@[
    [confirmBtn.rightAnchor constraintEqualToAnchor:alertView.rightAnchor],
    [confirmBtn.bottomAnchor constraintEqualToAnchor:alertView.bottomAnchor],
    [confirmBtn.widthAnchor constraintEqualToAnchor:alertView.widthAnchor multiplier:0.5 constant:-0.25],
    [confirmBtn.heightAnchor constraintEqualToConstant:44.0],
  ]];

  UIView *containerView = self.view.window ?: self.view;
  [containerView addSubview:overlay];
  overlay.frame = containerView.bounds;

  [cancelBtn addTarget:self action:@selector(dismissBindAlert) forControlEvents:UIControlEventTouchUpInside];
  self.pendingBot = bot;
  [confirmBtn addTarget:self action:@selector(confirmBind) forControlEvents:UIControlEventTouchUpInside];
  (void)isRebind;
}

- (void)dismissBindAlert {
  self.pendingBot = nil;
  [self removeBindAlert];
}

- (void)confirmBind {
  [self removeBindAlert];
  V2NIMUserAIBot *bot = self.pendingBot;
  self.pendingBot = nil;
  if (bot == nil) {
    return;
  }
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }
  [self performBindWithBot:bot];
}

- (void)removeBindAlert {
  UIView *containerView = self.view.window ?: self.view;
  for (UIView *subview in [containerView.subviews copy]) {
    if (subview.tag == kNEAIRobotBindAlertTag) {
      [subview removeFromSuperview];
      break;
    }
  }
}

- (void)performBindWithBot:(V2NIMUserAIBot *)bot {
  self.view.userInteractionEnabled = NO;
  __weak typeof(self) weakSelf = self;
  [self.viewModel bindBot:bot qrCode:self.qrCode completion:^(NSError * _Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      strongSelf.view.userInteractionEnabled = YES;
      if (error != nil) {
        [strongSelf.view ne_makeToast:robotErrorMessage(error)];
        return;
      }

      UINavigationController *nav = strongSelf.navigationController;
      if (nav) {
        NSMutableArray<UIViewController *> *controllers = [nav.viewControllers mutableCopy];
        NSIndexSet *indexes = [controllers indexesOfObjectsPassingTest:^BOOL(UIViewController * _Nonnull obj,
                                                                             NSUInteger idx,
                                                                             BOOL * _Nonnull stop) {
          return obj == strongSelf;
        }];
        if (indexes.count > 0) {
          [controllers removeObjectsAtIndexes:indexes];
          [nav setViewControllers:controllers animated:NO];
        }

        [[Router shared] use:NEAIRobotBindDetailRouterCompat
                  parameters:@{
                    @"nav": nav,
                    @"bot": bot,
                    @"animated": @YES,
                  }
                     closure:nil];
      }
    });
  }];
}

#pragma mark - Lazy Init

- (UIView *)createBotView {
  if (!_createBotView) {
    _createBotView = [[UIView alloc] init];
    _createBotView.translatesAutoresizingMaskIntoConstraints = NO;
    _createBotView.backgroundColor = [UIColor whiteColor];
  }
  return _createBotView;
}

- (UIView *)createBotIconView {
  if (!_createBotIconView) {
    _createBotIconView = [[UIView alloc] init];
    _createBotIconView.translatesAutoresizingMaskIntoConstraints = NO;
    _createBotIconView.backgroundColor = [UIColor ne_normalTheme];
    _createBotIconView.clipsToBounds = YES;
  }
  return _createBotIconView;
}

- (UIView *)createBotPlusH {
  if (!_createBotPlusH) {
    _createBotPlusH = [[UIView alloc] init];
    _createBotPlusH.translatesAutoresizingMaskIntoConstraints = NO;
    _createBotPlusH.backgroundColor = [UIColor whiteColor];
  }
  return _createBotPlusH;
}

- (UIView *)createBotPlusV {
  if (!_createBotPlusV) {
    _createBotPlusV = [[UIView alloc] init];
    _createBotPlusV.translatesAutoresizingMaskIntoConstraints = NO;
    _createBotPlusV.backgroundColor = [UIColor whiteColor];
  }
  return _createBotPlusV;
}

- (UILabel *)createBotLabel {
  if (!_createBotLabel) {
    _createBotLabel = [[UILabel alloc] init];
    _createBotLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _createBotLabel.text = contactLocalizable(@"create_ai_robot");
    _createBotLabel.font = [UIFont systemFontOfSize:14.0];
    _createBotLabel.textColor = [UIColor ne_darkText];
  }
  return _createBotLabel;
}

- (UIView *)createBotSeparator {
  if (!_createBotSeparator) {
    _createBotSeparator = [[UIView alloc] init];
    _createBotSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    _createBotSeparator.backgroundColor = [UIColor ne_greyLine];
  }
  return _createBotSeparator;
}

- (UIImageView *)createBotArrowView {
  if (!_createBotArrowView) {
    _createBotArrowView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
    _createBotArrowView.translatesAutoresizingMaskIntoConstraints = NO;
    _createBotArrowView.contentMode = UIViewContentModeScaleAspectFit;
    _createBotArrowView.hidden = YES;
  }
  return _createBotArrowView;
}

- (UILabel *)sectionLabel {
  if (!_sectionLabel) {
    _sectionLabel = [[UILabel alloc] init];
    _sectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _sectionLabel.text = contactLocalizable(@"ai_robot_bind_select_hint");
    _sectionLabel.font = [UIFont systemFontOfSize:14.0];
    _sectionLabel.textColor = [UIColor ne_emptyTitleColor];
  }
  return _sectionLabel;
}

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.estimatedRowHeight = 0.0;
    _tableView.estimatedSectionHeaderHeight = 0.0;
    _tableView.estimatedSectionFooterHeight = 0.0;
    if (@available(iOS 15.0, *)) {
      _tableView.sectionHeaderTopPadding = 0.0;
    }
  }
  return _tableView;
}

@end
