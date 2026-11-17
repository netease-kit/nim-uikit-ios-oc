// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NIMInputEmoticonManager.h"

NS_ASSUME_NONNULL_BEGIN

@class NIMInputEmoticonButton;

/// 表情按钮点击代理
@protocol NIMInputEmoticonButtonDelegate <NSObject>

- (void)selectedEmoticon:(NIMInputEmoticon *)emotion catalogID:(NSString *)catalogID;

@end

/// 表情按钮
@interface NIMInputEmoticonButton : UIButton

@property (nonatomic, strong, nullable) NIMInputEmoticon *emotionData;
@property (nonatomic, copy, nullable) NSString *catalogID;
@property (nonatomic, weak, nullable) id<NIMInputEmoticonButtonDelegate> delegate;

/// 工厂方法：根据表情数据创建按钮
/// @param data       表情数据
/// @param catalogID  分类 ID
/// @param delegate   点击代理
+ (instancetype)iconButtonWithData:(NIMInputEmoticon *)data
                         catalogID:(NSString *)catalogID
                          delegate:(id<NIMInputEmoticonButtonDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
