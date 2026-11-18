// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ExpandButton;

@protocol BrowserToolsBarDelegate <NSObject>

- (void)didCloseClick;
- (void)didSaveClick;

@end

@interface BrowserToolsBar : UIView

@property (nonatomic, weak, nullable) id<BrowserToolsBarDelegate> delegate;
@property (nonatomic, strong) ExpandButton *saveButton;
@property (nonatomic, strong) ExpandButton *closeButton;

- (void)setupUI;
- (void)saveClick;
- (void)closeClick;

@end

NS_ASSUME_NONNULL_END
