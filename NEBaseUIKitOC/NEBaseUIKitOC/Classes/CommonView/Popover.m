// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "Popover.h"

@interface Popover ()

@property (nonatomic, strong, readwrite) UIControl *blackOverlay;
@property (nonatomic, weak) UIView *containerView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, assign) CGRect originalContentFrame;
@property (nonatomic, assign) CGPoint arrowShowPoint;

@end

@implementation PopoverOption

+ (instancetype)optionWithType:(PopoverOptionType)type value:(id)value {
  PopoverOption *option = [[PopoverOption alloc] init];
  option.type = type;
  option.value = value;
  return option;
}

@end

static UIWindow *NEPopoverKeyWindow(void) {
  if (@available(iOS 13.0, *)) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
      if (![scene isKindOfClass:[UIWindowScene class]]) {
        continue;
      }
      UIWindowScene *windowScene = (UIWindowScene *)scene;
      if (windowScene.activationState != UISceneActivationStateForegroundActive) {
        continue;
      }
      for (UIWindow *window in windowScene.windows) {
        if (window.isKeyWindow) {
          return window;
        }
      }
    }
  }
  return UIApplication.sharedApplication.keyWindow ?: UIApplication.sharedApplication.delegate.window;
}

@implementation Popover

- (instancetype)init {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (instancetype)initWithShowHandler:(void (^)(void))showHandler
                     dismissHandler:(void (^)(void))dismissHandler {
  self = [self init];
  if (self) {
    _didShowHandler = [showHandler copy];
    _didDismissHandler = [dismissHandler copy];
  }
  return self;
}

- (instancetype)initWithOptions:(NSArray<PopoverOption *> *)options
                    showHandler:(void (^)(void))showHandler
                 dismissHandler:(void (^)(void))dismissHandler {
  self = [self init];
  if (self) {
    [self setOptions:options];
    _didShowHandler = [showHandler copy];
    _didDismissHandler = [dismissHandler copy];
  }
  return self;
}

- (void)commonInit {
  self.backgroundColor = UIColor.clearColor;
  self.accessibilityViewIsModal = YES;
  _arrowSize = CGSizeMake(16.0, 10.0);
  _animationIn = 0.6;
  _animationOut = 0.3;
  _cornerRadius = 6.0;
  _sideEdge = 20.0;
  _popoverType = PopoverTypeDown;
  _blackOverlayColor = [UIColor colorWithWhite:0 alpha:0.2];
  _popoverColor = UIColor.whiteColor;
  _dismissOnBlackOverlayTap = YES;
  _showBlackOverlay = YES;
  _highlightFromView = NO;
  _highlightCornerRadius = 0;
  _springDamping = 0.7;
  _initialSpringVelocity = 3.0;
  _sideOffset = 6.0;
  _blackOverlay = [[UIControl alloc] init];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.contentView.frame = self.bounds;
}

- (void)showAsDialog:(UIView *)contentView {
  UIWindow *rootView = NEPopoverKeyWindow();
  if (!rootView) {
    return;
  }
  [self showAsDialog:contentView inView:rootView];
}

- (void)showAsDialog:(UIView *)contentView inView:(UIView *)inView {
  self.arrowSize = CGSizeZero;
  CGPoint point = CGPointMake(CGRectGetMidX(inView.bounds),
                              CGRectGetMidY(inView.bounds) - CGRectGetHeight(contentView.frame) / 2.0);
  [self show:contentView point:point inView:inView];
}

- (void)show:(UIView *)contentView fromView:(UIView *)fromView {
  UIWindow *rootView = NEPopoverKeyWindow();
  if (!rootView) {
    return;
  }
  [self show:contentView fromView:fromView inView:rootView];
}

- (void)show:(UIView *)contentView fromView:(UIView *)fromView inView:(UIView *)inView {
  CGPoint point = CGPointZero;
  if (self.popoverType == PopoverTypeAuto) {
    CGPoint convertedPoint = [fromView.superview convertPoint:fromView.frame.origin toView:nil];
    if (convertedPoint.y + CGRectGetHeight(fromView.frame) + self.arrowSize.height + CGRectGetHeight(contentView.frame) > CGRectGetHeight(inView.frame)) {
      self.popoverType = PopoverTypeUp;
    } else {
      self.popoverType = PopoverTypeDown;
    }
  }

  switch (self.popoverType) {
    case PopoverTypeUp:
      point = [inView convertPoint:CGPointMake(CGRectGetMinX(fromView.frame) + CGRectGetWidth(fromView.frame) / 2.0,
                                               CGRectGetMinY(fromView.frame))
                           fromView:fromView.superview];
      break;
    case PopoverTypeDown:
    case PopoverTypeAuto:
      point = [inView convertPoint:CGPointMake(CGRectGetMinX(fromView.frame) + CGRectGetWidth(fromView.frame) / 2.0,
                                               CGRectGetMaxY(fromView.frame))
                           fromView:fromView.superview];
      break;
    case PopoverTypeLeft:
      point = [inView convertPoint:CGPointMake(CGRectGetMinX(fromView.frame) - self.sideOffset,
                                               CGRectGetMinY(fromView.frame) + CGRectGetHeight(fromView.frame) * 0.5)
                           fromView:fromView.superview];
      break;
    case PopoverTypeRight:
      point = [inView convertPoint:CGPointMake(CGRectGetMaxX(fromView.frame) + self.sideOffset,
                                               CGRectGetMinY(fromView.frame) + CGRectGetHeight(fromView.frame) * 0.5)
                           fromView:fromView.superview];
      break;
  }

  if (self.highlightFromView) {
    [self createHighlightLayerFromView:fromView inView:inView];
  }
  [self show:contentView point:point inView:inView];
}

- (void)show:(UIView *)contentView point:(CGPoint)point {
  UIWindow *rootView = NEPopoverKeyWindow();
  if (!rootView) {
    return;
  }
  [self show:contentView point:point inView:rootView];
}

- (void)show:(UIView *)contentView point:(CGPoint)point inView:(UIView *)inView {
  self.originalContentFrame = contentView.frame;

  if (self.dismissOnBlackOverlayTap || self.showBlackOverlay) {
    self.blackOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.blackOverlay.frame = inView.bounds;
    [inView addSubview:self.blackOverlay];

    if (self.showBlackOverlay) {
      if (self.overlayBlur) {
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:self.overlayBlur];
        effectView.frame = self.blackOverlay.bounds;
        effectView.userInteractionEnabled = NO;
        [self.blackOverlay addSubview:effectView];
      } else {
        if (!self.highlightFromView) {
          self.blackOverlay.backgroundColor = self.blackOverlayColor;
        }
        self.blackOverlay.alpha = 0;
      }
    }

    if (self.dismissOnBlackOverlayTap) {
      [self.blackOverlay addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    }
  }

  self.containerView = inView;
  self.contentView = contentView;
  self.contentView.backgroundColor = UIColor.clearColor;
  self.contentView.layer.cornerRadius = self.cornerRadius;
  self.contentView.layer.masksToBounds = YES;
  self.arrowShowPoint = point;
  [self showInternal];
}

- (BOOL)accessibilityPerformEscape {
  [self dismiss];
  return YES;
}

- (void)dismiss {
  if (!self.superview) {
    return;
  }

  if (self.willDismissHandler) {
    self.willDismissHandler();
  }

  [UIView animateWithDuration:self.animationOut
                        delay:0
                      options:0
                   animations:^{
                     self.transform = CGAffineTransformMakeScale(0.0001, 0.0001);
                     self.blackOverlay.alpha = 0;
                   }
                   completion:^(__unused BOOL finished) {
                     [self.contentView removeFromSuperview];
                     [self.blackOverlay removeFromSuperview];
                     [self removeFromSuperview];
                     self.transform = CGAffineTransformIdentity;
                     self.contentView.frame = self.originalContentFrame;
                     if (self.didDismissHandler) {
                       self.didDismissHandler();
                     }
                   }];
}

- (void)drawRect:(CGRect)rect {
  [super drawRect:rect];
  if (!self.containerView) {
    return;
  }

  UIBezierPath *arrow = [UIBezierPath bezierPath];
  CGPoint arrowPoint = [self.containerView convertPoint:self.arrowShowPoint toView:self];

  switch (self.popoverType) {
    case PopoverTypeUp: {
      [arrow moveToPoint:CGPointMake(arrowPoint.x, CGRectGetHeight(self.bounds))];
      [arrow addLineToPoint:CGPointMake(arrowPoint.x - self.arrowSize.width * 0.5,
                                        self.isCornerLeftArrow ? self.arrowSize.height : CGRectGetHeight(self.bounds) - self.arrowSize.height)];
      [arrow addLineToPoint:CGPointMake(self.cornerRadius, CGRectGetHeight(self.bounds) - self.arrowSize.height)];
      [arrow addArcWithCenter:CGPointMake(self.cornerRadius,
                                          CGRectGetHeight(self.bounds) - self.arrowSize.height - self.cornerRadius)
                       radius:self.cornerRadius
                   startAngle:[self radians:90]
                     endAngle:[self radians:180]
                    clockwise:YES];
      [arrow addLineToPoint:CGPointMake(0, self.cornerRadius)];
      [arrow addArcWithCenter:CGPointMake(self.cornerRadius, self.cornerRadius)
                       radius:self.cornerRadius
                   startAngle:[self radians:180]
                     endAngle:[self radians:270]
                    clockwise:YES];
      [arrow addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds) - self.cornerRadius, 0)];
      [arrow addArcWithCenter:CGPointMake(CGRectGetWidth(self.bounds) - self.cornerRadius, self.cornerRadius)
                       radius:self.cornerRadius
                   startAngle:[self radians:270]
                     endAngle:[self radians:0]
                    clockwise:YES];
      [arrow addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds),
                                        CGRectGetHeight(self.bounds) - self.arrowSize.height - self.cornerRadius)];
      [arrow addArcWithCenter:CGPointMake(CGRectGetWidth(self.bounds) - self.cornerRadius,
                                          CGRectGetHeight(self.bounds) - self.arrowSize.height - self.cornerRadius)
                       radius:self.cornerRadius
                   startAngle:[self radians:0]
                     endAngle:[self radians:90]
                    clockwise:YES];
      [arrow addLineToPoint:CGPointMake(arrowPoint.x + self.arrowSize.width * 0.5,
                                        self.isCornerRightArrow ? self.arrowSize.height : CGRectGetHeight(self.bounds) - self.arrowSize.height)];
      break;
    }
    case PopoverTypeDown:
    case PopoverTypeAuto: {
      [arrow moveToPoint:CGPointMake(arrowPoint.x, 0)];

      if (self.isCloseToCornerRightArrow && !self.isCornerRightArrow) {
        if (!self.isBehindCornerRightArrow) {
          [arrow addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds) - self.cornerRadius, self.arrowSize.height)];
          [arrow addArcWithCenter:CGPointMake(CGRectGetWidth(self.bounds) - self.cornerRadius,
                                              self.arrowSize.height + self.cornerRadius)
                           radius:self.cornerRadius
                       startAngle:[self radians:270]
                         endAngle:[self radians:0]
                        clockwise:YES];
        } else {
          [arrow addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds), self.arrowSize.height + self.cornerRadius)];
          [arrow addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds), self.arrowSize.height)];
        }
      } else {
        [arrow addLineToPoint:CGPointMake(self.isBehindCornerLeftArrow ? CGRectGetMinX(self.frame) - self.arrowSize.width * 0.5 : arrowPoint.x + self.arrowSize.width * 0.5,
                                          self.isCornerRightArrow ? self.arrowSize.height + CGRectGetHeight(self.bounds) : self.arrowSize.height)];
        [arrow addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds) - self.cornerRadius, self.arrowSize.height)];
        [arrow addArcWithCenter:CGPointMake(CGRectGetWidth(self.bounds) - self.cornerRadius,
                                            self.arrowSize.height + self.cornerRadius)
                         radius:self.cornerRadius
                     startAngle:[self radians:270]
                       endAngle:[self radians:0]
                      clockwise:YES];
      }

      [arrow addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - self.cornerRadius)];
      [arrow addArcWithCenter:CGPointMake(CGRectGetWidth(self.bounds) - self.cornerRadius,
                                          CGRectGetHeight(self.bounds) - self.cornerRadius)
                       radius:self.cornerRadius
                   startAngle:[self radians:0]
                     endAngle:[self radians:90]
                    clockwise:YES];
      [arrow addLineToPoint:CGPointMake(0, CGRectGetHeight(self.bounds))];
      [arrow addArcWithCenter:CGPointMake(self.cornerRadius,
                                          CGRectGetHeight(self.bounds) - self.cornerRadius)
                       radius:self.cornerRadius
                   startAngle:[self radians:90]
                     endAngle:[self radians:180]
                    clockwise:YES];
      [arrow addLineToPoint:CGPointMake(0, self.arrowSize.height + self.cornerRadius)];

      if (!self.isBehindCornerLeftArrow) {
        [arrow addArcWithCenter:CGPointMake(self.cornerRadius,
                                            self.arrowSize.height + self.cornerRadius)
                         radius:self.cornerRadius
                     startAngle:[self radians:180]
                       endAngle:[self radians:270]
                      clockwise:YES];
      }

      if (self.isBehindCornerRightArrow) {
        [arrow addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds) - self.arrowSize.width * 0.5,
                                          self.isCornerLeftArrow ? self.arrowSize.height + CGRectGetHeight(self.bounds) : self.arrowSize.height)];
      } else if (!(self.isCloseToCornerLeftArrow && !self.isCornerLeftArrow)) {
        [arrow addLineToPoint:CGPointMake(arrowPoint.x - self.arrowSize.width * 0.5,
                                          self.isCornerLeftArrow ? self.arrowSize.height + CGRectGetHeight(self.bounds) : self.arrowSize.height)];
      }
      break;
    }
    case PopoverTypeLeft: {
      [arrow moveToPoint:CGPointMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) * 0.5)];
      [arrow addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds) - self.arrowSize.height,
                                        CGRectGetHeight(self.bounds) * 0.5 + self.arrowSize.width * 0.5)];
      [arrow addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds) - self.arrowSize.height,
                                        CGRectGetHeight(self.bounds) - self.cornerRadius)];
      [arrow addArcWithCenter:CGPointMake(CGRectGetWidth(self.bounds) - self.arrowSize.height - self.cornerRadius,
                                          CGRectGetHeight(self.bounds) - self.cornerRadius)
                       radius:self.cornerRadius
                   startAngle:[self radians:0]
                     endAngle:[self radians:90]
                    clockwise:YES];
      [arrow addLineToPoint:CGPointMake(self.cornerRadius, CGRectGetHeight(self.bounds))];
      [arrow addArcWithCenter:CGPointMake(self.cornerRadius,
                                          CGRectGetHeight(self.bounds) - self.cornerRadius)
                       radius:self.cornerRadius
                   startAngle:[self radians:90]
                     endAngle:[self radians:180]
                    clockwise:YES];
      [arrow addLineToPoint:CGPointMake(0, self.cornerRadius)];
      [arrow addArcWithCenter:CGPointMake(self.cornerRadius, self.cornerRadius)
                       radius:self.cornerRadius
                   startAngle:[self radians:180]
                     endAngle:[self radians:270]
                    clockwise:YES];
      [arrow addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds) - self.arrowSize.height - self.cornerRadius, 0)];
      [arrow addArcWithCenter:CGPointMake(CGRectGetWidth(self.bounds) - self.arrowSize.height - self.cornerRadius,
                                          self.cornerRadius)
                       radius:self.cornerRadius
                   startAngle:[self radians:270]
                     endAngle:[self radians:0]
                    clockwise:YES];
      [arrow addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds) - self.arrowSize.height,
                                        CGRectGetHeight(self.bounds) * 0.5 - self.arrowSize.width * 0.5)];
      break;
    }
    case PopoverTypeRight: {
      [arrow moveToPoint:CGPointMake(arrowPoint.x, CGRectGetHeight(self.bounds) * 0.5)];
      [arrow addLineToPoint:CGPointMake(arrowPoint.x + self.arrowSize.height,
                                        CGRectGetHeight(self.bounds) * 0.5 + self.arrowSize.width * 0.5)];
      [arrow addLineToPoint:CGPointMake(arrowPoint.x + self.arrowSize.height,
                                        CGRectGetHeight(self.bounds) - self.cornerRadius)];
      [arrow addArcWithCenter:CGPointMake(arrowPoint.x + self.arrowSize.height + self.cornerRadius,
                                          CGRectGetHeight(self.bounds) - self.cornerRadius)
                       radius:self.cornerRadius
                   startAngle:[self radians:180]
                     endAngle:[self radians:90]
                    clockwise:NO];
      [arrow addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds) + arrowPoint.x - self.cornerRadius,
                                        CGRectGetHeight(self.bounds))];
      [arrow addArcWithCenter:CGPointMake(CGRectGetWidth(self.bounds) + arrowPoint.x - self.cornerRadius,
                                          CGRectGetHeight(self.bounds) - self.cornerRadius)
                       radius:self.cornerRadius
                   startAngle:[self radians:90]
                     endAngle:[self radians:0]
                    clockwise:NO];
      [arrow addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds) + arrowPoint.x, self.cornerRadius)];
      [arrow addArcWithCenter:CGPointMake(CGRectGetWidth(self.bounds) + arrowPoint.x - self.cornerRadius,
                                          self.cornerRadius)
                       radius:self.cornerRadius
                   startAngle:[self radians:0]
                     endAngle:-[self radians:90]
                    clockwise:NO];
      [arrow addLineToPoint:CGPointMake(arrowPoint.x + self.arrowSize.height - self.cornerRadius, 0)];
      [arrow addArcWithCenter:CGPointMake(arrowPoint.x + self.arrowSize.height + self.cornerRadius,
                                          self.cornerRadius)
                       radius:self.cornerRadius
                   startAngle:-[self radians:90]
                     endAngle:-[self radians:180]
                    clockwise:NO];
      [arrow addLineToPoint:CGPointMake(arrowPoint.x + self.arrowSize.height,
                                        CGRectGetHeight(self.bounds) * 0.5 - self.arrowSize.width * 0.5)];
      break;
    }
  }

  [self.popoverColor setFill];
  [arrow fill];
  if (self.borderColor) {
    [self.borderColor setStroke];
    [arrow stroke];
  }
}

- (void)setOptions:(NSArray<PopoverOption *> *)options {
  for (PopoverOption *option in options) {
    switch (option.type) {
      case PopoverOptionTypeArrowSize:
        self.arrowSize = [option.value CGSizeValue];
        break;
      case PopoverOptionTypeAnimationIn:
        self.animationIn = [option.value doubleValue];
        break;
      case PopoverOptionTypeAnimationOut:
        self.animationOut = [option.value doubleValue];
        break;
      case PopoverOptionTypeCornerRadius:
        self.cornerRadius = [option.value doubleValue];
        break;
      case PopoverOptionTypeSideEdge:
        self.sideEdge = [option.value doubleValue];
        break;
      case PopoverOptionTypeBlackOverlayColor:
        self.blackOverlayColor = option.value;
        break;
      case PopoverOptionTypeOverlayBlur:
        self.overlayBlur = [UIBlurEffect effectWithStyle:[option.value integerValue]];
        break;
      case PopoverOptionTypeType:
        self.popoverType = [option.value integerValue];
        break;
      case PopoverOptionTypeColor:
        self.popoverColor = option.value;
        break;
      case PopoverOptionTypeDismissOnBlackOverlayTap:
        self.dismissOnBlackOverlayTap = [option.value boolValue];
        break;
      case PopoverOptionTypeShowBlackOverlay:
        self.showBlackOverlay = [option.value boolValue];
        break;
      case PopoverOptionTypeSpringDamping:
        self.springDamping = [option.value doubleValue];
        break;
      case PopoverOptionTypeInitialSpringVelocity:
        self.initialSpringVelocity = [option.value doubleValue];
        break;
      case PopoverOptionTypeSideOffset:
        self.sideOffset = [option.value doubleValue];
        break;
      case PopoverOptionTypeBorderColor:
        self.borderColor = option.value;
        break;
    }
  }
}

- (void)create {
  if (!self.containerView) {
    return;
  }

  CGRect frame = self.contentView.frame;
  switch (self.popoverType) {
    case PopoverTypeUp:
    case PopoverTypeDown:
    case PopoverTypeAuto:
      frame.origin.x = self.arrowShowPoint.x - frame.size.width * 0.5;
      break;
    case PopoverTypeLeft:
    case PopoverTypeRight:
      frame.origin.y = self.arrowShowPoint.y - frame.size.height * 0.5;
      break;
  }

  CGFloat sideEdge = 0;
  if (frame.size.width < CGRectGetWidth(self.containerView.frame)) {
    sideEdge = self.sideEdge;
  }
  CGFloat outerSideEdge = CGRectGetMaxX(frame) - CGRectGetWidth(self.containerView.bounds);
  if (outerSideEdge > 0) {
    frame.origin.x -= (outerSideEdge + sideEdge);
  } else if (CGRectGetMinX(frame) < 0) {
    frame.origin.x += fabs(CGRectGetMinX(frame)) + sideEdge;
  }

  self.frame = frame;
  CGPoint arrowPoint = [self.containerView convertPoint:self.arrowShowPoint toView:self];
  CGPoint anchorPoint = CGPointZero;

  switch (self.popoverType) {
    case PopoverTypeUp:
      frame.origin.y = self.arrowShowPoint.y - frame.size.height - self.arrowSize.height;
      anchorPoint = CGPointMake(arrowPoint.x / frame.size.width, 1);
      break;
    case PopoverTypeDown:
    case PopoverTypeAuto:
      frame.origin.y = self.arrowShowPoint.y;
      anchorPoint = CGPointMake(arrowPoint.x / frame.size.width, 0);
      break;
    case PopoverTypeLeft:
      frame.origin.x = self.arrowShowPoint.x - frame.size.width - self.arrowSize.height;
      anchorPoint = CGPointMake(1, 0.5);
      break;
    case PopoverTypeRight:
      frame.origin.x = self.arrowShowPoint.x;
      anchorPoint = CGPointMake(0, 0.5);
      break;
  }

  if (CGSizeEqualToSize(self.arrowSize, CGSizeZero)) {
    anchorPoint = CGPointMake(0.5, 0.5);
  }

  CGPoint lastAnchor = self.layer.anchorPoint;
  self.layer.anchorPoint = anchorPoint;
  CGFloat positionX = self.layer.position.x + (anchorPoint.x - lastAnchor.x) * CGRectGetWidth(self.layer.bounds);
  CGFloat positionY = self.layer.position.y + (anchorPoint.y - lastAnchor.y) * CGRectGetHeight(self.layer.bounds);
  self.layer.position = CGPointMake(positionX, positionY);

  switch (self.popoverType) {
    case PopoverTypeUp:
    case PopoverTypeDown:
    case PopoverTypeAuto:
      frame.size.height += self.arrowSize.height;
      break;
    case PopoverTypeLeft:
    case PopoverTypeRight:
      frame.size.width += self.arrowSize.height;
      break;
  }

  self.frame = frame;
}

- (void)createHighlightLayerFromView:(UIView *)fromView inView:(UIView *)inView {
  UIBezierPath *path = [UIBezierPath bezierPathWithRect:inView.bounds];
  CGRect highlightRect = [inView convertRect:fromView.frame fromView:fromView.superview];
  UIBezierPath *highlightPath = [UIBezierPath bezierPathWithRoundedRect:highlightRect
                                                           cornerRadius:self.highlightCornerRadius];
  [path appendPath:highlightPath];
  path.usesEvenOddFillRule = YES;

  CAShapeLayer *fillLayer = [CAShapeLayer layer];
  fillLayer.path = path.CGPath;
  fillLayer.fillRule = kCAFillRuleEvenOdd;
  fillLayer.fillColor = self.blackOverlayColor.CGColor;
  [self.blackOverlay.layer addSublayer:fillLayer];
}

- (void)showInternal {
  if (!self.containerView) {
    return;
  }

  [self setNeedsDisplay];
  CGRect frame = self.contentView.frame;
  switch (self.popoverType) {
    case PopoverTypeUp:
      frame.origin.y = 0;
      break;
    case PopoverTypeDown:
    case PopoverTypeAuto:
      frame.origin.y = self.arrowSize.height;
      break;
    case PopoverTypeLeft:
    case PopoverTypeRight:
      frame.origin.x = 0;
      break;
  }
  self.contentView.frame = frame;

  [self addSubview:self.contentView];
  [self.containerView addSubview:self];
  [self create];

  self.transform = CGAffineTransformMakeScale(0, 0);
  if (self.willShowHandler) {
    self.willShowHandler();
  }

  [UIView animateWithDuration:self.animationIn
                        delay:0
       usingSpringWithDamping:self.springDamping
        initialSpringVelocity:self.initialSpringVelocity
                      options:0
                   animations:^{
                     self.transform = CGAffineTransformIdentity;
                   }
                   completion:^(__unused BOOL finished) {
                     if (self.didShowHandler) {
                       self.didShowHandler();
                     }
                   }];

  [UIView animateWithDuration:self.animationIn / 3.0
                        delay:0
                      options:UIViewAnimationOptionCurveLinear
                   animations:^{
                     self.blackOverlay.alpha = 1;
                   }
                   completion:nil];
}

- (BOOL)isCloseToCornerLeftArrow {
  return self.arrowShowPoint.x < CGRectGetMinX(self.frame) + self.arrowSize.width / 2.0 + self.cornerRadius;
}

- (BOOL)isCloseToCornerRightArrow {
  return self.arrowShowPoint.x > CGRectGetMinX(self.frame) + CGRectGetWidth(self.bounds) - self.arrowSize.width / 2.0 - self.cornerRadius;
}

- (BOOL)isCornerLeftArrow {
  return self.arrowShowPoint.x == CGRectGetMinX(self.frame);
}

- (BOOL)isCornerRightArrow {
  return self.arrowShowPoint.x == CGRectGetMinX(self.frame) + CGRectGetWidth(self.bounds);
}

- (BOOL)isBehindCornerLeftArrow {
  return self.arrowShowPoint.x < CGRectGetMinX(self.frame);
}

- (BOOL)isBehindCornerRightArrow {
  return self.arrowShowPoint.x > CGRectGetMinX(self.frame) + CGRectGetWidth(self.bounds);
}

- (CGFloat)radians:(CGFloat)degrees {
  return M_PI * degrees / 180.0;
}

@end
