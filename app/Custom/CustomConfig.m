// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomConfig.h"
#import "AIChatDataLoader.h"
#import "CustomChatViewController.h"
#import "CustomView.h"
#import "AppKey.h"
#import "NEStyleManager.h"
#import "NEP2PSecurityWarningView.h"
#import "NESecurityWarningView.h"
#import <NEChatKit/ChatRepo.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/NERouterUrl.h>
#import <NEChatKit/Router.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatUIKitOC/AIChatViewController.h>
#import <NEChatUIKitOC/ChatUIConfig.h>
#import <NEChatUIKitOC/NEBaseChatRouter.h>
#import <NEChatUIKitOC/ChatViewController.h>
#import <NEChatUIKitOC/MessageContentModel.h>
#import <NEChatUIKitOC/NEChatUIKitClient.h>
#import <NEChatUIKitOC/NEMoreItemModel.h>
#import <NEBaseUIKitOC/CommonUIConfig.h>
#import <NEBaseUIKitOC/NEUIView+Hierarchy.h>
#import <NEBaseUIKitOC/ViewControllerExtension.h>
#import <NEBaseUIKitOC/UIView+YXToast.h>
#import <NEContactUIKitOC/ContactUIConfig.h>
#import <NEContactUIKitOC/ContactInfo.h>
#import <NEContactUIKitOC/NEBaseContactViewController.h>
#import <NEConversationUIKitOC/ConversationUIConfig.h>
#import <NEConversationUIKitOC/NEConversationListModel.h>
#import <Photos/Photos.h>
#import <ZLPhotoBrowser/ZLPhotoBrowser-Swift.h>
#import <NEConversationUIKitOC/NEConversationViewController.h>

static NSInteger const kNIMDemoSecurityWarningTag = 2026043001;
static NSString *const NIMDemoPushP2pChatVCRouterCompat = @"imkit://chat/p2pChat.page";

static NSArray<V2NIMMessage *> *NIMDemoSafeMessagesValue(id value) {
  if (![value isKindOfClass:NSArray.class]) {
    return nil;
  }
  NSMutableArray<V2NIMMessage *> *messages = [NSMutableArray array];
  for (id obj in (NSArray *)value) {
    if ([obj isKindOfClass:V2NIMMessage.class]) {
      [messages addObject:obj];
    }
  }
  return messages.count > 0 ? [messages copy] : nil;
}

@interface ChatViewController (CustomSecurityWarning) <NEP2PSecurityWarningViewDelegate>
@end

@implementation ChatViewController (CustomSecurityWarning)

- (void)didClickRemoveButton {
  self.bodyTopViewHeight = 0;
}

@end

@interface CustomConfig ()
@property (nonatomic, strong) NESecurityWarningView *securityWarningView;
@property (nonatomic, strong) NEP2PSecurityWarningView *p2pSecurityWarningView;
@end

@implementation CustomConfig

+ (instancetype)shared {
  static CustomConfig *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[CustomConfig alloc] init];
  });
  return instance;
}

- (void)configCommonUIKit {
  [CommonUIConfig shared].backArrowImage = [UIImage imageNamed:@"copy_right"];
}

- (void)configChatUIKit {
  MessageProperties *properties = ChatUIConfig.shared.messageProperties;
  properties.avatarType = NEChatAvatarTypeCycle;
  properties.avatarCornerRadius = 8.0;
  properties.signalBgColor = UIColor.yellowColor;
  properties.selfMessageBgColor = UIColor.ne_greenText;
  properties.receiveMessageBgColor = UIColor.ne_greenText;
  properties.timeTextColor = UIColor.ne_darkText;
  properties.timeTextSize = 18.0;
  properties.userNickColor = UIColor.ne_redText;
  properties.userNickTextSize = 8.0;
  properties.selfMessageTextColor = UIColor.ne_redColor;
  properties.receiveMessageTextColor = UIColor.blueColor;
  properties.selfMessageTextSize = 14.0;
  properties.receiveMessageTextSize = 12.0;
  properties.selfMessageBgImage = [UIImage imageNamed:@"copy_right"];
  properties.receiveMessageBgImage = [UIImage imageNamed:@"copy_right"];
  properties.showP2PMessageStatus = NO;
  properties.showTeamMessageStatus = NO;
  properties.titleBarRightRes = [UIImage imageNamed:@"copy_right"];
  properties.titleBarRightClick = ^(ChatViewController *viewController) {
    [viewController showToast:@"标题栏右侧图标的点击事件"];
  };
  properties.chatTableViewBackgroundColor = UIColor.ne_redText;

  ChatUIConfig.shared.messageItemClick =
      ^(NEChatBaseViewController *viewController, __unused UITableViewCell *cell,
        MessageContentModel *model) {
        [viewController showToast:[NSString stringWithFormat:@"点击了消息: %@",
                                                             model.message.text]];
      };

  __weak typeof(self) weakSelf = self;
  ChatUIConfig.shared.chatInputBar =
      ^(__unused ChatViewController *viewController, NSMutableArray<UIButton *> *items) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (items.count > 2) {
          UIButton *takePictureButton = items[2];
          [takePictureButton setImage:nil forState:UIControlStateNormal];
          [takePictureButton setTitle:@"拍照" forState:UIControlStateNormal];
          [takePictureButton setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
          [takePictureButton removeTarget:takePictureButton.superview
                                   action:nil
                         forControlEvents:UIControlEventAllEvents];
          [takePictureButton addTarget:self
                                action:@selector(customClick:)
                      forControlEvents:UIControlEventTouchUpInside];
        }

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:@"新增" forState:UIControlStateNormal];
        [button setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        [button addTarget:self
                   action:@selector(customClick:)
         forControlEvents:UIControlEventTouchUpInside];
        [items addObject:button];
      };

  ChatUIConfig.shared.chatInputMenu =
      ^(__unused ChatViewController *viewController, NSMutableArray<NEMoreItemModel *> *items) {
        NEMoreItemModel *newItem = [[NEMoreItemModel alloc] init];
        newItem.customImage = [UIImage imageNamed:@"mine_collection"];
        newItem.action = ^(UIViewController *controller, __unused NEMoreItemModel *item) {
          [controller showToast:@"【更多】区域功能自定义点击事件"];
        };
        newItem.title = @"新增";
        [items addObject:newItem];

        for (NEMoreItemModel *item in items) {
          if (item.type == NEMoreActionTypeRtc) {
            item.customImage = [UIImage imageNamed:@"mine_setting"];
            newItem.action = ^(UIViewController *controller, __unused NEMoreItemModel *selectedItem) {
              [controller showToast:@"【更多】区域功能自定义点击事件"];
            };
            item.type = NEMoreActionTypeRtc;
            item.title = @"覆盖";
          }
        }

        NSIndexSet *fileIndexes = [items indexesOfObjectsPassingTest:
            ^BOOL(NEMoreItemModel *item, __unused NSUInteger index, __unused BOOL *stop) {
              return item.type == NEMoreActionTypeFile;
            }];
        [items removeObjectsAtIndexes:fileIndexes];
      };

  ChatUIConfig.shared.chatPopMenu =
      ^(__unused ChatViewController *viewController, NSMutableArray<OperationItem *> *items,
        MessageContentModel *model) {
        if (model.type != MessageTypeText) return;
        for (OperationItem *item in items) {
          if (item.type == OperationTypeCopy) item.text = @"粘贴";
        }
      };

  ChatUIConfig.shared.popMenuClick =
      ^(ChatViewController *viewController, OperationItem *item) {
        if (item.type == OperationTypeCopy) [viewController showToast:@"自定义点击事件"];
      };

  ChatUIConfig.shared.customController = ^(ChatViewController *viewController) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    viewController.navigationView.backgroundColor = UIColor.grayColor;
    [self.customTopView.button setTitle:@"通过配置项添加" forState:UIControlStateNormal];
    viewController.bodyTopView.backgroundColor = UIColor.purpleColor;
    [viewController.bodyTopView addSubview:self.customTopView];
    viewController.bodyTopViewHeight = 80.0;
    [self.customBottomView.button setTitle:@"通过配置项添加" forState:UIControlStateNormal];
    viewController.bodyBottomView.backgroundColor = UIColor.purpleColor;
    [viewController.bodyBottomView addSubview:self.customBottomView];
    viewController.bodyBottomViewHeight = 60.0;
  };

  [ChatKitClient shared].beforeSend =
      ^MessageSendParams *( __unused UIViewController *viewController, MessageSendParams *param) {
        param.message.text = [NSString stringWithFormat:@"%@%@", param.message.text ?: @"", @"[拦截1]"];
        return param;
      };
  [ChatKitClient shared].beforeSendCompletion =
      ^(__unused UIViewController *viewController, MessageSendParams *param,
        void (^completion)(MessageSendParams *)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
                         param.message.text = [NSString stringWithFormat:@"%@%@",
                                                                            param.message.text ?: @"",
                                                                            @"[拦截2]"];
                         completion(param);
                       });
      };
  [ChatKitClient shared].sendMessageCallback =
      ^(UIViewController *viewController, V2NIMSendMessageResult *result,
        __unused V2NIMError *error, __unused NSUInteger progress) {
        if (result.antispamResult) {
          [viewController showToast:[NSString stringWithFormat:@"反垃圾结果：%@",
                                                                result.antispamResult]];
        }
      };
}

- (void)configContactUIKit {
  ContactUIConfig *config = ContactUIConfig.shared;
  config.contactProperties.avatarCornerRadius = 4.0;
  config.contactProperties.avatarType = NEContactAvatarTypeCycle;
  config.title = @"好友列表";
  config.titleColor = UIColor.purpleColor;
  config.contactProperties.itemTitleSize = 28.0;
  config.contactProperties.itemTitleColor = UIColor.redColor;
  config.showTitleBar = YES;
  config.headerItemClick = ^(NEBaseContactViewController *viewController,
                             __unused ContactInfo *info, NSIndexPath *indexPath) {
    [viewController showToast:[NSString stringWithFormat:@"点击了头部模块中的第 %ld 个",
                                                          (long)indexPath.row]];
  };
  config.friendItemClick = ^(NEBaseContactViewController *viewController,
                             ContactInfo *info, __unused NSIndexPath *indexPath) {
    [viewController showToast:[NSString stringWithFormat:@"点击了好友列表中的: %@",
                                                          info.user.showName ?: @""]];
  };
  config.showTitleBarRight2Icon = YES;
  config.showTitleBarRightIcon = YES;
  config.titleBarRightRes = [UIImage imageNamed:@"person"];
  config.titleBarRight2Res = [UIImage imageNamed:@"contact"];
  config.titleBarRightClick = ^(__unused NEBaseContactViewController *viewController) {
    NSLog(@"addItemAction");
  };
  config.titleBarRight2Click = ^(__unused NEBaseContactViewController *viewController) {
    NSLog(@"searchItemAction");
  };
  config.contactProperties.divideLineColor = UIColor.blueColor;
  config.contactProperties.indexTitleColor = UIColor.greenColor;

  __weak typeof(self) weakSelf = self;
  config.customController = ^(NEBaseContactViewController *viewController) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    viewController.navigationView.backgroundColor = UIColor.grayColor;
    [self.customTopView.button setTitle:@"通过配置项添加" forState:UIControlStateNormal];
    viewController.bodyTopView.backgroundColor = UIColor.purpleColor;
    [viewController.bodyTopView addSubview:self.customTopView];
    viewController.bodyTopViewHeight = 80.0;
    [self.customBottomView.button setTitle:@"通过配置项添加" forState:UIControlStateNormal];
    viewController.bodyBottomView.backgroundColor = UIColor.purpleColor;
    [viewController.bodyBottomView addSubview:self.customBottomView];
    viewController.bodyBottomViewHeight = 60.0;
  };
}

- (void)configConversationUIKit {
  ConversationUIConfig *config = ConversationUIConfig.shared;
  config.conversationProperties.avatarCornerRadius = 4.0;
  config.conversationProperties.avatarType = NEConversationAvatarTypeCycle;
  config.showTitleBar = YES;
  config.showTitleBarRight2Icon = YES;
  config.showTitleBarRightIcon = YES;
  config.titleBarTitle = @"消息";
  config.titleBarTitleColor = UIColor.purpleColor;
  config.titleBarLeftRes = [[UIImage alloc] init];
  config.conversationProperties.itemBackground = UIColor.grayColor;
  config.conversationProperties.itemStickTopBackground = UIColor.orangeColor;
  config.conversationProperties.itemTitleSize = 24.0;
  config.conversationProperties.itemContentSize = 18.0;
  config.conversationProperties.itemTitleColor = UIColor.redColor;
  config.conversationProperties.itemContentColor = UIColor.blueColor;
  config.conversationProperties.itemDateColor = UIColor.greenColor;
  config.conversationProperties.itemDateSize = 14.0;
  config.stickTopButtonTitle = @"左侧";
  config.stickTopButtonCancelTitle = @"左侧1";
  config.stickTopButtonBackgroundColor = UIColor.brownColor;
  config.stickTopButtonClick = ^(NEBaseConversationController *viewController,
                                 __unused NEConversationListModel *model,
                                 __unused NSIndexPath *indexPath) {
    [viewController showToast:@"会话列表 cell 左划置顶按钮点击事件"];
  };
  config.deleteButtonTitle = @"右侧";
  config.deleteButtonBackgroundColor = UIColor.purpleColor;
  config.deleteButtonClick = ^(NEBaseConversationController *viewController,
                               __unused NEConversationListModel *model,
                               __unused NSIndexPath *indexPath) {
    [viewController showToast:@"会话列表 cell 左划删除按钮点击事件"];
  };
  config.titleBarLeftClick = ^(NEBaseConversationController *viewController) {
    [viewController showSingleAlert:nil message:@"titleBarLeftClick" handler:^{}];
  };
  config.titleBarRightClick = ^(NEBaseConversationController *viewController) {
    [viewController showToast:@"didClickAddBtn"];
  };
  config.titleBarRight2Click = ^(NEBaseConversationController *viewController) {
    [viewController showToast:@"didClickSearchBtn"];
  };
  config.itemClick = ^(NEBaseConversationController *viewController,
                       NEConversationListModel *model, __unused NSIndexPath *indexPath) {
    [viewController showToast:model.conversation.name ?: @"会话列表点击事件"];
  };

  __weak typeof(self) weakSelf = self;
  config.customController = ^(NEBaseConversationController *viewController) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    viewController.navigationView.backgroundColor = UIColor.grayColor;
    [self.customTopView.button setTitle:@"通过配置项添加" forState:UIControlStateNormal];
    viewController.bodyTopView.backgroundColor = UIColor.purpleColor;
    [viewController.bodyTopView addSubview:self.customTopView];
    viewController.bodyTopViewHeight = 80.0;
    [self.customBottomView.button setTitle:@"通过配置项添加" forState:UIControlStateNormal];
    viewController.bodyBottomView.backgroundColor = UIColor.purpleColor;
    [viewController.bodyBottomView addSubview:self.customBottomView];
    viewController.bodyBottomViewHeight = 60.0;
  };
}

- (void)loadAIChatData {
  ChatUIConfig.shared.aiChatViewController = ^(__unused AIChatViewController *controller) {};
  ChatUIConfig.shared.aiChatDataLoader =
      ^(NSArray<V2NIMMessage *> *_Nullable messages,
        void (^completion)(NSArray<AIChatCellModel *> *_Nullable models,
                           NSError *_Nullable error)) {
        [AIChatDataLoader loadData:messages completion:completion];
      };

  ChatUIConfig.shared.aiChatDidClick =
      ^(AIChatViewController *controller, NSArray<V2NIMMessage *> *_Nullable messages) {
        NSString *newMessageId = messages.lastObject.messageClientId;
        NSString *oldMessageId = controller.lastMessages.lastObject.messageClientId;
        if (newMessageId.length > 0 && [newMessageId isEqualToString:oldMessageId]) {
          return;
        }
        [controller showLoadingView];
        [controller loadMoreData:messages];
      };

  ChatUIConfig.shared.aiChatReloadClick =
      ^(AIChatViewController *controller, NSArray<V2NIMMessage *> *_Nullable messages) {
        [controller showLoadingView];
        [controller loadMoreData:messages];
      };
}

- (void)loadPhotoBrowser {
  ChatUIConfig.shared.chatInputPhotoClick =
      ^(UIViewController *chatViewController, NEMediaType mediaType, NSInteger limit,
        void (^selectImageBlock)(NSArray<NEResultModel *> *results, BOOL isOriginal)) {
        ZLPhotoConfiguration *configuration = [ZLPhotoConfiguration default];
        configuration.canSelectAsset = nil;
        configuration.didSelectAsset = nil;
        configuration.didDeselectAsset = nil;
        switch (mediaType) {
          case NEMediaTypeAll:
          {
            NSMutableSet<NSString *> *selectedVideoIds = [NSMutableSet set];
            configuration.allowSelectImage = YES;
            configuration.allowSelectVideo = YES;
            configuration.allowSelectLivePhoto = YES;
            configuration.allowTakePhotoInLibrary = NO;
            configuration.allowMixSelect = NO;
            configuration.editAfterSelectThumbnailImage = NO;
            configuration.showSelectBtnWhenSingleSelect = YES;
            configuration.maxSelectCount = limit;
            configuration.maxSelectVideoDataSize = ChatUIConfig.shared.fileSizeLimit * 1024;
            __weak ZLPhotoConfiguration *weakConfiguration = configuration;
            configuration.canSelectAsset = ^BOOL(PHAsset *asset) {
              if (selectedVideoIds.count == 0) return YES;
              if (asset.mediaType != PHAssetMediaTypeVideo) return NO;
              return [selectedVideoIds containsObject:asset.localIdentifier] ||
                     selectedVideoIds.count < 1;
            };
            configuration.didSelectAsset = ^(PHAsset *asset) {
              if (asset.mediaType != PHAssetMediaTypeVideo) return;
              [selectedVideoIds addObject:asset.localIdentifier];
              weakConfiguration.maxSelectCount = 1;
            };
            configuration.didDeselectAsset = ^(PHAsset *asset) {
              if (asset.mediaType != PHAssetMediaTypeVideo) return;
              [selectedVideoIds removeObject:asset.localIdentifier];
              weakConfiguration.maxSelectCount = limit;
            };
            break;
          }
          case NEMediaTypeImage:
            configuration.allowSelectImage = YES;
            configuration.allowSelectVideo = NO;
            configuration.showSelectBtnWhenSingleSelect = NO;
            configuration.maxSelectCount = limit;
            configuration.editAfterSelectThumbnailImage = YES;
            configuration.allowSelectLivePhoto = YES;
            configuration.allowTakePhotoInLibrary = NO;
            break;
          case NEMediaTypeVideo:
          default:
            configuration.allowSelectImage = NO;
            configuration.allowSelectVideo = YES;
            configuration.editAfterSelectThumbnailImage = NO;
            configuration.showSelectBtnWhenSingleSelect = NO;
            configuration.maxSelectCount = limit;
            configuration.allowTakePhotoInLibrary = NO;
            break;
        }

        ZLPhotoPicker *picker = [[ZLPhotoPicker alloc] init];
        picker.selectImageBlock = ^(NSArray<ZLResultModel *> *results, BOOL isOriginal) {
          if (!selectImageBlock) {
            return;
          }
          NSMutableArray<NEResultModel *> *callbackResults = [NSMutableArray array];
          for (ZLResultModel *result in results) {
            if (![result isKindOfClass:[ZLResultModel class]]) {
              continue;
            }
            NEResultModel *model = [[NEResultModel alloc] initWithAsset:result.asset
                                                                   image:result.image
                                                                   index:result.index];
            [callbackResults addObject:model];
          }
          selectImageBlock(callbackResults, isOriginal);
        };
        [picker showPhotoLibraryWithSender:chatViewController];
      };
}

- (void)loadSecurityWarningView {
  __weak typeof(self) weakSelf = self;
  ConversationUIConfig.shared.customController = ^(UIViewController *controller) {
    if (![controller isKindOfClass:[NEBaseConversationController class]]) return;
    NEBaseConversationController *viewController = (NEBaseConversationController *)controller;
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    self.securityWarningView.warningLabel.text = NELocalizable(@"security_warning");
    [viewController.bodyTopView addSubview:self.securityWarningView];
    CGFloat topInset = [NEStyleManager.instance isNormalStyle] ? 0.0 : 60.0;
    [NSLayoutConstraint activateConstraints:@[
      [self.securityWarningView.topAnchor constraintEqualToAnchor:viewController.bodyTopView.topAnchor constant:topInset],
      [self.securityWarningView.leftAnchor constraintEqualToAnchor:viewController.bodyTopView.leftAnchor],
      [self.securityWarningView.rightAnchor constraintEqualToAnchor:viewController.bodyTopView.rightAnchor],
      [self.securityWarningView.heightAnchor constraintEqualToConstant:56.0],
    ]];
    viewController.bodyTopViewHeight = [NEStyleManager.instance isNormalStyle] ? 56.0 : 116.0;
  };

  ChatUIConfig.shared.customController = ^(ChatViewController *viewController) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    strongSelf.p2pSecurityWarningView.delegate = viewController;
    strongSelf.p2pSecurityWarningView.tag = kNIMDemoSecurityWarningTag;
    [viewController.bodyTopView addSubview:strongSelf.p2pSecurityWarningView];
    [NSLayoutConstraint activateConstraints:@[
      [strongSelf.p2pSecurityWarningView.topAnchor
          constraintEqualToAnchor:viewController.bodyTopView.topAnchor],
      [strongSelf.p2pSecurityWarningView.leftAnchor
          constraintEqualToAnchor:viewController.bodyTopView.leftAnchor],
      [strongSelf.p2pSecurityWarningView.rightAnchor
          constraintEqualToAnchor:viewController.bodyTopView.rightAnchor],
      [strongSelf.p2pSecurityWarningView.heightAnchor constraintEqualToConstant:56],
    ]];
    viewController.bodyTopViewHeight = 56;
  };
}

- (void)customClick:(UIButton *)button {
  [[button neViewContainingController] showToast:@"文本输入框下方 tab 按钮自定义点击事件"];
}

- (CustomView *)customTopView {
  if (!_customTopView) {
    _customTopView = [[CustomView alloc] initWithFrame:CGRectMake(0, 10, UIScreen.mainScreen.bounds.size.width, 40)];
    _customTopView.backgroundColor = UIColor.blueColor;
  }
  return _customTopView;
}

- (CustomView *)customBottomView {
  if (!_customBottomView) {
    _customBottomView = [[CustomView alloc] initWithFrame:CGRectMake(0, 10, UIScreen.mainScreen.bounds.size.width, 40)];
    _customBottomView.backgroundColor = UIColor.greenColor;
  }
  return _customBottomView;
}

- (void)loadRtcEntry {
  NEChatInputMenuBlock previousInputMenu = ChatUIConfig.shared.chatInputMenu;
  ChatUIConfig.shared.chatInputMenu = ^(ChatViewController *controller,
                                        NSMutableArray<NEMoreItemModel *> *items) {
    if (previousInputMenu) {
      previousInputMenu(controller, items);
    }

    V2NIMConversationType conversationType =
        [V2NIMConversationIdUtil conversationType:ChatRepo.conversationId];
    if (conversationType != V2NIM_CONVERSATION_TYPE_P2P) {
      return;
    }

    for (NEMoreItemModel *item in items) {
      if (item.type == NEMoreActionTypeRtc) {
        return;
      }
    }

    NEMoreItemModel *rtc = [[NEMoreItemModel alloc] init];
    rtc.image = [[NEChatUIKitClient instance] getImageSourceWithImageName:@"chat_rtc"];
    rtc.title = [[NEChatUIKitClient instance] getLanguageWithKey:@"chat_rtc"];
    rtc.type = NEMoreActionTypeRtc;
    [items addObject:rtc];
  };
}

- (void)registerCustomChatRouterForFunUI:(BOOL)isFunUI {
  [[Router shared] register:NIMDemoPushP2pChatVCRouterCompat closure:^(NSDictionary<NSString *, id> *param) {
    // 未接管（普通手机 / 回退 legacy）时才走下面的自定义推栈逻辑。
    if ([ChatRouter presentConversationIfHandledWithRoute:NIMDemoPushP2pChatVCRouterCompat parameters:param]) {
      return;
    }
    UINavigationController *nav = [param[@"nav"] isKindOfClass:UINavigationController.class]
                                       ? param[@"nav"]
                                       : nil;
    if (!nav) {
      return;
    }

    BOOL animated = [param[@"animated"] respondsToSelector:@selector(boolValue)]
                        ? [param[@"animated"] boolValue]
                        : YES;
    NSString *conversationId = [param[@"conversationId"] isKindOfClass:NSString.class]
                                   ? param[@"conversationId"]
                                   : nil;
    if (conversationId.length <= 0) {
      return;
    }

    V2NIMMessage *anchor = [param[@"anchor"] isKindOfClass:V2NIMMessage.class] ? param[@"anchor"] : nil;
    NSArray<V2NIMMessage *> *onReceiveNewMsgs = NIMDemoSafeMessagesValue(param[@"onReceiveNewMsgs"]);
    ChatViewController *p2pChatVC = isFunUI
        ? [[CustomFunChatViewController alloc] initWithConversationId:conversationId anchor:anchor]
        : [[CustomNormalChatViewController alloc] initWithConversationId:conversationId anchor:anchor];
    if (onReceiveNewMsgs.count > 0) {
      p2pChatVC.pendingNewMessages = [onReceiveNewMsgs mutableCopy];
    }

    NSMutableArray<UIViewController *> *viewControllers =
        [nav.viewControllers mutableCopy] ?: [NSMutableArray array];
    for (NSInteger i = 0; i < viewControllers.count; i++) {
      UIViewController *vc = viewControllers[i];
      if (![vc isKindOfClass:ChatViewController.class]) {
        continue;
      }

      viewControllers[i] = p2pChatVC;
      nav.viewControllers = viewControllers;
      [nav popToViewController:p2pChatVC animated:animated];
      return;
    }

    NSInteger count = nav.viewControllers.count;
    [nav pushViewController:p2pChatVC animated:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                     if ([param[@"removeUserVC"] respondsToSelector:@selector(boolValue)] &&
                         [param[@"removeUserVC"] boolValue]) {
                       NSInteger currentCount = count;
                       NSMutableArray<UIViewController *> *controllers =
                           [nav.viewControllers mutableCopy] ?: [NSMutableArray array];
                       while (currentCount > 1 &&
                              currentCount <= (NSInteger)controllers.count &&
                              [controllers.lastObject isKindOfClass:ChatViewController.class]) {
                         [controllers removeObjectAtIndex:currentCount - 1];
                         currentCount--;
                       }
                       nav.viewControllers = controllers;
                     }
                   });
  }];
}

- (NESecurityWarningView *)securityWarningView {
  if (!_securityWarningView) {
    _securityWarningView = [[NESecurityWarningView alloc] init];
    _securityWarningView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _securityWarningView;
}

- (NEP2PSecurityWarningView *)p2pSecurityWarningView {
  if (!_p2pSecurityWarningView) {
    _p2pSecurityWarningView = [[NEP2PSecurityWarningView alloc] init];
    _p2pSecurityWarningView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _p2pSecurityWarningView;
}

@end
