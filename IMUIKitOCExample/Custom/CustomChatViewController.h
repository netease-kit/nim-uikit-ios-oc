// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEChatUIKitOC/FunP2PChatViewController.h>
#import <NEChatUIKitOC/P2PChatViewController.h>
#import <NERtcCallKit/NECallEngine.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomNormalChatViewController : P2PChatViewController <NERecordProvider>
@end

@interface CustomFunChatViewController : FunP2PChatViewController <NERecordProvider>
@end

NS_ASSUME_NONNULL_END
