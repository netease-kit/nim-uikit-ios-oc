// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NEChatKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 已读未读页面 - ViewModel
@interface ReadViewModel : NSObject

/// 已读用户列表
@property (nonatomic, strong) NSMutableArray<NETeamMemberInfoModel *> *readUsers;
/// 未读用户列表
@property (nonatomic, strong) NSMutableArray<NETeamMemberInfoModel *> *unReadUsers;

/// 获取群消息已读回执状态详情
/// - Parameters:
///   - message: 群消息
///   - teamId: 群 id
///   - completion: 完成回调
- (void)getTeamMessageReceiptDetail:(V2NIMMessage *)message
                             teamId:(NSString *)teamId
                         completion:(void (^)(NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
