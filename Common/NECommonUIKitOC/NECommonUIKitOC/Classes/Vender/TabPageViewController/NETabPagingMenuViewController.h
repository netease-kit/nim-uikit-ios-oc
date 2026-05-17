// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

#import "NETabPagingMenuView.h"

NS_ASSUME_NONNULL_BEGIN

@class NETabPagingMenuViewController;

@protocol NETabPagingMenuViewControllerDelegate <NSObject>
@optional

- (void)menuViewController:(NETabPagingMenuViewController *)viewController
  focusViewDidEndTransition:(PagingMenuFocusView *)focusView;
- (void)menuViewController:(NETabPagingMenuViewController *)viewController
   willAnimateFocusViewTo:(NSInteger)index
          withCoordinator:(PagingMenuFocusViewAnimationCoordinator *)coordinator;
- (void)menuViewController:(NETabPagingMenuViewController *)viewController
               willDisplay:(NEPagingMenuViewCell *)cell
                 forItemAt:(NSInteger)index;

@required

- (void)menuViewController:(NETabPagingMenuViewController *)viewController
                 didSelect:(NSInteger)page
              previousPage:(NSInteger)previousPage;

@end

@protocol NETabPagingMenuViewControllerDataSource <NSObject>

- (NSInteger)numberOfItemsForMenuViewController:(NETabPagingMenuViewController *)viewController;
- (NEPagingMenuViewCell *)menuViewController:(NETabPagingMenuViewController *)viewController
                               cellForItemAt:(NSInteger)index;
- (CGFloat)menuViewController:(NETabPagingMenuViewController *)viewController
               widthForItemAt:(NSInteger)index;

@end

@interface NETabPagingMenuViewController : UIViewController

@property (nonatomic, weak, nullable) id<NETabPagingMenuViewControllerDelegate> delegate;
@property (nonatomic, weak, nullable) id<NETabPagingMenuViewControllerDataSource> dataSource;
@property (nonatomic, strong, readonly) NETabPagingMenuView *menuView;
@property (nonatomic, strong, readonly) PagingMenuFocusView *focusView;
@property (nonatomic, assign, readonly) CGPoint focusPointerOffset;
@property (nonatomic, assign, readonly) CGFloat percentOffset;
@property (nonatomic, assign) NETabPagingMenuViewAlignment cellAlignment;
@property (nonatomic, assign) CGFloat cellSpacing;
@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, copy, readonly) NSArray<NEPagingMenuViewCell *> *visibleCells;
@property (nonatomic, strong, readonly, nullable) NEPagingMenuViewCell *currentFocusedCell;
@property (nonatomic, strong, readonly, nullable) NSNumber *currentFocusedIndex;

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated;
- (void)scrollToIndex:(NSInteger)index percent:(CGFloat)percent animated:(BOOL)animated;
- (nullable NEPagingMenuViewCell *)cellForItemAtIndex:(NSInteger)index;
- (void)registerFocusView:(UIView *)view isBehindCell:(BOOL)isBehindCell;
- (void)registerFocusViewNib:(UINib *)nib isBehindCell:(BOOL)isBehindCell;
- (void)registerNib:(nullable UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;
- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;
- (NEPagingMenuViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier
                                                        forIndex:(NSInteger)index;
- (void)reloadData;
- (void)reloadDataWithPreferredFocusIndex:(nullable NSNumber *)preferredFocusIndex
                        completionHandler:(nullable NEPagingKitAnimationCompletion)completionHandler;
- (void)invalidateLayout;

@end

NS_ASSUME_NONNULL_END
