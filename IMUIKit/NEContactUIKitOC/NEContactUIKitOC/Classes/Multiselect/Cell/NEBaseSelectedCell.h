// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import "MultiSelectModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseSelectedCell : UICollectionViewCell
@property (nonatomic, strong) NEUserHeaderView *avatarImageView;
- (void)setupUI;
- (void)configure:(id)model;
@end

NS_ASSUME_NONNULL_END
