// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseCollectionMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseCollectionMessageAudioCell : NEBaseCollectionMessageCell

@property (nonatomic, strong) UIImageView *audioImageView;
@property (nonatomic, strong) UILabel *audioTimeLabel;
@property (nonatomic, strong) UIImageView *bubbleImage;
@property (nonatomic, assign) BOOL isPlaying;

- (void)startPlayAnimation;
- (void)stopPlayAnimation;

@end

NS_ASSUME_NONNULL_END
