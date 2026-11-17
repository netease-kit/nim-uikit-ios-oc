// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CornerCell.h"

@interface CornerCell ()
@property (nonatomic, assign) CornerType cornerTypeInternal;
@end

@implementation CornerCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.backgroundColor = UIColor.clearColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    _fillColor = UIColor.whiteColor;
    _edgeInset = UIEdgeInsetsMake(0, 20, 0, 20);
    _cornerTypeInternal = CornerTypeNone;
    _showDefaultLine = NO;

    _cornerLayer = [CAShapeLayer layer];
    [self.layer insertSublayer:_cornerLayer below:self.contentView.layer];

    _dividerLine = [[UIView alloc] init];
    _dividerLine.translatesAutoresizingMaskIntoConstraints = NO;
    _dividerLine.backgroundColor = [UIColor colorWithRed:0xF5/255.0 green:0xF8/255.0 blue:0xFC/255.0 alpha:1];
    _dividerLine.hidden = YES;
    [self.contentView addSubview:_dividerLine];

    _dividerLineLeftMargin = [_dividerLine.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:36];
    _dividerLineRightMargin = [_dividerLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20];
    [NSLayoutConstraint activateConstraints:@[
      _dividerLineLeftMargin,
      _dividerLineRightMargin,
      [_dividerLine.heightAnchor constraintEqualToConstant:1],
      [_dividerLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];
  }
  return self;
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
  [self drawRoundedCornerWithRect:rect];
}

- (void)drawRoundedCornerWithRect:(CGRect)rect {
  CGRect roundRect = CGRectMake(rect.origin.x + _edgeInset.left,
                                rect.origin.y + _edgeInset.top,
                                rect.size.width - (_edgeInset.left + _edgeInset.right),
                                rect.size.height - (_edgeInset.top + _edgeInset.bottom));
  UIRectCorner corners = 0;

  if (_cornerTypeInternal == CornerTypeNone) {
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:roundRect];
    _cornerLayer.path = path.CGPath;
    _cornerLayer.fillColor = _fillColor.CGColor;
    if (_showDefaultLine) _dividerLine.hidden = NO;
    return;
  }

  if (_cornerTypeInternal & CornerTypeTopLeft)     { corners |= UIRectCornerTopLeft;    if (_showDefaultLine) _dividerLine.hidden = NO; }
  if (_cornerTypeInternal & CornerTypeTopRight)    { corners |= UIRectCornerTopRight; }
  if (_cornerTypeInternal & CornerTypeBottomLeft)  { corners |= UIRectCornerBottomLeft; if (_showDefaultLine) _dividerLine.hidden = YES; }
  if (_cornerTypeInternal & CornerTypeBottomRight) { corners |= UIRectCornerBottomRight; }

  UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:roundRect
                                             byRoundingCorners:corners
                                                   cornerRadii:CGSizeMake(10, 10)];
  _cornerLayer.path = path.CGPath;
  _cornerLayer.fillColor = _fillColor.CGColor;
}

- (void)drawRoundedCornerInRect:(CGRect)rect {
  [self drawRoundedCornerWithRect:rect];
}

@end
