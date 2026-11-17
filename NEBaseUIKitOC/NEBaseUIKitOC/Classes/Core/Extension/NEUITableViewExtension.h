// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Compatibility header. Implementation is provided by UIView+YXToast.
@interface UITableView (NEUITableViewExtension)

- (void)reloadData:(NSArray<NSIndexPath *> *)indexs;
- (void)reloadData:(NSArray<NSIndexPath *> *)indexs
         animation:(UITableViewRowAnimation)animation
        completion:(nullable void (^)(BOOL finished))completion;
- (void)deleteData:(NSArray<NSIndexPath *> *)indexs;
- (void)deleteData:(NSArray<NSIndexPath *> *)indexs
         animation:(UITableViewRowAnimation)animation
        completion:(nullable void (^)(BOOL finished))completion;
- (void)insertData:(NSArray<NSIndexPath *> *)indexs;
- (void)insertData:(NSArray<NSIndexPath *> *)indexs
         animation:(UITableViewRowAnimation)animation
        completion:(nullable void (^)(BOOL finished))completion;

@end

NS_ASSUME_NONNULL_END
