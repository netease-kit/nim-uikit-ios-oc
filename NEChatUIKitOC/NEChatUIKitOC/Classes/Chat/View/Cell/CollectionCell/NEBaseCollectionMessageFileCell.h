// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseCollectionMessageCell.h"

#import <NEBaseUIKitOC/FileStateView.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseCollectionMessageFileCell : NEBaseCollectionMessageCell

@property (nonatomic, strong) FileStateView *fileStateView;
@property (nonatomic, strong) UIImageView *bubbleImage;
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *sizeLabel;
@property (nonatomic, strong) UIView *labelView;

- (void)uploadProgress:(NSUInteger)progress;

@end

NS_ASSUME_NONNULL_END
