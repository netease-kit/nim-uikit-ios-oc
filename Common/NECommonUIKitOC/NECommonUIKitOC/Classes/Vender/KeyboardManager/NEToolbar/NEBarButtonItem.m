// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBarButtonItem.h"
#import "NEInvocation.h"

static void NEBarButtonItemClassInitialize(void) {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NEBarButtonItem *appearance = [NEBarButtonItem appearance];
    NSArray<NSNumber *> *states = @[
      @(UIControlStateNormal),
      @(UIControlStateHighlighted),
      @(UIControlStateDisabled),
      @(UIControlStateSelected),
      @(UIControlStateApplication),
      @(UIControlStateReserved)
    ];

    for (NSNumber *stateNumber in states) {
      UIControlState state = stateNumber.unsignedIntegerValue;
      [appearance setBackgroundImage:nil forState:state barMetrics:UIBarMetricsDefault];
      [appearance setBackgroundImage:nil forState:state style:UIBarButtonItemStyleDone barMetrics:UIBarMetricsDefault];
      [appearance setBackgroundImage:nil forState:state style:UIBarButtonItemStylePlain barMetrics:UIBarMetricsDefault];
      [appearance setBackButtonBackgroundImage:nil forState:state barMetrics:UIBarMetricsDefault];
    }

    [appearance setTitlePositionAdjustment:UIOffsetZero forBarMetrics:UIBarMetricsDefault];
    [appearance setBackgroundVerticalPositionAdjustment:0 forBarMetrics:UIBarMetricsDefault];
    [appearance setBackButtonBackgroundVerticalPositionAdjustment:0 forBarMetrics:UIBarMetricsDefault];
  });
}

@implementation NEBarButtonItem

- (instancetype)init {
  NEBarButtonItemClassInitialize();
  self = [super init];
  if (self) {
    _isSystemItem = NO;
  }
  return self;
}

- (instancetype)initWithBarButtonSystemItem:(UIBarButtonSystemItem)systemItem target:(id)target action:(SEL)action {
  NEBarButtonItemClassInitialize();
  self = [super initWithBarButtonSystemItem:systemItem target:target action:action];
  if (self) {
    _isSystemItem = NO;
  }
  return self;
}

- (instancetype)initWithImage:(UIImage *)image style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
  NEBarButtonItemClassInitialize();
  self = [super initWithImage:image style:style target:target action:action];
  if (self) {
    _isSystemItem = NO;
  }
  return self;
}

- (instancetype)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
  NEBarButtonItemClassInitialize();
  self = [super initWithTitle:title style:style target:target action:action];
  if (self) {
    _isSystemItem = NO;
  }
  return self;
}

- (instancetype)initWithCustomView:(UIView *)customView {
  NEBarButtonItemClassInitialize();
  self = [super initWithCustomView:customView];
  if (self) {
    _isSystemItem = NO;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  NEBarButtonItemClassInitialize();
  self = [super initWithCoder:coder];
  if (self) {
    _isSystemItem = NO;
  }
  return self;
}

- (void)setTintColor:(UIColor *)tintColor {
  [super setTintColor:tintColor];

  NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionary];
  if (tintColor) {
    attributes[NSForegroundColorAttributeName] = tintColor;
  }
  NSDictionary<NSAttributedStringKey, id> *existing = [self titleTextAttributesForState:UIControlStateNormal];
  if (existing.count) {
    [attributes addEntriesFromDictionary:existing];
  }
  [self setTitleTextAttributes:attributes forState:UIControlStateNormal];
}

- (void)setTarget:(id)target action:(SEL)action {
  if (target && action) {
    self.invocation = [[NEInvocation alloc] initWithTarget:target action:action];
  } else {
    self.invocation = nil;
  }
}

- (void)dealloc {
  self.target = nil;
  self.invocation = nil;
}

@end
