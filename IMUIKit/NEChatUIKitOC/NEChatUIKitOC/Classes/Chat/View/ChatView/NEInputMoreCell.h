// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKitOC/NEChatKitOC.h>
#import "NEMoreItemModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEInputMoreCell : UICollectionViewCell

@property (nonatomic, strong, nullable) NEMoreItemModel *cellData;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;

- (void)config:(NEMoreItemModel *)itemModel;
+ (CGSize)getSize;

@end

NS_ASSUME_NONNULL_END
