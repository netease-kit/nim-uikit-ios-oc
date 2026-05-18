// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 工具类：在独立 Window 上弹出 UIAlertController
@interface NEAlertViewController : NSObject

+ (void)presentAlertWithTitle:(nullable NSString *)title
               messageContent:(nullable NSString *)messageContent
                  cancelTitle:(nullable NSString *)cancelTitle
                 confirmTitle:(nullable NSString *)confirmTitle
               cancelComplete:(nullable void (^)(void))cancelComplete
              confirmComplete:(nullable void (^)(void))confirmComplete;

+ (void)removePresentAlertViewController;

@end

NS_ASSUME_NONNULL_END
