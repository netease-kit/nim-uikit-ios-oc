// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UITableViewCell+NEAdaptiveSelection.h"
#import <objc/runtime.h>

/// 原始底色关联对象 key。
static void *NEAdaptiveSelectionOriginalColorKey = &NEAdaptiveSelectionOriginalColorKey;

@implementation UITableViewCell (NEAdaptiveSelection)

- (void)ne_captureAdaptiveSelectionBackground {
  NSDictionary<NSString *, id> *original = @{
    @"content" : self.contentView.backgroundColor ?: (id)[NSNull null],
    @"cell" : self.backgroundColor ?: (id)[NSNull null],
  };
  objc_setAssociatedObject(self, NEAdaptiveSelectionOriginalColorKey, original,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)ne_applyAdaptiveSelectionColor:(UIColor *)color selected:(BOOL)selected {
  if (color && selected) {
    self.contentView.backgroundColor = color;
    self.backgroundColor = color;
    return;
  }
  NSDictionary<NSString *, id> *original =
      objc_getAssociatedObject(self, NEAdaptiveSelectionOriginalColorKey);
  if (!original) {
    return;
  }
  id content = original[@"content"];
  id cellColor = original[@"cell"];
  self.contentView.backgroundColor = (content == [NSNull null]) ? nil : content;
  self.backgroundColor = (cellColor == [NSNull null]) ? nil : cellColor;
}

@end
