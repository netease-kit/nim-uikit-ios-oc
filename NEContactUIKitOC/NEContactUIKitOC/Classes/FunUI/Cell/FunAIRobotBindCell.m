// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunAIRobotBindCell.h"
#import "FunContactUIColor.h"

@implementation FunAIRobotBindCell

- (CGFloat)avatarSize {
  return 40.0;
}

- (CGFloat)avatarCornerRadius {
  return 4.0;
}

- (CGFloat)nameFont {
  return 17.0;
}

- (UIColor *)separatorColor {
  return [UIColor funContactLineBorderColor];
}

@end
