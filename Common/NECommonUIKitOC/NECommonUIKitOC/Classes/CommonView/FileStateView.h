// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, FileStateViewState) {
  FileStateViewStateFileOpen = 1,
  FileStateViewStateFileDownload,
};

typedef FileStateViewState FileState;

static const FileStateViewState FileOpenState = FileStateViewStateFileOpen;
static const FileStateViewState FileDownloadState = FileStateViewStateFileDownload;
static const FileStateViewState FileStateOpen = FileStateViewStateFileOpen;
static const FileStateViewState FileStateDownload = FileStateViewStateFileDownload;
static const FileState FileStateFileOpen = FileStateViewStateFileOpen;
static const FileState FileStateFileDownload = FileStateViewStateFileDownload;

NS_ASSUME_NONNULL_BEGIN

@interface FileStateView : UIView

@property (nonatomic, strong, readonly) CAShapeLayer *circleLayer;
@property (nonatomic, strong, readonly) CAShapeLayer *progressLayer;
@property (nonatomic, strong, readonly) UIImageView *FileOpenImage;
@property (nonatomic, strong, readonly) UIView *alphaBackView;
@property (nonatomic, strong, readonly) UIView *verticalLineLeft;
@property (nonatomic, strong, readonly) UIView *verticalLineRight;
@property (nonatomic, assign) FileStateViewState state;

- (void)setProgress:(float)progress;

@end

NS_ASSUME_NONNULL_END
