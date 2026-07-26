// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomConfig.h"
#import "AIChatDataLoader.h"
#import "CustomChatViewController.h"
#import "AppKey.h"
#import "NEStyleManager.h"
#import "NEP2PSecurityWarningView.h"
#import "NESecurityWarningView.h"
#import <NEChatKit/ChatRepo.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/NERouterUrl.h>
#import <NEChatKit/Router.h>
#import <NEChatUIKitOC/AIChatViewController.h>
#import <NEChatUIKitOC/ChatUIConfig.h>
#import <NEChatUIKitOC/ChatViewController.h>
#import <NEChatUIKitOC/NEChatUIKitClient.h>
#import <NEChatUIKitOC/NEMoreItemModel.h>
#import <NECommonUIKitOC/CommonUIConfig.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import <NEContactUIKitOC/ContactUIConfig.h>
#import <NEConversationUIKitOC/ConversationUIConfig.h>
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
  // Keep the demo behavior unchanged by default. This method mirrors the Swift
  // sample entry so the OC demo has the same customization surface.
}

- (void)configContactUIKit {
}

- (void)configConversationUIKit {
  __weak typeof(self) weakSelf = self;
  ConversationUIConfig.shared.customController = ^(UIViewController *vc) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf || ![vc isKindOfClass:[NEConversationViewController class]]) {
      return;
    }

    NEConversationViewController *viewController = (NEConversationViewController *)vc;
    strongSelf.securityWarningView.warningLabel.text = NELocalizable(@"security_warning");

    if (strongSelf.securityWarningView.superview != viewController.bodyTopView) {
      [strongSelf.securityWarningView removeFromSuperview];
      [viewController.bodyTopView addSubview:strongSelf.securityWarningView];
      CGFloat topInset = [NEStyleManager.instance isNormalStyle] ? 0.0 : 60.0;
      [NSLayoutConstraint activateConstraints:@[
        [strongSelf.securityWarningView.topAnchor constraintEqualToAnchor:viewController.bodyTopView.topAnchor constant:topInset],
        [strongSelf.securityWarningView.leftAnchor constraintEqualToAnchor:viewController.bodyTopView.leftAnchor],
        [strongSelf.securityWarningView.rightAnchor constraintEqualToAnchor:viewController.bodyTopView.rightAnchor],
        [strongSelf.securityWarningView.heightAnchor constraintEqualToConstant:56.0],
      ]];
    }

    viewController.bodyTopViewHeight = [NEStyleManager.instance isNormalStyle] ? 56.0 : 116.0;
  };
}

- (void)loadAIChatData {
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
        switch (mediaType) {
          case NEMediaTypeAll:
            configuration.allowSelectImage = YES;
            configuration.allowSelectVideo = YES;
            configuration.allowSelectLivePhoto = YES;
            configuration.allowTakePhotoInLibrary = NO;
            configuration.allowMixSelect = NO;
            configuration.maxSelectCount = limit;
            configuration.maxSelectVideoDataSize = ChatUIConfig.shared.fileSizeLimit * 1024;
            break;
          case NEMediaTypeImage:
            configuration.allowSelectImage = YES;
            configuration.allowSelectVideo = NO;
            configuration.maxSelectCount = limit;
            configuration.editAfterSelectThumbnailImage = YES;
            configuration.allowSelectLivePhoto = YES;
            configuration.allowTakePhotoInLibrary = NO;
            break;
          case NEMediaTypeVideo:
          default:
            configuration.allowSelectImage = NO;
            configuration.allowSelectVideo = YES;
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
  [self configConversationUIKit];

  NEChatCustomControllerBlock previousCustomController = ChatUIConfig.shared.customController;
  __weak typeof(self) weakSelf = self;
  ChatUIConfig.shared.customController = ^(ChatViewController *viewController) {
    if (previousCustomController) {
      previousCustomController(viewController);
    }

    if ([viewController.bodyTopView viewWithTag:kNIMDemoSecurityWarningTag]) {
      viewController.bodyTopViewHeight = 56;
      return;
    }

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
