// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, CornerType) {
  CornerTypeNone        = 0,
  CornerTypeTopLeft     = 1 << 0,
  CornerTypeTopRight    = 1 << 1,
  CornerTypeBottomLeft  = 1 << 2,
  CornerTypeBottomRight = 1 << 3,
};

/// 单个操作项视图
@interface NECustomAlertAction : UIView

@property (nonatomic, assign) BOOL showDefaultLine;
@property (nonatomic, strong) UILabel *contentText;
@property (nonatomic, copy, nullable) void (^clickAction)(void);
@property (nonatomic, copy, nullable) void (^cancelAction)(void);
@property (nonatomic, assign) CornerType cornerType;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, assign) UIEdgeInsets edgeInset;
@property (nonatomic, strong) UIView *dividerLine;
@property (nonatomic, strong, nullable) NSLayoutConstraint *dividerLineLeftMargin;
@property (nonatomic, strong, nullable) NSLayoutConstraint *dividerLineRightMargin;

- (instancetype)initWithTitle:(nullable NSString *)title completion:(nullable void (^)(void))completion;
+ (instancetype)actionWithTitle:(nullable NSString *)title handler:(nullable void (^)(void))handler;

@end

// -----------------------------------------------

/// 自定义底部弹出操作表
@interface NECustomActionSheetController : UIViewController

@property (nonatomic, strong) NECustomAlertAction *cancelAction;
@property (nonatomic, strong) UIView *boldDividerLine;

- (void)addAction:(NECustomAlertAction *)action actionHeight:(CGFloat)actionHeight;

@end

NS_ASSUME_NONNULL_END
