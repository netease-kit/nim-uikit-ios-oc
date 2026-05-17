// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NETranslateLanguageManager : NSObject

@property (class, nonatomic, readonly) NETranslateLanguageManager *shared;

/// Language data list (e.g. @[@"英语", @"日语", ...])
@property (nonatomic, strong) NSMutableArray<NSString *> *languageDatas;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
