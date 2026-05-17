// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "MessageAtInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MessageAtCacheModel : NSObject

@property (nonatomic, strong) MessageAtInfoModel *atModel;
@property (nonatomic, copy) NSString *accid;
@property (nonatomic, copy, nullable) NSString *text;

- (instancetype)initWithAtModel:(MessageAtInfoModel *)atModel accid:(NSString *)accid;

@end

NS_ASSUME_NONNULL_END
