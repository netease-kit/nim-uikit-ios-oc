// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NormalContactRouter.h"
#import "ContactConst.h"
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NIMSDK/NIMSDK.h>

// ViewController imports
#import "ContactSelectedViewController.h"
#import "ContactSelectedPageController.h"
#import "MultiSelectViewController.h"
#import "FindFriendViewController.h"
#import "ContactUserViewController.h"
#import "ContactViewController.h"
#import "ValidationPageController.h"
#import "BlackListViewController.h"
#import "TeamListViewController.h"
#import "AIUserController.h"
#import "AIRobotController.h"
#import "CreateAIRobotController.h"
#import "RobotChatCardController.h"
#import "RobotNicknameEditController.h"
#import "AIRobotDetailController.h"
#import "AIRobotConfigController.h"
#import "AIRobotBindController.h"
#import "NEBaseAIRobotBindController.h"
#import "AIRobotBindViewModel.h"
#import <NECommonUIKitOC/UIView+YXToast.h>

@implementation ContactRouter (Normal)

+ (void)registerRouter {
  // 成员选择页面
  [[Router shared] register:ContactUserSelectRouter closure:^(NSDictionary<NSString *,id> *param) {
    NSLog(@"param:%@", param);
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    NSNumber *animatedNum = [param[@"animated"] isKindOfClass:[NSNumber class]] ? param[@"animated"] : nil;
    BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
    NSSet<NSString *> *filters = [param[@"filters"] isKindOfClass:[NSSet class]] ? param[@"filters"] : nil;
    ContactSelectedViewController *contactSelectVC = [[ContactSelectedViewController alloc] initWithFilterUsers:filters];
    NSNumber *limitNum = [param[@"limit"] isKindOfClass:[NSNumber class]] ? param[@"limit"] : nil;
    if (limitNum != nil && [limitNum integerValue] > 0) {
      contactSelectVC.limit = [limitNum integerValue];
    }
    NSString *uid = [param[@"uid"] isKindOfClass:[NSString class]] ? param[@"uid"] : nil;
    if (uid != nil) {
      contactSelectVC.userId = uid;
    }
    [nav pushViewController:contactSelectVC animated:animated];
  }];

  // 携带机器人的成员选择页面
  [[Router shared] register:ContactFusionSelectRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    NSNumber *animatedNum = [param[@"animated"] isKindOfClass:[NSNumber class]] ? param[@"animated"] : nil;
    BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
    NSSet<NSString *> *userFilters = [param[@"filters"] isKindOfClass:[NSSet class]] ? param[@"filters"] : nil;
    ContactSelectedPageController *contactSelectedPageController = [[ContactSelectedPageController alloc] initWithFilterUsers:userFilters];
    NSNumber *limitNum = [param[@"limit"] isKindOfClass:[NSNumber class]] ? param[@"limit"] : nil;
    if (limitNum != nil && [limitNum integerValue] > 0) {
      contactSelectedPageController.limit = [limitNum integerValue];
    }
    NSString *uid = [param[@"uid"] isKindOfClass:[NSString class]] ? param[@"uid"] : nil;
    if (uid != nil) {
      contactSelectedPageController.userId = uid;
    }
    [nav pushViewController:contactSelectedPageController animated:animated];
  }];

  // 转发选择页面
  [[Router shared] register:ForwardMultiSelectRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    NSNumber *animatedNum = [param[@"animated"] isKindOfClass:[NSNumber class]] ? param[@"animated"] : nil;
    BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
    NSSet<NSString *> *filters = [param[@"filters"] isKindOfClass:[NSSet class]] ? param[@"filters"] : nil;
    MultiSelectViewController *contactSelectVC = [[MultiSelectViewController alloc] initWithFilterUsers:filters];
    NSNumber *limitNum = [param[@"limit"] isKindOfClass:[NSNumber class]] ? param[@"limit"] : nil;
    if (limitNum != nil && [limitNum integerValue] > 0) {
      contactSelectVC.limit = [limitNum integerValue];
    }
    NSString *uid = [param[@"uid"] isKindOfClass:[NSString class]] ? param[@"uid"] : nil;
    if (uid != nil) {
      contactSelectVC.userId = uid;
    }
    [nav presentViewController:contactSelectVC animated:animated completion:nil];
  }];

  // 添加好友页面
  [[Router shared] register:ContactAddFriendRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    NSNumber *animatedNum = [param[@"animated"] isKindOfClass:[NSNumber class]] ? param[@"animated"] : nil;
    BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
    FindFriendViewController *findFriend = [[FindFriendViewController alloc] init];
    [nav pushViewController:findFriend animated:animated];
  }];

  // 用户信息页面
  [[Router shared] register:ContactUserInfoPageRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    if (nav != nil) {
      NSNumber *animatedNum = [param[@"animated"] isKindOfClass:[NSNumber class]] ? param[@"animated"] : nil;
      BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
      NSNumber *isRobotNum = [param[@"isRobot"] isKindOfClass:[NSNumber class]] ? param[@"isRobot"] : nil;
      BOOL isRobot = isRobotNum != nil ? [isRobotNum boolValue] : NO;
      NEUserWithFriend *user = [param[@"user"] isKindOfClass:[NEUserWithFriend class]] ? param[@"user"] : nil;
      V2NIMUser *nimUser = [param[@"nim_user"] isKindOfClass:[V2NIMUser class]] ? param[@"nim_user"] : nil;
      NSString *uid = [param[@"uid"] isKindOfClass:[NSString class]] ? param[@"uid"] : nil;
      if (user != nil) {
        ContactUserViewController *userInfoVC = [[ContactUserViewController alloc] initWithUser:user];
        userInfoVC.isRobot = isRobot;
        [nav pushViewController:userInfoVC animated:animated];
      } else if (nimUser != nil) {
        ContactUserViewController *userInfoVC = [[ContactUserViewController alloc] initWithNimUser:nimUser];
        userInfoVC.isRobot = isRobot;
        [nav pushViewController:userInfoVC animated:animated];
      } else if (uid != nil) {
        ContactUserViewController *userInfoVC = [[ContactUserViewController alloc] initWithAccountId:uid];
        userInfoVC.isRobot = isRobot;
        [nav pushViewController:userInfoVC animated:animated];
      }
    }
  }];

  // 好友列表页面
  [[Router shared] register:ContactPageRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    if (nav != nil) {
      NSNumber *animatedNum = [param[@"animated"] isKindOfClass:[NSNumber class]] ? param[@"animated"] : nil;
      BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
      ContactViewController *contactVC = [[ContactViewController alloc] init];
      [nav pushViewController:contactVC animated:animated];
    }
  }];

  // 验证消息页面
  [[Router shared] register:ValidationMessageRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    if (nav != nil) {
      NSNumber *animatedNum = [param[@"animated"] isKindOfClass:[NSNumber class]] ? param[@"animated"] : nil;
      BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
      ValidationPageController *validationController = [[ValidationPageController alloc] init];
      [nav pushViewController:validationController animated:animated];
    }
  }];

  // 黑名单页面
  [[Router shared] register:ContactBlackListRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    if (nav != nil) {
      NSNumber *animatedNum = [param[@"animated"] isKindOfClass:[NSNumber class]] ? param[@"animated"] : nil;
      BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
      BlackListViewController *blackVC = [[BlackListViewController alloc] init];
      [nav pushViewController:blackVC animated:animated];
    }
  }];

  // 我的数字人列表
  [[Router shared] register:ContactAIUserListRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    if (nav != nil) {
      NSNumber *animatedNum = param[@"animated"];
      BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
      AIUserController *aiUserVC = [[AIUserController alloc] init];
      [nav pushViewController:aiUserVC animated:animated];
    }
  }];

  // 我的机器人列表
  [[Router shared] register:ContactAIRobotListRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    if (nav != nil) {
      NSNumber *animatedNum = param[@"animated"];
      BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
      AIRobotController *robotVC = [[AIRobotController alloc] init];
      [nav pushViewController:robotVC animated:animated];
    }
  }];

  // 创建机器人
  [[Router shared] register:ContactCreateAIRobotRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    if (nav != nil) {
      NSNumber *animatedNum = param[@"animated"];
      BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
      CreateAIRobotController *createVC = [[CreateAIRobotController alloc] init];
      V2NIMUserAIBot *bot = param[@"bot"];
      if (bot != nil) {
        // 编辑模式：预填 bot、注入保存回调（用于刷新 Detail 页）
        createVC.editingBot = bot;
        void (^onEditSaved)(V2NIMUserAIBot *) = param[@"onEditSaved"];
        if (onEditSaved) {
          createVC.onEditSavedCallback = onEditSaved;
        }
      } else {
        // 新建模式：注入默认昵称
        NSString *defaultName = param[@"defaultName"];
        if (defaultName) {
          createVC.defaultName = defaultName;
        }
        // 来自绑定页的新建：注入 qrCode 以便创建后自动绑定
        NSString *qrCode = param[@"autoBindQrCode"];
        if (qrCode) {
          createVC.autoBindQrCode = qrCode;
        }
        UIViewController *sourceVC = param[@"autoBindSourceVC"];
        if (sourceVC) {
          createVC.autoBindSourceVC = sourceVC;
        }
      }
      [nav pushViewController:createVC animated:animated];
    }
  }];

  // 聊天页头像点击进入的机器人名片页
  [[Router shared] register:ContactRobotChatCardRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    V2NIMUserAIBot *bot = param[@"bot"];
    if (nav != nil && bot != nil) {
      NSNumber *animatedNum = param[@"animated"];
      BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
      RobotChatCardController *cardVC = [[RobotChatCardController alloc] initWithBot:bot];
      [nav pushViewController:cardVC animated:animated];
    }
  }];

  // 机器人昵称编辑页
  [[Router shared] register:ContactRobotNicknameEditRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    if (nav != nil) {
      NSNumber *animatedNum = param[@"animated"];
      BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
      RobotNicknameEditController *editVC = [[RobotNicknameEditController alloc] init];
      NSString *currentName = param[@"currentName"];
      editVC.currentName = currentName ?: @"";
      void (^onSaved)(NSString *) = param[@"onSaved"];
      if (onSaved) {
        editVC.onSaved = onSaved;
      }
      [nav pushViewController:editVC animated:animated];
    }
  }];

  // 机器人名片页
  [[Router shared] register:ContactAIRobotDetailRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    V2NIMUserAIBot *bot = param[@"bot"];
    if (nav != nil && bot != nil) {
      NSNumber *animatedNum = param[@"animated"];
      BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
      AIRobotDetailController *detailVC = [[AIRobotDetailController alloc] initWithBot:bot];
      [nav pushViewController:detailVC animated:animated];
    }
  }];

  // 机器人配置串页
  [[Router shared] register:ContactAIRobotConfigRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    V2NIMUserAIBot *bot = param[@"bot"];
    if (nav != nil && bot != nil) {
      NSNumber *animatedNum = param[@"animated"];
      BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
      AIRobotConfigController *configVC = [[AIRobotConfigController alloc] initWithBot:bot];
      [nav pushViewController:configVC animated:animated];
    }
  }];

  // 绑定机器人页（扫码后跳转）
  [[Router shared] register:ContactAIRobotBindRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    if (nav != nil) {
      NSNumber *animatedNum = param[@"animated"];
      BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
      NSString *scanJSON = param[@"qrCode"];
      if (scanJSON != nil) {
        // 解析扫码 JSON，校验过期时间
        NSDictionary *result = [NEBaseAIRobotBindController parseQrCodeJSON:scanJSON];
        NSString *errorMessage = result[@"errorMessage"];
        if (errorMessage != nil) {
          // 已过期：Toast 提示，不跳转
          [nav.topViewController.view ne_makeToast:errorMessage];
          return;
        }
        NSString *qrCode = result[@"qrCode"];
        if (qrCode == nil) {
          // 不符合机器人二维码格式：提示扫码失败
          [nav.topViewController.view ne_makeToast:contactLocalizable(@"scan_qr_fail")];
          return;
        }
        AIRobotBindController *bindVC = [[AIRobotBindController alloc] init];
        bindVC.qrCode = qrCode;
        NSString *prevAccid = param[@"previousBoundAccid"];
        if (prevAccid != nil) {
          bindVC.viewModel.previousBoundAccid = prevAccid;
        }
        [nav pushViewController:bindVC animated:animated];
      }
    }
  }];

  // 我的群聊
  [[Router shared] register:ContactTeamListRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    if (nav != nil) {
      NSNumber *animatedNum = param[@"animated"];
      BOOL animated = animatedNum != nil ? [animatedNum boolValue] : YES;
      TeamListViewController *team = [[TeamListViewController alloc] init];
      NSNumber *isClickCallBackNum = param[@"isClickCallBack"];
      if (isClickCallBackNum != nil) {
        team.isClickCallBack = [isClickCallBackNum boolValue];
      }
      [nav pushViewController:team animated:animated];
    }
  }];
}

@end
