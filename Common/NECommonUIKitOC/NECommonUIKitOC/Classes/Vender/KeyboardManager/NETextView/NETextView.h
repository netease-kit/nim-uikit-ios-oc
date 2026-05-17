// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NETextView : UITextView

@property (nonatomic, strong, readonly) UILabel *placeholderLabel;
@property (nonatomic, strong, nullable) UIColor *placeholderTextColor;
@property (nonatomic, copy, nullable) NSString *placeholder;
@property (nonatomic, copy, nullable) NSAttributedString *attributedPlaceholder;

- (void)refreshPlaceholder;
- (void)removeAllAutoLayout;

@end

NS_ASSUME_NONNULL_END
