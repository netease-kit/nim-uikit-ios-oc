// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NEChatKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TeamMemberSelectVMDelegate <NSObject>
@end

/// 群成员选择 ViewModel
@interface TeamMemberSelectVM : NSObject

/// TeamRepo 实例
@property (nonatomic, strong) TeamRepo *teamRepo;

/// 群成员信息（加载后缓存）
@property (nonatomic, strong, nullable) NETeamInfoModel *teamInfo;

/// 获取群成员列表
/// - Parameters:
///   - teamId: 群 id
///   - completion: 完成回调
- (void)getTeamMembers:(NSString *)teamId
            completion:(void (^)(NSError *_Nullable error, NETeamInfoModel *_Nullable model))completion;

- (void)getTeamMembers:(NSString *)teamId
               progress:(nullable void (^)(NETeamMemberLoadProgress *progress))progress
             completion:(void (^)(NSError *_Nullable error, NETeamInfoModel *_Nullable model))completion;

@end

NS_ASSUME_NONNULL_END
