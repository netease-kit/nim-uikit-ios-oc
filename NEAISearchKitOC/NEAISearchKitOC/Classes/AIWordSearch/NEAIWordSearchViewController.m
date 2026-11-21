// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAIWordSearchViewController.h"
#import "NEAISearchConstant.h"
#import "NEAIWordSearchModel.h"
#import "NEAIWordSearchTextCell.h"
#import <NEChatKit/NEAppLanguageUtil.h>
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NELottieAnimationView.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEBaseUIKitOC/ViewControllerExtension.h>
#import <NEBaseUIKitOC/UIView+YXToast.h>
#import <NEBaseUIKitOC/UIWindow+NEActiveKeyWindow.h>
#import <NEChatKit/NECoreIM2Constant.h>

@interface NEAIWordSearchViewController ()

@property (nonatomic, strong, nullable) UITapGestureRecognizer *tap;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentTableViewTopAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *navTitleMaxWidthConstraint;
@property (nonatomic, assign) CGFloat viewHeight;
@property (nonatomic, strong) UIView *inputBackView;
@property (nonatomic, strong) UILabel *placeHolderLabel;
@property (nonatomic, strong) UITextView *inputTextView;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UIButton *sureButton;
@property (nonatomic, strong) UITableView *contentTableView;

@end

@implementation NEAIWordSearchViewController

- (instancetype)init:(NSString *)searchText {
  return [self initWithSearchText:searchText];
}

- (instancetype)initWithSearchText:(NSString *)searchText {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    [self setupDefaultValue];
    _searchText = [searchText copy];
    [self setupUI];
    self.viewModel.delegate = self;
    [self loadData:searchText];
  }
  return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [self setupDefaultValue];
    [self setupUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setupDefaultValue];
    [self setupUI];
  }
  return self;
}

- (void)dealloc {
  if (self.tap.view) {
    [self.tap.view removeGestureRecognizer:self.tap];
  }
}

- (void)setTitle:(NSString *)title {
  [super setTitle:title];
  self.navTitle.text = title ?: @"";
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  self.view.layer.cornerRadius = 8.0;
  self.view.layer.borderWidth = 0.5;
  self.view.layer.borderColor = UIColor.lightGrayColor.CGColor;

  [self updateNavTitleMaxWidth];
  if (self.isEmbeddedInColumn) {
    UIView *host = self.parentViewController.view;
    if (!host) {
      return;
    }
    if (self.viewHeight == 0) {
      self.viewHeight = 406.0;
    }
    CGFloat width = [self embeddedColumnWidthInHost:host];
    CGFloat height = MIN(self.viewHeight, CGRectGetHeight(host.bounds));
    self.view.frame = CGRectMake(0, CGRectGetHeight(host.bounds) - height, width, height);
    self.columnDimView.frame = CGRectMake(0, 0, width, CGRectGetHeight(host.bounds));
    return;
  }
  if (self.viewHeight == 0) {
    self.viewHeight = 406.0;
  }
  if (![self usesNativeSheetPresentation]) {
    CGRect bounds = [self sheetContainerBounds];
    CGFloat height = MIN(self.viewHeight, CGRectGetHeight(bounds));
    self.view.frame = CGRectMake(CGRectGetMinX(bounds),
                                 CGRectGetMaxY(bounds) - height,
                                 CGRectGetWidth(bounds),
                                 height);
  }
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  // 结果面板可能被嵌入右列（宽约 558），行高必须按当前列表宽度重测；
  // 首次布局时宽度从 0 变成列宽，也需要补一次重算。
  CGFloat width = CGRectGetWidth(self.contentTableView.bounds);
  if (width <= 0 || fabs(width - self.viewModel.itemMaxWidth) <= 0.5) {
    return;
  }
  [self.viewModel updateItemMaxWidth:width];
  if (self.viewModel.data.count > 0) {
    [self.contentTableView reloadData];
  }
}

/// 弹窗可用容器：优先 presentationController，其次窗口，最后父视图。
- (CGRect)sheetContainerBounds {
  CGRect bounds = self.presentationController.containerView.bounds;
  if (CGRectGetWidth(bounds) > 0 && CGRectGetHeight(bounds) > 0) {
    return bounds;
  }
  bounds = self.view.window.bounds;
  if (CGRectGetWidth(bounds) > 0 && CGRectGetHeight(bounds) > 0) {
    return bounds;
  }
  bounds = self.view.superview.bounds;
  if (CGRectGetWidth(bounds) > 0 && CGRectGetHeight(bounds) > 0) {
    return bounds;
  }
  return self.view.bounds;
}

- (CGFloat)embeddedColumnWidthInHost:(UIView *)host {
  CGFloat windowWidth = host.window ? CGRectGetWidth(host.window.bounds) : CGRectGetWidth(host.bounds);
  BOOL isFullWindow = CGRectGetWidth(host.bounds) >= windowWidth - 1;
  CGFloat railInset = isFullWindow ? MAX(0, host.window.safeAreaInsets.right) : 0;
  return MAX(0, CGRectGetWidth(host.bounds) - railInset);
}

- (void)updateNavTitleMaxWidth {
  if (!self.navTitleMaxWidthConstraint) return;
  CGFloat width = MAX(0, CGRectGetWidth([self sheetContainerBounds]) - self.margin * 4.0 - self.backButtonWidth -
                             self.moreButtonWidth - 16.0);
  if (fabs(self.navTitleMaxWidthConstraint.constant - width) > 0.5) {
    self.navTitleMaxWidthConstraint.constant = width;
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  UIView *containerView = self.presentationController.containerView;
  if (self.modalPresentationStyle == UIModalPresentationOverCurrentContext && !self.columnDimView && containerView) {
    UIView *dim = [[UIView alloc] initWithFrame:containerView.bounds];
    dim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    dim.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [containerView insertSubview:dim belowSubview:self.view];
    self.columnDimView = dim;
  }
  if (self.tap || !containerView) {
    return;
  }
  UITapGestureRecognizer *backgroundTap =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
  backgroundTap.cancelsTouchesInView = NO;
  [containerView addGestureRecognizer:backgroundTap];
  self.tap = backgroundTap;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.columnDimView removeFromSuperview];
  self.columnDimView = nil;
  if (self.isEmbeddedInColumn) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NEAdaptiveOverlayDidDismiss" object:nil];
  }
}

- (void)setupDefaultValue {
  _viewModel = [[NEAIWordSearchViewModel alloc] init];
  _margin = 16.0;
  _titleBarBottomLineHeight = 1.0;
  _backButtonWidth = ([NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish) ? 60.0 : 33.0;
  _moreButtonWidth = ([NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish) ? 100.0 : 85.0;
  _themeColor = UIColor.ne_normalTheme;
}

- (void)showToast:(NSString *)toast {
  [self ne_showToast:toast ?: @""];
}

- (void)showErrorToast:(NSError *)error {
  if (!error) {
    return;
  }

  NSInteger code = error.code;
  if (code == failedOperation) {
    [self showToast:commonLocalizable(@"parameter_setting_error")];
  } else if (code == rateLimitExceeded) {
    [self showToast:commonLocalizable(@"rate_limit_exceeded")];
  } else if (code == userNotExistCode) {
    [self showToast:commonLocalizable(@"user_not_exist")];
  } else if (code == userBannedCode) {
    [self showToast:commonLocalizable(@"user_banned")];
  } else if (code == userChatBannedCode) {
    [self showToast:commonLocalizable(@"user_chat_banned")];
  } else if (code == noFriendCode) {
    [self showToast:commonLocalizable(@"friend_not_exist")];
  } else if (code == messageHitAntispam1 || code == messageHitAntispam2) {
    [self showToast:commonLocalizable(@"message_hit_antispam")];
  } else if (code == teamMemberNotExist) {
    [self showToast:commonLocalizable(@"team_member_not_exist")];
  } else if (code == teamNormalMemberChatBanned) {
    [self showToast:commonLocalizable(@"team_normal_member_chat_banned")];
  } else if (code == teamMemberChatBanned) {
    [self showToast:commonLocalizable(@"team_member_chat_banned")];
  } else if (code == notAIAccount) {
    [self showToast:commonLocalizable(@"not_ai_account")];
  } else if (code == cannotBlockAIAccount) {
    [self showToast:commonLocalizable(@"cannot_blocklist_ai_account")];
  } else if (code == aiMessagesDisabled) {
    [self showToast:commonLocalizable(@"ai_messages_function_disabled")];
  } else if (code == aiMessageRequestFailed) {
    [self showToast:commonLocalizable(@"failed_request_to_the_LLM")];
  } else {
    [self showToast:NEAISearchLocalizable(@"request_exception")];
  }
}

- (void)loadData:(NSString *)searchText {
  [self setTitleText:YES];
  __weak typeof(self) weakSelf = self;
  [self.viewModel loadData:searchText completion:^(NSError * _Nullable error) {
    [weakSelf showErrorToast:error];
    [weakSelf tableViewReload:NO];
  }];
}

- (void)loadMoreData:(NSString *)searchText {
  [self setTitleText:YES];
  [self.inputTextView resignFirstResponder];
  __weak typeof(self) weakSelf = self;
  [self.viewModel loadData:searchText completion:^(NSError * _Nullable error) {
    [weakSelf showErrorToast:error];
    [weakSelf tableViewReload:NO];
  }];
}

- (void)setupUI {
  [self configureSheetPresentation];
  self.title = NEAISearchLocalizable(@"ai_word_searching");
  self.view.backgroundColor = UIColor.whiteColor;

  [self.view addSubview:self.titleBarView];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleBarView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.titleBarView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.titleBarView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.titleBarView.heightAnchor constraintEqualToConstant:50.0],
  ]];

  [self.view addSubview:self.contentTableView];
  self.contentTableViewTopAnchor =
      [self.contentTableView.topAnchor constraintEqualToAnchor:self.titleBarBottomLine.bottomAnchor constant:0];
  self.contentTableViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.contentTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.contentTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.contentTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  [self.contentTableView registerClass:[NEAIWordSearchTextCell class]
                forCellReuseIdentifier:NSStringFromClass([NEAIWordSearchTextCell class])];
}

- (void)setTitleText:(BOOL)isLoading {
  if (isLoading) {
    self.title = NEAISearchLocalizable(@"ai_word_searching");
    self.loadingView.hidden = NO;
  } else {
    self.title = NEAISearchLocalizable(@"ai_word_search");
    self.loadingView.hidden = YES;
  }
}

- (void)cancelButtonAction {
  if (self.tap.view) {
    [self.tap.view removeGestureRecognizer:self.tap];
  }
  if (self.columnDismissHandler) {
    self.columnDismissHandler();
    return;
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tapAction:(UITapGestureRecognizer *)tap {
  CGPoint point = [tap locationInView:self.view];
  if (!CGRectContainsPoint(self.view.bounds, point)) {
    [self cancelButtonAction];
  }
}

- (void)moreButtonAction {
  self.viewHeight = 700.0;
  if (self.isEmbeddedInColumn && self.parentViewController.view) {
    UIView *host = self.parentViewController.view;
    [UIView animateWithDuration:0.25
                     animations:^{
                       CGFloat width = [self embeddedColumnWidthInHost:host];
                       CGFloat height = MIN(self.viewHeight, CGRectGetHeight(host.bounds));
                       self.view.frame = CGRectMake(0, CGRectGetHeight(host.bounds) - height, width, height);
                       self.columnDimView.frame = CGRectMake(0, 0, width, CGRectGetHeight(host.bounds));
                       [self.view layoutIfNeeded];
                     }];
  } else if (![self updateNativeSheetHeight:self.viewHeight identifier:@"com.netease.imuikit.aiSearch.expanded" animated:YES]) {
    [UIView animateWithDuration:0.25 animations:^{
      CGRect bounds = [self sheetContainerBounds];
      CGFloat height = MIN(self.viewHeight, CGRectGetHeight(bounds));
      self.view.frame = CGRectMake(CGRectGetMinX(bounds),
                                   CGRectGetMaxY(bounds) - height,
                                   CGRectGetWidth(bounds),
                                   height);
      [self.view layoutIfNeeded];
    }];
  }

  [self.moreButton removeFromSuperview];
  [self.view addSubview:self.inputBackView];
  [NSLayoutConstraint activateConstraints:@[
    [self.inputBackView.topAnchor constraintEqualToAnchor:self.titleBarBottomLine.bottomAnchor constant:16.0],
    [self.inputBackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20.0],
    [self.inputBackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20.0],
    [self.inputBackView.heightAnchor constraintEqualToConstant:120.0],
  ]];

  self.contentTableViewTopAnchor.constant = 136.0;
}

- (BOOL)usesNativeSheetPresentation {
  if (@available(iOS 15.0, *)) {
    return UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone;
  }
  return NO;
}

- (void)configureSheetPresentation {
  if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) return;
  if (@available(iOS 15.0, *)) {
    self.modalPresentationStyle = UIModalPresentationPageSheet;
    [self updateNativeSheetHeight:406.0 identifier:@"com.netease.imuikit.aiSearch.compact" animated:NO];
  } else {
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
  }
}

- (BOOL)updateNativeSheetHeight:(CGFloat)height identifier:(NSString *)identifier animated:(BOOL)animated {
  if (!self.usesNativeSheetPresentation || !self.sheetPresentationController) return NO;
  if (@available(iOS 16.0, *)) {
    UISheetPresentationController *sheet = self.sheetPresentationController;
    UISheetPresentationControllerDetentIdentifier detentIdentifier = identifier;
    UISheetPresentationControllerDetent *detent = [UISheetPresentationControllerDetent customDetentWithIdentifier:detentIdentifier resolver:^CGFloat(id<UISheetPresentationControllerDetentResolutionContext> context) {
      return MIN(height, context.maximumDetentValue);
    }];
    void (^update)(void) = ^{
      sheet.detents = @[detent];
      sheet.selectedDetentIdentifier = detentIdentifier;
      sheet.prefersGrabberVisible = NO;
      sheet.prefersScrollingExpandsWhenScrolledToEdge = NO;
      sheet.preferredCornerRadius = 8.0;
    };
    if (animated) [sheet animateChanges:update]; else update();
    return YES;
  }
  if (@available(iOS 15.0, *)) {
    UISheetPresentationController *sheet = self.sheetPresentationController;
    BOOL expanded = height > 500.0;
    void (^update)(void) = ^{
      sheet.detents = @[expanded ? [UISheetPresentationControllerDetent largeDetent] : [UISheetPresentationControllerDetent mediumDetent]];
      sheet.selectedDetentIdentifier = expanded ? UISheetPresentationControllerDetentIdentifierLarge : UISheetPresentationControllerDetentIdentifierMedium;
      sheet.prefersGrabberVisible = NO;
      sheet.prefersScrollingExpandsWhenScrolledToEdge = NO;
      sheet.preferredCornerRadius = 8.0;
    };
    if (animated) [sheet animateChanges:update]; else update();
    return YES;
  }
  return NO;
}

- (void)sureButtonAction {
  if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
    [self showToast:commonLocalizable(@"network_error")];
    return;
  }

  if (self.inputTextView.text.length > 0) {
    [self loadMoreData:self.inputTextView.text];
    self.inputTextView.text = @"";
    self.placeHolderLabel.hidden = NO;
    self.sureButton.enabled = NO;
    self.clearButton.hidden = YES;
  }
}

- (void)doneButtonAction {
  [self.inputTextView resignFirstResponder];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  (void)tableView;
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  (void)tableView;
  (void)section;
  return self.viewModel.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NEAIWordSearchTextCell *cell =
      [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NEAIWordSearchTextCell class])
                                      forIndexPath:indexPath];
  NEAIWordSearchModel *model = self.viewModel.data[indexPath.row];
  [cell setModel:model];

  if (self.viewModel.data.count == 1 && !self.moreButton.hidden) {
    [cell showBottomLine:NO];
  } else {
    [cell showBottomLine:YES];
  }
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  NEAIWordSearchModel *model = self.viewModel.data[indexPath.row];
  return model.height + 16.0 + 20.0;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
  self.placeHolderLabel.hidden = YES;
  if (textView.text.length <= 0) {
    self.sureButton.enabled = NO;
  }
  return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
  if (textView.text.length > 0) {
    self.placeHolderLabel.hidden = YES;
    self.sureButton.enabled = YES;
  } else {
    self.placeHolderLabel.hidden = NO;
    self.sureButton.enabled = NO;
  }
  self.clearButton.hidden = textView.text.length == 0;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
  if (textView.text.length <= 0) {
    self.placeHolderLabel.hidden = NO;
    self.sureButton.enabled = NO;
  }
}

- (void)clearText {
  self.inputTextView.text = @"";
  [self textViewDidChange:self.inputTextView];
}

- (void)tableViewReload:(BOOL)isLoading {
  [self setTitleText:isLoading];
  [self.contentTableView reloadData];
}

- (UIButton *)cancelButton {
  if (!_cancelButton) {
    _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_cancelButton setTitle:NEAISearchLocalizable(@"cancel") forState:UIControlStateNormal];
    _cancelButton.titleLabel.font = [UIFont systemFontOfSize:16.0];
    [_cancelButton setTitleColor:UIColor.ne_darkText forState:UIControlStateNormal];
    _cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _cancelButton.accessibilityIdentifier = @"id.cancel";
  }
  return _cancelButton;
}

- (NELottieAnimationView *)loadingView {
  if (!_loadingView) {
    _loadingView = [[NELottieAnimationView alloc] initWithName:@"ne_loading_data" bundle:NEAISearchBundle()];
    _loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    _loadingView.loopMode = LottieLoopModeLoop;
    _loadingView.contentMode = UIViewContentModeScaleAspectFill;
    _loadingView.accessibilityIdentifier = @"id.loadingView";
  }
  return _loadingView;
}

- (UILabel *)navTitle {
  if (!_navTitle) {
    _navTitle = [[UILabel alloc] initWithFrame:CGRectZero];
    _navTitle.translatesAutoresizingMaskIntoConstraints = NO;
    _navTitle.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
    _navTitle.textAlignment = NSTextAlignmentCenter;
    _navTitle.text = @"";
    _navTitle.accessibilityIdentifier = @"id.title";
  }
  return _navTitle;
}

- (UIButton *)moreButton {
  if (!_moreButton) {
    _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_moreButton setImage:NEAISearchImageNamed(@"ai_expand") forState:UIControlStateNormal];
    [_moreButton setTitle:NEAISearchLocalizable(@"input_more_button") forState:UIControlStateNormal];
    _moreButton.titleLabel.font = [UIFont systemFontOfSize:16.0];
    [_moreButton setTitleColor:self.themeColor forState:UIControlStateNormal];
    [_moreButton addTarget:self action:@selector(moreButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _moreButton.accessibilityIdentifier = @"id.threePoint";
  }
  return _moreButton;
}

- (UIView *)titleBarBottomLine {
  if (!_titleBarBottomLine) {
    _titleBarBottomLine = [[UIView alloc] initWithFrame:CGRectZero];
    _titleBarBottomLine.translatesAutoresizingMaskIntoConstraints = NO;
    _titleBarBottomLine.backgroundColor = [UIColor ne_colorWithHexString:@"#E9EFF5"];
    _titleBarBottomLine.hidden = NO;
  }
  return _titleBarBottomLine;
}

- (UIView *)titleBarView {
  if (!_titleBarView) {
    _titleBarView = [[UIView alloc] initWithFrame:CGRectZero];
    _titleBarView.translatesAutoresizingMaskIntoConstraints = NO;
    _titleBarView.backgroundColor = UIColor.clearColor;
    [_titleBarView addSubview:self.cancelButton];
    [_titleBarView addSubview:self.moreButton];
    [_titleBarView addSubview:self.navTitle];
    [_titleBarView addSubview:self.loadingView];
    [_titleBarView addSubview:self.titleBarBottomLine];

    [NSLayoutConstraint activateConstraints:@[
      [self.cancelButton.leftAnchor constraintEqualToAnchor:_titleBarView.leftAnchor constant:self.margin],
      [self.cancelButton.centerYAnchor constraintEqualToAnchor:_titleBarView.centerYAnchor],
      [self.cancelButton.widthAnchor constraintEqualToConstant:self.backButtonWidth],
      [self.cancelButton.heightAnchor constraintEqualToConstant:18.0],
    ]];

    [NSLayoutConstraint activateConstraints:@[
      [self.moreButton.rightAnchor constraintEqualToAnchor:_titleBarView.rightAnchor constant:-self.margin],
      [self.moreButton.centerYAnchor constraintEqualToAnchor:_titleBarView.centerYAnchor],
      [self.moreButton.widthAnchor constraintEqualToConstant:self.moreButtonWidth],
      [self.moreButton.heightAnchor constraintEqualToConstant:18.0],
    ]];

    self.navTitleMaxWidthConstraint =
        [self.navTitle.widthAnchor constraintLessThanOrEqualToConstant:[self sheetContainerBounds].size.width];
    [NSLayoutConstraint activateConstraints:@[
      [self.navTitle.centerXAnchor constraintEqualToAnchor:_titleBarView.centerXAnchor],
      [self.navTitle.centerYAnchor constraintEqualToAnchor:_titleBarView.centerYAnchor],
      self.navTitleMaxWidthConstraint,
    ]];
    [self updateNavTitleMaxWidth];

    [self.loadingView play];
    [NSLayoutConstraint activateConstraints:@[
      [self.loadingView.centerYAnchor constraintEqualToAnchor:_titleBarView.centerYAnchor],
      [self.loadingView.widthAnchor constraintEqualToConstant:16.0],
      [self.loadingView.heightAnchor constraintEqualToConstant:16.0],
      [self.loadingView.rightAnchor constraintEqualToAnchor:self.navTitle.leftAnchor constant:-2.0],
    ]];

    [NSLayoutConstraint activateConstraints:@[
      [self.titleBarBottomLine.leftAnchor constraintEqualToAnchor:_titleBarView.leftAnchor],
      [self.titleBarBottomLine.rightAnchor constraintEqualToAnchor:_titleBarView.rightAnchor],
      [self.titleBarBottomLine.bottomAnchor constraintEqualToAnchor:_titleBarView.bottomAnchor],
      [self.titleBarBottomLine.heightAnchor constraintEqualToConstant:self.titleBarBottomLineHeight],
    ]];
  }
  return _titleBarView;
}

- (UIView *)inputBackView {
  if (!_inputBackView) {
    _inputBackView = [[UIView alloc] initWithFrame:CGRectZero];
    _inputBackView.translatesAutoresizingMaskIntoConstraints = NO;
    _inputBackView.backgroundColor = [UIColor ne_colorWithHexString:@"#F5F5F5"];
    _inputBackView.layer.cornerRadius = 4.0;
    [_inputBackView addSubview:self.inputTextView];
    [_inputBackView addSubview:self.clearButton];
    [_inputBackView addSubview:self.sureButton];

    [NSLayoutConstraint activateConstraints:@[
      [self.inputTextView.leftAnchor constraintEqualToAnchor:_inputBackView.leftAnchor constant:12.0],
      [self.inputTextView.rightAnchor constraintEqualToAnchor:_inputBackView.rightAnchor constant:-44.0],
      [self.inputTextView.topAnchor constraintEqualToAnchor:_inputBackView.topAnchor constant:12.0],
      [self.inputTextView.bottomAnchor constraintEqualToAnchor:_inputBackView.bottomAnchor constant:-30.0],
      [self.clearButton.rightAnchor constraintEqualToAnchor:_inputBackView.rightAnchor constant:-12.0],
      [self.clearButton.topAnchor constraintEqualToAnchor:self.inputTextView.topAnchor constant:4.0],
      [self.clearButton.widthAnchor constraintEqualToConstant:24.0],
      [self.clearButton.heightAnchor constraintEqualToConstant:24.0],
    ]];

    [NSLayoutConstraint activateConstraints:@[
      [self.sureButton.rightAnchor constraintEqualToAnchor:_inputBackView.rightAnchor constant:-12.0],
      [self.sureButton.bottomAnchor constraintEqualToAnchor:_inputBackView.bottomAnchor constant:-12.0],
      [self.sureButton.widthAnchor constraintEqualToConstant:40.0],
      [self.sureButton.heightAnchor constraintEqualToConstant:18.0],
    ]];
  }
  return _inputBackView;
}

- (UILabel *)placeHolderLabel {
  if (!_placeHolderLabel) {
    _placeHolderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _placeHolderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _placeHolderLabel.text = NEAISearchLocalizable(@"input_more_placeholder");
    _placeHolderLabel.font = [UIFont systemFontOfSize:16.0];
    _placeHolderLabel.textColor = [UIColor ne_colorWithHexString:@"#AAAAAA"];
  }
  return _placeHolderLabel;
}

- (UITextView *)inputTextView {
  if (!_inputTextView) {
    _inputTextView = [[UITextView alloc] initWithFrame:CGRectZero];
    _inputTextView.translatesAutoresizingMaskIntoConstraints = NO;
    _inputTextView.backgroundColor = UIColor.clearColor;
    _inputTextView.font = [UIFont systemFontOfSize:16.0];
    _inputTextView.textColor = UIColor.ne_darkText;
    _inputTextView.delegate = self;

    [_inputTextView addSubview:self.placeHolderLabel];
    [NSLayoutConstraint activateConstraints:@[
      [self.placeHolderLabel.leftAnchor constraintEqualToAnchor:_inputTextView.leftAnchor constant:6.0],
      [self.placeHolderLabel.topAnchor constraintEqualToAnchor:_inputTextView.topAnchor constant:8.0],
      [self.placeHolderLabel.rightAnchor constraintEqualToAnchor:_inputTextView.rightAnchor constant:-6.0],
      [self.placeHolderLabel.heightAnchor constraintEqualToConstant:18.0],
    ]];

    UIToolbar *accessoryView = [[UIToolbar alloc] initWithFrame:CGRectMake(
        0, 0, CGRectGetWidth([UIWindow ne_activeKeyWindow].bounds), 40.0)];
    accessoryView.barStyle = UIBarStyleDefault;

    UIButton *accessoryDoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    accessoryDoneButton.frame = CGRectMake(0, 0, 60.0, 20.0);
    accessoryDoneButton.translatesAutoresizingMaskIntoConstraints = NO;
    [accessoryDoneButton setTitle:NEAISearchLocalizable(@"complete") forState:UIControlStateNormal];
    [accessoryDoneButton setTitleColor:UIColor.ne_normalTheme forState:UIControlStateNormal];
    [accessoryDoneButton addTarget:self action:@selector(doneButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [accessoryView addSubview:accessoryDoneButton];
    [NSLayoutConstraint activateConstraints:@[
      [accessoryDoneButton.rightAnchor constraintEqualToAnchor:accessoryView.rightAnchor constant:-12.0],
      [accessoryDoneButton.centerYAnchor constraintEqualToAnchor:accessoryView.centerYAnchor],
      [accessoryDoneButton.widthAnchor constraintEqualToConstant:44.0],
      [accessoryDoneButton.heightAnchor constraintEqualToConstant:20.0],
    ]];

    _inputTextView.inputAccessoryView = accessoryView;
  }
  return _inputTextView;
}

- (UIButton *)clearButton {
  if (!_clearButton) {
    _clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    _clearButton.backgroundColor = UIColor.clearColor;
    _clearButton.tintColor = UIColor.ne_emptyTitleColor;
    _clearButton.accessibilityIdentifier = @"id.clear";
    if (@available(iOS 13.0, *)) {
      UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightRegular];
      [_clearButton setImage:[UIImage systemImageNamed:@"xmark.circle.fill" withConfiguration:configuration] forState:UIControlStateNormal];
    } else {
      [_clearButton setTitle:@"×" forState:UIControlStateNormal];
      [_clearButton setTitleColor:UIColor.ne_emptyTitleColor forState:UIControlStateNormal];
      _clearButton.titleLabel.font = [UIFont systemFontOfSize:16];
    }
    [_clearButton addTarget:self action:@selector(clearText) forControlEvents:UIControlEventTouchUpInside];
    _clearButton.hidden = YES;
  }
  return _clearButton;
}

- (UIButton *)sureButton {
  if (!_sureButton) {
    _sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sureButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_sureButton setTitle:NEAISearchLocalizable(@"ok") forState:UIControlStateNormal];
    [_sureButton setTitleColor:[UIColor ne_colorWithHexString:@"#2155EE"] forState:UIControlStateNormal];
    [_sureButton setTitleColor:[UIColor ne_colorWithHexString:@"#2155EE" alpha:0.5]
                      forState:UIControlStateDisabled];
    _sureButton.titleLabel.font = [UIFont systemFontOfSize:16.0];
    [_sureButton addTarget:self action:@selector(sureButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _sureButton.accessibilityIdentifier = @"id.sureButton";
    _sureButton.enabled = NO;
  }
  return _sureButton;
}

- (UITableView *)contentTableView {
  if (!_contentTableView) {
    _contentTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _contentTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _contentTableView.backgroundColor = UIColor.clearColor;
    _contentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _contentTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _contentTableView.delegate = self;
    _contentTableView.dataSource = self;

    if (@available(iOS 11.0, *)) {
      _contentTableView.estimatedRowHeight = 0;
      _contentTableView.estimatedSectionHeaderHeight = 0;
      _contentTableView.estimatedSectionFooterHeight = 0;
    }
    if (@available(iOS 15.0, *)) {
      _contentTableView.sectionHeaderTopPadding = 0.0;
    }
  }
  return _contentTableView;
}

@end
