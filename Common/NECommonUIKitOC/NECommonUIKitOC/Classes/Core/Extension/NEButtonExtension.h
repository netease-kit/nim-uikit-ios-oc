// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NEButtonStyle) {
  NEButtonStyleTop,
  NEButtonStyleLeft,
  NEButtonStyleBottom,
  NEButtonStyleRight,
};

typedef NEButtonStyle ButtonStyle;

@interface UIButton (NEButtonExtension)

- (void)layoutButtonImage;
- (void)layoutButtonImageWithStyle:(NEButtonStyle)style space:(CGFloat)space;

@end

NS_ASSUME_NONNULL_END
