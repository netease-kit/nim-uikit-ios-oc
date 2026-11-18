// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 生日日期选择器底部弹出视图
@interface BirthdayDatePickerView : UIView

@property (nonatomic, strong) UIDatePicker *picker;
@property (nonatomic, copy, nullable) void (^timeCallBack)(NSString *_Nullable time);
@property (nonatomic, copy, nullable) void (^onDismiss)(void);

@end

NS_ASSUME_NONNULL_END
