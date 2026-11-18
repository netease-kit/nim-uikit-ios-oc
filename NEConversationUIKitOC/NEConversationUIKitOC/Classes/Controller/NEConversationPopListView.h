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
