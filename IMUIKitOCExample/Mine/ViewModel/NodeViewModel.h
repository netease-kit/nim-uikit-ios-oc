// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NETeamUIKitOC/SettingSectionModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface NodeViewModel : NSObject

@property(nonatomic, strong) NSMutableArray<SettingSectionModel *> *sectionData;

- (void)getData;

@end

NS_ASSUME_NONNULL_END
