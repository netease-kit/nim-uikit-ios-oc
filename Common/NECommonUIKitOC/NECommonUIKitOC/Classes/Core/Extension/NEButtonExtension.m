// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEButtonExtension.h"

@implementation UIButton (NEButtonExtension)

- (void)layoutButtonImage {
  [self layoutButtonImageWithStyle:NEButtonStyleLeft space:5.0];
}

- (void)layoutButtonImageWithStyle:(NEButtonStyle)style space:(CGFloat)space {
  CGFloat imageWidth = self.imageView.bounds.size.width;
  CGFloat imageHeight = self.imageView.bounds.size.height;
  CGFloat labelWidth = self.titleLabel.intrinsicContentSize.width;
  CGFloat labelHeight = self.titleLabel.intrinsicContentSize.height;

  UIEdgeInsets imageEdgeInsets = UIEdgeInsetsZero;
  UIEdgeInsets labelEdgeInsets = UIEdgeInsetsZero;
  UIEdgeInsets contentEdgeInsets = UIEdgeInsetsZero;

  CGFloat buttonWidth = self.bounds.size.width;
  CGFloat minHeight = MIN(imageHeight, labelHeight);

  switch (style) {
    case NEButtonStyleLeft:
      self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
      labelEdgeInsets = UIEdgeInsetsMake(0, space, 0, -space);
      contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, space);
      break;
    case NEButtonStyleRight: {
      self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
      CGFloat widthOffset = labelWidth + space / 2.0;
      if (labelWidth + imageWidth + space > buttonWidth) {
        widthOffset = self.titleLabel.frame.size.width + space / 2.0;
      }
      imageEdgeInsets = UIEdgeInsetsMake(0, widthOffset, 0, -widthOffset);
      labelEdgeInsets = UIEdgeInsetsMake(0, -(imageWidth + space / 2.0), 0, imageWidth + space / 2.0);
      contentEdgeInsets = UIEdgeInsetsMake(0, space / 2.0, 0, space / 2.0);
      break;
    }
    case NEButtonStyleTop: {
      self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
      self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
      CGFloat widthOffset = labelWidth / 2.0;
      if (labelWidth + imageWidth + space > buttonWidth) {
        widthOffset = (buttonWidth - imageWidth) / 2.0;
      }
      CGFloat titleWidth = self.titleLabel.frame.size.width;
      if (imageWidth + titleWidth + space > buttonWidth) {
        widthOffset = (buttonWidth - imageWidth) / 2.0;
      }
      imageEdgeInsets = UIEdgeInsetsMake(-(labelHeight + space), widthOffset, 0, -widthOffset);
      labelEdgeInsets = UIEdgeInsetsMake(0, -imageWidth, -(space + imageHeight), 0);
      CGFloat heightOffset = (minHeight + space) / 2.0;
      contentEdgeInsets = UIEdgeInsetsMake(heightOffset, 0, heightOffset, 0);
      break;
    }
    case NEButtonStyleBottom: {
      self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
      self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
      CGFloat widthOffset = labelWidth / 2.0;
      if (labelWidth + imageWidth + space > buttonWidth) {
        widthOffset = (buttonWidth - imageWidth) / 2.0;
      }
      CGFloat titleWidth = self.titleLabel.frame.size.width;
      if (imageWidth + titleWidth + space > buttonWidth) {
        widthOffset = (buttonWidth - imageWidth) / 2.0;
      }
      imageEdgeInsets = UIEdgeInsetsMake(0, widthOffset, -(labelHeight + space), -widthOffset);
      labelEdgeInsets = UIEdgeInsetsMake(-(space + imageHeight), -imageWidth, 0, 0);
      CGFloat heightOffset = (minHeight + space) / 2.0;
      contentEdgeInsets = UIEdgeInsetsMake(heightOffset, 0, heightOffset, 0);
      break;
    }
  }

  self.contentEdgeInsets = contentEdgeInsets;
  self.titleEdgeInsets = labelEdgeInsets;
  self.imageEdgeInsets = imageEdgeInsets;
}

@end

