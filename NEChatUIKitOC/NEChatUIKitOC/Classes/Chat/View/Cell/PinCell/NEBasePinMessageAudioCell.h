// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBasePinMessageAudioCell : NEBasePinMessageCell

@property (nonatomic, strong) UIImageView *audioImageView;
@property (nonatomic, strong) UILabel *audioTimeLabel;
@property (nonatomic, strong) UIImageView *bubbleImage;
@property (nonatomic, assign) BOOL isPlaying;

- (void)startAnimation;
- (void)stopAnimation;

@end

NS_ASSUME_NONNULL_END
