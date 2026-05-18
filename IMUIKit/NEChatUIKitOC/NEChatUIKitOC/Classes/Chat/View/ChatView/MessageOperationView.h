// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKitOC/NEChatKitOC.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MessageOperationViewDelegate <NSObject>
- (void)didSelectedItem:(OperationItem *)item;
@end

@interface MessageOperationView : UIView <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak, nullable) id<MessageOperationViewDelegate> delegate;
@property (nonatomic, strong) NSMutableArray<OperationItem *> *items;

@end

NS_ASSUME_NONNULL_END
