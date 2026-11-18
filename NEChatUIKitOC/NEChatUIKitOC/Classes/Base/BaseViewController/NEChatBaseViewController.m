// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatBaseViewController.h"
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import "ChatNavigationView.h"
#import "ChatUIConfig.h"
#import "NEChatUIConstant.h"
#import "UIImage+Chat.h"

@interface NEChatBaseViewController () <NENavigationBarHeightProviding>

@property (nonatomic, strong, readwrite) NEEmptyDataView *emptyView;

@end

@implementation NEChatBaseViewController

- (UIViewController *)documentPreviewPresenter {
  if ([NEAdaptiveDeviceGate adaptiveHostActive] && self.view.window.rootViewController) {
    return self.view.window.rootViewController;
  }
  return self;
}

- (void)presentAdaptivePreview:(UIViewController *)controller
                      animated:(BOOL)animated
                    completion:(void (^)(void))completion {
  if (!controller) {
    return;
  }
  UIViewController *presenter = self;
  if ([NEAdaptiveDeviceGate adaptiveHostActive] && self.view.window.rootViewController) {
    presenter = self.view.window.rootViewController;
    while (presenter.presentedViewController) {
      presenter = presenter.presentedViewController;
    }
  }
  if (presenter.presentedViewController == controller) {
    return;
  }
  [presenter presentViewController:controller animated:animated completion:completion];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  return self;
}

#pragma mark - Properties

/// Custom setter for topConstant — updates constraint (Swift didSet)
- (void)setTopConstant:(CGFloat)topConstant {
  _topConstant = topConstant;
  self.navigationViewHeightAnchor.constant = topConstant;
}

/// Override title setter to also update the navigation view title label
- (void)setTitle:(NSString *)title {
  [super setTitle:title];
  self.navigationView.navTitle.text = title;
}

/// Lazy getter for emptyView
- (NEEmptyDataView *)emptyView {
  if (!_emptyView) {
    _emptyView = [[NEEmptyDataView alloc] initWithImageName:@"emptyView"
                                                    content:@""
                                                      frame:CGRectZero];
    _emptyView.translatesAutoresizingMaskIntoConstraints = NO;
    _emptyView.userInteractionEnabled = NO;
    _emptyView.hidden = YES;
  }
  return _emptyView;
}

/// Lazy getter for navigationView
- (ChatNavigationView *)navigationView {
  if (!_navigationView) {
    _navigationView = [[ChatNavigationView alloc] init];
  }
  return _navigationView;
}

#pragma mark - Lifecycle

- (void)viewSafeAreaInsetsDidChange {
  [super viewSafeAreaInsetsDidChange];
  [self ne_refreshNavigationBarHeightIfNeeded];
}

- (CGFloat)ne_navigationBarHeight {
  CGFloat extra = NEAdaptiveDeviceGate.adaptiveHostActive ? 2.0 : 0.0;
  return NEUIKitNavigationAndStatusHeightForView(self.view) + extra;
}

- (void)ne_applyNavigationBarHeight:(CGFloat)height {
  if (!self.navigationViewHeightAnchor || !self.navigationView.superview ||
      self.navigationView.isHidden) {
    return;
  }
  if (fabs(self.navigationViewHeightAnchor.constant - height) < 0.5 &&
      fabs(self.topConstant - height) < 0.5) {
    return;
  }
  self.topConstant = height;
  [self.view setNeedsLayout];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self ne_refreshNavigationBarHeightIfNeeded];

  // 配置项：会话界面是否展示标题栏
  if (!ChatUIConfig.shared.messageProperties.showTitleBar) {
    self.navigationController.navigationBarHidden = YES;
    [self.navigationView removeFromSuperview];
    return;
  }

  NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
  if (useSystemNavValue && [useSystemNavValue boolValue]) {
    self.navigationController.navigationBarHidden = NO;
    [self.navigationView removeFromSuperview];
    [self setupBackUI];
  } else {
    self.navigationController.navigationBarHidden = YES;
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor clearColor];

  NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
  if (useSystemNavValue && [useSystemNavValue boolValue]) {
    self.topConstant = NEUIKitNavigationAndStatusHeightForView(self.view);
  } else {
    self.topConstant = NEUIKitNavigationAndStatusHeightForView(self.view);
    self.navigationView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.navigationView addBackButtonTarget:self selector:@selector(backEvent)];
    [self.navigationView addMoreButtonTarget:self selector:@selector(toSetting)];

    [self.view addSubview:self.navigationView];
    self.navigationViewHeightAnchor = [self.navigationView.heightAnchor constraintEqualToConstant:self.topConstant];
    self.navigationViewHeightAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
      [self.navigationView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
      [self.navigationView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
      [self.navigationView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    ]];
  }
}

#pragma mark - Actions

- (void)setupBackUI {
  UIImage *image = [CommonUIConfig.shared.backArrowImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:image
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(backEvent)];
  backItem.accessibilityIdentifier = @"id.backArrow";
  self.navigationItem.leftBarButtonItem = backItem;
  self.navigationController.navigationBar.topItem.backBarButtonItem = [[UIBarButtonItem alloc] init];
  self.navigationController.navigationBar.topItem.backBarButtonItem.tintColor = [UIColor ne_darkText];
}

- (void)backEvent {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)toSetting {
  // Subclass override point
}

- (void)addLeftSwipeDismissGesture {
  // 侧滑返回（根视图）
  UIScreenEdgePanGestureRecognizer *gestureRecognizer =
      [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDismiss:)];
  gestureRecognizer.edges = UIRectEdgeLeft;
  [self.view addGestureRecognizer:gestureRecognizer];
}

- (void)swipeDismiss:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
  }
}

#pragma mark - Bottom Actions

- (void)showBottomTelAction:(NSURL *)url {
  [self ne_showBottomTelAction:url];
}

- (void)showCustomBottomTelAction:(NSURL *)url {
  [self ne_showCustomBottomTelAction:url];
}

- (void)showBottomMailAction:(NSURL *)url {
  [self ne_showBottomMailAction:url];
}

- (void)showCustomBottomMailAction:(NSURL *)url {
  [self ne_showCustomBottomMailAction:url];
}

- (void)showBottomVideoAction:(UIViewController *)target cameraOnly:(BOOL)cameraOnly {
  (void)cameraOnly;
  [self ne_showBottomVideoAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)target
                         editing:YES];
}

- (void)showCustomBottomVideoAction:(UIViewController *)target isVideo:(BOOL)isVideo {
  (void)isVideo;
  [self ne_showCustomBottomVideoAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)target
                               editing:YES];
}

- (void)showBottomFileAction:(UIViewController *)target {
  [self ne_showBottomFileAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate>)target];
}

- (void)showCustomBottomFileAction:(UIViewController *)target {
  [self ne_showCustomBottomFileAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate>)target];
}

- (void)showActionSheet:(NSArray<UIAlertAction *> *)actions {
  [self ne_showActionSheet:actions];
}

- (void)showCustomActionSheet:(NSArray<NECustomAlertAction *> *)actions {
  [self ne_showCustomActionSheet:actions];
}

- (void)showAlert:(nullable NSString *)title message:(nullable NSString *)message sure:(void(^)(UIAlertAction *action))sureBlock {
  [self ne_showAlert:title message:message sure:sureBlock];
}

- (void)showSingleAlert:(nullable NSString *)title message:(nullable NSString *)message handler:(nullable void(^)(void))handler {
  [self ne_showSingleAlert:title message:message handler:handler];
}

- (void)showSingleAlert:(NSString *)message completion:(void(^)(void))completion {
  [self ne_showSingleAlert:nil message:message handler:completion];
}

- (void)addRightAction:(UIImage *)image action:(SEL)action target:(id)target {
  UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:target action:action];
  self.navigationItem.rightBarButtonItem = item;
}

@end
