// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, FileState) {
  FileStateFileOpen = 1,
  FileStateFileDownload = 2,
};

typedef FileState FileStateViewState;

#define FileStateViewStateFileOpen FileStateFileOpen
#define FileStateViewStateFileDownload FileStateFileDownload

static const FileState FileOpenState = FileStateFileOpen;
static const FileState FileDownloadState = FileStateFileDownload;
static const FileState FileStateOpen = FileStateFileOpen;
static const FileState FileStateDownload = FileStateFileDownload;

NS_ASSUME_NONNULL_BEGIN

@interface FileStateView : UIView

@property (nonatomic, strong) CAShapeLayer *circleLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, assign) FileState state;
@property (nonatomic, strong) UIImageView *FileOpenImage;
@property (nonatomic, strong) UIView *alphaBackView;
@property (nonatomic, strong) UIView *verticalLineLeft;
@property (nonatomic, strong) UIView *verticalLineRight;

- (void)setProgress:(float)progress;

@end

NS_ASSUME_NONNULL_END
