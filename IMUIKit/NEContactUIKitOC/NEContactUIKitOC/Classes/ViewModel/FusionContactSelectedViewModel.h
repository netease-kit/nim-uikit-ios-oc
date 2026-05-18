// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NEFusionContactCellModel.h"

@class ContactRepo;

NS_ASSUME_NONNULL_BEGIN

typedef void (^FusionContactCallBack)(NSError *_Nullable);

@interface FusionContactSelectedViewModel : NSObject

@property (nonatomic, strong) NSMutableArray<NEFusionContactCellModel *> *memberDatas;
@property (nonatomic, strong) NSMutableSet<NSString *> *memberSelectedSet;
@property (nonatomic, strong) ContactRepo *contactRepo;

- (void)loadMemberDatas:(nullable NSSet<NSString *> *)filters
             completion:(void (^)(NSError *_Nullable))completion;
- (void)loadAIUserData:(nullable NSSet<NSString *> *)filters;

@end

NS_ASSUME_NONNULL_END
