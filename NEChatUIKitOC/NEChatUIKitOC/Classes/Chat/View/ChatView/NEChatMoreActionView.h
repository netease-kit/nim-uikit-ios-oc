// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKit/NEChatKit.h>
#import "NEMoreItemModel.h"

NS_ASSUME_NONNULL_BEGIN

@class NEInputMoreCell;
@class NEChatMoreActionView;

@protocol NEMoreViewDelegate <NSObject>
- (void)moreViewDidSelectMoreCell:(NEChatMoreActionView *)moreView cell:(NEInputMoreCell *)cell;
@end

@interface NEChatMoreActionView : UIView

@property (nonatomic, strong, nullable) UICollectionViewFlowLayout *moreFlowLayout;
@property (nonatomic, weak, nullable) id<NEMoreViewDelegate> delegate;

- (void)configData:(NSArray<NEMoreItemModel *> *)data;

- (void)setupConstraints;

@end

NS_ASSUME_NONNULL_END
