// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PopListItem : NSObject

@property (nonatomic, strong, nullable) UIImage *image;
@property (nonatomic, copy, nullable) NSString *showName;
@property (nonatomic, strong) UIColor *showNameColor;
@property (nonatomic, copy, nullable) dispatch_block_t completion;

@end

@interface NEBasePopListView : UIView

@property (nonatomic, strong, readonly) UIView *shadowView;
@property (nonatomic, strong, readonly) UIView *popView;
@property (nonatomic, assign) CGFloat buttonHeight;
@property (nonatomic, assign) CGFloat popViewWidth;
@property (nonatomic, assign) CGFloat popViewHeight;
@property (nonatomic, assign) CGFloat popViewRadius;
@property (nonatomic, assign) CGFloat topConstant;
@property (nonatomic, copy) NSArray<PopListItem *> *itemDatas;

/// 弹窗锚点：优先跟随实际点击的入口（导航栏按钮或迁移到侧栏后的侧栏按钮）。
@property (nonatomic, weak, nullable) UIView *anchorView;
/// 直接给定的锚点矩形（self 坐标系），优先于 anchorView；nil 表示不指定。
@property (nonatomic, strong, nullable) NSValue *anchorRect;
/// 锚点定位使用的顶部/右侧约束，由子类 setupUI 赋值。
@property (nonatomic, strong, nullable) NSLayoutConstraint *shadowTopConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *shadowRightConstraint;

- (void)setupUI;
- (void)itemClick:(UIButton *)sender;
- (void)removeSelf;

@end

/// NormalUI implementation. The runtime hierarchy intentionally matches Swift:
/// PopListView/FunPopListView -> NEBasePopListView.
@interface PopListView : NEBasePopListView
@end

@interface FunPopListView : NEBasePopListView
@property (nonatomic, strong) UIView *triangleView;
@end

/// Source-compatible aliases retained for older Objective-C call sites. They
/// are aliases, not additional runtime classes, so they do not alter the Swift
/// parity hierarchy above.
@compatibility_alias NEConversationPopListItem PopListItem;
@compatibility_alias NEConversationBasePopListView NEBasePopListView;
@compatibility_alias NEConversationNormalPopListView PopListView;
@compatibility_alias NEConversationFunPopListView FunPopListView;

NS_ASSUME_NONNULL_END
