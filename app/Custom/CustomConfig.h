// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomConfig : NSObject

+ (instancetype)shared;
- (void)configCommonUIKit;
- (void)configChatUIKit;
- (void)configContactUIKit;
- (void)configConversationUIKit;
- (void)loadAIChatData;
- (void)loadPhotoBrowser;
- (void)loadSecurityWarningView;
- (void)loadRtcEntry;
- (void)registerCustomChatRouterForFunUI:(BOOL)isFunUI;

@end

NS_ASSUME_NONNULL_END
