// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAdaptiveRailPageNavigation.h"

#import "NEAdaptiveRailActionSupport.h"

#import <objc/runtime.h>

/// 一处被隐藏的原入口及其原透明度。
@interface NEAdaptiveHiddenControl : NSObject
@property (nonatomic, strong) UIButton *control;
@property (nonatomic, assign) CGFloat alpha;
@end

@implementation NEAdaptiveHiddenControl
@end

@interface NEAdaptiveKeyValueObservation : NSObject
- (instancetype)initWithObject:(NSObject *)object
                       keyPath:(NSString *)keyPath
                       handler:(void (^)(void))handler;
@end

@implementation NEAdaptiveKeyValueObservation {
  __weak NSObject *_observedObject;
  NSString *_keyPath;
  void (^_handler)(void);
}

- (instancetype)initWithObject:(NSObject *)object keyPath:(NSString *)keyPath handler:(void (^)(void))handler {
  self = [super init];
  if (self) {
    _observedObject = object;
    _keyPath = [keyPath copy];
    _handler = [handler copy];
    [object addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:NULL];
  }
  return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
  if (self->_handler) {
    self->_handler();
  }
}

- (void)invalidate {
  NSObject *object = _observedObject;
  if (object && _keyPath) {
    @try {
      [object removeObserver:self forKeyPath:_keyPath];
    } @catch (__unused NSException *exception) {
      // 对象已释放或该 KVO 已注销，忽略。
    }
  }
  _observedObject = nil;
  _keyPath = nil;
  _handler = nil;
}

- (void)dealloc {
  [self invalidate];
}

@end

#pragma mark - 视图树工具

/// 深度优先、按子视图顺序查找第一个满足条件的视图。
static UIView *NEAdaptiveFirstView(UIView *root, BOOL (^predicate)(UIView *view)) {
  NSMutableArray<UIView *> *stack = [NSMutableArray arrayWithObject:root];
  while (stack.count > 0) {
    UIView *view = stack.lastObject;
    [stack removeLastObject];
    if (predicate(view)) {
      return view;
    }
    for (UIView *child in view.subviews.reverseObjectEnumerator) {
      [stack addObject:child];
    }
  }
  return nil;
}

static BOOL NEAdaptiveClassChainContains(NSObject *object, NSString *className) {
  Class cls = object_getClass(object);
  while (cls) {
    NSString *name = NSStringFromClass(cls);
    if ([name isEqualToString:className] || [name hasSuffix:[@"." stringByAppendingString:className]]) {
      return YES;
    }
    cls = class_getSuperclass(cls);
  }
  return NO;
}

/// `NENavigationView` 是 IMUIKit 各模块共用的自绘标题栏；聊天模块使用它的子类
static BOOL NEAdaptiveIsNavigationBarView(UIView *view) {
  return NEAdaptiveClassChainContains(view, @"NENavigationView");
}

static BOOL NEAdaptiveIsUnifiedBackButton(UIView *view) {
  if (![view isKindOfClass:[UIButton class]]) {
    return NO;
  }
  return NEAdaptiveClassChainContains(view, @"NEUnifiedBackButton");
}

static UIView *NEAdaptiveCustomNavigationBar(UIViewController *page) {
  return NEAdaptiveFirstView(page.view, ^BOOL(UIView *view) {
    return NEAdaptiveIsNavigationBarView(view) && !view.isHidden && view.superview != nil;
  });
}

static UIButton *NEAdaptiveUnifiedBackButton(UIView *root) {
  UIView *view = NEAdaptiveFirstView(root, ^BOOL(UIView *candidate) {
    return NEAdaptiveIsUnifiedBackButton(candidate) && candidate.superview != nil;
  });
  return (UIButton *)view;
}

/// 按标识收集按钮；不要求当前可见，页面后续展示由绑定观察并实时过滤。
static NSArray<UIButton *> *NEAdaptiveControls(UIView *root, NSArray<NSString *> *identifiers) {
  NSMutableArray<UIButton *> *found = [NSMutableArray array];
  NSMutableArray<UIView *> *stack = [NSMutableArray arrayWithObject:root];
  while (stack.count > 0) {
    UIView *view = stack.lastObject;
    [stack removeLastObject];
    if ([view isKindOfClass:[UIButton class]] && view.superview != nil) {
      NSString *identifier = view.accessibilityIdentifier;
      if (identifier && [identifiers containsObject:identifier]) {
        [found addObject:(UIButton *)view];
      }
    }
    for (UIView *child in view.subviews.reverseObjectEnumerator) {
      [stack addObject:child];
    }
  }
  return found;
}

static UIButton *NEAdaptiveFirstControl(UIView *root, NSArray<NSString *> *identifiers) {
  return NEAdaptiveControls(root, identifiers).firstObject;
}

static int NEAdaptiveTrailingOrder(UIButton *button) {
  NSString *identifier = button.accessibilityIdentifier;
  if ([identifier isEqualToString:@"id.createTopic"]) {
    return 0;
  }
  if ([identifier isEqualToString:@"id.threePoint"]) {
    return 1;
  }
  if ([identifier isEqualToString:@"id.sureButton"] || [identifier isEqualToString:@"id.multiSelect"]) {
    return 2;
  }
  if ([identifier isEqualToString:@"id.adaptiveAction"]) {
    return 3;
  }
  return 4;
}

static NEAdaptiveRailAction *NEAdaptiveActionForButton(UIButton *button) {
  NSString *rawTitle = [button titleForState:UIControlStateNormal] ?: button.currentTitle;
  NSString *text = nil;
  NSString *badge = nil;
  [NEAdaptiveRailTitle splitTitle:rawTitle text:&text badge:&badge];
  UIImage *image = text == nil ? [button imageForState:UIControlStateNormal] : nil;

  NEAdaptiveRailAction *action = [[NEAdaptiveRailAction alloc] init];
  action.title = text;
  action.badge = badge;
  action.image = image;
  action.accessibilityText = rawTitle ?: button.accessibilityLabel ?: text;
  action.isEnabled = button.isEnabled;
  action.identifier = button.accessibilityIdentifier;
  __weak UIButton *weakButton = button;
  action.handler = ^{
    UIButton *strongButton = weakButton;
    if (!strongButton) {
      return;
    }
    [NEAdaptiveActionInvocation forwardControl:strongButton];
  };
  return action;
}

static NEAdaptiveRailAction *NEAdaptiveActionForItem(UIBarButtonItem *item) {
  if ([item.customView isKindOfClass:[UIButton class]]) {
    return NEAdaptiveActionForButton((UIButton *)item.customView);
  }
  NSString *text = nil;
  NSString *badge = nil;
  [NEAdaptiveRailTitle splitTitle:item.title text:&text badge:&badge];
  UIImage *image = text == nil ? item.image : nil;

  NEAdaptiveRailAction *action = [[NEAdaptiveRailAction alloc] init];
  action.title = text;
  action.badge = badge;
  action.image = image;
  action.accessibilityText = item.title ?: item.accessibilityLabel ?: text;
  action.isEnabled = item.isEnabled;
  action.identifier = item.accessibilityIdentifier;
  action.target = item.target;
  action.selector = item.action;

  if ([item.customView isKindOfClass:[UIControl class]] && ![item.customView isKindOfClass:[UIButton class]]) {
    __weak UIControl *weakControl = (UIControl *)item.customView;
    action.handler = ^{
      UIControl *strongControl = weakControl;
      if (!strongControl) {
        return;
      }
      [NEAdaptiveActionInvocation forwardControl:strongControl];
    };
  }
  return action;
}

#pragma mark - NEAdaptiveRailPageNavigation

@implementation NEAdaptiveRailPageNavigation {
  __weak UIViewController *_page;
  __weak UIView *_customBar;
  /// 页面自绘头部（非 NENavigationView）：使用统一返回按钮或收起入口。
  BOOL _usesCustomHeader;
  __weak UIButton *_customBackControl;
  NSArray<UIButton *> *_customTrailingControls;
  UIBarButtonItem *_systemBackItem;
  NSArray<UIBarButtonItem *> *_systemTrailingItems;
  NSNumber *_systemHidesBackButtonBeforeSuppression;
  BOOL _suppressesSystemNavigation;
  BOOL _suppressedSystemItems;
  NSMutableArray<NEAdaptiveHiddenControl *> *_hiddenControls;
  NSMutableArray<NEAdaptiveKeyValueObservation *> *_observations;
  BOOL _isSuppressed;
}

- (instancetype)initWithPage:(UIViewController *)page {
  self = [super init];
  if (self) {
    _page = page;
    _customTrailingControls = @[];
    _systemTrailingItems = @[];
    _hiddenControls = [NSMutableArray array];
    _observations = [NSMutableArray array];
  }
  return self;
}

+ (nullable instancetype)makeForPage:(UIViewController *)page {
  // 只要求视图已加载：页面在布局中可能还没完成 window 挂载，
  if (!page.isViewLoaded) {
    return nil;
  }
  NEAdaptiveRailPageNavigation *navigation = [[self alloc] initWithPage:page];
  UIView *bar = NEAdaptiveCustomNavigationBar(page);
  if (bar) {
    navigation->_customBar = bar;
    navigation->_customBackControl = NEAdaptiveFirstControl(bar, @[ @"id.backArrow" ]);
    // 标准标题栏同时支持内置 moreButton（id.threePoint）与页面追加的自定义右侧按钮
    // （如 Bot 子会话的 id.createTopic），按横坐标保持页面顺序。
    NSArray<UIButton *> *trailing = NEAdaptiveControls(bar, @[ @"id.threePoint", @"id.createTopic" ]);
    UIView *host = bar;
    navigation->_customTrailingControls = [trailing sortedArrayUsingComparator:^NSComparisonResult(UIButton *lhs, UIButton *rhs) {
      CGFloat left = [lhs convertRect:lhs.bounds toView:host].origin.x;
      CGFloat right = [rhs convertRect:rhs.bounds toView:host].origin.x;
      if (left == right) {
        return NSOrderedSame;
      }
      return left < right ? NSOrderedAscending : NSOrderedDescending;
    }];
    if (navigation->_customBackControl || navigation->_customTrailingControls.count > 0) {
      return navigation;
    }
  }

  UIButton *back = NEAdaptiveUnifiedBackButton(page.view) ?: NEAdaptiveFirstControl(page.view, @[ @"id.arrowDown", @"id.adaptiveBack" ]);
  NSMutableArray<UIButton *> *candidateTrailing =
      [NEAdaptiveControls(page.view, @[ @"id.sureButton", @"id.multiSelect", @"id.adaptiveAction", @"id.createTopic" ]) mutableCopy];
  if (back) {
    // 页面在 viewWillAppear 阶段可能还没完成 Auto Layout；此时不做行过滤，
    if (back.bounds.size.width > 0 && back.bounds.size.height > 0) {
      CGRect backFrame = [back convertRect:back.bounds toView:page.view];
      NSMutableArray<UIButton *> *filtered = [NSMutableArray array];
      for (UIButton *control in candidateTrailing) {
        CGRect frame = [control convertRect:control.bounds toView:page.view];
        if (fabs(frame.origin.y + frame.size.height / 2 - (backFrame.origin.y + backFrame.size.height / 2)) <= 40) {
          [filtered addObject:control];
        }
      }
      candidateTrailing = filtered;
    }
  } else {
    NSMutableArray<UIButton *> *filtered = [NSMutableArray array];
    for (UIButton *control in candidateTrailing) {
      if ([control convertRect:control.bounds toView:page.view].origin.y < 160) {
        [filtered addObject:control];
      }
    }
    candidateTrailing = filtered;
  }
  if (back || candidateTrailing.count > 0) {
    navigation->_usesCustomHeader = YES;
    navigation->_customBackControl = back;
    navigation->_customTrailingControls = [candidateTrailing copy];
    return navigation;
  }

  UINavigationController *navigationController = page.navigationController;
  if (!navigationController || navigationController.isNavigationBarHidden) {
    return nil;
  }
  UIBarButtonItem *systemBack = page.navigationItem.leftBarButtonItem;
  NSArray<UIBarButtonItem *> *systemTrailing = page.navigationItem.rightBarButtonItems ?: @[];
  if (!systemBack && systemTrailing.count == 0) {
    return nil;
  }
  navigation->_customBar = nil;
  navigation->_customBackControl = nil;
  navigation->_customTrailingControls = @[];
  navigation->_systemBackItem = systemBack;
  navigation->_systemTrailingItems = [systemTrailing copy];
  navigation->_suppressesSystemNavigation = YES;
  navigation->_suppressedSystemItems = NO;
  return navigation;
}

+ (BOOL)hasVisibleTitleBarInPage:(UIViewController *)page {
  if (!page.isViewLoaded) {
    return NO;
  }
  if (NEAdaptiveCustomNavigationBar(page)) {
    return YES;
  }
  if (NEAdaptiveUnifiedBackButton(page.view)) {
    return YES;
  }
  if (NEAdaptiveControls(page.view, @[ @"id.arrowDown", @"id.adaptiveBack" ]).count > 0) {
    return YES;
  }
  UINavigationController *navigation = page.navigationController;
  if (navigation && !navigation.isNavigationBarHidden) {
    return YES;
  }
  return NO;
}

#pragma mark - 动作描述

- (nullable NEAdaptiveRailAction *)backAction {
  if (_customBackControl && self.isCustomBarVisible && !_customBackControl.isHidden) {
    return NEAdaptiveActionForButton(_customBackControl);
  }
  if (_systemBackItem && self.isSystemBarAvailable) {
    return NEAdaptiveActionForItem(_systemBackItem);
  }
  return nil;
}

- (NSArray<NEAdaptiveRailAction *> *)trailingActions {
  NSMutableArray<NEAdaptiveRailAction *> *actions = [NSMutableArray array];
  if (self.isCustomBarVisible) {
    NSMutableArray<UIButton *> *visible = [NSMutableArray array];
    for (UIButton *control in _customTrailingControls) {
      if (!control.isHidden && control.isUserInteractionEnabled) {
        [visible addObject:control];
      }
    }
    UIView *host = _page.view ?: visible.firstObject;
    NSArray<UIButton *> *ordered = [visible sortedArrayUsingComparator:^NSComparisonResult(UIButton *lhs, UIButton *rhs) {
      if (!host) {
        return NSOrderedSame;
      }
      CGFloat left = [lhs convertRect:lhs.bounds toView:host].origin.x;
      CGFloat right = [rhs convertRect:rhs.bounds toView:host].origin.x;
      if (fabs(left - right) > 0.5) {
        return left < right ? NSOrderedAscending : NSOrderedDescending;
      }
      int lhsOrder = NEAdaptiveTrailingOrder(lhs);
      int rhsOrder = NEAdaptiveTrailingOrder(rhs);
      if (lhsOrder == rhsOrder) {
        return NSOrderedSame;
      }
      return lhsOrder < rhsOrder ? NSOrderedAscending : NSOrderedDescending;
    }];
    for (UIButton *control in ordered) {
      [actions addObject:NEAdaptiveActionForButton(control)];
    }
  }
  if (self.isSystemBarAvailable) {
    // rightBarButtonItems 的第一个是最右侧，倒序后才是页面从左到右。
    for (UIBarButtonItem *item in _systemTrailingItems.reverseObjectEnumerator) {
      [actions addObject:NEAdaptiveActionForItem(item)];
    }
  }
  NSMutableArray<NEAdaptiveRailAction *> *filtered = [NSMutableArray array];
  for (NEAdaptiveRailAction *action in actions) {
    if (action.title.length > 0 || action.image || action.badge.length > 0) {
      [filtered addObject:action];
    }
  }
  return filtered;
}

- (BOOL)isCustomBarVisible {
  if (_usesCustomHeader) {
    NSMutableArray<UIButton *> *controls = [NSMutableArray array];
    if (_customBackControl) {
      [controls addObject:_customBackControl];
    }
    [controls addObjectsFromArray:_customTrailingControls];
    for (UIButton *control in controls) {
      if (control.superview != nil && !control.isHidden) {
        return YES;
      }
    }
    return NO;
  }
  UIView *bar = _customBar;
  return bar != nil && !bar.isHidden && bar.superview != nil;
}

- (BOOL)isSystemBarAvailable {
  UINavigationController *navigation = _page.navigationController;
  return navigation != nil && !navigation.isNavigationBarHidden;
}

- (BOOL)isValidForPage:(UIViewController *)page {
  if (_page != page) {
    return NO;
  }
  if (_usesCustomHeader) {
    NSMutableArray<UIButton *> *controls = [NSMutableArray array];
    if (_customBackControl) {
      [controls addObject:_customBackControl];
    }
    [controls addObjectsFromArray:_customTrailingControls];
    for (UIButton *control in controls) {
      if (control.superview != nil) {
        return YES;
      }
    }
    return NO;
  }
  if (_customBackControl || _customTrailingControls.count > 0) {
    return self.isCustomBarVisible;
  }
  return self.isSystemBarAvailable;
}

#pragma mark - 原入口的隐藏与恢复

- (void)suppress {
  if (_isSuppressed) {
    return;
  }
  _isSuppressed = YES;
  NSMutableArray<UIButton *> *controls = [NSMutableArray array];
  if (_customBackControl) {
    [controls addObject:_customBackControl];
  }
  [controls addObjectsFromArray:_customTrailingControls];
  for (UIButton *control in controls) {
    NEAdaptiveHiddenControl *entry = [[NEAdaptiveHiddenControl alloc] init];
    entry.control = control;
    entry.alpha = control.alpha;
    [_hiddenControls addObject:entry];
    control.alpha = 0;
  }

  UIViewController *page = _page;
  if (_suppressesSystemNavigation && page) {
    NSUInteger stackDepth = page.navigationController.viewControllers.count;
    BOOL needsSystemSuppression =
        _systemBackItem != nil || _systemTrailingItems.count > 0 || stackDepth > 1;
    if (needsSystemSuppression) {
      UINavigationItem *item = page.navigationItem;
      _systemHidesBackButtonBeforeSuppression = @(item.hidesBackButton);
      item.leftBarButtonItem = nil;
      item.rightBarButtonItems = @[];
      item.hidesBackButton = YES;
      _suppressedSystemItems = YES;
    }
  }
  [self observeChanges];
}

- (void)refreshSuppressedSystemItems {
  UIViewController *page = _page;
  if (!_isSuppressed || !_suppressedSystemItems || !page) {
    return;
  }
  UINavigationItem *item = page.navigationItem;
  if (item.leftBarButtonItem) {
    _systemBackItem = item.leftBarButtonItem;
    item.leftBarButtonItem = nil;
  }
  if (item.rightBarButtonItems.count > 0) {
    _systemTrailingItems = item.rightBarButtonItems;
    item.rightBarButtonItems = @[];
  }
  item.hidesBackButton = YES;
}

- (void)restore {
  if (!_isSuppressed) {
    return;
  }
  _isSuppressed = NO;
  for (NEAdaptiveKeyValueObservation *observation in _observations) {
    [observation invalidate];
  }
  [_observations removeAllObjects];
  for (NEAdaptiveHiddenControl *entry in _hiddenControls) {
    entry.control.alpha = entry.alpha;
  }
  [_hiddenControls removeAllObjects];

  UIViewController *page = _page;
  if (_suppressedSystemItems && page) {
    if (_systemBackItem) {
      page.navigationItem.leftBarButtonItem = _systemBackItem;
    }
    if (_systemHidesBackButtonBeforeSuppression) {
      page.navigationItem.hidesBackButton = _systemHidesBackButtonBeforeSuppression.boolValue;
    }
    if (_systemTrailingItems.count > 0) {
      page.navigationItem.rightBarButtonItems = _systemTrailingItems;
    }
    _suppressedSystemItems = NO;
  }
  _systemBackItem = nil;
  _systemTrailingItems = @[];
  _systemHidesBackButtonBeforeSuppression = nil;
}

- (void)observeChanges {
  __weak NEAdaptiveRailPageNavigation *weakSelf = self;
  void (^notify)(void) = ^{
    [weakSelf notifyChange];
  };
  UIView *bar = _customBar;
  if (bar) {
    [_observations addObject:[[NEAdaptiveKeyValueObservation alloc] initWithObject:bar
                                                                           keyPath:@"hidden"
                                                                           handler:notify]];
  }
  NSMutableArray<UIButton *> *controls = [NSMutableArray array];
  if (_customBackControl) {
    [controls addObject:_customBackControl];
  }
  [controls addObjectsFromArray:_customTrailingControls];
  for (UIButton *control in controls) {
    [_observations addObject:[[NEAdaptiveKeyValueObservation alloc] initWithObject:control
                                                                           keyPath:@"enabled"
                                                                           handler:notify]];
    [_observations addObject:[[NEAdaptiveKeyValueObservation alloc] initWithObject:control
                                                                           keyPath:@"hidden"
                                                                           handler:notify]];
  }
  for (UIBarButtonItem *item in _systemTrailingItems) {
    [_observations addObject:[[NEAdaptiveKeyValueObservation alloc] initWithObject:item
                                                                           keyPath:@"title"
                                                                           handler:notify]];
    [_observations addObject:[[NEAdaptiveKeyValueObservation alloc] initWithObject:item
                                                                           keyPath:@"enabled"
                                                                           handler:notify]];
  }
}

- (void)notifyChange {
  void (^handler)(void) = self.onChange;
  if (!handler) {
    return;
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    handler();
  });
}

- (void)dealloc {
  for (NEAdaptiveKeyValueObservation *observation in _observations) {
    [observation invalidate];
  }
}

@end
