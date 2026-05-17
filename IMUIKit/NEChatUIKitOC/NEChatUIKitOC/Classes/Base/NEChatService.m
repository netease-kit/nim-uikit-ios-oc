// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatService.h"
#import "NEBaseChatRouter.h"
#import "NormalChatRouter.h"
#import "FunChatRouter.h"
#import "NEEmotionTool.h"
#import <NEChatKitOC/IMKitClient.h>
#import <NEChatKitOC/NIMKitFileLocationHelper.h>
#import <NIMSDK/NIMSDK.h>
#import <SDWebImage/SDWebImage.h>
#if __has_include(<SDWebImageWebPCoder/SDImageWebPCoder.h>)
#import <SDWebImageWebPCoder/SDImageWebPCoder.h>
#define HAS_WEBP_CODER 1
#endif
#if __has_include(<SDWebImageSVGKitPlugin/SDImageSVGKCoder.h>)
#import <SDWebImageSVGKitPlugin/SDImageSVGKCoder.h>
#define HAS_SVG_CODER 1
#endif

@implementation NEChatService

+ (instancetype)shared {
  static NEChatService *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NEChatService alloc] initPrivate];
  });
  return instance;
}

- (instancetype)initPrivate {
  self = [super init];
  return self;
}

#pragma mark - ChatServiceDelegate

- (void)setupInit:(NSDictionary<NSString *, id> *)params {
  [self registerRouter:params];
}

#pragma mark - Router

- (void)registerRouter:(NSDictionary<NSString *, id> *)param {
  NSNumber *isFun = param[@"isFun"];
  if (isFun && [isFun boolValue]) {
    [ChatRouter registerFun];
  } else {
    [NormalChatRouter register];
  }

  [NIMKitFileLocationHelper setStaticAppkey:[[NIMSDK sharedSDK] appKey]];
  [NIMKitFileLocationHelper setStaticUserId:[[IMKitClient instance] account]];

#ifdef HAS_WEBP_CODER
  SDImageWebPCoder *webpCoder = [[SDImageWebPCoder alloc] init];
  [[SDImageCodersManager sharedManager] addCoder:webpCoder];
#endif
#ifdef HAS_SVG_CODER
  SDImageSVGKCoder *svgCoder = [SDImageSVGKCoder shared];
  [[SDImageCodersManager sharedManager] addCoder:svgCoder];
#endif

  [[NEChatKitClient instance] addEmojDelegate:self];
}

#pragma mark - NEChatEmojProtocol

- (NSAttributedString *)getEmojAttributeString:(NSString *)content
                                          font:(CGFloat)font
                                         color:(UIColor *)color {
  NSAttributedString *attributeStr = [NEEmotionTool getAttWithStr:content
                                                              font:[UIFont systemFontOfSize:font]
                                                             color:color
                                                            offset:CGPointMake(0, -4)];
  return attributeStr;
}

@end
