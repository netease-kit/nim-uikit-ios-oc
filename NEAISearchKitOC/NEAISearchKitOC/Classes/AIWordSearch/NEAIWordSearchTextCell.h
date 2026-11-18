// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEAIWordSearchModel;

@interface NEAIWordSearchTextCell : UITableViewCell

- (void)showBottomLine:(BOOL)show;
- (void)setModel:(NEAIWordSearchModel *)model;

@end

NS_ASSUME_NONNULL_END
