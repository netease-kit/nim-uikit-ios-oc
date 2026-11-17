// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <NEChatKit/ChatKitClient.h>
#import <NEChatKit/NEChatKitClient.h>

@class NEEmotionTool;

NS_ASSUME_NONNULL_BEGIN

@interface NEChatService : NSObject <ChatServiceDelegate, NEChatEmojProtocol>

+ (instancetype)shared;

/// 注册 NEChatUIKit 初始化协议
/// - Parameter params: 初始化参数
- (void)setupInit:(NSDictionary<NSString *, id> * _Nullable)params;

/// 注册路由
/// - Parameter param: 参数
- (void)registerRouter:(NSDictionary<NSString *, id> * _Nullable)param;

/// 获取表情富文本
- (NSAttributedString * _Nullable)getEmojAttributeString:(NSString *)content
                                                    font:(CGFloat)font
                                                   color:(UIColor *)color;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
