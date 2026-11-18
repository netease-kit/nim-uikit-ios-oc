// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "LinkableLabelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface NELinkableLabel : UILabel

@property (nonatomic, weak, nullable) id<LinkableLabelProtocol> delegate;

- (void)updateLinkDetection;

@end

NS_ASSUME_NONNULL_END
