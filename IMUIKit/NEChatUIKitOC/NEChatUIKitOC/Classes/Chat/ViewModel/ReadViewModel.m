// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ReadViewModel.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import "NETeamUserManager.h"
#import "ChatMessageHelper.h"

@implementation ReadViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _readUsers = [NSMutableArray array];
    _unReadUsers = [NSMutableArray array];
  }
  return self;
}

- (void)getTeamMessageReceiptDetail:(V2NIMMessage *)message
                             teamId:(NSString *)teamId
                         completion:(void (^)(NSError *_Nullable error))completion {
  __weak typeof(self) weakSelf = self;
  [[ChatRepo shared] getTeamMessageReceiptDetail:message
                                    memberAccountIds:[NSSet set]
                                          completion:^(V2NIMTeamMessageReadReceiptDetail *_Nullable readReceiptDetail,
                                                            NSError *_Nullable error) {
    if (!readReceiptDetail) {
      if (completion) {
        completion(error);
      }
      return;
    }

    if (error) {
      if (completion) {
        completion(error);
      }
      return;
    }

    // 加载用户信息
    NSMutableArray *loadUserIds = [NSMutableArray array];
    [loadUserIds addObjectsFromArray:readReceiptDetail.readAccountList];
    [loadUserIds addObjectsFromArray:readReceiptDetail.unreadAccountList];

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [[NETeamUserManager shared] getTeamMembers:loadUserIds notify:NO completion:^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      // 已读用户
      for (NSString *userId in readReceiptDetail.readAccountList) {
        NETeamMemberInfoModel *memberInfo = [[NETeamMemberInfoModel alloc] init];
        memberInfo.teamMember = [[NETeamUserManager shared] getTeamMemberInfo:userId];
        memberInfo.nimUser = [ChatMessageHelper getUserFromCache:userId];
        [strongSelf.readUsers addObject:memberInfo];
      }

      // 未读用户
      for (NSString *userId in readReceiptDetail.unreadAccountList) {
        NETeamMemberInfoModel *memberInfo = [[NETeamMemberInfoModel alloc] init];
        memberInfo.teamMember = [[NETeamUserManager shared] getTeamMemberInfo:userId];
        memberInfo.nimUser = [ChatMessageHelper getUserFromCache:userId];
        [strongSelf.unReadUsers addObject:memberInfo];
      }

      dispatch_group_leave(group);
    }];

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
      if (completion) {
        completion(nil);
      }
    });
  }];
}

@end
