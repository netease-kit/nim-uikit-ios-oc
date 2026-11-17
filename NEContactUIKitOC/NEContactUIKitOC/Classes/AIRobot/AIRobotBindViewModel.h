// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface AIRobotBindViewModel : NSObject

/// Robot list sorted by createTime desc.
@property (nonatomic, strong) NSMutableArray<V2NIMUserAIBot *> *bots;

/// Previously bound bot accid parsed from the QR payload.
@property (nonatomic, copy, nullable) NSString *previousBoundAccid;

/// Fetch all robots with automatic pagination.
- (void)loadBots:(void (^)(NSError *_Nullable error))completion;

/// Bind the selected robot to the QR code.
- (void)bindBot:(V2NIMUserAIBot *)bot
         qrCode:(NSString *)qrCode
     completion:(void (^)(NSError *_Nullable error))completion;
- (void)bindBot:(V2NIMUserAIBot *)bot
         qrCode:(NSString *)qrCode
               :(void (^)(NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
