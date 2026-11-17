// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "MessageEnum.h"

NS_ASSUME_NONNULL_BEGIN

@interface CollectionFileModel : NSObject

@property (nonatomic, assign) NSUInteger progress;
@property (nonatomic, assign) float size;
@property (nonatomic, assign) DownloadState state;
@property (nonatomic, weak, nullable) id cell;

@end

NS_ASSUME_NONNULL_END
