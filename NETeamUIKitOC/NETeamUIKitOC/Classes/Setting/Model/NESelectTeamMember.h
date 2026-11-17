// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

@class NETeamMemberInfoModel;

NS_ASSUME_NONNULL_BEGIN

@interface NESelectTeamMember : NSObject

@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, strong, nullable) NETeamMemberInfoModel *member;

@end

NS_ASSUME_NONNULL_END
