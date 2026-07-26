// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UserSettingViewModel.h"
#import "NEChatUIConstant.h"
#import <NEChatKit/NEChatKitOC.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NEChatKit/NEALog.h>
#import <NEChatKit/NECoreIM2Constant.h>

@interface UserSettingViewModel () <NEConversationListener, NELocalConversationListener, AIUserPinListener>
@property (nonatomic, strong) ChatRepo *chatRepo;
@property (nonatomic, strong) ContactRepo *contactRepo;
@property (nonatomic, strong) ConversationRepo *conversationRepo;
@property (nonatomic, strong) LocalConversationRepo *localConversationRepo;
@property (nonatomic, strong) SettingRepo *settingRepo;
@end

@implementation UserSettingViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _chatRepo = [ChatRepo shared];
    _contactRepo = [ContactRepo shared];
    _conversationRepo = [ConversationRepo shared];
    _localConversationRepo = [LocalConversationRepo shared];
    _settingRepo = [SettingRepo shared];
    _cellDatas = [NSMutableArray array];

    if ([NIMSDK sharedSDK].v2Option.enableV2CloudConversation == NO) {
      [_localConversationRepo addLocalConversationListener:self];
    } else {
      [_conversationRepo addConversationListener:self];
    }

    if ([IMKitConfigCenter shared].enableAIUser) {
      [[NEAIUserPinManager shared] addPinManagerListener:self];
    }
  }
  return self;
}

- (void)dealloc {
  if ([NIMSDK sharedSDK].v2Option.enableV2CloudConversation == NO) {
    [_localConversationRepo removeLocalConversationListener:self];
  } else {
    [_conversationRepo removeConversationListener:self];
  }

  if ([IMKitConfigCenter shared].enableAIUser) {
    [[NEAIUserPinManager shared] removePinManagerListener:self];
  }
}

- (void)getConversation:(NSString *)userId completion:(void (^)(NSError *_Nullable error))completion {
  NSString *cid = [V2NIMConversationIdUtil p2pConversationId:userId];
  if (!cid) return;

  __weak typeof(self) weakSelf = self;
  if ([NIMSDK sharedSDK].v2Option.enableV2CloudConversation == NO) {
    [self.localConversationRepo getConversation:cid completion:^(V2NIMLocalConversation *_Nullable conversation, NSError *_Nullable error) {
      if (conversation) {
        weakSelf.conversation = conversation;
      }
      if (completion) completion(error);
    }];
  } else {
    [self.conversationRepo getConversation:cid completion:^(V2NIMConversation *_Nullable conversation, NSError *_Nullable error) {
      if (conversation) {
        weakSelf.conversation = conversation;
      }
      if (completion) completion(error);
    }];
  }
}

- (void)getUserSettingModel:(NSString *)userId completion:(void (^)(void))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ UserSettingViewModel", ChatUIKitModuleName] desc:[NSString stringWithFormat:@"%s, userId: %@", __FUNCTION__, userId]];
  __weak typeof(self) weakSelf = self;
  [self.contactRepo getUserWithFriend:@[userId] completion:^(NSArray<NEUserWithFriend *> *_Nullable userfriends, NSError *_Nullable error) {
    weakSelf.userInfo = userfriends.firstObject;
    [weakSelf getSectionDatas];
    [weakSelf.delegate didNeedRefreshUI];
    if (completion) completion();
  }];
}

- (void)getSectionDatas {
  [self.cellDatas removeAllObjects];

  __weak typeof(self) weakSelf = self;

  // 标记
  if ([IMKitConfigCenter shared].enablePinMessage) {
    UserSettingCellModel *mark = [[UserSettingCellModel alloc] init];
    mark.cellName = chatLocalizable(@"operation_pin");
    mark.type = UserSettingTypeSelectType;
    mark.cellClick = ^{
      [weakSelf.delegate didClickMark];
    };
    [self.cellDatas addObject:mark];
  }

  // 搜索聊天记录
  UserSettingCellModel *history = [[UserSettingCellModel alloc] init];
  history.cellName = chatLocalizable(@"historical_record");
  history.type = UserSettingTypeSelectType;
  history.cellClick = ^{
    [weakSelf.delegate didClickHistory];
  };
  [self.cellDatas addObject:history];

  // 开启消息提醒
  UserSettingCellModel *remind = [[UserSettingCellModel alloc] init];
  remind.cellName = chatLocalizable(@"message_remind");
  [self.cellDatas addObject:remind];

  NSString *userId = self.userInfo.user.accountId;
  if (userId) {
    remind.switchOpen = [self.settingRepo getP2PMessageMuteMode:userId] == V2NIM_P2P_MESSAGE_MUTE_MODE_OFF;
  }

  remind.swichChange = ^(BOOL isOpen) {
    if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
      [weakSelf.delegate didShowErrorMsg:commonLocalizable(@"network_error")];
      remind.switchOpen = !isOpen;
      [weakSelf.delegate didNeedRefreshUI];
      return;
    }
    NSString *uid = weakSelf.userInfo.user.accountId;
    if (uid) {
      V2NIMP2PMessageMuteMode muteMode = isOpen ? V2NIM_P2P_MESSAGE_MUTE_MODE_OFF : V2NIM_P2P_MESSAGE_MUTE_MODE_ON;
      [weakSelf.settingRepo setP2PMessageMuteMode:uid muteMode:muteMode completion:^(NSError *_Nullable error) {
        if (error) {
          [weakSelf.delegate didNeedRefreshUI];
          [weakSelf.delegate didError:error];
        } else {
          remind.switchOpen = isOpen;
        }
      }];
    }
  };

  // 聊天置顶
  UserSettingCellModel *setTop = [[UserSettingCellModel alloc] init];
  setTop.cellName = chatLocalizable(@"session_set_top");
  [self.cellDatas addObject:setTop];

  if (self.conversation) {
    setTop.switchOpen = self.conversation.stickTop;
  }

  setTop.swichChange = ^(BOOL isOpen) {
    if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
      [weakSelf.delegate didShowErrorMsg:commonLocalizable(@"network_error")];
      setTop.switchOpen = !isOpen;
      [weakSelf.delegate didNeedRefreshUI];
      return;
    }

    NSString *uid = weakSelf.userInfo.user.accountId;
    NSString *cid = [V2NIMConversationIdUtil p2pConversationId:uid];
    if (uid && cid) {
      if ([NIMSDK sharedSDK].v2Option.enableV2CloudConversation == NO) {
        [weakSelf.localConversationRepo setStickTop:cid stickTop:isOpen completion:^(NSError *_Nullable error) {
          if (error) {
            [weakSelf.delegate didNeedRefreshUI];
            [weakSelf.delegate didError:error];
          } else {
            setTop.switchOpen = !isOpen;
          }
        }];
      } else {
        [weakSelf.conversationRepo setStickTop:cid stickTop:isOpen completion:^(NSError *_Nullable error) {
          if (error) {
            [weakSelf.delegate didNeedRefreshUI];
            [weakSelf.delegate didError:error];
          } else {
            setTop.switchOpen = !isOpen;
          }
        }];
      }
    }
  };

  // AI PIN 置顶
  V2NIMUser *user = self.userInfo.user;
  NSString *account = user.accountId;
  NSString *serverExtensions = user.serverExtension;
  if (account && serverExtensions) {
    NSDictionary *jsonObject = [NECommonUtil getDictionaryFromJSONString:serverExtensions];
    if (jsonObject && jsonObject[aiUserPinKey]) {
      UserSettingCellModel *changePin = [[UserSettingCellModel alloc] init];
      changePin.cellName = chatLocalizable(@"ai_user_pin_top");
      [self.cellDatas addObject:changePin];

      if ([[NEAIUserPinManager shared] checkoutUnPinAIUser:user]) {
        changePin.switchOpen = YES;
      } else {
        changePin.switchOpen = NO;
      }

      changePin.swichChange = ^(BOOL isOpen) {
        if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
          [weakSelf.delegate didShowErrorMsg:commonLocalizable(@"network_error")];
          changePin.switchOpen = !isOpen;
          [weakSelf.delegate didNeedRefreshUI];
          return;
        }
        if (isOpen) {
          [[NEAIUserPinManager shared] pinAIUser:account completion:^(NSError *_Nullable error, BOOL finish) {
            [NEALog infoLog:ChatUIKitModuleName desc:[NSString stringWithFormat:@"%s pinAIUser error: %@, finish: %d", __FUNCTION__, error, finish]];
          }];
        } else {
          [[NEAIUserPinManager shared] unpinAIUser:account completion:^(NSError *_Nullable error, BOOL finish) {
            [NEALog infoLog:ChatUIKitModuleName desc:[NSString stringWithFormat:@"%s unpinAIUser error: %@, finish: %d", __FUNCTION__, error, finish]];
          }];
        }
      };
    }
  }

  [self setAudoType];
}

- (void)setAudoType {
  for (UserSettingCellModel *model in self.cellDatas) {
    if (model == self.cellDatas.firstObject) {
      model.cornerType = CornerTypeTopLeft | CornerTypeTopRight;
      if (model == self.cellDatas.lastObject) {
        model.cornerType = CornerTypeTopLeft | CornerTypeTopRight | CornerTypeBottomLeft | CornerTypeBottomRight;
      }
    } else if (model == self.cellDatas.lastObject) {
      model.cornerType = CornerTypeBottomLeft | CornerTypeBottomRight;
    } else {
      model.cornerType = CornerTypeNone;
    }
  }
}

- (void)setFunType {
  for (UserSettingCellModel *model in self.cellDatas) {
    model.cornerType = CornerTypeNone;
  }
}

- (void)userInfoDidChange {
  [self getSectionDatas];
  [self.delegate didNeedRefreshUI];
}

#pragma mark - NEConversationListener

- (void)onConversationChanged:(NSArray<V2NIMConversation *> *)conversations {
  for (V2NIMConversation *changeConversation in conversations) {
    if (self.conversation && [self.conversation.conversationId isEqualToString:changeConversation.conversationId]) {
      self.conversation = changeConversation;
      [self getSectionDatas];
      [self.delegate didNeedRefreshUI];
    }
  }
}

#pragma mark - NELocalConversationListener

- (void)onLocalConversationChanged:(NSArray<V2NIMLocalConversation *> *)conversations {
  for (V2NIMLocalConversation *changeConversation in conversations) {
    if (self.conversation && [self.conversation.conversationId isEqualToString:changeConversation.conversationId]) {
      self.conversation = changeConversation;
      [self getSectionDatas];
      [self.delegate didNeedRefreshUI];
    }
  }
}

@end
