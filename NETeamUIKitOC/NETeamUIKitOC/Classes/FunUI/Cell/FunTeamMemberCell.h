// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamMemberCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface FunTeamMemberCell : NEBaseTeamMemberCell

@property (nonatomic, strong) UIView *dividerLine;

- (void)setOwnerStyle;
- (void)setManagerStyle;

@end

NS_ASSUME_NONNULL_END
