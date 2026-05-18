// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import "NEChatUIConstant.h"

NS_ASSUME_NONNULL_BEGIN

/// 语言 Cell 数据模型
@interface NElanguageCellModel : NSObject

@property (nonatomic, copy) NSString *language;
@property (nonatomic, assign) BOOL isSelect;
@property (nonatomic, assign) CornerType cornerType;

@end

/// 语言选择 ViewModel
@interface SelectLanguageViewModel : NSObject

@property (nonatomic, strong) NSMutableArray<NElanguageCellModel *> *datas;

- (void)setupData:(BOOL)isFun;

@end

NS_ASSUME_NONNULL_END
