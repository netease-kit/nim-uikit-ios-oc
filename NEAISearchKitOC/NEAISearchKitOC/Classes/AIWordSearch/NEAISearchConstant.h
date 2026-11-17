// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const NEAISearchModuleName;

FOUNDATION_EXPORT NSString *NEAISearchLocalizable(NSString *key);
FOUNDATION_EXPORT UIFont *NEAISearchTextFont(void);
FOUNDATION_EXPORT CGSize NEAISearchTextMaxSize(void);
FOUNDATION_EXPORT NSBundle *NEAISearchBundle(void);
FOUNDATION_EXPORT UIImage * _Nullable NEAISearchImageNamed(NSString * _Nullable name);

NS_ASSUME_NONNULL_END
