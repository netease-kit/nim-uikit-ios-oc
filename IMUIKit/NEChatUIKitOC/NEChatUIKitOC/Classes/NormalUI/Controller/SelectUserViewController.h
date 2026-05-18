// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEBaseSelectUserViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SelectUserViewController : NEBaseSelectUserViewController

- (instancetype)initWithConversationId:(NSString *)conversationId showSelf:(BOOL)showSelf showTeamMembers:(BOOL)showTeamMembers;

@end

NS_ASSUME_NONNULL_END
