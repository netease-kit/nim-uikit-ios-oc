// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import "CollectionMessageModel.h"
#import "ChatMessageHelper.h"
#import "ChatCellConstantValue.h"

NS_ASSUME_NONNULL_BEGIN

@class NEBaseCollectionMessageCell;
@class CollectionMessageModel;

@protocol CollectionMessageCellDelegate <NSObject>
@required
- (void)didClickMore:(nullable CollectionMessageModel *)model;
- (void)didClickContent:(nullable CollectionMessageModel *)model cell:(NEBaseCollectionMessageCell *)cell;

@optional
- (void)didTapDetectedLink:(nullable CollectionMessageModel *)model cell:(NEBaseCollectionMessageCell *)cell url:(nullable NSURL *)url;
@end

@interface NEBaseCollectionMessageCell : UITableViewCell

@property (nonatomic, strong, nullable) NSLayoutConstraint *contentWidth;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentHeight;
@property (nonatomic, strong, nullable) CollectionMessageModel *collectionModel;
@property (nonatomic, weak, nullable) id<CollectionMessageCellDelegate> delegate;
@property (nonatomic, strong, nullable) UITapGestureRecognizer *contentGesture;

@property (nonatomic, strong) NEUserHeaderView *headerView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *conversationLabel;
@property (nonatomic, strong) UIImageView *moreImageView;
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIView *line;
@property (nonatomic, strong, nullable) NSLayoutConstraint *backLeftConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *backRightConstraint;

- (void)setupCommonUI;
- (void)configureData:(CollectionMessageModel *)model;
- (void)moreClick;
- (void)contentClick;
- (void)setFunStyle;

@end

NS_ASSUME_NONNULL_END
