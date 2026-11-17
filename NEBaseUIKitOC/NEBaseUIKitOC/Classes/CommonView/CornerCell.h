// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEBaseUIKitOC/NECustomActionSheetController.h>  // CornerType 定义在此

NS_ASSUME_NONNULL_BEGIN

@interface CornerCell : UITableViewCell

@property (nonatomic, strong) CAShapeLayer *cornerLayer;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, assign) UIEdgeInsets edgeInset;
@property (nonatomic, assign) CornerType cornerType;
@property (nonatomic, assign) BOOL showDefaultLine;
@property (nonatomic, strong) UIView *dividerLine;
@property (nonatomic, strong, nullable) NSLayoutConstraint *dividerLineLeftMargin;
@property (nonatomic, strong, nullable) NSLayoutConstraint *dividerLineRightMargin;

- (void)drawRoundedCornerWithRect:(CGRect)rect;
- (void)drawRoundedCornerInRect:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
