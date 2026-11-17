// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationNavigationCoordinator.h"

@interface NEConversationNavigationCoordinator ()
@property (nonatomic, strong, readwrite) UINavigationController *navigationController;
@property (nonatomic, strong, readwrite, nullable) NEConversationOpenIntent *activeIntent;
@property (nonatomic, strong, readwrite, nullable) UIViewController *currentPlaceholder;
- (void)popExtensionsToChatRootAnimated:(BOOL)animated;
@end

@implementation NEConversationNavigationCoordinator

{
  UIViewController *_emptyViewController;
  __weak UIViewController *_activeController;
  NSString *_openingKey;
}

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController {
  self = [super init];
  if (self) {
    _navigationController = navigationController;
    _emptyViewController = navigationController.viewControllers.firstObject;
    _currentPlaceholder = _emptyViewController;
  }
  return self;
}

- (BOOL)isShowingPlaceholder {
  UIViewController *top = self.navigationController.topViewController;
  if (!top) {
    return NO;
  }
  if (self.currentPlaceholder) {
    return top == self.currentPlaceholder;
  }
  return top == _emptyViewController;
}

- (void)showPlaceholder:(UIViewController *)placeholder {
  self.activeIntent = nil;
  _activeController = nil;
  self.currentPlaceholder = placeholder;
  [self.navigationController setViewControllers:@[ placeholder ] animated:NO];
}

- (void)reset {
  self.activeIntent = nil;
  _activeController = nil;
  self.currentPlaceholder = _emptyViewController;
  if (_emptyViewController) {
    [self.navigationController setViewControllers:@[ _emptyViewController ] animated:NO];
  }
}

- (BOOL)syncActiveIntentWithNavigationStack {
  if (!self.isShowingPlaceholder || (self.activeIntent == nil && _activeController == nil)) {
    return NO;
  }
  self.activeIntent = nil;
  _activeController = nil;
  return YES;
}

- (BOOL)open:(NEConversationOpenIntent *)intent {
  NSAssert([NSThread isMainThread], @"NEConversationNavigationCoordinator.open must run on the main thread.");
  if (intent.key.length == 0) {
    return NO;
  }

  if ([self.activeIntent.key isEqualToString:intent.key]) {
    // 从搜索页进入会话后返回：聊天页已被 pop，但 activeIntent 仍残留在搜索页上；
    if (_activeController && ![self.navigationController.viewControllers containsObject:_activeController]) {
      self.activeIntent = nil;
      _activeController = nil;
    } else {
    // 同一个会话：保持现状，只执行额外的定位动作。
    if (intent.requiresPresentationAction) {
      BOOL (^presentationAction)(NEConversationOpenIntent *, UIViewController *) = self.presentationAction;
      UIViewController *root = _activeController ?: self.navigationController.viewControllers.firstObject;
      if (!presentationAction || !root || !presentationAction(intent, root)) {
        return NO;
      }
    }
    id animatedValue = intent.parameters[@"animated"];
    BOOL animated = [animatedValue respondsToSelector:@selector(boolValue)] ? [animatedValue boolValue] : NO;
    [self popExtensionsToChatRootAnimated:animated];
    return YES;
    }
  }

  if (self.openingKey && [self.openingKey isEqualToString:intent.key]) {
    return NO;
  }
  _openingKey = intent.key;
  UIViewController *controller = self.controllerFactory ? self.controllerFactory(intent) : nil;
  _openingKey = nil;
  if (!controller) {
    return NO;
  }
  // 有占位根时把会话页压在其上，保留页面自身返回；没有占位（测试/自定义栈）时退回单页栈，
  UIViewController *base = self.currentPlaceholder ?: _emptyViewController;
  if (base && base != controller) {
    [self.navigationController setViewControllers:@[ base, controller ] animated:NO];
  } else {
    [self.navigationController setViewControllers:@[ controller ] animated:NO];
  }
  self.activeIntent = intent;
  _activeController = controller;
  return YES;
}

- (void)popExtensionsToChatRootAnimated:(BOOL)animated {
  NSArray<UIViewController *> *stack = self.navigationController.viewControllers;
  if (stack.count <= 1) {
    return;
  }
  UIViewController *target = _activeController ?: stack.firstObject;
  if (!target) {
    return;
  }
  BOOL contains = NO;
  for (UIViewController *controller in stack) {
    if (controller == target) {
      contains = YES;
      break;
    }
  }
  if (!contains) {
    return;
  }
  [self.navigationController popToViewController:target animated:animated];
}

@end
