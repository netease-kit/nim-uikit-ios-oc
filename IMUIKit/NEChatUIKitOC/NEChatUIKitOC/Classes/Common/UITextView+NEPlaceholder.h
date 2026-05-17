// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Category that adds `attributedPlaceholder` support to UITextView
/// (mirrors UITextField's API for drop-in compatibility).
@interface UITextView (NEPlaceholder)

/// An attributed string that is displayed when the text view is empty.
@property (nonatomic, copy, nullable) NSAttributedString *attributedPlaceholder;

@end

NS_ASSUME_NONNULL_END
