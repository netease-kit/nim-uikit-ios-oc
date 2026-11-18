// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, VideoState) {
  VideoStateVideoPlay = 1,
  VideoStateVideoDownload = 2,
};

typedef VideoState VideoStateViewState;

#define VideoStateViewStateVideoPlay VideoStateVideoPlay
#define VideoStateViewStateVideoDownload VideoStateVideoDownload

static const VideoState VideoPlayState = VideoStateVideoPlay;
static const VideoState VideoDownloadState = VideoStateVideoDownload;
static const VideoState VideoStatePlay = VideoStateVideoPlay;
static const VideoState VideoStateDownload = VideoStateVideoDownload;

NS_ASSUME_NONNULL_BEGIN

@interface VideoStateView : UIView

@property (nonatomic, assign) VideoState state;

- (void)setProgress:(float)progress;

@end

NS_ASSUME_NONNULL_END
