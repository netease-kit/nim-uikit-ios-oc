// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationListModel.h"
#import <NIMSDK/NIMSDK.h>

@interface NEConversationListModel ()
@property (nonatomic, copy, readwrite) NSString *conversationId;
@property (nonatomic, assign, readwrite) NSInteger type;
@property (nonatomic, copy, readwrite, nullable) NSString *name;
@property (nonatomic, copy, readwrite, nullable) NSString *avatar;
@property (nonatomic, assign, readwrite) NSInteger unreadCount;
@property (nonatomic, assign, readwrite) BOOL stickTop;
@property (nonatomic, assign, readwrite) int64_t sortOrder;
@property (nonatomic, assign, readwrite) BOOL mute;
@property (nonatomic, copy, readwrite, nullable) NSString *localExtension;
@property (nonatomic, strong, readwrite, nullable) V2NIMLastMessage *lastMessage;
@end

@implementation NEConversationListModel

#pragma mark - 便捷构造

+ (instancetype)modelWithCloudConversation:(V2NIMConversation *)conversation {
  NEConversationListModel *model = [[NEConversationListModel alloc] init];
  [model _fillFromCloudConversation:conversation];
  model.cloudConversation = conversation;
  return model;
}

+ (instancetype)modelWithLocalConversation:(V2NIMLocalConversation *)conversation {
  NEConversationListModel *model = [[NEConversationListModel alloc] init];
  [model _fillFromLocalConversation:conversation];
  model.localConversation = conversation;
  return model;
}

#pragma mark - 更新

- (void)updateWithCloudConversation:(V2NIMConversation *)conversation {
  [self _fillFromCloudConversation:conversation];
  self.cloudConversation = conversation;
  // 更新后清除可能过期的富文本缓存
  self.lastMessageContent = nil;
}

- (void)updateWithLocalConversation:(V2NIMLocalConversation *)conversation {
  [self _fillFromLocalConversation:conversation];
  self.localConversation = conversation;
  self.lastMessageContent = nil;
}

#pragma mark - Private: 属性填充

- (void)_fillFromCloudConversation:(V2NIMConversation *)conv {
  self.conversationId = conv.conversationId ?: @"";
  self.type = (NSInteger)conv.type;
  self.name = conv.name;
  self.avatar = conv.avatar;
  self.unreadCount = conv.unreadCount;
  self.stickTop = conv.stickTop;
  self.sortOrder = conv.sortOrder;
  self.mute = conv.mute;
  self.localExtension = conv.localExtension;
  self.lastMessage = conv.lastMessage;
}

- (void)_fillFromLocalConversation:(V2NIMLocalConversation *)conv {
  self.conversationId = conv.conversationId ?: @"";
  self.type = (NSInteger)conv.type;
  self.name = conv.name;
  self.avatar = conv.avatar;
  self.unreadCount = conv.unreadCount;
  self.stickTop = conv.stickTop;
  self.sortOrder = conv.sortOrder;
  self.mute = conv.mute;
  self.localExtension = conv.localExtension;
  self.lastMessage = conv.lastMessage;
}

@end
