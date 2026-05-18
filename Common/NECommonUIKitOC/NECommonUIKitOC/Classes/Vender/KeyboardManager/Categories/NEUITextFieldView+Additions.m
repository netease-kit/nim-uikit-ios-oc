// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEUITextFieldView+Additions.h"
#import <objc/runtime.h>

const CGFloat kNEUseDefaultKeyboardDistance = CGFLOAT_MAX;

static void *NEKeyboardDistanceFromTextFieldKey = &NEKeyboardDistanceFromTextFieldKey;
static void *NEIgnoreSwitchingByNextPreviousKey = &NEIgnoreSwitchingByNextPreviousKey;
static void *NEEnableModeKey = &NEEnableModeKey;
static void *NEShouldResignOnTouchOutsideModeKey = &NEShouldResignOnTouchOutsideModeKey;

@implementation UIView (NETextFieldViewAdditions)

- (CGFloat)neKeyboardDistanceFromTextField {
  NSNumber *distance = objc_getAssociatedObject(self, NEKeyboardDistanceFromTextFieldKey);
  return distance ? distance.doubleValue : kNEUseDefaultKeyboardDistance;
}

- (void)setNeKeyboardDistanceFromTextField:(CGFloat)neKeyboardDistanceFromTextField {
  objc_setAssociatedObject(self, NEKeyboardDistanceFromTextFieldKey, @(neKeyboardDistanceFromTextField), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)neIgnoreSwitchingByNextPrevious {
  return [objc_getAssociatedObject(self, NEIgnoreSwitchingByNextPreviousKey) boolValue];
}

- (void)setNeIgnoreSwitchingByNextPrevious:(BOOL)neIgnoreSwitchingByNextPrevious {
  objc_setAssociatedObject(self, NEIgnoreSwitchingByNextPreviousKey, @(neIgnoreSwitchingByNextPrevious), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NEEnableMode)neEnableMode {
  NSNumber *mode = objc_getAssociatedObject(self, NEEnableModeKey);
  return mode ? mode.integerValue : NEEnableModeDefault;
}

- (void)setNeEnableMode:(NEEnableMode)neEnableMode {
  objc_setAssociatedObject(self, NEEnableModeKey, @(neEnableMode), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NEEnableMode)neShouldResignOnTouchOutsideMode {
  NSNumber *mode = objc_getAssociatedObject(self, NEShouldResignOnTouchOutsideModeKey);
  return mode ? mode.integerValue : NEEnableModeDefault;
}

- (void)setNeShouldResignOnTouchOutsideMode:(NEEnableMode)neShouldResignOnTouchOutsideMode {
  objc_setAssociatedObject(self, NEShouldResignOnTouchOutsideModeKey, @(neShouldResignOnTouchOutsideMode), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
