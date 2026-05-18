// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseViewController.h"
#import "NENavigationView.h"
#import "NEConfigManager.h"
#import "CommonUIConfig.h"
#import "NECommonUIConstant.h"
#import <NEChatKitOC/NEConstant.h>
#import <NEChatKitOC/UIColor+NECommon.h>

@interface NEBaseViewController ()
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

  if (isSystemNav) {
    self.topConstant = NEConstant.navigationAndStatusHeight;
  } else {
    self.topConstant = NEConstant.navigationAndStatusHeight;
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

#pragma mark - Property Overrides

- (void)setTopConstant:(CGFloat)topConstant {
  _topConstant = topConstant;
  self.navigationViewHeightAnchor.constant = topConstant;
}

- (void)setTitle:(NSString *)title {
  [super setTitle:title];
  self.navigationView.navTitle.text = title;
}

#pragma mark - Public

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
  [alert addAction:[UIAlertAction actionWithTitle:@"确定"
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