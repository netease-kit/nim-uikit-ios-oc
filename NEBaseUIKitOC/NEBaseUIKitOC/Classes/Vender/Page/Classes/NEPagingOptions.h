// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEPagingContentInteraction.h"
#import "NEPagingBorderOptions.h"
#import "NEPagingIndicatorOptions.h"
#import "NEPagingMenuHorizontalAlignment.h"
#import "NEPagingMenuInteraction.h"
#import "NEPagingMenuPosition.h"
#import "NEPagingMenuItemSize.h"
#import "NEPagingMenuTransition.h"
#import "NEPagingNavigationOrientation.h"
#import "NEPagingSelectedScrollPosition.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEPagingOptions : NSObject <NSCopying>

@property (nonatomic, strong) NEPagingMenuItemSize *menuItemSize;
@property (nonatomic, assign) CGFloat menuItemSpacing;
@property (nonatomic, assign) CGFloat menuItemLabelSpacing;
@property (nonatomic, assign) UIEdgeInsets menuInsets;
@property (nonatomic, assign) NEPagingMenuHorizontalAlignment menuHorizontalAlignment;
@property (nonatomic, assign) NEPagingMenuPosition menuPosition;
@property (nonatomic, assign) NEPagingMenuTransition menuTransition;
@property (nonatomic, assign) PagingMenuInteraction menuInteraction;
@property (nonatomic, assign) PagingContentInteraction contentInteraction;
@property (nonatomic, assign) NEPagingSelectedScrollPosition selectedScrollPosition;
@property (nonatomic, strong) NEPagingIndicatorOptions *indicatorOptions;
@property (nonatomic, assign) Class indicatorClass;
@property (nonatomic, strong) NEPagingBorderOptions *borderOptions;
@property (nonatomic, assign) Class borderClass;
@property (nonatomic, assign) Class menuLayoutClass;
@property (nonatomic, strong) UIColor *indicatorColor;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) BOOL includeSafeAreaInsets;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIFont *selectedFont;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *selectedTextColor;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *selectedBackgroundColor;
@property (nonatomic, strong) UIColor *menuBackgroundColor;
@property (nonatomic, strong) UIColor *pagingContentBackgroundColor;
@property (nonatomic, assign) NEPagingNavigationOrientation contentNavigationOrientation;
@property (nonatomic, assign, readonly) UICollectionViewScrollPosition scrollPosition;
@property (nonatomic, assign, readonly) CGFloat menuHeight;
@property (nonatomic, assign, readonly) CGFloat estimatedItemWidth;

@end

NS_ASSUME_NONNULL_END
