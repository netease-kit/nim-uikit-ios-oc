// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NECustomActionSheetController.h"

@interface NECustomAlertAction ()
@property (nonatomic, assign) CornerType cornerTypeInternal;
@property (nonatomic, strong) CAShapeLayer *cornerLayer;
@end

@implementation NECustomAlertAction

- (instancetype)initWithTitle:(nullable NSString *)title completion:(nullable void (^)(void))completion {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _fillColor = UIColor.whiteColor;
    _edgeInset = UIEdgeInsetsZero;
    _cornerTypeInternal = CornerTypeNone;

    _cornerLayer = [CAShapeLayer layer];
    [self.layer insertSublayer:_cornerLayer atIndex:0];

    _dividerLine = [[UIView alloc] init];
    _dividerLine.translatesAutoresizingMaskIntoConstraints = NO;
    _dividerLine.backgroundColor = [UIColor colorWithRed:0xED/255.0 green:0xED/255.0 blue:0xED/255.0 alpha:1];
    _dividerLine.hidden = NO;
    [self addSubview:_dividerLine];

    _dividerLineLeftMargin = [_dividerLine.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:0];
    _dividerLineRightMargin = [_dividerLine.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:0];
    [NSLayoutConstraint activateConstraints:@[
      _dividerLineLeftMargin,
      _dividerLineRightMargin,
      [_dividerLine.heightAnchor constraintEqualToConstant:1],
      [_dividerLine.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    self.backgroundColor = UIColor.clearColor;

    _contentText = [[UILabel alloc] init];
    _contentText.translatesAutoresizingMaskIntoConstraints = NO;
    _contentText.textAlignment = NSTextAlignmentCenter;
    _contentText.font = [UIFont systemFontOfSize:16];
    _contentText.textColor = [UIColor colorWithRed:0x33/255.0 green:0x33/255.0 blue:0x33/255.0 alpha:1];
    _contentText.text = title;
    [self addSubview:_contentText];

    [NSLayoutConstraint activateConstraints:@[
      [_contentText.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:16],
      [_contentText.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-16],
      [_contentText.topAnchor constraintEqualToAnchor:self.topAnchor],
      [_contentText.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    _clickAction = completion;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewTap:)];
    [self addGestureRecognizer:tap];
  }
  return self;
}

+ (instancetype)actionWithTitle:(nullable NSString *)title handler:(nullable void (^)(void))handler {
  return [[self alloc] initWithTitle:title completion:handler];
}

- (void)setCornerType:(CornerType)cornerType {
  if (_cornerTypeInternal != cornerType) {
    _cornerTypeInternal = cornerType;
    [self setNeedsDisplay];
  }
}

- (CornerType)cornerType {
  return _cornerTypeInternal;
}

- (void)drawRect:(CGRect)rect {
  [self drawRoundedCornerInRect:rect];
}

- (void)drawRoundedCornerInRect:(CGRect)rect {
  CGRect roundRect = CGRectMake(rect.origin.x + _edgeInset.left,
                                rect.origin.y + _edgeInset.top,
                                rect.size.width - (_edgeInset.left + _edgeInset.right),
                                rect.size.height - (_edgeInset.top + _edgeInset.bottom));
  UIRectCorner corners = 0;
  if (_cornerTypeInternal & CornerTypeTopLeft)     corners |= UIRectCornerTopLeft;
  if (_cornerTypeInternal & CornerTypeTopRight)    corners |= UIRectCornerTopRight;
  if (_cornerTypeInternal & CornerTypeBottomLeft)  corners |= UIRectCornerBottomLeft;
  if (_cornerTypeInternal & CornerTypeBottomRight) corners |= UIRectCornerBottomRight;

  UIBezierPath *path;
  if (corners == 0) {
    path = [UIBezierPath bezierPathWithRect:roundRect];
  } else {
    path = [UIBezierPath bezierPathWithRoundedRect:roundRect
                                 byRoundingCorners:corners
                                       cornerRadii:CGSizeMake(10, 10)];
  }
  _cornerLayer.path = path.CGPath;
  _cornerLayer.fillColor = _fillColor.CGColor;
}

- (void)handleViewTap:(UITapGestureRecognizer *)sender {
  if (_cancelAction) _cancelAction();
  if (_clickAction)  _clickAction();
}

@end

// -----------------------------------------------

@interface NECustomActionSheetController ()
@property (nonatomic, assign) CGFloat sheetHeight;
@property (nonatomic, weak) NECustomAlertAction *topAction;
@end

@implementation NECustomActionSheetController

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [UIView animateWithDuration:0.25 animations:^{
        self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
      }];
    });
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupUI];
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissTap)];
  [self.view addGestureRecognizer:tap];
}

- (void)setupUI {
  __weak typeof(self) weakSelf = self;
  _cancelAction = [[NECustomAlertAction alloc] initWithTitle:@"取消" completion:nil];
  _cancelAction.translatesAutoresizingMaskIntoConstraints = NO;
  _cancelAction.clickAction = ^{ [weakSelf handleDismissTap]; };
  [self addAction:_cancelAction actionHeight:89];

  _boldDividerLine = [[UIView alloc] init];
  _boldDividerLine.translatesAutoresizingMaskIntoConstraints = NO;
  _boldDividerLine.backgroundColor = [UIColor colorWithRed:0xF7/255.0 green:0xF7/255.0 blue:0xF7/255.0 alpha:1];
  [self.view addSubview:_boldDividerLine];
  [NSLayoutConstraint activateConstraints:@[
    [_boldDividerLine.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [_boldDividerLine.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [_boldDividerLine.bottomAnchor constraintEqualToAnchor:_cancelAction.topAnchor],
    [_boldDividerLine.heightAnchor constraintEqualToConstant:6],
  ]];
  _sheetHeight += 6;
}

- (void)handleDismissTap {
  [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)addAction:(NECustomAlertAction *)action actionHeight:(CGFloat)actionHeight {
  action.translatesAutoresizingMaskIntoConstraints = NO;
  __weak typeof(self) weakSelf = self;
  action.cancelAction = ^{ [weakSelf handleDismissTap]; };
  [self.view addSubview:action];
  [NSLayoutConstraint activateConstraints:@[
    [action.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [action.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [action.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-_sheetHeight],
    [action.heightAnchor constraintEqualToConstant:actionHeight],
  ]];
  _sheetHeight += actionHeight;

  _topAction.cornerType = CornerTypeNone;
  _topAction = action;
  _topAction.cornerType = CornerTypeTopLeft | CornerTypeTopRight;
}

@end
