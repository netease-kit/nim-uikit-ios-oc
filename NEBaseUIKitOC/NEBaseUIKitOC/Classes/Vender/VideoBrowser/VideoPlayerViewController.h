// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BrowserToolsBar;
@class ExpandButton;
@class ToastImageView;
@class VideoToolBar;

@interface VideoPlayerViewController : UIViewController

@property (nonatomic, strong, nullable) NSURL *videoUrl;
@property (nonatomic, assign) NSInteger totalTime;
@property (nonatomic, strong) ExpandButton *playButton;
@property (nonatomic, strong) BrowserToolsBar *toolsBar;
@property (nonatomic, strong) ToastImageView *successView;
@property (nonatomic, strong) VideoToolBar *videoToolBar;

- (void)didCloseClick;
- (void)didSaveClick;
- (void)endPlay;

@end

NS_ASSUME_NONNULL_END
