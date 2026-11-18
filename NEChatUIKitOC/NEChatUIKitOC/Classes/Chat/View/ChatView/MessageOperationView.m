// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageOperationView.h"
#import "ChatMenuGeometry.h"
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import "OperationCell.h"
#import "UIImage+Chat.h"
#import "NEChatUIConstant.h"
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEChatKit/UIColor+NECommon.h>

#if __has_include(<NEChatKit/NEChatKit-Swift.h>)
#import <NEChatKit/NEChatKit-Swift.h>
#endif

static const CGFloat kOperationItemWidth = 54.0;
static const CGFloat kOperationVisualItemWidth = 50.0;
static const CGFloat kOperationItemSpacing = 2.0;
static const CGFloat kOperationHorizontalPadding = 4.0;
static const CGFloat kReactionPanelItemSize = 36.0;
static const CGFloat kReactionPanelImageSize = 22.0;
// Five operation cells plus the shared 4pt content inset on each side.
// This keeps the seven-cell reaction rail aligned with the operation grid.

@interface MessageReactionEmojiCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation MessageReactionEmojiCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _imageView = [[UIImageView alloc] init];
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_imageView];
    [NSLayoutConstraint activateConstraints:@[
      [_imageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
      [_imageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
      [_imageView.widthAnchor constraintEqualToConstant:kReactionPanelImageSize],
      [_imageView.heightAnchor constraintEqualToConstant:kReactionPanelImageSize],
    ]];
  }
  return self;
}

@end

@interface MessageOperationView ()
@property (nonatomic, strong) UIView *emojiBackView;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UICollectionView *emojiCollection;
@property (nonatomic, strong) UICollectionView *emojiAllCollection;
@property (nonatomic, strong) UICollectionView *operationCollection;
@property (nonatomic, strong) NSArray<NEMessageReactionEmoji *> *quickReactionItems;
@property (nonatomic, strong) NSArray<NEMessageReactionEmoji *> *allReactionItems;
@property (nonatomic, strong, nullable) NSLayoutConstraint *operationTopToEmoji;
@property (nonatomic, strong, nullable) NSLayoutConstraint *operationTopToView;
@property (nonatomic, assign, readwrite) BOOL showingAllEmoji;
@property (nonatomic, assign) BOOL isClampingFrame;
@end

@implementation MessageOperationView

- (void)layoutSubviews {
  [super layoutSubviews];
  if (self.isClampingFrame) return;
  self.isClampingFrame = YES;
  [self clampFrameToVisibleArea];
  self.isClampingFrame = NO;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) [self setupUI];
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) [self setupUI];
  return self;
}

- (void)setupUI {
  _items = [NSMutableArray array];
  _quickReactionItems = @[];
  _allReactionItems = @[];
  _showMoreButton = YES;
  _viewUnderMessage = YES;
  self.backgroundColor = UIColor.whiteColor;
  self.layer.cornerRadius = 7;
  self.layer.shadowOffset = CGSizeMake(0, 4);
  self.layer.shadowColor = UIColor.ne_operationBorderColor.CGColor;
  self.layer.shadowOpacity = 0.25;
  self.layer.shadowRadius = 7;

  _emojiBackView = [[UIView alloc] init];
  _emojiBackView.translatesAutoresizingMaskIntoConstraints = NO;
  [self addSubview:_emojiBackView];
  [NSLayoutConstraint activateConstraints:@[
    [_emojiBackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
    [_emojiBackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    [_emojiBackView.topAnchor constraintEqualToAnchor:self.topAnchor],
    [_emojiBackView.heightAnchor constraintEqualToConstant:50],
  ]];

  UICollectionViewFlowLayout *quickLayout = [[UICollectionViewFlowLayout alloc] init];
  quickLayout.itemSize = CGSizeMake(kReactionPanelItemSize, kReactionPanelItemSize);
  quickLayout.minimumLineSpacing = 0;
  quickLayout.minimumInteritemSpacing = 0;
  _emojiCollection = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:quickLayout];
  _emojiCollection.translatesAutoresizingMaskIntoConstraints = NO;
  _emojiCollection.delegate = self;
  _emojiCollection.dataSource = self;
  _emojiCollection.backgroundColor = UIColor.clearColor;
  _emojiCollection.showsHorizontalScrollIndicator = NO;
  _emojiCollection.accessibilityIdentifier = @"id.messageReaction.quickCollection";
  [_emojiCollection registerClass:[MessageReactionEmojiCell class] forCellWithReuseIdentifier:NSStringFromClass(MessageReactionEmojiCell.class)];
  [_emojiBackView addSubview:_emojiCollection];
  [NSLayoutConstraint activateConstraints:@[
    [_emojiCollection.leftAnchor constraintEqualToAnchor:_emojiBackView.leftAnchor constant:kOperationHorizontalPadding],
    [_emojiCollection.rightAnchor constraintEqualToAnchor:_emojiBackView.rightAnchor constant:-kOperationHorizontalPadding],
    [_emojiCollection.centerYAnchor constraintEqualToAnchor:_emojiBackView.centerYAnchor],
    [_emojiCollection.heightAnchor constraintEqualToConstant:kReactionPanelItemSize],
  ]];

  _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
  _moreButton.translatesAutoresizingMaskIntoConstraints = NO;
  [_moreButton setImage:chatLoadImage(@"reaction_more_emoji") forState:UIControlStateNormal];
  [_moreButton setImage:chatLoadImage(@"reaction_less_emoji") forState:UIControlStateSelected];
  _moreButton.backgroundColor = UIColor.whiteColor;
  _moreButton.accessibilityIdentifier = @"id.messageReaction.more";
  [_moreButton addTarget:self action:@selector(moreButtonAction) forControlEvents:UIControlEventTouchUpInside];
  [_emojiBackView addSubview:_moreButton];
  _moreButton.imageEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7);
  [NSLayoutConstraint activateConstraints:@[
    [_moreButton.rightAnchor constraintEqualToAnchor:_emojiBackView.rightAnchor constant:-kOperationHorizontalPadding],
    [_moreButton.centerYAnchor constraintEqualToAnchor:_emojiBackView.centerYAnchor],
    [_moreButton.widthAnchor constraintEqualToConstant:kReactionPanelItemSize],
    [_moreButton.heightAnchor constraintEqualToConstant:kReactionPanelItemSize],
  ]];

  UIView *line = [[UIView alloc] init];
  line.translatesAutoresizingMaskIntoConstraints = NO;
  line.backgroundColor = [UIColor ne_colorWithHexString:@"#E4E9F2"];
  [_emojiBackView addSubview:line];
  [NSLayoutConstraint activateConstraints:@[
    [line.leadingAnchor constraintEqualToAnchor:_emojiBackView.leadingAnchor constant:16],
    [line.trailingAnchor constraintEqualToAnchor:_emojiBackView.trailingAnchor constant:-16],
    [line.bottomAnchor constraintEqualToAnchor:_emojiBackView.bottomAnchor],
    [line.heightAnchor constraintEqualToConstant:0.5],
  ]];

  UICollectionViewFlowLayout *operationLayout = [[UICollectionViewFlowLayout alloc] init];
  // Keep the original operation grid geometry so adding the reaction strip
  // does not change the number of action buttons shown on each row.
  operationLayout.itemSize = CGSizeMake(kOperationVisualItemWidth, 56);
  operationLayout.minimumLineSpacing = 0;
  operationLayout.minimumInteritemSpacing = kOperationItemSpacing;
  _operationCollection = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:operationLayout];
  _operationCollection.translatesAutoresizingMaskIntoConstraints = NO;
  _operationCollection.delegate = self;
  _operationCollection.dataSource = self;
  _operationCollection.backgroundColor = UIColor.whiteColor;
  _operationCollection.accessibilityIdentifier = @"id.messageOperation.collection";
  [_operationCollection registerClass:[OperationCell class] forCellWithReuseIdentifier:NSStringFromClass(OperationCell.class)];
  [self addSubview:_operationCollection];
  [NSLayoutConstraint activateConstraints:@[
    [_operationCollection.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:kOperationHorizontalPadding],
    [_operationCollection.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-kOperationHorizontalPadding],
    [_operationCollection.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8],
  ]];
  _operationTopToEmoji = [_operationCollection.topAnchor constraintEqualToAnchor:_emojiBackView.bottomAnchor constant:8];
  _operationTopToView = [_operationCollection.topAnchor constraintEqualToAnchor:self.topAnchor constant:8];
  _operationTopToView.active = YES;
  _emojiBackView.hidden = YES;

  UICollectionViewFlowLayout *allLayout = [[UICollectionViewFlowLayout alloc] init];
  allLayout.itemSize = CGSizeMake(kReactionPanelItemSize, kReactionPanelItemSize);
  allLayout.minimumLineSpacing = 0;
  allLayout.minimumInteritemSpacing = 0;
  _emojiAllCollection = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:allLayout];
  _emojiAllCollection.translatesAutoresizingMaskIntoConstraints = NO;
  _emojiAllCollection.delegate = self;
  _emojiAllCollection.dataSource = self;
  _emojiAllCollection.backgroundColor = UIColor.clearColor;
  _emojiAllCollection.showsHorizontalScrollIndicator = NO;
  _emojiAllCollection.accessibilityIdentifier = @"id.messageReaction.allCollection";
  [_emojiAllCollection registerClass:[MessageReactionEmojiCell class] forCellWithReuseIdentifier:NSStringFromClass(MessageReactionEmojiCell.class)];
}

- (void)setItems:(NSMutableArray<OperationItem *> *)items {
  _items = [items isKindOfClass:NSArray.class] ? [items mutableCopy] : [NSMutableArray array];
  [self.operationCollection reloadData];
}

- (void)setShowMoreButton:(BOOL)showMoreButton {
  _showMoreButton = showMoreButton;
  self.moreButton.hidden = !showMoreButton;
}

- (void)configureReactionsWithProvider:(id)provider quickIndexes:(NSArray<NSNumber *> *)quickIndexes showEmoji:(BOOL)showEmoji showMoreButton:(BOOL)showMoreButton {
  self.showEmoji = showEmoji && provider != nil;
  self.showMoreButton = showMoreButton;
  self.emojiBackView.hidden = !self.showEmoji;
  self.moreButton.hidden = !self.showEmoji || !showMoreButton;
  self.moreButton.selected = NO;
  self.showingAllEmoji = NO;
  if (self.showEmoji && [provider respondsToSelector:@selector(allEmojis)]) {
    self.allReactionItems = [provider allEmojis] ?: @[];
    // Long-press menus reserve the trailing slot for the expand control;
    // message-side panels hide that control and can show the seventh item.
    NSArray<NSNumber *> *visibleIndexes = showMoreButton
      ? [quickIndexes subarrayWithRange:NSMakeRange(0, MIN((NSUInteger)6, quickIndexes.count))]
      : quickIndexes;
    NSMutableArray<NEMessageReactionEmoji *> *quickItems = [NSMutableArray array];
    for (NSNumber *value in visibleIndexes ?: @[]) {
      for (NEMessageReactionEmoji *emoji in self.allReactionItems) {
        if (emoji.index == value.integerValue) {
          [quickItems addObject:emoji];
          break;
        }
      }
    }
    self.quickReactionItems = quickItems;
  } else {
    self.quickReactionItems = @[];
    self.allReactionItems = @[];
  }
  [self.emojiCollection reloadData];
  [self.emojiAllCollection reloadData];
}

- (void)showAllEmoji {
  if (!self.showEmoji) return;
  if (self.oldFrameWidth <= 0) self.oldFrameWidth = CGRectGetWidth(self.frame);
  // Preserve the operation menu width. The reaction collection wraps at
  // that width, so expanding the emoji grid never changes the popup edges.
  CGFloat expandedWidth = self.oldFrameWidth > 0 ? self.oldFrameWidth : CGRectGetWidth(self.frame);
  if (CGRectGetWidth(self.frame) != expandedWidth) {
    CGFloat oldMaxX = CGRectGetMaxX(self.frame);
    CGFloat hostWidth = CGRectGetWidth(self.superview.bounds) > 0 ? CGRectGetWidth(self.superview.bounds)
                                        : UIScreen.mainScreen.bounds.size.width;
    BOOL keepTrailingEdge = CGRectGetMidX(self.frame) > hostWidth / 2.0;
    CGRect compactFrame = self.frame;
    compactFrame.size.width = expandedWidth;
    if (keepTrailingEdge) compactFrame.origin.x = oldMaxX - expandedWidth;
    self.frame = compactFrame;
  }
  [self updateReactionLayoutSpacing];
  self.operationCollection.hidden = YES;
  self.showingAllEmoji = YES;
  if (!self.emojiAllCollection.superview) {
    [self addSubview:self.emojiAllCollection];
    [NSLayoutConstraint activateConstraints:@[
      [self.emojiAllCollection.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:kOperationHorizontalPadding],
      [self.emojiAllCollection.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-kOperationHorizontalPadding],
      [self.emojiAllCollection.topAnchor constraintEqualToAnchor:self.emojiBackView.bottomAnchor],
      [self.emojiAllCollection.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8],
    ]];
  }
  self.emojiAllCollection.hidden = NO;
  // The operation view is reused between messages. Reset both before and
  // after layout: reloadData can restore the previous offset during the first
  // layout pass when the collection was previously scrolled.
  [self resetAllEmojiCollectionToTop];
  CGFloat expandedHeight = 310.0;
  if (!self.viewUnderMessage && self.showMoreButton) {
    self.frame = CGRectOffset(self.frame, 0, -MAX(0, expandedHeight - CGRectGetHeight(self.frame)));
  }
  CGRect frame = self.frame;
  frame.size.height = expandedHeight;
  self.frame = frame;
  [self layoutIfNeeded];
  [self clampFrameToVisibleArea];
}

- (void)resetAllEmojiCollectionToTop {
  [self layoutIfNeeded];
  [self.emojiAllCollection layoutIfNeeded];
  [self.emojiAllCollection setContentOffset:CGPointZero animated:NO];

  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || self.emojiAllCollection.hidden) return;
    [self layoutIfNeeded];
    [self.emojiAllCollection layoutIfNeeded];
    CGPoint top = CGPointMake(0, -self.emojiAllCollection.adjustedContentInset.top);
    [self.emojiAllCollection setContentOffset:top animated:NO];
  });
}

- (void)updateReactionLayoutSpacing {
  CGFloat spacing = [self reactionInteritemSpacing];
  UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.emojiCollection.collectionViewLayout;
  if ([layout isKindOfClass:UICollectionViewFlowLayout.class]) {
    layout.minimumInteritemSpacing = spacing;
    [layout invalidateLayout];
  }
  UICollectionViewFlowLayout *allLayout = (UICollectionViewFlowLayout *)self.emojiAllCollection.collectionViewLayout;
  if ([allLayout isKindOfClass:UICollectionViewFlowLayout.class]) {
    allLayout.minimumInteritemSpacing = spacing;
    [allLayout invalidateLayout];
  }
}

- (CGFloat)reactionInteritemSpacing {
  CGFloat contentWidth = MAX(0, CGRectGetWidth(self.frame) - kOperationHorizontalPadding * 2);
  return MAX(0, (contentWidth - kReactionPanelItemSize * 7) / 6.0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  if (collectionView == self.operationCollection) {
    return CGSizeMake(kOperationVisualItemWidth, 56.0);
  }
  return CGSizeMake(kReactionPanelItemSize, kReactionPanelItemSize);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
 minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
  if (collectionView == self.operationCollection) return kOperationItemSpacing;
  return [self reactionInteritemSpacing];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
  if (collectionView != self.operationCollection) return UIEdgeInsetsZero;
  // Keep the first operation on the same five-column grid origin even when
  // this message type exposes only a small subset of actions.
  NSUInteger columnCount = 5;
  CGFloat occupiedWidth = columnCount * kOperationVisualItemWidth +
    MAX(0, (NSInteger)columnCount - 1) * kOperationItemSpacing;
  CGFloat inset = MAX(0, (CGRectGetWidth(collectionView.bounds) - occupiedWidth) / 2.0);
  return UIEdgeInsetsMake(0, inset, 0, inset);
}

- (void)showOperation {
  [self updateReactionLayoutSpacing];
  self.emojiAllCollection.hidden = YES;
  self.operationCollection.hidden = NO;
  self.showingAllEmoji = NO;
  self.operationTopToEmoji.active = NO;
  self.operationTopToView.active = NO;
  (self.showEmoji ? self.operationTopToEmoji : self.operationTopToView).active = YES;
  [self clampFrameToVisibleArea];
}

- (void)clampFrameToVisibleArea {
  UIView *host = self.superview;
  if (!host) return;

  CGRect area;
  if (self.hasVisibleFrame) {
    area = self.visibleFrame;
  } else {
    UIEdgeInsets insets = UIEdgeInsetsMake(MAX(0.0, NEUIKitNavigationAndStatusHeight()),
                                           0.0,
                                           MAX(0.0, host.safeAreaInsets.bottom),
                                           0.0);
    area = UIEdgeInsetsInsetRect(host.bounds, insets);
  }

  if (self.hasMessageRect) {
    CGRect resolved = CGRectZero;
    if (ChatMenuFrameForMessage(self.messageRect, host.bounds, area, self.frame.size, 8.0, &resolved)) {
      self.frame = resolved;
      self.viewUnderMessage = CGRectGetMinY(resolved) >= CGRectGetMaxY(self.messageRect);
      return;
    }
  }

  CGFloat top = MAX(0.0, CGRectGetMinY(area));
  CGFloat bottom = MIN(CGRectGetHeight(host.bounds), CGRectGetMaxY(area));
  CGFloat maxY = MAX(top, bottom - CGRectGetHeight(self.frame));
  CGRect frame = self.frame;
  frame.origin.y = MIN(MAX(CGRectGetMinY(frame), top), maxY);
  self.frame = frame;
}

- (void)moreButtonAction {
  self.moreButton.selected = !self.moreButton.selected;
  if (self.moreButton.selected) {
    [self showAllEmoji];
  } else {
    CGFloat targetWidth = self.oldFrameWidth > 0 ? self.oldFrameWidth : CGRectGetWidth(self.frame);
    if (CGRectGetWidth(self.frame) < targetWidth) {
      CGFloat currentMaxX = CGRectGetMaxX(self.frame);
      CGFloat hostWidth = CGRectGetWidth(self.superview.bounds) > 0 ? CGRectGetWidth(self.superview.bounds)
                                        : UIScreen.mainScreen.bounds.size.width;
    BOOL keepTrailingEdge = CGRectGetMidX(self.frame) > hostWidth / 2.0;
      CGRect restoredFrame = self.frame;
      restoredFrame.size.width = targetWidth;
      if (keepTrailingEdge) restoredFrame.origin.x = currentMaxX - targetWidth;
      self.frame = restoredFrame;
    }
    if (!self.viewUnderMessage) self.frame = CGRectOffset(self.frame, 0, MAX(0, 310 - self.oldFrameHeight));
    CGRect frame = self.frame;
    frame.size.height = self.oldFrameHeight;
    self.frame = frame;
    [self showOperation];
  }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  if (collectionView == self.emojiAllCollection) return self.allReactionItems.count;
  if (collectionView == self.emojiCollection) return self.quickReactionItems.count;
  return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  if (collectionView == self.emojiCollection || collectionView == self.emojiAllCollection) {
    MessageReactionEmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(MessageReactionEmojiCell.class) forIndexPath:indexPath];
    NSArray<NEMessageReactionEmoji *> *emojis = collectionView == self.emojiCollection ? self.quickReactionItems : self.allReactionItems;
    if (indexPath.item < emojis.count) {
      NEMessageReactionEmoji *emoji = emojis[indexPath.item];
      cell.imageView.image = chatLoadImage(emoji.resourceName);
      cell.accessibilityLabel = emoji.accessibilityDescription;
      cell.accessibilityIdentifier = [NSString stringWithFormat:@"id.messageReaction.emoji.%ld", (long)emoji.index];
    }
    return cell;
  }
  OperationCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(OperationCell.class) forIndexPath:indexPath];
  if (indexPath.item < self.items.count) cell.model = self.items[indexPath.item];
  return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  self.hidden = YES;
  if (collectionView == self.emojiCollection || collectionView == self.emojiAllCollection) {
    NSArray<NEMessageReactionEmoji *> *emojis = collectionView == self.emojiCollection ? self.quickReactionItems : self.allReactionItems;
    if (indexPath.item < emojis.count && self.onSelectReaction) self.onSelectReaction(emojis[indexPath.item].index);
    return;
  }
  if (indexPath.item < self.items.count && [self.delegate respondsToSelector:@selector(didSelectedItem:)]) {
    [self.delegate didSelectedItem:self.items[indexPath.item]];
  }
}

@end
