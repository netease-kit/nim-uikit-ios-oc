// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (NEHierarchy)

- (nullable UIViewController *)neViewContainingController;
- (nullable UIViewController *)neTopMostController;
- (nullable UIViewController *)neParentContainerViewController;
- (nullable UIView *)neSuperviewOfClassType:(Class)classType;
- (nullable UIView *)neSuperviewOfClassType:(Class)classType belowView:(nullable UIView *)belowView;
- (NSArray<UIView *> *)neResponderSiblings;
- (NSArray<UIView *> *)neDeepResponderViews;
- (nullable UISearchBar *)neTextFieldSearchBar;
- (BOOL)neIsAlertViewTextField;

@end

@interface NSObject (NEHierarchyDescription)

- (NSString *)_NEDescription;

@end

NS_ASSUME_NONNULL_END
