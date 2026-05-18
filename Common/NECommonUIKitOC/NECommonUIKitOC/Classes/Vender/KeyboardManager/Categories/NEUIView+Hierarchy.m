// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEUIView+Hierarchy.h"
#import "NEUITextFieldView+Additions.h"
#import "NEUIViewController+Additions.h"

static BOOL NECanBecomeFirstResponderView(UIView *view) {
  BOOL canBecome = NO;
  if ([view conformsToProtocol:@protocol(UITextInput)]) {
    if ([view isKindOfClass:[UITextView class]]) {
      canBecome = ((UITextView *)view).editable;
    } else if ([view isKindOfClass:[UITextField class]]) {
      canBecome = ((UITextField *)view).enabled;
    }
  }

  if (canBecome) {
    canBecome = view.userInteractionEnabled &&
      !view.hidden &&
      view.alpha != 0.0 &&
      ![view neIsAlertViewTextField] &&
      [view neTextFieldSearchBar] == nil;
  }
  return canBecome;
}

@implementation UIView (NEHierarchy)

- (UIViewController *)neViewContainingController {
  UIResponder *nextResponder = self;
  do {
    nextResponder = nextResponder.nextResponder;
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
      return (UIViewController *)nextResponder;
    }
  } while (nextResponder);
  return nil;
}

- (UIViewController *)neTopMostController {
  NSMutableArray<UIViewController *> *controllersHierarchy = [NSMutableArray array];
  UIViewController *topController = self.window.rootViewController;
  if (!topController) {
    return [self neViewContainingController];
  }

  [controllersHierarchy addObject:topController];
  while (topController.presentedViewController) {
    topController = topController.presentedViewController;
    [controllersHierarchy addObject:topController];
  }

  UIResponder *matchController = [self neViewContainingController];
  while ([matchController isKindOfClass:[UIViewController class]] &&
         ![controllersHierarchy containsObject:(UIViewController *)matchController]) {
    do {
      matchController = matchController.nextResponder;
    } while (matchController && ![matchController isKindOfClass:[UIViewController class]]);
  }

  return (UIViewController *)matchController;
}

- (UIViewController *)neParentContainerViewController {
  UIViewController *matchController = [self neViewContainingController];
  UIViewController *parentContainerViewController = nil;

  if (matchController.navigationController) {
    UINavigationController *navController = matchController.navigationController;
    while (navController.navigationController) {
      navController = navController.navigationController;
    }

    UIViewController *parentController = navController;
    while (parentController.parentViewController &&
           ![parentController.parentViewController isKindOfClass:[UINavigationController class]] &&
           ![parentController.parentViewController isKindOfClass:[UITabBarController class]] &&
           ![parentController.parentViewController isKindOfClass:[UISplitViewController class]]) {
      parentController = parentController.parentViewController;
    }

    if (navController == parentController) {
      parentContainerViewController = navController.topViewController;
    } else {
      parentContainerViewController = parentController;
    }
  } else if (matchController.tabBarController) {
    UITabBarController *tabController = matchController.tabBarController;
    if ([tabController.selectedViewController isKindOfClass:[UINavigationController class]]) {
      parentContainerViewController = ((UINavigationController *)tabController.selectedViewController).topViewController;
    } else {
      parentContainerViewController = tabController.selectedViewController;
    }
  } else {
    while (matchController.parentViewController &&
           ![matchController.parentViewController isKindOfClass:[UINavigationController class]] &&
           ![matchController.parentViewController isKindOfClass:[UITabBarController class]] &&
           ![matchController.parentViewController isKindOfClass:[UISplitViewController class]]) {
      matchController = matchController.parentViewController;
    }
    parentContainerViewController = matchController;
  }

  UIViewController *finalController = [parentContainerViewController neParentNEContainerViewController];
  return finalController ?: parentContainerViewController;
}

- (UIView *)neSuperviewOfClassType:(Class)classType {
  return [self neSuperviewOfClassType:classType belowView:nil];
}

- (UIView *)neSuperviewOfClassType:(Class)classType belowView:(UIView *)belowView {
  UIView *superView = self.superview;
  while (superView) {
    if ([superView isKindOfClass:classType]) {
      if ([superView isKindOfClass:[UIScrollView class]]) {
        NSString *classNameString = NSStringFromClass(superView.class);
        if (![superView.superview isKindOfClass:[UITableView class]] &&
            ![superView.superview isKindOfClass:[UITableViewCell class]] &&
            ![classNameString hasPrefix:@"_"]) {
          return superView;
        }
      } else {
        return superView;
      }
    } else if (superView == belowView) {
      return nil;
    }
    superView = superView.superview;
  }
  return nil;
}

- (NSArray<UIView *> *)neResponderSiblings {
  NSMutableArray<UIView *> *textFields = [NSMutableArray array];
  for (UIView *textField in self.superview.subviews) {
    if ((textField == self || !textField.neIgnoreSwitchingByNextPrevious) &&
        NECanBecomeFirstResponderView(textField)) {
      [textFields addObject:textField];
    }
  }
  return textFields;
}

- (NSArray<UIView *> *)neDeepResponderViews {
  NSMutableArray<UIView *> *textFields = [NSMutableArray array];
  for (UIView *textField in self.subviews) {
    if ((textField == self || !textField.neIgnoreSwitchingByNextPrevious) &&
        NECanBecomeFirstResponderView(textField)) {
      [textFields addObject:textField];
    } else if (textField.subviews.count != 0 &&
               self.userInteractionEnabled &&
               !self.hidden &&
               self.alpha != 0.0) {
      [textFields addObjectsFromArray:[textField neDeepResponderViews]];
    }
  }

  return [textFields sortedArrayUsingComparator:^NSComparisonResult(UIView *view1, UIView *view2) {
    CGRect frame1 = [view1 convertRect:view1.bounds toView:self];
    CGRect frame2 = [view2 convertRect:view2.bounds toView:self];
    if (CGRectGetMinY(frame1) != CGRectGetMinY(frame2)) {
      return CGRectGetMinY(frame1) < CGRectGetMinY(frame2) ? NSOrderedAscending : NSOrderedDescending;
    }
    if (CGRectGetMinX(frame1) != CGRectGetMinX(frame2)) {
      return CGRectGetMinX(frame1) < CGRectGetMinX(frame2) ? NSOrderedAscending : NSOrderedDescending;
    }
    return NSOrderedSame;
  }];
}

- (UISearchBar *)neTextFieldSearchBar {
  UIResponder *responder = self.nextResponder;
  while (responder) {
    if ([responder isKindOfClass:[UISearchBar class]]) {
      return (UISearchBar *)responder;
    }
    if ([responder isKindOfClass:[UIViewController class]]) {
      break;
    }
    responder = responder.nextResponder;
  }
  return nil;
}

- (BOOL)neIsAlertViewTextField {
  UIResponder *alertViewController = [self neViewContainingController];
  while (alertViewController) {
    if ([alertViewController isKindOfClass:[UIAlertController class]]) {
      return YES;
    }
    alertViewController = alertViewController.nextResponder;
  }
  return NO;
}

@end

@implementation NSObject (NEHierarchyDescription)

- (NSString *)_NEDescription {
  return [NSString stringWithFormat:@"<%@ %p>", self, self];
}

@end
