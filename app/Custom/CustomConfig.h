// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

@class UIButton;
@class CustomView;

NS_ASSUME_NONNULL_BEGIN

@interface CustomConfig : NSObject

+ (instancetype)shared;
@property (nonatomic, strong) CustomView *customTopView;
@property (nonatomic, strong) CustomView *customBottomView;
- (void)configCommonUIKit;
- (void)configChatUIKit;
- (void)configContactUIKit;
- (void)configConversationUIKit;
- (void)loadAIChatData;
- (void)loadPhotoBrowser;
- (void)loadSecurityWarningView;
- (void)loadRtcEntry;
- (void)registerCustomChatRouterForFunUI:(BOOL)isFunUI;
- (void)customClick:(UIButton *)button;

@end

NS_ASSUME_NONNULL_END
