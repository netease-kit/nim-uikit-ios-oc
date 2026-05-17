#import "FunContactRouter.h"
#import "ContactConst.h"
#import "FunContactSelectedViewController.h"
#import "FunContactSelectedPageController.h"
#import "FunMultiSelectViewController.h"
#import "FunFindFriendViewController.h"
#import "FunContactUserViewController.h"
#import "FunContactViewController.h"
#import "FunValidationPageController.h"
#import "FunBlackListViewController.h"
#import "FunTeamListViewController.h"
#import "FunAIUserController.h"
#import "FunAIRobotController.h"
#import "FunCreateAIRobotController.h"
#import "FunRobotChatCardController.h"
#import "FunRobotNicknameEditController.h"
#import "FunAIRobotDetailController.h"
#import "FunAIRobotConfigController.h"
#import "FunAIRobotBindController.h"
#import "NEBaseAIRobotBindController.h"
#import "AIRobotBindViewModel.h"
#import <NECommonUIKitOC/UIView+YXToast.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NIMSDK/NIMSDK.h>

@implementation ContactRouter (Fun)

+ (void)registerFun {
  [[Router shared] register:ContactUserSelectRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    NSSet<NSString *> *filters = [param[@"filters"] isKindOfClass:[NSSet class]] ? param[@"filters"] : nil;
    FunContactSelectedViewController *vc = [[FunContactSelectedViewController alloc] initWithFilterUsers:filters];
    if ([param[@"limit"] isKindOfClass:[NSNumber class]] && [param[@"limit"] integerValue] > 0) {
      vc.limit = [param[@"limit"] integerValue];
    }
    if ([param[@"uid"] isKindOfClass:[NSString class]]) {
      vc.userId = param[@"uid"];
    }
    [nav pushViewController:vc animated:animated];
  }];
  [[Router shared] register:ContactFusionSelectRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    NSSet<NSString *> *filters = [param[@"filters"] isKindOfClass:[NSSet class]] ? param[@"filters"] : nil;
    FunContactSelectedPageController *vc = [[FunContactSelectedPageController alloc] initWithFilterUsers:filters];
    if ([param[@"limit"] isKindOfClass:[NSNumber class]] && [param[@"limit"] integerValue] > 0) {
      vc.limit = [param[@"limit"] integerValue];
    }
    if ([param[@"uid"] isKindOfClass:[NSString class]]) {
      vc.userId = param[@"uid"];
    }
    [nav pushViewController:vc animated:animated];
  }];
  [[Router shared] register:ForwardMultiSelectRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    NSSet<NSString *> *filters = [param[@"filters"] isKindOfClass:[NSSet class]] ? param[@"filters"] : nil;
    FunMultiSelectViewController *vc = [[FunMultiSelectViewController alloc] initWithFilterUsers:filters];
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    if ([param[@"limit"] isKindOfClass:[NSNumber class]] && [param[@"limit"] integerValue] > 0) {
      vc.limit = [param[@"limit"] integerValue];
    }
    if ([param[@"uid"] isKindOfClass:[NSString class]]) {
      vc.userId = param[@"uid"];
    }
    [nav presentViewController:vc animated:animated completion:nil];
  }];
  [[Router shared] register:ContactBlackListRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    FunBlackListViewController *vc = [[FunBlackListViewController alloc] init];
    [nav pushViewController:vc animated:animated];
  }];
  [[Router shared] register:ContactTeamListRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    FunTeamListViewController *vc = [[FunTeamListViewController alloc] init];
    if (param[@"isClickCallBack"]) vc.isClickCallBack = [param[@"isClickCallBack"] boolValue];
    [nav pushViewController:vc animated:animated];
  }];
  [[Router shared] register:ValidationMessageRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    FunValidationPageController *vc = [[FunValidationPageController alloc] init];
    [nav pushViewController:vc animated:animated];
  }];
  [[Router shared] register:ContactAddFriendRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    FunFindFriendViewController *vc = [[FunFindFriendViewController alloc] init];
    [nav pushViewController:vc animated:animated];
  }];
  [[Router shared] register:ContactUserInfoPageRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    BOOL isRobot = [param[@"isRobot"] isKindOfClass:[NSNumber class]] ? [param[@"isRobot"] boolValue] : NO;
    NEUserWithFriend *user = [param[@"user"] isKindOfClass:[NEUserWithFriend class]] ? param[@"user"] : nil;
    V2NIMUser *nimUser = [param[@"nim_user"] isKindOfClass:[V2NIMUser class]] ? param[@"nim_user"] : nil;
    NSString *uid = [param[@"uid"] isKindOfClass:[NSString class]] ? param[@"uid"] : nil;
    if (user) {
      FunContactUserViewController *vc = [[FunContactUserViewController alloc] initWithUser:user];
      vc.isRobot = isRobot;
      [nav pushViewController:vc animated:animated];
    } else if (nimUser) {
      FunContactUserViewController *vc = [[FunContactUserViewController alloc] initWithNimUser:nimUser];
      vc.isRobot = isRobot;
      [nav pushViewController:vc animated:animated];
    } else if (uid) {
      FunContactUserViewController *vc = [[FunContactUserViewController alloc] initWithAccountId:uid];
      vc.isRobot = isRobot;
      [nav pushViewController:vc animated:animated];
    }
  }];
  [[Router shared] register:ContactPageRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    FunContactViewController *vc = [[FunContactViewController alloc] init];
    [nav pushViewController:vc animated:animated];
  }];
  [[Router shared] register:ContactAIUserListRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    if (nav != nil) {
      BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
      FunAIUserController *vc = [[FunAIUserController alloc] init];
      [nav pushViewController:vc animated:animated];
    }
  }];
  [[Router shared] register:ContactAIRobotListRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    if (nav != nil) {
      BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
      FunAIRobotController *vc = [[FunAIRobotController alloc] init];
      [nav pushViewController:vc animated:animated];
    }
  }];
  [[Router shared] register:ContactCreateAIRobotRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    if (nav != nil) {
      BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
      FunCreateAIRobotController *vc = [[FunCreateAIRobotController alloc] init];
      V2NIMUserAIBot *bot = param[@"bot"];
      if (bot != nil) {
        vc.editingBot = bot;
        void (^onEditSaved)(V2NIMUserAIBot *) = param[@"onEditSaved"];
        if (onEditSaved != nil) {
          vc.onEditSavedCallback = onEditSaved;
        }
      } else {
        NSString *defaultName = param[@"defaultName"];
        if (defaultName != nil) {
          vc.defaultName = defaultName;
        }
        NSString *qrCode = param[@"autoBindQrCode"];
        if (qrCode != nil) {
          vc.autoBindQrCode = qrCode;
        }
        UIViewController *sourceVC = param[@"autoBindSourceVC"];
        if (sourceVC != nil) {
          vc.autoBindSourceVC = sourceVC;
        }
      }
      [nav pushViewController:vc animated:animated];
    }
  }];
  [[Router shared] register:ContactRobotChatCardRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    V2NIMUserAIBot *bot = param[@"bot"];
    if (nav != nil && bot != nil) {
      BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
      FunRobotChatCardController *vc = [[FunRobotChatCardController alloc] initWithBot:bot];
      [nav pushViewController:vc animated:animated];
    }
  }];
  [[Router shared] register:ContactRobotNicknameEditRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    if (nav != nil) {
      BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
      FunRobotNicknameEditController *vc = [[FunRobotNicknameEditController alloc] init];
      vc.currentName = param[@"currentName"] ?: @"";
      void (^onSaved)(NSString *) = param[@"onSaved"];
      if (onSaved != nil) {
        vc.onSaved = onSaved;
      }
      [nav pushViewController:vc animated:animated];
    }
  }];
  [[Router shared] register:ContactAIRobotDetailRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    V2NIMUserAIBot *bot = param[@"bot"];
    if (nav != nil && bot != nil) {
      BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
      FunAIRobotDetailController *vc = [[FunAIRobotDetailController alloc] initWithBot:bot];
      [nav pushViewController:vc animated:animated];
    }
  }];
  [[Router shared] register:ContactAIRobotConfigRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    V2NIMUserAIBot *bot = param[@"bot"];
    if (nav != nil && bot != nil) {
      BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
      FunAIRobotConfigController *vc = [[FunAIRobotConfigController alloc] initWithBot:bot];
      [nav pushViewController:vc animated:animated];
    }
  }];
  [[Router shared] register:ContactAIRobotBindRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    if (nav != nil) {
      BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
      NSString *scanJSON = param[@"qrCode"];
      if (scanJSON != nil) {
        NSDictionary *result = [NEBaseAIRobotBindController parseQrCodeJSON:scanJSON];
        NSString *errorMessage = result[@"errorMessage"];
        if (errorMessage != nil) {
          [nav.topViewController.view ne_makeToast:errorMessage];
          return;
        }
        NSString *qrCode = result[@"qrCode"];
        if (qrCode == nil) {
          [nav.topViewController.view ne_makeToast:contactLocalizable(@"scan_qr_fail")];
          return;
        }
        FunAIRobotBindController *vc = [[FunAIRobotBindController alloc] init];
        vc.qrCode = qrCode;
        NSString *prevAccid = param[@"previousBoundAccid"];
        if (prevAccid != nil) {
          vc.viewModel.previousBoundAccid = prevAccid;
        }
        [nav pushViewController:vc animated:animated];
      }
    }
  }];
}

@end
