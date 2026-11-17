// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKit/NEChatKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OperationCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong, nullable) OperationItem *model;

- (void)commonUI;

@end

NS_ASSUME_NONNULL_END
