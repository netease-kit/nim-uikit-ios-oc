// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingOptions.h"

@implementation NEPagingOptions

- (instancetype)init {
  self = [super init];
  if (self) {
    _selectedScrollPosition = NEPagingSelectedScrollPositionPreferCentered;
    _menuItemSize = [NEPagingMenuItemSize sizeToFitMinWidth:150 height:40];
    _menuPosition = NEPagingMenuPositionTop;
    _menuTransition = NEPagingMenuTransitionScrollAlongside;
    _menuInteraction = PagingMenuInteractionScrolling;
    _menuItemSpacing = 0;
    _menuItemLabelSpacing = 20;
    _menuInsets = UIEdgeInsetsZero;
    _menuHorizontalAlignment = NEPagingMenuHorizontalAlignmentLeft;
    _contentInteraction = PagingContentInteractionScrolling;
    _includeSafeAreaInsets = YES;
    _indicatorOptions = [NEPagingIndicatorOptions visibleWithHeight:4
                                                             zIndex:NSIntegerMax
                                                            spacing:UIEdgeInsetsZero
                                                             insets:UIEdgeInsetsMake(0, 8, 0, 8)];
    _borderOptions = [NEPagingBorderOptions visibleWithHeight:1
                                                       zIndex:NSIntegerMax - 1
                                                       insets:UIEdgeInsetsMake(0, 8, 0, 8)];
    _font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    _selectedFont = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    _textColor = [UIColor blackColor];
    _selectedTextColor = [UIColor colorWithRed:3.0 / 255.0 green:125.0 / 255.0 blue:233.0 / 255.0 alpha:1.0];
    _backgroundColor = [UIColor clearColor];
    _selectedBackgroundColor = [UIColor clearColor];
    _menuBackgroundColor = [UIColor whiteColor];
    _pagingContentBackgroundColor = [UIColor whiteColor];
    _borderColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    _indicatorColor = [UIColor colorWithRed:3.0 / 255.0 green:125.0 / 255.0 blue:233.0 / 255.0 alpha:1.0];
    _contentNavigationOrientation = NEPagingNavigationOrientationHorizontal;
    _indicatorClass = NSClassFromString(@"NEPagingIndicatorView");
    _borderClass = NSClassFromString(@"NEPagingBorderView");
    _menuLayoutClass = NSClassFromString(@"NEPagingCollectionViewLayout");
  }
  return self;
}

- (CGFloat)menuHeight {
  return self.menuItemSize.height + self.menuInsets.top + self.menuInsets.bottom;
}

- (UICollectionViewScrollPosition)scrollPosition {
  switch (self.selectedScrollPosition) {
    case NEPagingSelectedScrollPositionLeft:
      return UICollectionViewScrollPositionLeft;
    case NEPagingSelectedScrollPositionRight:
      return UICollectionViewScrollPositionRight;
    case NEPagingSelectedScrollPositionPreferCentered:
    case NEPagingSelectedScrollPositionCenter:
      return UICollectionViewScrollPositionCenteredHorizontally;
  }
}

- (CGFloat)estimatedItemWidth {
  return self.menuItemSize.width;
}

- (id)copyWithZone:(NSZone *)zone {
  NEPagingOptions *copy = [[[self class] allocWithZone:zone] init];
  copy.selectedScrollPosition = self.selectedScrollPosition;
  copy.menuItemSize = [self.menuItemSize copy];
  copy.menuHorizontalAlignment = self.menuHorizontalAlignment;
  copy.menuPosition = self.menuPosition;
  copy.menuTransition = self.menuTransition;
  copy.menuInteraction = self.menuInteraction;
  copy.menuItemSpacing = self.menuItemSpacing;
  copy.menuItemLabelSpacing = self.menuItemLabelSpacing;
  copy.menuInsets = self.menuInsets;
  copy.contentInteraction = self.contentInteraction;
  copy.indicatorOptions = [self.indicatorOptions copy];
  copy.indicatorClass = self.indicatorClass;
  copy.borderOptions = [self.borderOptions copy];
  copy.borderClass = self.borderClass;
  copy.menuLayoutClass = self.menuLayoutClass;
  copy.indicatorColor = self.indicatorColor;
  copy.borderColor = self.borderColor;
  copy.includeSafeAreaInsets = self.includeSafeAreaInsets;
  copy.font = self.font;
  copy.selectedFont = self.selectedFont;
  copy.textColor = self.textColor;
  copy.selectedTextColor = self.selectedTextColor;
  copy.backgroundColor = self.backgroundColor;
  copy.selectedBackgroundColor = self.selectedBackgroundColor;
  copy.menuBackgroundColor = self.menuBackgroundColor;
  copy.pagingContentBackgroundColor = self.pagingContentBackgroundColor;
  copy.contentNavigationOrientation = self.contentNavigationOrientation;
  return copy;
}

@end
