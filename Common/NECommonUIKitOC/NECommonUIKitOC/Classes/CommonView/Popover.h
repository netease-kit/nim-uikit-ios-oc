// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PopoverType) {
  PopoverTypeUp = 0,
  PopoverTypeDown,
  PopoverTypeLeft,
  PopoverTypeRight,
  PopoverTypeAuto,
};

typedef NS_ENUM(NSInteger, PopoverOptionType) {
  PopoverOptionTypeArrowSize = 0,
  PopoverOptionTypeAnimationIn,
  PopoverOptionTypeAnimationOut,
  PopoverOptionTypeCornerRadius,
  PopoverOptionTypeSideEdge,
  PopoverOptionTypeBlackOverlayColor,
  PopoverOptionTypeOverlayBlur,
  PopoverOptionTypeType,
  PopoverOptionTypeColor,
  PopoverOptionTypeDismissOnBlackOverlayTap,
  PopoverOptionTypeShowBlackOverlay,
  PopoverOptionTypeSpringDamping,
  PopoverOptionTypeInitialSpringVelocity,
  PopoverOptionTypeSideOffset,
  PopoverOptionTypeBorderColor,
};

@interface PopoverOption : NSObject

@property (nonatomic, assign) PopoverOptionType type;
@property (nonatomic, strong, nullable) id value;

+ (instancetype)optionWithType:(PopoverOptionType)type value:(nullable id)value;

@end

@interface Popover : UIView

@property (nonatomic, assign) CGSize arrowSize;
@property (nonatomic, assign) NSTimeInterval animationIn;
@property (nonatomic, assign) NSTimeInterval animationOut;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat sideEdge;
@property (nonatomic, assign) PopoverType popoverType;
@property (nonatomic, strong) UIColor *blackOverlayColor;
@property (nonatomic, strong, nullable) UIBlurEffect *overlayBlur;
@property (nonatomic, strong) UIColor *popoverColor;
@property (nonatomic, assign) BOOL dismissOnBlackOverlayTap;
@property (nonatomic, assign) BOOL showBlackOverlay;
@property (nonatomic, assign) BOOL highlightFromView;
@property (nonatomic, assign) CGFloat highlightCornerRadius;
@property (nonatomic, assign) CGFloat springDamping;
@property (nonatomic, assign) CGFloat initialSpringVelocity;
@property (nonatomic, assign) CGFloat sideOffset;
@property (nonatomic, strong, nullable) UIColor *borderColor;

@property (nonatomic, copy, nullable) void (^willShowHandler)(void);
@property (nonatomic, copy, nullable) void (^willDismissHandler)(void);
@property (nonatomic, copy, nullable) void (^didShowHandler)(void);
@property (nonatomic, copy, nullable) void (^didDismissHandler)(void);

@property (nonatomic, strong, readonly) UIControl *blackOverlay;

- (instancetype)init;
- (instancetype)initWithShowHandler:(nullable void (^)(void))showHandler
                     dismissHandler:(nullable void (^)(void))dismissHandler;
- (instancetype)initWithOptions:(nullable NSArray<PopoverOption *> *)options
                    showHandler:(nullable void (^)(void))showHandler
                 dismissHandler:(nullable void (^)(void))dismissHandler;

- (void)showAsDialog:(UIView *)contentView;
- (void)showAsDialog:(UIView *)contentView inView:(UIView *)inView;
- (void)show:(UIView *)contentView fromView:(UIView *)fromView;
- (void)show:(UIView *)contentView fromView:(UIView *)fromView inView:(UIView *)inView;
- (void)show:(UIView *)contentView point:(CGPoint)point;
- (void)show:(UIView *)contentView point:(CGPoint)point inView:(UIView *)inView;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END

