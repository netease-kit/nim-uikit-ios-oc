// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "ContactInfo.h"

NS_ASSUME_NONNULL_BEGIN

/*
 通讯录 section 数据模型
 // initial: tableView 对应 section 的标题
 // contacts: tableView 对应 section 的数据
 */
@interface ContactSection : NSObject

@property (nonatomic, copy) NSString *initial;
@property (nonatomic, strong) NSMutableArray<ContactInfo *> *contacts;

- (instancetype)initWithInitial:(NSString *)initial
                       contacts:(NSArray<ContactInfo *> *)contacts;

/// 比较方法（用于排序）
- (NSComparisonResult)compare:(ContactSection *)other;

@end

NS_ASSUME_NONNULL_END
