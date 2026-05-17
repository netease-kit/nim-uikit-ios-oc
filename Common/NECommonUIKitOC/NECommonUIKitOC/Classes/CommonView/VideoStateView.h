// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, VideoStateViewState) {
  VideoStateViewStateVideoPlay = 1,
  VideoStateViewStateVideoDownload,
};

static const VideoStateViewState VideoPlayState = VideoStateViewStateVideoPlay;
static const VideoStateViewState VideoDownloadState = VideoStateViewStateVideoDownload;
static const VideoStateViewState VideoStatePlay = VideoStateViewStateVideoPlay;
static const VideoStateViewState VideoStateDownload = VideoStateViewStateVideoDownload;

NS_ASSUME_NONNULL_BEGIN

@interface VideoStateView : UIView

@property (nonatomic, assign) VideoStateViewState state;

- (void)setProgress:(float)progress;

@end

NS_ASSUME_NONNULL_END
