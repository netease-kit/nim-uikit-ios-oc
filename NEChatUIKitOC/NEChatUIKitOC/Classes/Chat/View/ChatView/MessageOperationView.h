// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKit/NEChatKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MessageOperationViewDelegate <NSObject>
- (void)didSelectedItem:(OperationItem *)item;
@end

@interface MessageOperationView : UIView <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak, nullable) id<MessageOperationViewDelegate> delegate;
@property (nonatomic, strong) NSMutableArray<OperationItem *> *items;
@property (nonatomic, assign) BOOL showEmoji;
@property (nonatomic, assign) BOOL showMoreButton;
@property (nonatomic, assign) CGFloat oldFrameHeight;
/// Width of the ordinary operation menu, restored after reaction expansion.
@property (nonatomic, assign) CGFloat oldFrameWidth;
/// Visible message-list bounds in the operation view's superview coordinates.
@property (nonatomic, assign) CGRect visibleFrame;
@property (nonatomic, assign) BOOL hasVisibleFrame;
/// 被长按消息在操作视图 superview 坐标系里的矩形（用于共享几何 `ChatMenuFrameForMessage`）。
@property (nonatomic, assign) CGRect messageRect;
@property (nonatomic, assign) BOOL hasMessageRect;
@property (nonatomic, assign) BOOL viewUnderMessage;
@property (nonatomic, assign, readonly) BOOL showingAllEmoji;
@property (nonatomic, copy, nullable) void (^onSelectReaction)(NSInteger index);

- (void)configureReactionsWithProvider:(nullable id)provider
                           quickIndexes:(NSArray<NSNumber *> *)quickIndexes
                              showEmoji:(BOOL)showEmoji
                         showMoreButton:(BOOL)showMoreButton;
- (void)showAllEmoji;
- (void)showOperation;

@end

NS_ASSUME_NONNULL_END
