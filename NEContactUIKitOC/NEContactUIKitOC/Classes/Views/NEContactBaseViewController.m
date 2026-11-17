// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEContactBaseViewController.h"
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NEConstant.h>
#import "ContactUIConfig.h"
#import "NEBaseContactRouter.h"

@interface NEContactBaseViewController () <NENavigationBarHeightProviding>
@property(nonatomic, strong, readwrite) NENavigationView *navigationView;
@end

@implementation NEContactBaseViewController

- (BOOL)shouldShowNavigationBar {
  if ([ContactUIConfig shared].showTitleBar) {
    return YES;
  }
  return self.navigationController.viewControllers.count > 1;
}

- (CGFloat)defaultCustomNavigationHeight {
  CGFloat extra = NEAdaptiveDeviceGate.adaptiveHostActive ? 2.0 : 0.0;
  return NEUIKitNavigationAndStatusHeightForView(self.view) + extra;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)setTitle:(NSString *)title {
  [super setTitle:title];
  self.navigationView.navTitle.text = title;
}

- (NSString *)title {
  return [super title];
}

- (void)setTopConstant:(CGFloat)topConstant {
  _topConstant = topConstant;
  self.navigationViewHeightAnchor.constant = topConstant;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self ne_refreshNavigationBarHeightIfNeeded];

  BOOL shouldShowNavigationBar = [self shouldShowNavigationBar];

  if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)] &&
      self.navigationController.interactivePopGestureRecognizer) {
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.interactivePopGestureRecognizer.enabled = (self.navigationController.viewControllers.count > 1);
  }

  if (!shouldShowNavigationBar) {
    self.topConstant = 0;
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
    if (self.navigationView.superview) {
      [self.view bringSubviewToFront:self.navigationView];
    }
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  self.edgesForExtendedLayout = UIRectEdgeNone;

  NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
  BOOL shouldShowNavigationBar = [self shouldShowNavigationBar];
  if (useSystemNavValue && [useSystemNavValue boolValue]) {
    _topConstant = 0;
  } else {
    _topConstant = shouldShowNavigationBar ? [self defaultCustomNavigationHeight] : 0;
    if (shouldShowNavigationBar) {
      self.navigationView.translatesAutoresizingMaskIntoConstraints = NO;
      [self.navigationView addBackButtonTarget:self selector:@selector(backEvent)];
      [self.navigationView addMoreButtonTarget:self selector:@selector(toSetting)];

      UIImage *backImage = [CommonUIConfig shared].backArrowImage;
      if (backImage) {
        [self.navigationView setBackButtonImage:[backImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
      }
      self.navigationView.backButton.tintColor = [UIColor ne_colorWithHexString:@"333333"];

      [self.view addSubview:self.navigationView];
      self.navigationViewHeightAnchor = [self.navigationView.heightAnchor constraintEqualToConstant:_topConstant];
      self.navigationViewHeightAnchor.active = YES;
      [NSLayoutConstraint activateConstraints:@[
        [self.navigationView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.navigationView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.navigationView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
      ]];
    }
  }
}

- (void)viewSafeAreaInsetsDidChange {
  [super viewSafeAreaInsetsDidChange];
  [self ne_refreshNavigationBarHeightIfNeeded];
}

#pragma mark - NENavigationBarHeightProviding

- (CGFloat)ne_navigationBarHeight {
  return [self defaultCustomNavigationHeight];
}

- (void)ne_applyNavigationBarHeight:(CGFloat)height {
  if (!self.navigationViewHeightAnchor || !self.navigationView.superview) {
    return;
  }
  if (fabs(self.navigationViewHeightAnchor.constant - height) < 0.5) {
    return;
  }
  self.topConstant = height;
  [self.view setNeedsLayout];
}

- (void)setupBackUI {
  UIColor *backTintColor = [UIColor ne_colorWithHexString:@"333333"];
  self.navigationController.navigationBar.tintColor = backTintColor;
  UIImage *sourceImage = [CommonUIConfig shared].backArrowImage;
  UIImage *image = [sourceImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:image
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(backEvent)];
  backItem.accessibilityIdentifier = @"id.backArrow";
  backItem.tintColor = backTintColor;
  self.navigationItem.leftBarButtonItem = backItem;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)] &&
      gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
    return self.navigationController.viewControllers.count > 1;
  }
  return YES;
}

- (void)backEvent {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)appEnterBackground {
}

- (void)toSetting {
}

#pragma mark - Lazy Init

- (NENavigationView *)navigationView {
  if (!_navigationView) {
    _navigationView = [[NENavigationView alloc] init];
  }
  return _navigationView;
}

- (NEEmptyDataView *)emptyView {
  if (!_emptyView) {
    _emptyView = [[NEEmptyDataView alloc] initWithImageName:@"user_empty"
                                                    content:@""
                                                      frame:CGRectZero];
    _emptyView.translatesAutoresizingMaskIntoConstraints = NO;
    _emptyView.userInteractionEnabled = NO;
    _emptyView.hidden = YES;
  }
  return _emptyView;
}

@end
