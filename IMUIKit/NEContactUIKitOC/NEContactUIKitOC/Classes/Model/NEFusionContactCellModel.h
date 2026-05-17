// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>

@class NEUserWithFriend;

NS_ASSUME_NONNULL_BEGIN

@interface NEFusionContactCellModel : NSObject

/// 用户信息
@property (nonatomic, strong, nullable) NEUserWithFriend *user;
/// cell 类型
@property (nonatomic, assign) NSInteger type;
/// 是否选中
@property (nonatomic, assign) BOOL selected;
/// 机器人数据
@property (nonatomic, strong, nullable) V2NIMAIUser *aiUser;

/// 获取 accid
- (NSString *)getAccountId;

/// 获取显示名称
- (NSString *)getShowName;

/// 获取末尾 count 个字符的简称
- (NSString *)getShortName:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
