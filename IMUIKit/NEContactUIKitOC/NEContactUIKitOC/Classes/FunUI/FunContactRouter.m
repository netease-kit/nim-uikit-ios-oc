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

#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NEChatKitOC.h>

static NSString * const NEFunContactUserSelectRouterCompat = @"imkit://contact/selector.page";
static NSString * const NEFunContactFusionSelectRouterCompat = @"imkit://contact/fusionselector.page";
static NSString * const NEFunForwardMultiSelectRouterCompat = @"imkit://contact/tab/selector.page";
static NSString * const NEFunContactBlackListRouterCompat = @"imkit://contact/blackList.page";
static NSString * const NEFunContactTeamListRouterCompat = @"imkit://contact/teamList.page";
static NSString * const NEFunValidationMessageRouterCompat = @"imkit://contact/verifyList.page";
static NSString * const NEFunContactAddFriendRouterCompat = @"imkit://contact/addFriend.page";
static NSString * const NEFunContactUserInfoPageRouterCompat = @"imkit://contact/userInfo.page";
static NSString * const NEFunContactPageRouterCompat = @"imkit://contact/contactList.page";
static NSString * const NEFunContactAIUserListRouterCompat = @"imkit://contact/aiList.page";
static NSString * const NEFunContactAIRobotListRouterCompat = @"imkit://contact/aiRobotList.page";
static NSString * const NEFunContactCreateAIRobotRouterCompat = @"imkit://contact/createAIRobot.page";
static NSString * const NEFunContactRobotChatCardRouterCompat = @"imkit://contact/robotChatCard.page";
static NSString * const NEFunContactRobotNicknameEditRouterCompat = @"imkit://contact/robotNicknameEdit.page";
static NSString * const NEFunContactAIRobotDetailRouterCompat = @"imkit://contact/aiRobotDetail.page";
static NSString * const NEFunContactAIRobotConfigRouterCompat = @"imkit://contact/aiRobotConfig.page";
static NSString * const NEFunContactAIRobotBindRouterCompat = @"imkit://contact/aiRobotBind.page";

@implementation ContactRouter (Fun)

+ (void)registerFun {
  [[Router shared] register:NEFunContactUserSelectRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
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
  [[Router shared] register:NEFunContactFusionSelectRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
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
  [[Router shared] register:NEFunForwardMultiSelectRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
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
  [[Router shared] register:NEFunContactBlackListRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    FunBlackListViewController *vc = [[FunBlackListViewController alloc] init];
    [nav pushViewController:vc animated:animated];
  }];
  [[Router shared] register:NEFunContactTeamListRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    FunTeamListViewController *vc = [[FunTeamListViewController alloc] init];
    if (param[@"isClickCallBack"]) vc.isClickCallBack = [param[@"isClickCallBack"] boolValue];
    [nav pushViewController:vc animated:animated];
  }];
  [[Router shared] register:NEFunValidationMessageRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    FunValidationPageController *vc = [[FunValidationPageController alloc] init];
    [nav pushViewController:vc animated:animated];
  }];
  [[Router shared] register:NEFunContactAddFriendRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    FunFindFriendViewController *vc = [[FunFindFriendViewController alloc] init];
    [nav pushViewController:vc animated:animated];
  }];
  [[Router shared] register:NEFunContactUserInfoPageRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
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
  [[Router shared] register:NEFunContactPageRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    FunContactViewController *vc = [[FunContactViewController alloc] init];
    [nav pushViewController:vc animated:animated];
  }];
  [[Router shared] register:NEFunContactAIUserListRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    if (nav != nil) {
      BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
      FunAIUserController *vc = [[FunAIUserController alloc] init];
      [nav pushViewController:vc animated:animated];
    }
  }];
  [[Router shared] register:NEFunContactAIRobotListRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    if (nav != nil) {
      BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
      FunAIRobotController *vc = [[FunAIRobotController alloc] init];
      [nav pushViewController:vc animated:animated];
    }
  }];
  [[Router shared] register:NEFunContactCreateAIRobotRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
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
  [[Router shared] register:NEFunContactRobotChatCardRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    V2NIMUserAIBot *bot = param[@"bot"];
    if (nav != nil && bot != nil) {
      BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
      FunRobotChatCardController *vc = [[FunRobotChatCardController alloc] initWithBot:bot];
      [nav pushViewController:vc animated:animated];
    }
  }];
  [[Router shared] register:NEFunContactRobotNicknameEditRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
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
  [[Router shared] register:NEFunContactAIRobotDetailRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    V2NIMUserAIBot *bot = param[@"bot"];
    if (nav != nil && bot != nil) {
      BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
      FunAIRobotDetailController *vc = [[FunAIRobotDetailController alloc] initWithBot:bot];
      [nav pushViewController:vc animated:animated];
    }
  }];
  [[Router shared] register:NEFunContactAIRobotConfigRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = param[@"nav"];
    V2NIMUserAIBot *bot = param[@"bot"];
    if (nav != nil && bot != nil) {
      BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
      FunAIRobotConfigController *vc = [[FunAIRobotConfigController alloc] initWithBot:bot];
      [nav pushViewController:vc animated:animated];
    }
  }];
  [[Router shared] register:NEFunContactAIRobotBindRouterCompat closure:^(NSDictionary<NSString *,id> *param) {
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
