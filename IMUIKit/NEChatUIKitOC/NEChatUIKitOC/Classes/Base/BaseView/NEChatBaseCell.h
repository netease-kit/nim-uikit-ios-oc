// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

@class MessageContentModel;

NS_ASSUME_NONNULL_BEGIN

@interface NEChatBaseCell : UITableViewCell

- (void)uploadProgress:(NSUInteger)progress;
- (void)setModel:(MessageContentModel *)model;
- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend;

@end

NS_ASSUME_NONNULL_END