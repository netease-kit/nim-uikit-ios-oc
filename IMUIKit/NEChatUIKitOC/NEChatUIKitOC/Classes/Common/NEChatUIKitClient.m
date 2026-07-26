// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatUIKitClient.h"
#import "NEChatUIConstant.h"
#import "ChatUIConfig.h"
#import "NEMoreItemModel.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/XKitServiceManager.h>
#import <objc/runtime.h>

@interface NEChatUIKitClient ()

/// Registered custom cell dictionary (key = type string, value = cell class)
@property (nonatomic, strong) NSMutableDictionary<NSString *, Class> *customRegisterDic;

@end

static Class NEChatUIKitResolveCustomCellClass(id cellValue) {
  Class cellClass = Nil;
  if ([cellValue isKindOfClass:[NSString class]]) {
    cellClass = NSClassFromString((NSString *)cellValue);
  } else if (cellValue && object_isClass(cellValue)) {
    cellClass = (Class)cellValue;
  }

  if (cellClass && [cellClass isSubclassOfClass:[UITableViewCell class]]) {
    return cellClass;
  }
  return Nil;
}

@implementation NEChatUIKitClient

#pragma mark - Singleton

+ (NEChatUIKitClient *)instance {
  static NEChatUIKitClient *_instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[NEChatUIKitClient alloc] init];
  });
  return _instance;
}

#pragma mark - Init

- (instancetype)init {
  self = [super init];
  if (self) {
    _customRegisterDic = [NSMutableDictionary dictionary];
    _moreAction = [NSMutableArray array];
    [self setupDefaultActions];
  }
  return self;
}

- (void)setupDefaultActions {
  NEMoreItemModel *photo = [[NEMoreItemModel alloc] init];
  photo.image = chatLoadImage(@"fun_chat_photo");
  photo.title = chatLocalizable(@"chat_photo");
  photo.type = NEMoreActionTypePhoto;
  [_moreAction addObject:photo];

  NEMoreItemModel *picture = [[NEMoreItemModel alloc] init];
  picture.image = chatLoadImage(@"chat_takePicture");
  picture.title = chatLocalizable(@"chat_takePicture");
  picture.type = NEMoreActionTypeTakePicture;
  [_moreAction addObject:picture];

  NEMoreItemModel *file = [[NEMoreItemModel alloc] init];
  file.image = chatLoadImage(@"chat_file");
  file.title = chatLocalizable(@"chat_file");
  file.type = NEMoreActionTypeFile;
  [_moreAction addObject:file];

  // RTC — only if NERtcCallUIKit is registered
  if ([[XKitServiceManager getInstance] serviceIsRegister:@"NERtcCallUIKit"]) {
    NEMoreItemModel *rtc = [[NEMoreItemModel alloc] init];
    rtc.image = chatLoadImage(@"chat_rtc");
    rtc.title = chatLocalizable(@"chat_rtc");
    rtc.type = NEMoreActionTypeRtc;
    [_moreAction addObject:rtc];
  }

  if (IMKitConfigCenter.shared.enableAIUser) {
    NEMoreItemModel *translate = [[NEMoreItemModel alloc] init];
    translate.image = chatLoadImage(@"chat_translation");
    translate.title = chatLocalizable(@"chat_translate");
    translate.type = NEMoreActionTypeTranslate;
    [_moreAction addObject:translate];
  }

  if (IMKitConfigCenter.shared.enableAIChatHelper) {
    NEMoreItemModel *aiChat = [[NEMoreItemModel alloc] init];
    aiChat.image = chatLoadImage(@"fun_chat_aiChat");
    aiChat.title = chatLocalizable(@"ai_chat_title");
    aiChat.type = NEMoreActionTypeAiChat;
    [_moreAction addObject:aiChat];
  }
}

#pragma mark - More Action Data

- (NSArray<NEMoreItemModel *> *)getMoreActionDataWithSessionType:(V2NIMConversationType)sessionType
                                                  viewController:(ChatViewController *)viewController {
  NSMutableArray<NEMoreItemModel *> *more = [NSMutableArray array];
  for (NEMoreItemModel *model in self.moreAction) {
    if (model.type != NEMoreActionTypeRtc) {
      [more addObject:model];
    } else if (sessionType == V2NIM_CONVERSATION_TYPE_P2P) {
      [more addObject:model];
    }
  }

  if ([ChatUIConfig shared].chatInputMenu) {
    [ChatUIConfig shared].chatInputMenu(viewController, more);
  }

  return [more copy];
}

#pragma mark - Custom Cell Registration

- (void)regsiterCustomCell:(NSDictionary<NSString *, Class> *)registerDic {
  [registerDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, Class value, BOOL *stop) {
    Class cellClass = NEChatUIKitResolveCustomCellClass(value);
    if (cellClass) {
      self.customRegisterDic[key] = cellClass;
    } else {
      [self.customRegisterDic removeObjectForKey:key];
    }
  }];
}

- (NSDictionary<NSString *, Class> *)getRegisterCustomCell {
  for (NSString *key in [self.customRegisterDic allKeys]) {
    Class cellClass = NEChatUIKitResolveCustomCellClass(self.customRegisterDic[key]);
    if (cellClass) {
      self.customRegisterDic[key] = cellClass;
    } else {
      [self.customRegisterDic removeObjectForKey:key];
    }
  }
  return [self.customRegisterDic copy];
}

#pragma mark - Image & Language

- (UIImage *)getImageSourceWithImageName:(NSString *)imageName {
  return chatLoadImage(imageName);
}

- (NSString *)getLanguageWithKey:(NSString *)key {
  return chatLocalizable(key);
}

@end
