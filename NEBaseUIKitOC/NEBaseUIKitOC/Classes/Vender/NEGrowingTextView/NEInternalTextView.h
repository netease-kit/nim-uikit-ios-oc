// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEInternalTextView : UITextView <NSCopying>

@property (nonatomic, copy, nullable) NSAttributedString *placeholder;
@property (nonatomic, assign) BOOL shouldDisplayPlaceholder;
@property (nonatomic, assign, getter=isCaretHidden) BOOL caretHidden;

@end

NS_ASSUME_NONNULL_END
