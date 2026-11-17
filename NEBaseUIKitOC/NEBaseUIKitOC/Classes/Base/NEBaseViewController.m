// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseViewController.h"
#import "NENavigationView.h"
#import "NEAdaptiveDeviceGate.h"
#import "NEConfigManager.h"
#import "CommonUIConfig.h"
#import "NECommonUIConstant.h"
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>

@interface NEBaseViewController () <NENavigationBarHeightProviding>
@property (nonatomic, strong, readwrite) NENavigationView *navigationView;
@end

@implementation NEBaseViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    _topConstant = 0;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    _topConstant = 0;
  }
  return self;
}

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self ne_refreshNavigationBarHeightIfNeeded];

  if (!self.shouldShowTitleBar) {
    self.navigationController.navigationBarHidden = YES;
    [self.navigationView removeFromSuperview];
    return;
  }

  NSNumber *useSystemNavValue = [NEConfigManager.instance getParameterForKey:useSystemNav];
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
  self.view.backgroundColor = [UIColor whiteColor];

  NSNumber *useSystemNavValue = [NEConfigManager.instance getParameterForKey:useSystemNav];
  BOOL isSystemNav = useSystemNavValue && [useSystemNavValue boolValue];

  CGFloat topInset = NEUIKitNavigationAndStatusHeightForView(self.view);

  if (isSystemNav) {
    self.topConstant = topInset;
  } else {
    self.topConstant = topInset;
    self.navigationView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.navigationView addBackButtonTarget:self selector:@selector(backEvent)];
    if (self.shouldBindMoreButtonAction) {
      [self.navigationView addMoreButtonTarget:self selector:@selector(toSetting)];
    }

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

#pragma mark - Property Overrides

- (void)viewSafeAreaInsetsDidChange {
  [super viewSafeAreaInsetsDidChange];
  [self ne_refreshNavigationBarHeightIfNeeded];
}

#pragma mark - NENavigationBarHeightProviding

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
  CGFloat extra = NEAdaptiveDeviceGate.adaptiveHostActive ? 2.0 : 0.0;
  self.topConstant = height - extra;
  [self.view setNeedsLayout];
}

- (void)setTopConstant:(CGFloat)topConstant {
  CGFloat extra = NEAdaptiveDeviceGate.adaptiveHostActive ? 2.0 : 0.0;
  _topConstant = topConstant + extra;
  self.navigationViewHeightAnchor.constant = topConstant + extra;
  self.navigationView.titleBarTopCompensation = extra;
}

- (void)setTitle:(NSString *)title {
  [super setTitle:title];
  self.navigationView.navTitle.text = title;
}

#pragma mark - Public

- (BOOL)shouldShowTitleBar { return YES; }
- (BOOL)shouldBindMoreButtonAction { return YES; }

- (void)backEvent {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)toSetting {
  // 子类重写
}

- (void)addLeftSwipeDismissGesture {
  UIScreenEdgePanGestureRecognizer *gesture =
      [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDismiss:)];
  gesture.edges = UIRectEdgeLeft;
  [self.view addGestureRecognizer:gesture];
}

#pragma mark - Private

- (void)setupBackUI {
  UIImage *image = [CommonUIConfig.shared.backArrowImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:image
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(backEvent)];
  backItem.accessibilityIdentifier = @"id.backArrow";
  self.navigationItem.leftBarButtonItem = backItem;
  self.navigationController.navigationBar.topItem.backBarButtonItem = [[UIBarButtonItem alloc] init];
  self.navigationController.navigationBar.topItem.backBarButtonItem.tintColor = UIColor.ne_darkText;
}

- (void)swipeDismiss:(UIScreenEdgePanGestureRecognizer *)gesture {
  if (gesture.state == UIGestureRecognizerStateEnded) {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)showSingleAlertWithMessage:(NSString *)message completion:(nullable void (^)(void))completion {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                 message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:commonLocalizable(@"sure")
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *_) {
    if (completion) completion();
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Lazy Getters

- (NENavigationView *)navigationView {
  if (!_navigationView) {
    _navigationView = [[NENavigationView alloc] init];
  }
  return _navigationView;
}

@end
