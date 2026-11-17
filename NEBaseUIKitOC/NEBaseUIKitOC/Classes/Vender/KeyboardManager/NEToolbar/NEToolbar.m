// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#define NEBASEUIKITOC_INTERNAL 1
#import "NEToolbar.h"
#undef NEBASEUIKITOC_INTERNAL

static void NEToolbarClassInitialize(void) {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NEToolbar *appearance = [NEToolbar appearance];
    for (NSNumber *position in @[ @(UIBarPositionAny), @(UIBarPositionBottom), @(UIBarPositionTop), @(UIBarPositionTopAttached) ]) {
      [appearance setBackgroundImage:nil
                  forToolbarPosition:position.integerValue
                          barMetrics:UIBarMetricsDefault];
      [appearance setShadowImage:nil forToolbarPosition:UIBarPositionAny];
    }
    appearance.barTintColor = nil;
    appearance.backgroundColor = nil;
  });
}

@implementation NEToolbar

- (instancetype)initWithFrame:(CGRect)frame {
  NEToolbarClassInitialize();
  self = [super initWithFrame:frame];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  NEToolbarClassInitialize();
  self = [super initWithCoder:coder];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (void)commonInit {
  [self sizeToFit];
  self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.translucent = YES;
}

- (CGSize)sizeThatFits:(CGSize)size {
  CGSize fitted = [super sizeThatFits:size];
  fitted.height = 44.0;
  return fitted;
}

- (void)setTintColor:(UIColor *)tintColor {
  [super setTintColor:tintColor];
  for (UIBarButtonItem *item in self.items) {
    item.tintColor = tintColor;
  }
}

- (void)layoutSubviews {
  [super layoutSubviews];

  if (@available(iOS 11.0, *)) {
    return;
  }

  UIView *customTitleView = self.titleBarButton.customView;
  if (!customTitleView) {
    return;
  }

  CGRect leftRect = CGRectNull;
  CGRect rightRect = CGRectNull;
  BOOL foundTitleBarButton = NO;

  NSArray<UIView *> *sortedSubviews = [self.subviews sortedArrayUsingComparator:^NSComparisonResult(UIView *view1, UIView *view2) {
    if (CGRectGetMinX(view1.frame) != CGRectGetMinX(view2.frame)) {
      return CGRectGetMinX(view1.frame) < CGRectGetMinX(view2.frame) ? NSOrderedAscending : NSOrderedDescending;
    }
    if (CGRectGetMinY(view1.frame) != CGRectGetMinY(view2.frame)) {
      return CGRectGetMinY(view1.frame) < CGRectGetMinY(view2.frame) ? NSOrderedAscending : NSOrderedDescending;
    }
    return NSOrderedSame;
  }];

  for (UIView *barButtonItemView in sortedSubviews) {
    if (foundTitleBarButton) {
      rightRect = barButtonItemView.frame;
      break;
    } else if (barButtonItemView == customTitleView) {
      foundTitleBarButton = YES;
    } else if ([barButtonItemView isKindOfClass:UIControl.class]) {
      leftRect = barButtonItemView.frame;
    }
  }

  CGFloat titleMargin = 16.0;
  CGFloat maxWidth = CGRectGetWidth(self.frame) - titleMargin * 2 -
                     (CGRectIsNull(leftRect) ? 0.0 : CGRectGetMaxX(leftRect)) -
                     (CGRectIsNull(rightRect) ? 0.0 : CGRectGetWidth(self.frame) - CGRectGetMinX(rightRect));
  CGFloat maxHeight = CGRectGetHeight(self.frame);
  CGSize fittingSize = [customTitleView sizeThatFits:CGSizeMake(maxWidth, maxHeight)];
  CGRect titleRect = CGRectZero;

  if (fittingSize.width > 0.0 && fittingSize.height > 0.0) {
    CGFloat width = MIN(fittingSize.width, maxWidth);
    CGFloat height = MIN(fittingSize.height, maxHeight);
    CGFloat xPosition = CGRectIsNull(leftRect)
                            ? titleMargin
                            : titleMargin + CGRectGetMaxX(leftRect) + ((maxWidth - width) / 2.0);
    CGFloat yPosition = (maxHeight - height) / 2.0;
    titleRect = CGRectMake(xPosition, yPosition, width, height);
  } else {
    CGFloat xPosition = CGRectIsNull(leftRect) ? titleMargin : titleMargin + CGRectGetMaxX(leftRect);
    CGFloat width = CGRectGetWidth(self.frame) - titleMargin * 2 -
                    (CGRectIsNull(leftRect) ? 0.0 : CGRectGetMaxX(leftRect)) -
                    (CGRectIsNull(rightRect) ? 0.0 : CGRectGetWidth(self.frame) - CGRectGetMinX(rightRect));
    titleRect = CGRectMake(xPosition, 0.0, width, maxHeight);
  }

  customTitleView.frame = titleRect;
}

- (BOOL)enableInputClicksWhenVisible {
  return YES;
}

- (NEBarButtonItem *)previousBarButton {
  if (!_previousBarButton) {
    _previousBarButton = [[NEBarButtonItem alloc] initWithImage:nil style:UIBarButtonItemStylePlain target:nil action:nil];
  }
  return _previousBarButton;
}

- (NEBarButtonItem *)nextBarButton {
  if (!_nextBarButton) {
    _nextBarButton = [[NEBarButtonItem alloc] initWithImage:nil style:UIBarButtonItemStylePlain target:nil action:nil];
  }
  return _nextBarButton;
}

- (NETitleBarButtonItem *)titleBarButton {
  if (!_titleBarButton) {
    _titleBarButton = [[NETitleBarButtonItem alloc] initWithTitle:nil];
    _titleBarButton.accessibilityLabel = @"Title";
    _titleBarButton.accessibilityIdentifier = _titleBarButton.accessibilityLabel;
  }
  return _titleBarButton;
}

- (NEBarButtonItem *)doneBarButton {
  if (!_doneBarButton) {
    _doneBarButton = [[NEBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStyleDone target:nil action:nil];
  }
  return _doneBarButton;
}

- (NEBarButtonItem *)fixedSpaceBarButton {
  if (!_fixedSpaceBarButton) {
    _fixedSpaceBarButton = [[NEBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    _fixedSpaceBarButton.isSystemItem = YES;
  }
  if (@available(iOS 10.0, *)) {
    _fixedSpaceBarButton.width = 6.0;
  } else {
    _fixedSpaceBarButton.width = 20.0;
  }
  return _fixedSpaceBarButton;
}

- (void)dealloc {
  self.items = nil;
  _previousBarButton = nil;
  _nextBarButton = nil;
  _titleBarButton = nil;
  _doneBarButton = nil;
  _fixedSpaceBarButton = nil;
}

@end
