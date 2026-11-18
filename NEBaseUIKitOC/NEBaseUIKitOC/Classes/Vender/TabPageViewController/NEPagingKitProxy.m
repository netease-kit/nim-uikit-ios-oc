// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingKitProxy.h"

@implementation NEPagingKitConfig

static UIColor *_ne_focusColor;
static UIColor *_ne_normalColor;
static UIFont *_ne_menuTitleFont;

+ (UIColor *)focusColor {
  if (!_ne_focusColor) {
    _ne_focusColor = [UIColor colorWithRed:0.9137254902
                                     green:0.3490196078
                                      blue:0.3137254902
                                     alpha:1.0];
  }
  return _ne_focusColor;
}

+ (void)setFocusColor:(UIColor *)focusColor {
  _ne_focusColor = focusColor ?: [self focusColor];
}

+ (UIColor *)normalColor {
  if (!_ne_normalColor) {
    _ne_normalColor = UIColor.blackColor;
  }
  return _ne_normalColor;
}

+ (void)setNormalColor:(UIColor *)normalColor {
  _ne_normalColor = normalColor ?: [self normalColor];
}

+ (UIFont *)menuTitleFont {
  if (!_ne_menuTitleFont) {
    _ne_menuTitleFont = [UIFont systemFontOfSize:17.0];
  }
  return _ne_menuTitleFont;
}

+ (void)setMenuTitleFont:(UIFont *)menuTitleFont {
  _ne_menuTitleFont = menuTitleFont ?: [self menuTitleFont];
}

@end

@implementation NEPagingKitProxy

+ (void)catchLayoutCompletionWithLayout:(NEPagingKitLayoutBlock)layout
                             completion:(NEPagingKitAnimationCompletion)completion {
  [UIView animateWithDuration:0
                   animations:^{
                     if (layout) {
                       layout();
                     }
                   }
                   completion:^(BOOL finished) {
                     if (completion) {
                       completion(finished);
                     }
                   }];
}

+ (void)performSystemAnimation:(dispatch_block_t)animations
                    completion:(NEPagingKitAnimationCompletion)completion {
  [UIView performSystemAnimation:UISystemAnimationDelete
                         onViews:@[]
                        options:0
                     animations:^{
                       if (animations) {
                         animations();
                       }
                     }
                      completion:^(BOOL finished) {
                        if (completion) {
                          completion(finished);
                        }
                      }];
}

@end
