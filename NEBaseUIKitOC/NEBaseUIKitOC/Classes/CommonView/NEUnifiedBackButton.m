// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEUnifiedBackButton.h"

#import "CommonUIConfig.h"

@implementation NEUnifiedBackButton

+ (CGSize)unifiedSize {
  return CGSizeMake(34, 32);
}

- (instancetype)initWithAccessibilityLabel:(NSString *)accessibilityLabel {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    [self commonInit];
    self.accessibilityLabel = accessibilityLabel;
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (void)commonInit {
  self.translatesAutoresizingMaskIntoConstraints = NO;
  [self setTitle:nil forState:UIControlStateNormal];
  [self setImage:CommonUIConfig.shared.backArrowImage forState:UIControlStateNormal];
  self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  [NSLayoutConstraint activateConstraints:@[
    [self.widthAnchor constraintEqualToConstant:NEUnifiedBackButton.unifiedSize.width],
    [self.heightAnchor constraintEqualToConstant:NEUnifiedBackButton.unifiedSize.height],
  ]];
}

@end
