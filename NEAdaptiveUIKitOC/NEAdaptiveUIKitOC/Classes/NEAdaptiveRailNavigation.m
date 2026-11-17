// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAdaptiveRailNavigation.h"

#import "NEAdaptiveRailActionSupport.h"

#import <objc/runtime.h>

#pragma mark - 直接调用页面按钮原本的 selector 目标

@implementation NEAdaptiveActionInvocation

+ (void)invokeSelector:(SEL)selector onTarget:(nullable id)target sender:(nullable id)sender {
  NSObject *object = [target isKindOfClass:[NSObject class]] ? (NSObject *)target : nil;
  if (!selector || !object) {
    return;
  }
  Class cls = object_getClass(object);
  Method method = cls ? class_getInstanceMethod(cls, selector) : NULL;
  if (!method) {
    if ([object respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [object performSelector:selector withObject:sender];
#pragma clang diagnostic pop
    }
    return;
  }
  // 参数个数包含 self 与 _cmd；带 sender 的回调需要额外一个参数。
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  if (method_getNumberOfArguments(method) >= 3) {
    [object performSelector:selector withObject:sender];
  } else {
    [object performSelector:selector];
  }
#pragma clang diagnostic pop
}

+ (void)forwardControl:(UIControl *)control {
  __block BOOL invoked = NO;
  for (id target in control.allTargets) {
    NSArray<NSString *> *selectors =
        [control actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
    for (NSString *name in selectors) {
      [self invokeSelector:NSSelectorFromString(name) onTarget:target sender:control];
      invoked = YES;
    }
  }
  // UIAction 风格的按钮没有 selector 目标，退回控件自身派发。
  if (!invoked) {
    [control sendActionsForControlEvents:UIControlEventTouchUpInside];
  }
}

@end

#pragma mark - 页面按钮文案的计数拆分

@implementation NEAdaptiveRailTitle

+ (void)splitTitle:(nullable NSString *)title
              text:(NSString *_Nullable *_Nullable)text
             badge:(NSString *_Nullable *_Nullable)badge {
  if (text) {
    *text = nil;
  }
  if (badge) {
    *badge = nil;
  }
  if (title.length == 0) {
    return;
  }
  static NSRegularExpression *pattern;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pattern = [NSRegularExpression regularExpressionWithPattern:@"^(.+?)\\s*[（(]\\s*(\\d+)\\s*[)）]\\s*$"
                                                       options:0
                                                         error:nil];
  });
  NSTextCheckingResult *match =
      [pattern firstMatchInString:title options:0 range:NSMakeRange(0, title.length)];
  if (!match || match.numberOfRanges != 3) {
    if (text) {
      *text = title;
    }
    return;
  }
  NSString *rawText = [title substringWithRange:[match rangeAtIndex:1]];
  NSString *rawBadge = [title substringWithRange:[match rangeAtIndex:2]];
  NSString *trimmed = [rawText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (text) {
    *text = trimmed.length > 0 ? trimmed : nil;
  }
  if (badge) {
    *badge = rawBadge;
  }
}

@end

#pragma mark - NEAdaptiveRailAction

@implementation NEAdaptiveRailAction

- (instancetype)init {
  self = [super init];
  if (self) {
    _isEnabled = YES;
  }
  return self;
}

- (void)perform {
  if (self.handler) {
    self.handler();
    return;
  }
  if (!self.selector) {
    return;
  }
  [NEAdaptiveActionInvocation invokeSelector:self.selector onTarget:self.target sender:nil];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<NEAdaptiveRailAction: id=%@ title=%@ badge=%@ enabled=%d>",
                                    self.identifier, self.title, self.badge, (int)self.isEnabled];
}

@end
