// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Compatibility header. Implementation is provided by UIView+NECorner for all UIView subclasses.
@interface UITextField (NETextFieldExtension)

- (void)removeAllAutoLayout;

@end

NS_ASSUME_NONNULL_END

