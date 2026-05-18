// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEKeyboardManager+Position.h"
#import "NEKeyboardManager+Debug.h"
#import "NEKeyboardManager+Internal.h"
#import "NEKeyboardManager+UIKeyboardNotification.h"
#import "NEKeyboardManager+UITextFieldViewNotification.h"
#import "Categories/NEUIScrollView+Additions.h"
#import "Categories/NEUITextFieldView+Additions.h"
#import "Categories/NEUIView+Hierarchy.h"
#import <objc/runtime.h>

static void *NEMovedDistanceKey = &NEMovedDistanceKey;
static void *NEMovedDistanceChangedKey = &NEMovedDistanceChangedKey;
static void *NELastScrollViewKey = &NELastScrollViewKey;
static void *NEStartingContentOffsetKey = &NEStartingContentOffsetKey;
static void *NEStartingScrollIndicatorInsetsKey = &NEStartingScrollIndicatorInsetsKey;
static void *NEStartingContentInsetsKey = &NEStartingContentInsetsKey;
static void *NEStartingTextViewContentInsetsKey = &NEStartingTextViewContentInsetsKey;
static void *NEStartingTextViewScrollIndicatorInsetsKey = &NEStartingTextViewScrollIndicatorInsetsKey;
static void *NEIsTextViewContentInsetChangedKey = &NEIsTextViewContentInsetChangedKey;
static void *NEHasPendingAdjustRequestKey = &NEHasPendingAdjustRequestKey;

static BOOL NEIsTextViewResponder(UIView *view) {
  return [view isKindOfClass:[UIScrollView class]] && [view respondsToSelector:@selector(isEditable)];
}

static UIEdgeInsets NECurrentScrollIndicatorInsets(UIScrollView *scrollView) {
  if (@available(iOS 11.1, *)) {
    return scrollView.verticalScrollIndicatorInsets;
  }
  return scrollView.scrollIndicatorInsets;
}

static void NESetCurrentScrollIndicatorInsets(UIScrollView *scrollView, UIEdgeInsets insets) {
  if (@available(iOS 11.1, *)) {
    scrollView.verticalScrollIndicatorInsets = insets;
  } else {
    scrollView.scrollIndicatorInsets = insets;
  }
}

@interface NEKeyboardManager (PositionPrivate)

@property (nonatomic, assign) BOOL hasPendingAdjustRequest;
- (void)adjustPosition;

@end

@implementation NEKeyboardManager (Position)

- (CGFloat)movedDistance {
  NSNumber *value = objc_getAssociatedObject(self, NEMovedDistanceKey);
  return value ? value.doubleValue : 0.0;
}

- (void)setMovedDistance:(CGFloat)movedDistance {
  objc_setAssociatedObject(self, NEMovedDistanceKey, @(movedDistance), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  if (self.movedDistanceChanged) {
    self.movedDistanceChanged(movedDistance);
  }
}

- (void (^)(CGFloat))movedDistanceChanged {
  return objc_getAssociatedObject(self, NEMovedDistanceChangedKey);
}

- (void)setMovedDistanceChanged:(void (^)(CGFloat))movedDistanceChanged {
  objc_setAssociatedObject(self, NEMovedDistanceChangedKey, movedDistanceChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
  if (movedDistanceChanged) {
    movedDistanceChanged(self.movedDistance);
  }
}

- (UIScrollView *)lastScrollView {
  return ((NEWeakObjectContainer *)objc_getAssociatedObject(self, NELastScrollViewKey)).object;
}

- (void)setLastScrollView:(UIScrollView *)lastScrollView {
  objc_setAssociatedObject(self, NELastScrollViewKey, [[NEWeakObjectContainer alloc] initWithObject:lastScrollView], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGPoint)startingContentOffset {
  NSValue *value = objc_getAssociatedObject(self, NEStartingContentOffsetKey);
  return value ? value.CGPointValue : NEKeyboardManagerCGPointInvalidValue();
}

- (void)setStartingContentOffset:(CGPoint)startingContentOffset {
  objc_setAssociatedObject(self, NEStartingContentOffsetKey, [NSValue valueWithCGPoint:startingContentOffset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)startingScrollIndicatorInsets {
  NSValue *value = objc_getAssociatedObject(self, NEStartingScrollIndicatorInsetsKey);
  return value ? value.UIEdgeInsetsValue : UIEdgeInsetsZero;
}

- (void)setStartingScrollIndicatorInsets:(UIEdgeInsets)startingScrollIndicatorInsets {
  objc_setAssociatedObject(self, NEStartingScrollIndicatorInsetsKey, [NSValue valueWithUIEdgeInsets:startingScrollIndicatorInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)startingContentInsets {
  NSValue *value = objc_getAssociatedObject(self, NEStartingContentInsetsKey);
  return value ? value.UIEdgeInsetsValue : UIEdgeInsetsZero;
}

- (void)setStartingContentInsets:(UIEdgeInsets)startingContentInsets {
  objc_setAssociatedObject(self, NEStartingContentInsetsKey, [NSValue valueWithUIEdgeInsets:startingContentInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)startingTextViewContentInsets {
  NSValue *value = objc_getAssociatedObject(self, NEStartingTextViewContentInsetsKey);
  return value ? value.UIEdgeInsetsValue : UIEdgeInsetsZero;
}

- (void)setStartingTextViewContentInsets:(UIEdgeInsets)startingTextViewContentInsets {
  objc_setAssociatedObject(self, NEStartingTextViewContentInsetsKey, [NSValue valueWithUIEdgeInsets:startingTextViewContentInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)startingTextViewScrollIndicatorInsets {
  NSValue *value = objc_getAssociatedObject(self, NEStartingTextViewScrollIndicatorInsetsKey);
  return value ? value.UIEdgeInsetsValue : UIEdgeInsetsZero;
}

- (void)setStartingTextViewScrollIndicatorInsets:(UIEdgeInsets)startingTextViewScrollIndicatorInsets {
  objc_setAssociatedObject(self, NEStartingTextViewScrollIndicatorInsetsKey, [NSValue valueWithUIEdgeInsets:startingTextViewScrollIndicatorInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isTextViewContentInsetChanged {
  return [objc_getAssociatedObject(self, NEIsTextViewContentInsetChangedKey) boolValue];
}

- (void)setIsTextViewContentInsetChanged:(BOOL)isTextViewContentInsetChanged {
  objc_setAssociatedObject(self, NEIsTextViewContentInsetChangedKey, @(isTextViewContentInsetChanged), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)hasPendingAdjustRequest {
  return [objc_getAssociatedObject(self, NEHasPendingAdjustRequestKey) boolValue];
}

- (void)setHasPendingAdjustRequest:(BOOL)hasPendingAdjustRequest {
  objc_setAssociatedObject(self, NEHasPendingAdjustRequestKey, @(hasPendingAdjustRequest), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)optimizedAdjustPosition {
  if (!self.hasPendingAdjustRequest) {
    self.hasPendingAdjustRequest = YES;
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
      [self adjustPosition];
      self.hasPendingAdjustRequest = NO;
    }];
  }
}

- (void)adjustPosition {
  UIView *textFieldView = self.textFieldView;
  UIViewController *rootController = [textFieldView neParentContainerViewController];
  UIWindow *window = [self keyWindow];
  CGRect textFieldViewRectInWindow = CGRectZero;
  CGRect textFieldViewRectInRootSuperview = CGRectZero;
  if (!self.hasPendingAdjustRequest ||
      !textFieldView ||
      !rootController ||
      !window ||
      !textFieldView.superview) {
    return;
  }

  textFieldViewRectInWindow = [textFieldView.superview convertRect:textFieldView.frame toView:window];
  textFieldViewRectInRootSuperview = [textFieldView.superview convertRect:textFieldView.frame toView:rootController.view.superview];

  CFTimeInterval startTime = CACurrentMediaTime();
  [self showLog:@"****** adjustPosition started ******" indentation:1];

  CGPoint rootViewOrigin = rootController.view.frame.origin;
  CGFloat specialKeyboardDistanceFromTextField = textFieldView.neKeyboardDistanceFromTextField;
  UISearchBar *searchBar = [textFieldView neTextFieldSearchBar];
  if (searchBar) {
    specialKeyboardDistanceFromTextField = searchBar.neKeyboardDistanceFromTextField;
  }
  CGFloat newKeyboardDistanceFromTextField = specialKeyboardDistanceFromTextField == kNEUseDefaultKeyboardDistance ? self.keyboardDistanceFromTextField : specialKeyboardDistanceFromTextField;

  CGSize kbSize = self.keyboardFrame.size;
  CGRect kbFrame = self.keyboardFrame;
  kbFrame.origin.y -= newKeyboardDistanceFromTextField;
  kbFrame.size.height += newKeyboardDistanceFromTextField;
  CGRect intersectRect = CGRectIntersection(kbFrame, window.frame);
  kbSize = CGRectIsNull(intersectRect) ? CGSizeMake(CGRectGetWidth(kbFrame), 0) : intersectRect.size;

  CGFloat statusBarHeight = 0;
  if (@available(iOS 13.0, *)) {
    statusBarHeight = window.windowScene.statusBarManager.statusBarFrame.size.height;
  } else {
    statusBarHeight = UIApplication.sharedApplication.statusBarFrame.size.height;
  }

  CGFloat navigationBarAreaHeight = statusBarHeight + rootController.navigationController.navigationBar.frame.size.height;
  CGFloat layoutAreaHeight = rootController.view.layoutMargins.bottom;
  CGFloat topLayoutGuide = MAX(navigationBarAreaHeight, layoutAreaHeight) + 5;
  CGFloat bottomLayoutGuide = NEIsTextViewResponder(textFieldView) ? 0 : rootController.view.layoutMargins.bottom;

  CGFloat move = MIN(CGRectGetMinY(textFieldViewRectInRootSuperview) - topLayoutGuide,
                     CGRectGetMaxY(textFieldViewRectInWindow) - (CGRectGetHeight(window.frame) - kbSize.height) + bottomLayoutGuide);
  [self showLog:[NSString stringWithFormat:@"Need to move: %f", move]];

  UIScrollView *superScrollView = (UIScrollView *)[textFieldView neSuperviewOfClassType:UIScrollView.class];
  UIScrollView *enabledSuperScrollView = nil;
  while (superScrollView) {
    if (superScrollView.isScrollEnabled && !superScrollView.neShouldIgnoreScrollingAdjustment) {
      enabledSuperScrollView = superScrollView;
      break;
    }
    superScrollView = (UIScrollView *)[superScrollView neSuperviewOfClassType:UIScrollView.class];
  }

  if (self.lastScrollView) {
    UIScrollView *lastScrollView = self.lastScrollView;
    if (!enabledSuperScrollView) {
      if (!UIEdgeInsetsEqualToEdgeInsets(lastScrollView.contentInset, self.startingContentInsets)) {
        [self showLog:[NSString stringWithFormat:@"Restoring contentInset to: %@", NSStringFromUIEdgeInsets(self.startingContentInsets)]];
        [UIView animateWithDuration:self.animationDuration delay:0 options:self.animationCurve animations:^{
          lastScrollView.contentInset = self.startingContentInsets;
          lastScrollView.scrollIndicatorInsets = self.startingScrollIndicatorInsets;
        } completion:nil];
      }

      if (lastScrollView.neShouldRestoreScrollViewContentOffset &&
          !CGPointEqualToPoint(lastScrollView.contentOffset, self.startingContentOffset)) {
        [self showLog:[NSString stringWithFormat:@"Restoring contentOffset to: %@", NSStringFromCGPoint(self.startingContentOffset)]];
        BOOL animatedContentOffset = [textFieldView neSuperviewOfClassType:UIStackView.class belowView:lastScrollView] != nil;
        if (animatedContentOffset) {
          [lastScrollView setContentOffset:self.startingContentOffset animated:UIView.areAnimationsEnabled];
        } else {
          lastScrollView.contentOffset = self.startingContentOffset;
        }
      }

      self.startingContentInsets = UIEdgeInsetsZero;
      self.startingScrollIndicatorInsets = UIEdgeInsetsZero;
      self.startingContentOffset = CGPointZero;
      self.lastScrollView = nil;
    } else if (enabledSuperScrollView != lastScrollView) {
      if (!UIEdgeInsetsEqualToEdgeInsets(lastScrollView.contentInset, self.startingContentInsets)) {
        [self showLog:[NSString stringWithFormat:@"Restoring contentInset to: %@", NSStringFromUIEdgeInsets(self.startingContentInsets)]];
        [UIView animateWithDuration:self.animationDuration delay:0 options:self.animationCurve animations:^{
          lastScrollView.contentInset = self.startingContentInsets;
          lastScrollView.scrollIndicatorInsets = self.startingScrollIndicatorInsets;
        } completion:nil];
      }

      if (lastScrollView.neShouldRestoreScrollViewContentOffset &&
          !CGPointEqualToPoint(lastScrollView.contentOffset, self.startingContentOffset)) {
        [self showLog:[NSString stringWithFormat:@"Restoring contentOffset to: %@", NSStringFromCGPoint(self.startingContentOffset)]];
        BOOL animatedContentOffset = [textFieldView neSuperviewOfClassType:UIStackView.class belowView:lastScrollView] != nil;
        if (animatedContentOffset) {
          [lastScrollView setContentOffset:self.startingContentOffset animated:UIView.areAnimationsEnabled];
        } else {
          lastScrollView.contentOffset = self.startingContentOffset;
        }
      }

      self.lastScrollView = enabledSuperScrollView;
      self.startingContentInsets = enabledSuperScrollView.contentInset;
      self.startingContentOffset = enabledSuperScrollView.contentOffset;
      self.startingScrollIndicatorInsets = NECurrentScrollIndicatorInsets(enabledSuperScrollView);
      [self showLog:[NSString stringWithFormat:@"Saving ScrollView New contentInset: %@ and contentOffset: %@", NSStringFromUIEdgeInsets(self.startingContentInsets), NSStringFromCGPoint(self.startingContentOffset)]];
    }
  } else if (enabledSuperScrollView) {
    self.lastScrollView = enabledSuperScrollView;
    self.startingContentInsets = enabledSuperScrollView.contentInset;
    self.startingContentOffset = enabledSuperScrollView.contentOffset;
    self.startingScrollIndicatorInsets = NECurrentScrollIndicatorInsets(enabledSuperScrollView);
    [self showLog:[NSString stringWithFormat:@"Saving ScrollView contentInset: %@ and contentOffset: %@", NSStringFromUIEdgeInsets(self.startingContentInsets), NSStringFromCGPoint(self.startingContentOffset)]];
  }

  if (self.lastScrollView) {
    UIView *lastView = textFieldView;
    UIScrollView *loopScrollView = self.lastScrollView;

    while (loopScrollView) {
      BOOL shouldContinue = NO;
      if (move > 0) {
        shouldContinue = move > (-loopScrollView.contentOffset.y - loopScrollView.contentInset.top);
      } else if ([loopScrollView neSuperviewOfClassType:UITableView.class]) {
        UITableView *tableView = (UITableView *)[loopScrollView neSuperviewOfClassType:UITableView.class];
        shouldContinue = loopScrollView.contentOffset.y > 0;
        if (shouldContinue) {
          UITableViewCell *tableCell = (UITableViewCell *)[textFieldView neSuperviewOfClassType:UITableViewCell.class];
          NSIndexPath *indexPath = [tableView indexPathForCell:tableCell];
          NSIndexPath *previousIndexPath = indexPath ? [tableView nePreviousIndexPathOf:indexPath] : nil;
          if (previousIndexPath) {
            CGRect previousCellRect = [tableView rectForRowAtIndexPath:previousIndexPath];
            if (!CGRectIsEmpty(previousCellRect) && rootController.view.superview) {
              CGRect previousCellRectInRootSuperview = [tableView convertRect:previousCellRect toView:rootController.view.superview];
              move = MIN(0, CGRectGetMaxY(previousCellRectInRootSuperview) - topLayoutGuide);
            }
          }
        }
      } else if ([loopScrollView neSuperviewOfClassType:UICollectionView.class]) {
        UICollectionView *collectionView = (UICollectionView *)[loopScrollView neSuperviewOfClassType:UICollectionView.class];
        shouldContinue = loopScrollView.contentOffset.y > 0;
        if (shouldContinue) {
          UICollectionViewCell *collectionCell = (UICollectionViewCell *)[textFieldView neSuperviewOfClassType:UICollectionViewCell.class];
          NSIndexPath *indexPath = [collectionView indexPathForCell:collectionCell];
          NSIndexPath *previousIndexPath = indexPath ? [collectionView nePreviousIndexPathOf:indexPath] : nil;
          UICollectionViewLayoutAttributes *attributes = previousIndexPath ? [collectionView layoutAttributesForItemAtIndexPath:previousIndexPath] : nil;
          if (attributes && rootController.view.superview) {
            CGRect previousCellRectInRootSuperview = [collectionView convertRect:attributes.frame toView:rootController.view.superview];
            move = MIN(0, CGRectGetMaxY(previousCellRectInRootSuperview) - topLayoutGuide);
          }
        }
      } else {
        shouldContinue = CGRectGetMinY(textFieldViewRectInRootSuperview) < topLayoutGuide;
        if (shouldContinue) {
          move = MIN(0, CGRectGetMinY(textFieldViewRectInRootSuperview) - topLayoutGuide);
        }
      }

      if (shouldContinue) {
        UIScrollView *tempScrollView = (UIScrollView *)[loopScrollView neSuperviewOfClassType:UIScrollView.class];
        UIScrollView *nextScrollView = nil;
        while (tempScrollView) {
          if (tempScrollView.isScrollEnabled && !tempScrollView.neShouldIgnoreScrollingAdjustment) {
            nextScrollView = tempScrollView;
            break;
          }
          tempScrollView = (UIScrollView *)[tempScrollView neSuperviewOfClassType:UIScrollView.class];
        }

        CGRect lastViewRect = [lastView.superview convertRect:lastView.frame toView:loopScrollView];
        CGFloat shouldOffsetY = loopScrollView.contentOffset.y - MIN(loopScrollView.contentOffset.y, -move);
        shouldOffsetY = MIN(shouldOffsetY, CGRectGetMinY(lastViewRect));

        if (NEIsTextViewResponder(textFieldView) &&
            !nextScrollView &&
            shouldOffsetY >= 0) {
          CGRect currentTextFieldViewRect = [textFieldView.superview convertRect:textFieldView.frame toView:window];
          CGFloat expectedFixDistance = CGRectGetMinY(currentTextFieldViewRect) - topLayoutGuide;
          shouldOffsetY = MIN(shouldOffsetY, loopScrollView.contentOffset.y + expectedFixDistance);
          move = 0;
        } else {
          move -= (shouldOffsetY - loopScrollView.contentOffset.y);
        }

        CGPoint newContentOffset = CGPointMake(loopScrollView.contentOffset.x, shouldOffsetY);
        if (!CGPointEqualToPoint(loopScrollView.contentOffset, newContentOffset)) {
          [self showLog:[NSString stringWithFormat:@"old contentOffset: %@ new contentOffset: %@", NSStringFromCGPoint(loopScrollView.contentOffset), NSStringFromCGPoint(newContentOffset)]];
          [self showLog:[NSString stringWithFormat:@"Remaining Move: %f", move]];
          [UIView animateWithDuration:self.animationDuration delay:0 options:self.animationCurve animations:^{
            BOOL animatedContentOffset = [textFieldView neSuperviewOfClassType:UIStackView.class belowView:loopScrollView] != nil;
            if (animatedContentOffset) {
              [loopScrollView setContentOffset:newContentOffset animated:UIView.areAnimationsEnabled];
            } else {
              loopScrollView.contentOffset = newContentOffset;
            }
          } completion:^(__unused BOOL finished) {
            if ([loopScrollView isKindOfClass:[UITableView class]] || [loopScrollView isKindOfClass:[UICollectionView class]]) {
              [self reloadInputViews];
            }
          }];
        }

        lastView = loopScrollView;
        loopScrollView = nextScrollView;
      } else {
        move = 0;
        break;
      }
    }

    CGRect lastScrollViewRect = [self.lastScrollView.superview convertRect:self.lastScrollView.frame toView:window];
    if (!self.lastScrollView.neShouldIgnoreContentInsetAdjustment) {
      CGFloat bottomInset = kbSize.height - (CGRectGetHeight(window.frame) - CGRectGetMaxY(lastScrollViewRect));
      CGFloat bottomScrollIndicatorInset = bottomInset - newKeyboardDistanceFromTextField;
      bottomInset = MAX(self.startingContentInsets.bottom, bottomInset);
      bottomScrollIndicatorInset = MAX(self.startingScrollIndicatorInsets.bottom, bottomScrollIndicatorInset);
      if (@available(iOS 11.0, *)) {
        bottomInset -= self.lastScrollView.safeAreaInsets.bottom;
        bottomScrollIndicatorInset -= self.lastScrollView.safeAreaInsets.bottom;
      }

      UIEdgeInsets movedInsets = self.lastScrollView.contentInset;
      movedInsets.bottom = bottomInset;
      if (!UIEdgeInsetsEqualToEdgeInsets(self.lastScrollView.contentInset, movedInsets)) {
        [self showLog:[NSString stringWithFormat:@"old ContentInset: %@ new ContentInset: %@", NSStringFromUIEdgeInsets(self.lastScrollView.contentInset), NSStringFromUIEdgeInsets(movedInsets)]];
        [UIView animateWithDuration:self.animationDuration delay:0 options:self.animationCurve animations:^{
          self.lastScrollView.contentInset = movedInsets;
          UIEdgeInsets indicatorInsets = NECurrentScrollIndicatorInsets(self.lastScrollView);
          indicatorInsets.bottom = bottomScrollIndicatorInset;
          NESetCurrentScrollIndicatorInsets(self.lastScrollView, indicatorInsets);
        } completion:nil];
      }
    }
  }

  if (NEIsTextViewResponder(textFieldView) && ((UIScrollView *)textFieldView).isScrollEnabled) {
    UIScrollView *textView = (UIScrollView *)textFieldView;
    CGFloat keyboardYPosition = CGRectGetHeight(window.frame) - (kbSize.height - newKeyboardDistanceFromTextField);
    CGRect rootSuperViewFrameInWindow = window.frame;
    if (rootController.view.superview) {
      rootSuperViewFrameInWindow = [rootController.view.superview convertRect:rootController.view.superview.bounds toView:window];
    }

    CGFloat keyboardOverlapping = CGRectGetMaxY(rootSuperViewFrameInWindow) - keyboardYPosition;
    CGFloat textViewHeight = MIN(CGRectGetHeight(textView.frame), CGRectGetHeight(rootSuperViewFrameInWindow) - topLayoutGuide - keyboardOverlapping);
    if (CGRectGetHeight(textView.frame) - textView.contentInset.bottom > textViewHeight) {
      if (!self.isTextViewContentInsetChanged) {
        self.startingTextViewContentInsets = textView.contentInset;
        self.startingTextViewScrollIndicatorInsets = NECurrentScrollIndicatorInsets(textView);
      }

      self.isTextViewContentInsetChanged = YES;
      UIEdgeInsets newContentInset = textView.contentInset;
      newContentInset.bottom = CGRectGetHeight(textView.frame) - textViewHeight;
      if (@available(iOS 11.0, *)) {
        newContentInset.bottom -= textView.safeAreaInsets.bottom;
      }

      if (!UIEdgeInsetsEqualToEdgeInsets(textView.contentInset, newContentInset)) {
        [self showLog:[NSString stringWithFormat:@"%@ Old UITextView.contentInset: %@ New UITextView.contentInset: %@", textFieldView, NSStringFromUIEdgeInsets(textView.contentInset), NSStringFromUIEdgeInsets(newContentInset)]];
        [UIView animateWithDuration:self.animationDuration delay:0 options:self.animationCurve animations:^{
          textView.contentInset = newContentInset;
          textView.scrollIndicatorInsets = newContentInset;
        } completion:nil];
      }
    }
  }

  if (move >= 0) {
    rootViewOrigin.y = MAX(rootViewOrigin.y - move, MIN(0, -(kbSize.height - newKeyboardDistanceFromTextField)));
    if (!CGPointEqualToPoint(rootController.view.frame.origin, rootViewOrigin)) {
      [self showLog:@"Moving Upward"];
      [UIView animateWithDuration:self.animationDuration delay:0 options:self.animationCurve animations:^{
        CGRect rect = rootController.view.frame;
        rect.origin = rootViewOrigin;
        rootController.view.frame = rect;
        if (self.layoutIfNeededOnUpdate) {
          [rootController.view setNeedsLayout];
          [rootController.view layoutIfNeeded];
        }
        [self showLog:[NSString stringWithFormat:@"Set %@ origin to: %@", rootController, NSStringFromCGPoint(rootViewOrigin)]];
      } completion:nil];
    }
    self.movedDistance = self.topViewBeginOrigin.y - rootViewOrigin.y;
  } else {
    CGFloat disturbDistance = rootViewOrigin.y - self.topViewBeginOrigin.y;
    if (disturbDistance <= 0) {
      rootViewOrigin.y -= MAX(move, disturbDistance);
      if (!CGPointEqualToPoint(rootController.view.frame.origin, rootViewOrigin)) {
        [self showLog:@"Moving Downward"];
        [UIView animateWithDuration:self.animationDuration delay:0 options:self.animationCurve animations:^{
          CGRect rect = rootController.view.frame;
          rect.origin = rootViewOrigin;
          rootController.view.frame = rect;
          if (self.layoutIfNeededOnUpdate) {
            [rootController.view setNeedsLayout];
            [rootController.view layoutIfNeeded];
          }
          [self showLog:[NSString stringWithFormat:@"Set %@ origin to: %@", rootController, NSStringFromCGPoint(rootViewOrigin)]];
        } completion:nil];
      }
      self.movedDistance = self.topViewBeginOrigin.y - rootViewOrigin.y;
    }
  }

  CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
  [self showLog:[NSString stringWithFormat:@"****** adjustPosition ended: %f seconds ******", elapsedTime] indentation:-1];
}

- (void)restorePosition {
  self.hasPendingAdjustRequest = NO;
  if (CGPointEqualToPoint(self.topViewBeginOrigin, NEKeyboardManagerCGPointInvalidValue()) ||
      !self.rootViewController) {
    return;
  }

  UIViewController *rootViewController = self.rootViewController;
  if (!CGPointEqualToPoint(rootViewController.view.frame.origin, self.topViewBeginOrigin)) {
    [UIView animateWithDuration:self.animationDuration delay:0 options:self.animationCurve animations:^{
      [self showLog:[NSString stringWithFormat:@"Restoring %@ origin to: %@", rootViewController, NSStringFromCGPoint(self.topViewBeginOrigin)]];
      CGRect rect = rootViewController.view.frame;
      rect.origin = self.topViewBeginOrigin;
      rootViewController.view.frame = rect;
      if (self.layoutIfNeededOnUpdate) {
        [rootViewController.view setNeedsLayout];
        [rootViewController.view layoutIfNeeded];
      }
    } completion:nil];
  }

  self.movedDistance = 0;
  if (rootViewController.navigationController.interactivePopGestureRecognizer.state == UIGestureRecognizerStateBegan) {
    self.rootViewControllerWhilePopGestureRecognizerActive = rootViewController;
    self.topViewBeginOriginWhilePopGestureRecognizerActive = self.topViewBeginOrigin;
  }
  self.rootViewController = nil;
}

@end
