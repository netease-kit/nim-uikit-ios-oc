// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAdaptiveUIKitOCInternals.h"

@implementation NEAdaptiveNavigationObserver

- (instancetype)initWithNavigationController:(UINavigationController *)navigation
                                     didShow:(void (^)(void))didShow {
  self = [super init];
  if (self) {
    _originalDelegate = navigation.delegate;
    _didShow = [didShow copy];
    navigation.delegate = self;
  }
  return self;
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
  id<UINavigationControllerDelegate> original = self.originalDelegate;
  if ([original respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
    [original navigationController:navigationController willShowViewController:viewController animated:animated];
  }
  if (self.willShow) {
    self.willShow(viewController);
  }
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
  id<UINavigationControllerDelegate> original = self.originalDelegate;
  if ([original respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
    [original navigationController:navigationController didShowViewController:viewController animated:animated];
  }
  __weak NEAdaptiveNavigationObserver *weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    NEAdaptiveNavigationObserver *strongSelf = weakSelf;
    if (strongSelf.didShow) {
      strongSelf.didShow();
    }
  });
}

- (BOOL)respondsToSelector:(SEL)aSelector {
  if ([super respondsToSelector:aSelector]) {
    return YES;
  }
  id<UINavigationControllerDelegate> original = self.originalDelegate;
  return [original respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
  id<UINavigationControllerDelegate> original = self.originalDelegate;
  if ([original respondsToSelector:aSelector]) {
    return original;
  }
  return [super forwardingTargetForSelector:aSelector];
}

@end

#pragma mark - NEAdaptiveSectionHost

@implementation NEAdaptiveSectionHost {
  BOOL _contentVisible;
  __weak UIViewController *_emptyDetailController;
  NEAdaptiveNavigationObserver *_detailObservation;
  CGFloat _splitMasterWidth;
  CGFloat _dividerWidth;
  BOOL _hasSplitGeometry;
  BOOL _isTransferring;
  BOOL _waitingForTransition;
}

- (instancetype)initWithContent:(UINavigationController *)content {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _content = content;
    _contentVisible = NO;
  }
  return self;
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
  return NO;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self addChildViewController:_content];
  [self.view addSubview:_content.view];
  [_content didMoveToParentViewController:self];
  UIView *divider = [[UIView alloc] init];
  divider.userInteractionEnabled = NO;
  divider.accessibilityIdentifier = @"id.adaptive.section.divider";
  divider.hidden = YES;
  divider.tag = 0x4E454144;
  [self.view addSubview:divider];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  if (_hasSplitGeometry && self.splitDetail) {
    _content.view.frame = CGRectMake(0, 0, _splitMasterWidth, CGRectGetHeight(self.view.bounds));
    UIView *divider = [self.view viewWithTag:0x4E454144];
    divider.frame = CGRectMake(_splitMasterWidth, 0, _dividerWidth, CGRectGetHeight(self.view.bounds));
    divider.hidden = _dividerWidth <= 0;
    self.splitDetail.view.frame = CGRectMake(_splitMasterWidth + _dividerWidth, 0,
                                             MAX(0, CGRectGetWidth(self.view.bounds) - _splitMasterWidth - _dividerWidth),
                                             CGRectGetHeight(self.view.bounds));
  } else {
    _content.view.frame = self.view.bounds;
    UIView *divider = [self.view viewWithTag:0x4E454144];
    divider.hidden = YES;
  }
}

- (BOOL)isShowingDetailPlaceholder {
  if (self.splitDetail) {
    return self.splitDetail.topViewController == _emptyDetailController;
  }
  return _content.viewControllers.count == 1;
}

- (BOOL)hasDetailContent {
  if (!self.splitDetail) {
    return NO;
  }
  return self.splitDetail.topViewController != _emptyDetailController ||
         self.splitDetail.presentedViewController != nil;
}

- (void)resetDetail {
  if (self.splitDetail) {
    UIViewController *placeholder = _emptyDetailController;
    if (!placeholder) {
      placeholder = self.makeEmptyDetail ? self.makeEmptyDetail() : [[UIViewController alloc] init];
      _emptyDetailController = placeholder;
    }
    [self.splitDetail setViewControllers:@[ placeholder ] animated:NO];
  }
  UIViewController *root = _content.viewControllers.firstObject;
  if (root && _content.viewControllers.count > 1) {
    [_content setViewControllers:@[ root ] animated:NO];
  }
  if (self.onStackChanged) {
    self.onStackChanged();
  }
}

- (void)installDetailHost {
  if (self.splitDetail) {
    return;
  }
  UINavigationController *detail = self.makeDetailNavigation ? self.makeDetailNavigation() : [[UINavigationController alloc] init];
  UIViewController *placeholder = self.makeEmptyDetail ? self.makeEmptyDetail() : [[UIViewController alloc] init];
  _emptyDetailController = placeholder;
  [detail setViewControllers:@[ placeholder ] animated:NO];
  [self addChildViewController:detail];
  [self.view addSubview:detail.view];
  [detail didMoveToParentViewController:self];
  _splitDetail = detail;
  __weak typeof(self) weakSelf = self;
  _detailObservation = [[NEAdaptiveNavigationObserver alloc] initWithNavigationController:detail didShow:^{
    NEAdaptiveSectionHost *strongSelf = weakSelf;
    if (strongSelf && !strongSelf->_isTransferring && strongSelf.onStackChanged) {
      strongSelf.onStackChanged();
    }
  }];
  if (self.onDetailNavigationCreated) {
    self.onDetailNavigationCreated(detail);
  }
  if (_contentVisible) {
    [detail beginAppearanceTransition:YES animated:NO];
    [detail endAppearanceTransition];
  }
}

- (void)restoreSplitIfNeeded {
  UINavigationController *detail = self.splitDetail;
  UIViewController *root = _content.viewControllers.firstObject;
  if (!detail || !root) {
    return;
  }
  _isTransferring = YES;
  NSMutableArray<UIViewController *> *pushed = [NSMutableArray array];
  if (detail.viewControllers.firstObject != _emptyDetailController) {
    [pushed addObjectsFromArray:detail.viewControllers];
  } else if (detail.viewControllers.count > 1) {
    [pushed addObjectsFromArray:[detail.viewControllers subarrayWithRange:NSMakeRange(1, detail.viewControllers.count - 1)]];
  }
  detail.delegate = _detailObservation.originalDelegate;
  _detailObservation = nil;
  if (_contentVisible) {
    [detail beginAppearanceTransition:NO animated:NO];
    [detail endAppearanceTransition];
  }
  [detail setViewControllers:@[] animated:NO];
  if (pushed.count > 0) {
    NSMutableArray<UIViewController *> *pages = [NSMutableArray arrayWithObject:root];
    [pages addObjectsFromArray:pushed];
    [_content setViewControllers:pages animated:NO];
  }
  [detail willMoveToParentViewController:nil];
  [detail.view removeFromSuperview];
  [detail removeFromParentViewController];
  _splitDetail = nil;
  _hasSplitGeometry = NO;
  _isTransferring = NO;
}

- (void)configureSplitWithMasterWidth:(NSNumber *)masterWidth
                         dividerWidth:(CGFloat)dividerWidth
                         dividerColor:(UIColor *)dividerColor {
  UIView *divider = [self.view viewWithTag:0x4E454144];
  divider.backgroundColor = dividerColor;
  if (_isTransferring) {
    return;
  }
  id<UIViewControllerTransitionCoordinator> transition = _content.transitionCoordinator ?: self.splitDetail.transitionCoordinator;
  if (transition) {
    if (_waitingForTransition) {
      return;
    }
    _waitingForTransition = YES;
    __weak typeof(self) weakSelf = self;
    [transition animateAlongsideTransition:nil completion:^(__unused id<UIViewControllerTransitionCoordinatorContext> context) {
      NEAdaptiveSectionHost *strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      strongSelf->_waitingForTransition = NO;
      if (strongSelf.onStackChanged) {
        strongSelf.onStackChanged();
      }
    }];
    return;
  }
  if (!masterWidth) {
    [self restoreSplitIfNeeded];
    _hasSplitGeometry = NO;
    divider.hidden = YES;
    [self.view setNeedsLayout];
    return;
  }
  __weak typeof(self) weakSelf = self;
  [UIView performWithoutAnimation:^{
    [weakSelf applySplitConfigurationWithMasterWidth:masterWidth.doubleValue dividerWidth:dividerWidth];
  }];
}

- (void)applySplitConfigurationWithMasterWidth:(CGFloat)masterWidth dividerWidth:(CGFloat)dividerWidth {
  _splitMasterWidth = MAX(0, MIN(masterWidth, CGRectGetWidth(self.view.bounds)));
  _dividerWidth = MAX(0, dividerWidth);
  BOOL installsDetail = self.splitDetail == nil;
  if (installsDetail) {
    [self installDetailHost];
  }
  _hasSplitGeometry = YES;
  [self viewDidLayoutSubviews];
  NSArray<UIViewController *> *children = _content.viewControllers.count > 1
      ? [_content.viewControllers subarrayWithRange:NSMakeRange(1, _content.viewControllers.count - 1)] : @[];
  if (children.count > 0 && _content.viewControllers.firstObject) {
    _isTransferring = YES;
    UIViewController *root = _content.viewControllers.firstObject;
    [_content setViewControllers:@[ root ] animated:NO];
    NSMutableArray<UIViewController *> *pages = [NSMutableArray arrayWithObject:_emptyDetailController ?: [[UIViewController alloc] init]];
    [pages addObjectsFromArray:children];
    [self.splitDetail setViewControllers:pages animated:NO];
    _isTransferring = NO;
  }
  [self viewDidLayoutSubviews];
  if (installsDetail && _contentVisible && self.splitDetail) {
    [self.splitDetail beginAppearanceTransition:YES animated:NO];
    [self.splitDetail endAppearanceTransition];
  }
}

- (void)detachContentForTransfer {
  [self restoreSplitIfNeeded];
  [_content willMoveToParentViewController:nil];
  [_content.view removeFromSuperview];
  [_content removeFromParentViewController];
}

- (void)setVisible:(BOOL)visible {
  if (_contentVisible == visible) {
    return;
  }
  _contentVisible = visible;
  [_content beginAppearanceTransition:visible animated:NO];
  [_content endAppearanceTransition];
  if (self.splitDetail) {
    [self.splitDetail beginAppearanceTransition:visible animated:NO];
    [self.splitDetail endAppearanceTransition];
  }
}

@end
