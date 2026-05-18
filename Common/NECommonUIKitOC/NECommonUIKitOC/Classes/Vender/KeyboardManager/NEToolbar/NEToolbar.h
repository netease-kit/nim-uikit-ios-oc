// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEBarButtonItem.h"
#import "NETitleBarButtonItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEToolbar : UIToolbar <UIInputViewAudioFeedback>

@property (nonatomic, strong) NEBarButtonItem *previousBarButton;
@property (nonatomic, strong) NEBarButtonItem *nextBarButton;
@property (nonatomic, strong) NETitleBarButtonItem *titleBarButton;
@property (nonatomic, strong) NEBarButtonItem *doneBarButton;
@property (nonatomic, strong) NEBarButtonItem *fixedSpaceBarButton;

@end

NS_ASSUME_NONNULL_END
