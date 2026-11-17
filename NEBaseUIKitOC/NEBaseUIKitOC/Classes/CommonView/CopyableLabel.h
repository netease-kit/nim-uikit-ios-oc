// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NELinkableLabel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CopyableLabel : NELinkableLabel

@property (nonatomic, copy, nullable, getter=ne_copyString) NSString *copyString;

@end

NS_ASSUME_NONNULL_END
