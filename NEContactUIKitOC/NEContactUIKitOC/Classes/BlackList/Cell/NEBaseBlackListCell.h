// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEBaseTeamTableViewCell.h"

@class NEUserWithFriend;

NS_ASSUME_NONNULL_BEGIN

@protocol BlackListCellDelegate <NSObject>
- (void)removeUserWithAccount:(nullable NSString *)account index:(NSInteger)index;
@end

@interface NEBaseBlackListCell : NEBaseTeamTableViewCell

@property (nonatomic, weak, nullable) id<BlackListCellDelegate> delegate;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) UIButton *button;

- (void)buttonEvent:(UIButton *)sender;
- (void)buttonEventWithSender:(UIButton *)sender;
- (void)setModel:(id)model;

@end

NS_ASSUME_NONNULL_END
