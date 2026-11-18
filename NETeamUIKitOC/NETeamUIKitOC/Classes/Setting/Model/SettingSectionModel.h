// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

@class SettingCellModel;

NS_ASSUME_NONNULL_BEGIN

@interface SettingSectionModel : NSObject

@property (nonatomic, strong) NSMutableArray<SettingCellModel *> *cellModels;

- (void)setCornerType;

@end

NS_ASSUME_NONNULL_END
