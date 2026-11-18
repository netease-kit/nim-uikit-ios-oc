// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

#import "NEPagingKitProxy.h"

NS_ASSUME_NONNULL_BEGIN

@class NETabPagingMenuView;
@class PagingMenuFocusViewAnimationCoordinator;

typedef NS_ENUM(NSUInteger, NETabPagingMenuViewAlignment) {
  NETabPagingMenuViewAlignmentCenter,
  NETabPagingMenuViewAlignmentLeft,
  NETabPagingMenuViewAlignmentRight,
};

@interface NEPagingMenuViewCell : UIView

@property (nonatomic, assign, getter=isSelected) BOOL selected;
@property (nonatomic, copy, readonly, nullable) NSString *identifier;
@property (nonatomic, strong, readonly, nullable) NSNumber *index;

@end

typedef void (^PagingMenuFocusViewAnimationBlock)(PagingMenuFocusViewAnimationCoordinator *coordinator);

@interface PagingMenuFocusViewAnimationCoordinator : NSObject

@property (nonatomic, assign, readonly) CGRect beginFrame;
@property (nonatomic, assign, readonly) CGRect endFrame;

- (instancetype)initWithBeginFrame:(CGRect)beginFrame endFrame:(CGRect)endFrame;
- (void)animateFocusViewAlongside:(PagingMenuFocusViewAnimationBlock)animation
                       completion:(nullable NEPagingKitAnimationCompletion)completion;

@end

@interface PagingMenuFocusView : UIView

@property (nonatomic, strong, nullable) NSNumber *selectedIndex;

@end

@protocol PagingMenuViewDataSource <NSObject>

- (NSInteger)numberOfItemForPagingMenuView;
- (NEPagingMenuViewCell *)pagingMenuView:(NETabPagingMenuView *)pagingMenuView
                           cellForItemAt:(NSInteger)index;
- (CGFloat)pagingMenuView:(NETabPagingMenuView *)pagingMenuView
           widthForItemAt:(NSInteger)index;

@end

@protocol PagingMenuViewDelegate <NSObject>
@optional

- (void)pagingMenuView:(NETabPagingMenuView *)pagingMenuView
       didSelectItemAt:(NSInteger)index;
- (void)pagingMenuView:(NETabPagingMenuView *)pagingMenuView
willAnimateFocusViewTo:(NSInteger)index
        withCoordinator:(PagingMenuFocusViewAnimationCoordinator *)coordinator;
- (void)pagingMenuView:(NETabPagingMenuView *)pagingMenuView
           willDisplay:(NEPagingMenuViewCell *)cell
             forItemAt:(NSInteger)index;

@end

@interface NETabPagingMenuView : UIScrollView

@property (nonatomic, strong, readonly) PagingMenuFocusView *focusView;
@property (nonatomic, copy, readonly) NSArray<NEPagingMenuViewCell *> *visibleCells;
@property (nonatomic, assign) NETabPagingMenuViewAlignment cellAlignment;
@property (nonatomic, assign) CGFloat cellSpacing;
@property (nonatomic, assign, readonly) CGFloat totalSpacing;
@property (nonatomic, weak, nullable) id<PagingMenuViewDataSource> dataSource;
@property (nonatomic, weak, nullable) id<PagingMenuViewDelegate> menuDelegate;
@property (nonatomic, assign, readonly) NSInteger numberOfItem;

- (nullable NSNumber *)indexForItemAtPoint:(CGPoint)point;
- (nullable NEPagingMenuViewCell *)cellForItemAtIndex:(NSInteger)index;
- (void)reloadDataWithIndex:(NSInteger)index
                 completion:(nullable NEPagingKitAnimationCompletion)completion;
- (void)registerNib:(nullable UINib *)nib withIdentifier:(NSString *)identifier;
- (void)registerClass:(Class)cellClass withIdentifier:(NSString *)identifier;
- (void)registerFocusView:(UIView *)view isBehindCell:(BOOL)isBehindCell;
- (void)registerFocusViewNib:(UINib *)nib isBehindCell:(BOOL)isBehindCell;
- (NEPagingMenuViewCell *)dequeueWithIdentifier:(NSString *)identifier;
- (CGRect)rectForItemAtIndex:(NSInteger)index;
- (void)invalidateLayout;
- (void)scrollToIndex:(NSInteger)index percent:(CGFloat)percent;
- (void)scrollToIndex:(NSInteger)index
           completion:(NEPagingKitAnimationCompletion)completion;
- (nullable NSNumber *)expectedAlignmentPositionXIfNeeded;

@end

NS_ASSUME_NONNULL_END
