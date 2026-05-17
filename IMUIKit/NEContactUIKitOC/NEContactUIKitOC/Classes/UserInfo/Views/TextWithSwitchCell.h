// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "ContactBaseTextCell.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^ValueChangeBlock)(NSString *_Nullable title, BOOL value);

@interface TextWithSwitchCell : ContactBaseTextCell
@property (nonatomic, copy, nullable) ValueChangeBlock block;
@property (nonatomic, strong) UISwitch *switchButton;
- (void)valueChanged:(UISwitch *)switchBtn;
@end

NS_ASSUME_NONNULL_END
