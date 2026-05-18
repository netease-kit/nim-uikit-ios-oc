// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ExpandButton;
@class VideoToolBar;

@protocol VideoToolBarDelegate <NSObject>

- (void)didClickPause;
- (void)didClickPlay;
- (void)didSeek:(float)progress;
- (void)didStopRefreshProgress;
- (void)didStartRefreshProgress;

@end

@interface VideoToolBar : UIView

@property (nonatomic, assign) NSInteger total;
@property (nonatomic, weak, nullable) id<VideoToolBarDelegate> delegate;
@property (nonatomic, strong, readonly) ExpandButton *playButton;
@property (nonatomic, strong, readonly) UILabel *currentTimeLabel;
@property (nonatomic, strong, readonly) UILabel *totalTimeLabel;
@property (nonatomic, strong, readonly) UISlider *progressSlider;

- (void)resetState;

@end

NS_ASSUME_NONNULL_END
