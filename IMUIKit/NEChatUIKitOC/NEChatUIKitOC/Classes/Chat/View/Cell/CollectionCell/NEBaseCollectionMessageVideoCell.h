// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseCollectionMessageImageCell.h"
#import <NEChatKitOC/NECommonKitOC.h>
#import <NECommonUIKitOC/VideoStateView.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseCollectionMessageVideoCell : NEBaseCollectionMessageImageCell

@property (nonatomic, strong) VideoStateView *collectionStateView;
@property (nonatomic, strong) UILabel *collectionVideoTimeLabel;
@property (nonatomic, strong) UIView *collectionTimeView;

@end

NS_ASSUME_NONNULL_END
