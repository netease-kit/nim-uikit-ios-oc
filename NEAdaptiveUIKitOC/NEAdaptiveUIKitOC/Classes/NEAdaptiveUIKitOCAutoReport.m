// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/// NEAdaptiveUIKitOC 不依赖 NEChatKit，通过运行时弱引用复用统一埋点入口。
/// 引入组件时即上报；宿主未接入 NEChatKit 时不产生副作用。
@protocol NEAdaptiveUIKitOCReportProxy <NSObject>
+ (instancetype)shared;
- (void)buryDataPoints:(NSString *)component
               version:(NSString *)version;
@end

static Class NEAdaptiveUIKitOCReporterClass(void) {
  static Class reporterClass = Nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    reporterClass = NSClassFromString(@"NEChatKit.ChatKitClient");
    if (!reporterClass) {
      reporterClass = NSClassFromString(@"_TtC9NEChatKit13ChatKitClient");
    }
    if (!reporterClass) {
      reporterClass = NSClassFromString(@"ChatKitClient");
    }
    if (!reporterClass) {
      unsigned int count = 0;
      Class *classes = objc_copyClassList(&count);
      for (unsigned int i = 0; i < count; i++) {
        Class candidate = classes[i];
        if ([candidate respondsToSelector:@selector(shared)] &&
            [candidate instancesRespondToSelector:@selector(buryDataPoints:version:)]) {
          reporterClass = candidate;
          break;
        }
      }
      free(classes);
    }
  });
  return reporterClass;
}

@interface NEAdaptiveUIKitOCAutoReport : NSObject
@end

@implementation NEAdaptiveUIKitOCAutoReport

+ (void)load {
  // Adaptive 不直接依赖 NEChatKit，延迟到主队列执行，确保 NEChatKit 已完成加载。
  dispatch_async(dispatch_get_main_queue(), ^{
    Class reporterClass = NEAdaptiveUIKitOCReporterClass();
    if (!reporterClass) {
      return;
    }
    id<NEAdaptiveUIKitOCReportProxy> reporter =
        [(Class<NEAdaptiveUIKitOCReportProxy>)reporterClass shared];
    if (![reporter respondsToSelector:@selector(buryDataPoints:version:)]) {
      return;
    }
    NSBundle *bundle = [NSBundle bundleForClass:[NEAdaptiveUIKitOCAutoReport class]];
    NSString *version = bundle == [NSBundle mainBundle]
                            ? @""
                            : ([bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"");
    [reporter buryDataPoints:@"AdaptiveUIKitOC" version:version];
  });
}

@end
