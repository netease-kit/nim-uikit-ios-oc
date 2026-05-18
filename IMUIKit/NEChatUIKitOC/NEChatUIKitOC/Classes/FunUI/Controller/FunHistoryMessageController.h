// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseHistorySearchController.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>

NS_ASSUME_NONNULL_BEGIN

@interface FunHistoryMessageController : NEBaseHistorySearchController

@property (nonatomic, strong) ExpandButton *cancelButton;
@property (nonatomic, strong) FunSearchView *searchView;

@end

NS_ASSUME_NONNULL_END
