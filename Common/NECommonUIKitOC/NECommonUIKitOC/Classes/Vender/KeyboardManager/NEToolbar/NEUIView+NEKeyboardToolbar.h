// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

@class NEToolbar;

NS_ASSUME_NONNULL_BEGIN

@interface NEBarButtonItemConfiguration : NSObject

@property (nonatomic, assign, readonly) UIBarButtonSystemItem barButtonSystemItem;
@property (nonatomic, assign, readonly) BOOL hasSystemItem;
@property (nonatomic, strong, readonly, nullable) UIImage *image;
@property (nonatomic, copy, readonly, nullable) NSString *title;
@property (nonatomic, assign, readonly, nullable) SEL action;
@property (nonatomic, copy, nullable) NSString *accessibilityLabel;

- (instancetype)initWithBarButtonSystemItem:(UIBarButtonSystemItem)barButtonSystemItem
                                     action:(nullable SEL)action;
- (instancetype)initWithImage:(UIImage *)image action:(nullable SEL)action;
- (instancetype)initWithTitle:(NSString *)title action:(nullable SEL)action;

@end

@interface UIImage (NEKeyboardToolbarImage)

+ (nullable UIImage *)neKeyboardLeftImage;
+ (nullable UIImage *)neKeyboardRightImage;
+ (nullable UIImage *)neKeyboardUpImage;
+ (nullable UIImage *)neKeyboardDownImage;
+ (nullable UIImage *)neKeyboardPreviousImage;
+ (nullable UIImage *)neKeyboardNextImage;

@end

@interface UIView (NEKeyboardToolbar)

@property (nonatomic, strong) NEToolbar *neKeyboardToolbar;
@property (nonatomic, assign) BOOL neShouldHideToolbarPlaceholder;
@property (nonatomic, copy, nullable) NSString *neToolbarPlaceholder;
@property (nonatomic, copy, readonly, nullable) NSString *neDrawingToolbarPlaceholder;

- (void)neAddKeyboardToolbarWithTarget:(nullable id)target
                             titleText:(nullable NSString *)titleText
           rightBarButtonConfiguration:(nullable NEBarButtonItemConfiguration *)rightBarButtonConfiguration
        previousBarButtonConfiguration:(nullable NEBarButtonItemConfiguration *)previousBarButtonConfiguration
            nextBarButtonConfiguration:(nullable NEBarButtonItemConfiguration *)nextBarButtonConfiguration;

- (void)neAddDoneOnKeyboardWithTarget:(nullable id)target action:(SEL)action;
- (void)neAddDoneOnKeyboardWithTarget:(nullable id)target
                               action:(SEL)action
                    shouldShowPlaceholder:(BOOL)shouldShowPlaceholder;
- (void)neAddRightButtonOnKeyboardWithImage:(UIImage *)image
                                     target:(nullable id)target
                                     action:(SEL)action;
- (void)neAddRightButtonOnKeyboardWithText:(NSString *)text
                                    target:(nullable id)target
                                    action:(SEL)action;
- (void)neAddCancelDoneOnKeyboardWithTarget:(nullable id)target
                               cancelAction:(SEL)cancelAction
                                 doneAction:(SEL)doneAction;
- (void)neAddPreviousNextDoneOnKeyboardWithTarget:(nullable id)target
                                   previousAction:(SEL)previousAction
                                       nextAction:(SEL)nextAction
                                       doneAction:(SEL)doneAction;

@end

NS_ASSUME_NONNULL_END
