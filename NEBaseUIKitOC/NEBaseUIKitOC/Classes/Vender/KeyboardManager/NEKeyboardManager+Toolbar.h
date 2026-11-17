// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEKeyboardManager.h"

@class NEBarButtonItem;

NS_ASSUME_NONNULL_BEGIN

@interface NEKeyboardManager (Toolbar)

@property (nonatomic, assign, readonly) BOOL canGoPrevious;
@property (nonatomic, assign, readonly) BOOL canGoNext;

- (void)addToolbarIfRequired;
- (void)removeToolbarIfRequired;
- (BOOL)goPrevious;
- (BOOL)goNext;
- (void)reloadInputViews;
- (void)previousAction:(NEBarButtonItem *)barButton;
- (void)nextAction:(NEBarButtonItem *)barButton;
- (void)doneAction:(NEBarButtonItem *)barButton;

@end

NS_ASSUME_NONNULL_END
