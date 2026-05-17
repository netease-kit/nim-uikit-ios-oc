// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ContactConst.h"

@class NEUserWithFriend;

NS_ASSUME_NONNULL_BEGIN

/*
 通讯录 cell 数据模型
 // contactCellType: 自定义 UI 类型，其在注册会话列表 cell 时作为 key 与自定义 cell 进行绑定
 // localExtension: 本地扩展字段，可根据业务需求添加数据，与 contactCellType 结合可实现多种自定义 cell 的展示
 */
@interface ContactInfo : NSObject

@property (nonatomic, strong, nullable) NEUserWithFriend *user;
@property (nonatomic, assign) ContactCellType contactCellType;
@property (nonatomic, copy) NSString *router;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) BOOL isOnline;
@property (nonatomic, strong, nullable) UIColor *headerBackColor;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *localExtension;

- (nullable NSNumber *)getRowHeight;

/// 比较方法（用于排序）
- (NSComparisonResult)compare:(ContactInfo *)other;

@end

NS_ASSUME_NONNULL_END
