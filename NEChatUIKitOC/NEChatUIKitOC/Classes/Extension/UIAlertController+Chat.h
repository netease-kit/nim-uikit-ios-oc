// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIAlertController (Chat)

/// Show an alert with Cancel + OK buttons.
/// @param title  Alert title (nullable)
/// @param message  Alert message (nullable)
/// @param confirm  Block invoked when user taps OK
+ (UIAlertController *)reconfirmAlertViewWithTitle:(NSString * _Nullable)title
                                           message:(NSString * _Nullable)message
                                           confirm:(void (^)(void))confirm;

/// Show an alert with only an OK button.
/// @param title  Alert title (nullable)
/// @param message  Alert message (nullable)
/// @param confirm  Block invoked when user taps OK
+ (UIAlertController *)singleAlertViewWithTitle:(NSString * _Nullable)title
                                        message:(NSString * _Nullable)message
                                        confirm:(void (^)(void))confirm;

@end

NS_ASSUME_NONNULL_END
