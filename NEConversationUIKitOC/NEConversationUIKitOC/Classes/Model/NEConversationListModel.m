// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationListModel.h"
#import "ConversationUIConfig.h"
#import <NEChatKit/NEChatKit-Swift.h>
#import <NIMSDK/NIMSDK.h>

@interface NEConversationListModel ()
@property (nonatomic, copy, readwrite) NSString *conversationId;
@property (nonatomic, assign, readwrite) NSInteger type;
@property (nonatomic, copy, readwrite, nullable) NSString *name;
@property (nonatomic, copy, readwrite, nullable) NSString *avatar;
@property (nonatomic, assign) NSInteger sdkUnreadCount;
@property (nonatomic, assign) NSTimeInterval locallyReadTime;
@property (nonatomic, assign, readwrite) BOOL stickTop;
@property (nonatomic, assign, readwrite) int64_t sortOrder;
@property (nonatomic, assign, readwrite) NSTimeInterval updateTime;
@property (nonatomic, assign, readwrite) BOOL mute;
@property (nonatomic, copy, readwrite, nullable) NSString *localExtension;
@property (nonatomic, strong, readwrite, nullable) V2NIMLastMessage *lastMessage;
@end

@implementation NEConversationListModel

- (V2NIMConversation *)conversation {
  return self.cloudConversation;
}

- (void)setConversation:(V2NIMConversation *)conversation {
  if (conversation) {
    [self updateWithCloudConversation:conversation];
  } else {
    self.cloudConversation = nil;
  }
}

#pragma mark - 便捷构造

+ (instancetype)modelWithCloudConversation:(V2NIMConversation *)conversation {
  NEConversationListModel *model = [[NEConversationListModel alloc] init];
  [model updateWithCloudConversation:conversation];
  return model;
}

+ (instancetype)modelWithLocalConversation:(V2NIMLocalConversation *)conversation {
  NEConversationListModel *model = [[NEConversationListModel alloc] init];
  [model updateWithLocalConversation:conversation];
  return model;
}

#pragma mark - 更新

- (void)updateWithCloudConversation:(V2NIMConversation *)conversation {
  NSString *previousConversationId = self.conversationId;
  [self _fillFromCloudConversation:conversation];
  self.cloudConversation = conversation;
  self.localConversation = nil;
  if (![previousConversationId isEqualToString:self.conversationId]) {
    self.locallyReadTime = 0;
  }
  [self updateLastMessageContent];
}

- (void)updateWithLocalConversation:(V2NIMLocalConversation *)conversation {
  NSString *previousConversationId = self.conversationId;
  [self _fillFromLocalConversation:conversation];
  self.localConversation = conversation;
  self.cloudConversation = nil;
  if (![previousConversationId isEqualToString:self.conversationId]) {
    self.locallyReadTime = 0;
  }
  [self updateLastMessageContent];
}

- (NSInteger)unreadCount {
  if (self.sdkUnreadCount <= 0 || self.locallyReadTime <= 0) {
    return self.sdkUnreadCount;
  }
  NSTimeInterval lastMessageTime = self.lastMessage.messageRefer.createTime;
  return lastMessageTime <= self.locallyReadTime ? 0 : self.sdkUnreadCount;
}

- (void)markUnreadCountCleared {
  NSTimeInterval lastMessageTime = self.lastMessage.messageRefer.createTime;
  if (lastMessageTime <= 0) {
    lastMessageTime = NSDate.date.timeIntervalSince1970;
  }
  self.locallyReadTime = MAX(self.locallyReadTime, lastMessageTime);
}

- (void)markUnreadCountClearedThrough:(NSTimeInterval)readTime {
  self.locallyReadTime = MAX(self.locallyReadTime, readTime);
}

- (void)markUnreadCountClearedWithThrough:(NSTimeInterval)readTime {
  [self markUnreadCountClearedThrough:readTime];
}

#pragma mark - Private: 属性填充

- (void)_fillFromCloudConversation:(V2NIMConversation *)conv {
  self.conversationId = conv.conversationId ?: @"";
  self.type = (NSInteger)conv.type;
  self.name = conv.name;
  self.avatar = conv.avatar;
  self.sdkUnreadCount = conv.unreadCount;
  self.stickTop = conv.stickTop;
  self.sortOrder = conv.sortOrder;
  self.updateTime = conv.updateTime;
  self.mute = conv.mute;
  self.localExtension = conv.localExtension;
  self.lastMessage = conv.lastMessage;
}

- (void)_fillFromLocalConversation:(V2NIMLocalConversation *)conv {
  self.conversationId = conv.conversationId ?: @"";
  self.type = (NSInteger)conv.type;
  self.name = conv.name;
  self.avatar = conv.avatar;
  self.sdkUnreadCount = conv.unreadCount;
  self.stickTop = conv.stickTop;
  self.sortOrder = conv.sortOrder;
  self.updateTime = conv.updateTime;
  self.mute = conv.mute;
  self.localExtension = conv.localExtension;
  self.lastMessage = conv.lastMessage;
}

- (void)updateLastMessageContent {
  V2NIMLastMessage *lastMessage = self.lastMessage;
  if (lastMessage.messageType != V2NIM_MESSAGE_TYPE_TEXT || lastMessage.text.length == 0) {
    self.lastMessageContent = nil;
    return;
  }

  ConversationProperties *properties = ConversationUIConfig.shared.conversationProperties;
  CGFloat fontSize = properties.itemContentSize > 0 ? properties.itemContentSize : 13;
  self.lastMessageContent = [[NEChatKitClient instance] getEmojString:lastMessage.text
                                                              fontSize:fontSize
                                                                 color:properties.itemContentColor];
}

@end
