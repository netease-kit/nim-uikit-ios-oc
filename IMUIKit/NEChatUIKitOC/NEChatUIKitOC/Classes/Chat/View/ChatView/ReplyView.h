// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReplyView : UIView

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIView *line;
@property (nonatomic, strong) UILabel *textLabel;

@end

NS_ASSUME_NONNULL_END
