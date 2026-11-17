// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

@class NECommonLoader;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const NETeamUIKitModuleName;
FOUNDATION_EXPORT NSNotificationName const NETeamUIKitLeaveTeamBySelfNotification;
FOUNDATION_EXPORT NSNotificationName const NETeamUIKitPopGroupChatVCNotification;

FOUNDATION_EXPORT NECommonLoader *NETeamUIKitLoader(void);
FOUNDATION_EXPORT NSString *NETeamUIKitLocalizable(NSString *key);
FOUNDATION_EXPORT NSString *NETeamUIKitErrorToast(NSError *_Nullable error);

NS_ASSUME_NONNULL_END
