// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamRouter.h"
#import "TeamConstant.h"
#import "TeamKitConfigCenter.h"
#import <NEChatKit/NECommonUtil.h>
#import <NEChatKit/NSObject+NECommon.h>
#import <NEChatKit/NERouterUrl.h>
#import <NEChatKit/Router.h>
#import <NEChatKit/IMKitClient.h>
#import <NEChatKit/NEALog.h>
#import <NEChatKit/NECoreIM2Constant.h>
#import <NEChatKit/TeamRepo.h>
#import <NEChatKit/ChatRepo.h>
#import <NEChatKit/NESubscribeManager.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/NEFriendUserCache.h>
#import <NIMSDK/NIMSDK.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>

@implementation TeamRouter

static NSString * const NETeamCreateDiscussRoute = @"imkit://team.create.discuss";
static NSString * const NETeamCreateDiscussResultRoute = @"imkit://team.create.discuss.result";
static NSString * const NETeamCreateSeniorRoute = @"imkit://team.create.senior";
static NSString * const NETeamCreateSeniorResultRoute = @"imkit://team.create.senior.result";
static NSString * const NETeamJoinTeamRouter = @"imkit://team/joinTeam.page";
static NSString * const NETeamDetailInfoPageRouter = @"imkit://team/teamDetailInfo.page";
static NSString * const NETeamSettingViewRouter = @"imkit://team/teamSetting.page";
static NSString * const NETeamMemberSelectViewRouter = @"imkit://team/team.member.select.page";

+ (BOOL)isBlankString:(NSString *)string {
  if (![string isKindOfClass:[NSString class]]) {
    return YES;
  }
  return [[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0;
}

+ (NSString *)teamNameFromUsers:(NSArray *)users fallback:(NSString *)fallback {
  NSMutableArray<NSString *> *names = [NSMutableArray array];
  NSString *myAccount = [IMKitClient instance].account;
  if (myAccount.length > 0) {
    NEUserWithFriend *mine = [[NEFriendUserCache shared] getFriendInfo:myAccount];
    NSString *myName = [self isBlankString:[mine showName]] ? myAccount : [mine showName];
    [names addObject:myName];
  }

  for (id user in users) {
    if (![user isKindOfClass:[V2NIMUser class]]) {
      continue;
    }

    V2NIMUser *nimUser = (V2NIMUser *)user;
    NSString *showName = [self isBlankString:nimUser.name] ? nimUser.accountId : nimUser.name;
    if (showName.length > 0) {
      [names addObject:showName];
    }
  }

  if (names.count == 0) {
    return fallback;
  }
  return [names componentsJoinedByString:@"、"];
}

+ (NSString *)truncatedTeamName:(id)name fallback:(NSString *)fallback users:(NSArray *)users {
  NSString *result = [name isKindOfClass:[NSString class]] && ![self isBlankString:name] ? name : [self teamNameFromUsers:users fallback:fallback];
  if ([self isBlankString:result]) {
    result = fallback;
  }
  if (result.length <= 30) {
    return result ?: @"";
  }

  __block NSUInteger count = 0;
  __block NSUInteger endIndex = 0;
  [result enumerateSubstringsInRange:NSMakeRange(0, result.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(__unused NSString *substring,
                                       NSRange substringRange,
                                       __unused NSRange enclosingRange,
                                       BOOL *stop) {
    count += 1;
    endIndex = NSMaxRange(substringRange);
    if (count >= 30) {
      *stop = YES;
    }
  }];

  if (endIndex == 0 || endIndex >= result.length) {
    return result;
  }
  return [result substringToIndex:endIndex];
}

+ (NSString *)truncatedTeamName:(id)name fallback:(NSString *)fallback {
  return [self truncatedTeamName:name fallback:fallback users:nil];
}

+ (NSArray<NSString *> *)iconUrls {
  return @[
    @"https://yx-web-nosdn.netease.im/common/2425b4cc058e5788867d63c322feb7ac/groupAvatar1.png",
    @"https://yx-web-nosdn.netease.im/common/62c45692c9771ab388d43fea1c9d2758/groupAvatar2.png",
    @"https://yx-web-nosdn.netease.im/common/d1ed3c21d3f87a41568d17197760e663/groupAvatar3.png",
    @"https://yx-web-nosdn.netease.im/common/e677d8551deb96723af2b40b821c766a/groupAvatar4.png",
    @"https://yx-web-nosdn.netease.im/common/fd6c75bb6abca9c810d1292e66d5d87e/groupAvatar5.png",
  ];
}

+ (NSArray<NSString *> *)iconUrlsFun {
  return @[
    @"https://nim-nosdn.netease.im/MjYxNDkzNzE=/bmltYV8xNDIxMTk0NzAzMzhfMTY4NDgyNzc0MTczNV8yY2FlMjczZS01MDk0LTQ5NWMtODMzMS1mYTBmMTE1NmEyNDQ=",
    @"https://nim-nosdn.netease.im/MjYxNDkzNzE=/bmltYV8xNDIxMTk0NzAzMzhfMTY4NDgyNzc0MTczNV9jYWJmNjViNy1kMGM3LTRiNDEtYmVmMi1jYjhiNzRjY2EwY2M=",
    @"https://nim-nosdn.netease.im/MjYxNDkzNzE=/bmltYV8xNDIxMTk0NzAzMzhfMTY4NDgyNzc0MTczNV8yMzY1YmY5YS0xNGE1LTQxYTctYTg2My1hMzMyZWE5YzhhOTQ=",
    @"https://nim-nosdn.netease.im/MjYxNDkzNzE=/bmltYV8xNDIxMTk0NzAzMzhfMTY4NDgyNzc0MTczNV80NTQxMDhhNy1mNWMzLTQxMzMtOWU3NS1hNThiN2FiNjI5MWY=",
    @"https://nim-nosdn.netease.im/MjYxNDkzNzE=/bmltYV8xNDIxMTk0NzAzMzhfMTY4NDgyNzc0MTczNV8wMGVlNWUyOS0wYzg3LTQxMzUtYmVjOS00YjI1MjcxMDhhNTM=",
  ];
}

+ (void)register {
  [self registerCommonWithIconUrls:[self iconUrls]];
  [self registerRoutesWithJoinClass:@"JoinTeamViewController"
                        detailClass:@"TeamDetailViewController"
                       settingClass:@"TeamSettingViewController"
                  memberSelectClass:@"TeamMemberSelectController"];
}

+ (void)registerFun {
  [self registerCommonWithIconUrls:[self iconUrlsFun]];
  [self registerRoutesWithJoinClass:@"FunJoinTeamViewController"
                        detailClass:@"FunTeamDetailViewController"
                       settingClass:@"FunTeamSettingViewController"
                  memberSelectClass:@"FunTeamMemberSelectController"];
}

+ (void)registerCommonWithIconUrls:(NSArray<NSString *> *)iconUrls {
  [[Router shared] register:NETeamCreateDiscussRoute closure:^(NSDictionary<NSString *,id> *param) {
    NSArray<NSString *> *accids = [param[@"accids"] isKindOfClass:[NSArray class]] ? param[@"accids"] : nil;
    if (!accids.count) {
      return;
    }

    NSArray *users = [param[@"im_user"] isKindOfClass:[NSArray class]] ? param[@"im_user"] : nil;
    NSString *name = [self truncatedTeamName:param[@"names"] fallback:NETeamUIKitLocalizable(@"normal_team") users:users];

    NSString *iconUrl = [param[@"url"] isKindOfClass:[NSString class]] ? param[@"url"] : nil;
    if (iconUrl.length == 0) {
      NSUInteger index = arc4random_uniform((uint32_t)iconUrls.count);
      iconUrl = iconUrls[index];
    }

    V2NIMCreateTeamParams *createParams = [[V2NIMCreateTeamParams alloc] init];
    createParams.name = name;
    createParams.teamType = V2NIM_TEAM_TYPE_NORMAL;
    createParams.avatar = iconUrl;
    createParams.joinMode = V2NIM_TEAM_JOIN_MODE_FREE;
    createParams.inviteMode = V2NIM_TEAM_INVITE_MODE_ALL;
    createParams.agreeMode = V2NIM_TEAM_AGREE_MODE_NO_AUTH;
    createParams.updateInfoMode = V2NIM_TEAM_UPDATE_INFO_MODE_ALL;
    createParams.updateExtensionMode = V2NIM_TEAM_UPDATE_EXTENSION_MODE_ALL;

    NSString *jsonString = [NECommonUtil getJSONStringFromDictionary:@{discussTeamKey: @YES}];
    if (jsonString.length > 0) {
      createParams.serverExtension = jsonString;
    }

    [[TeamRepo shared] createTeam:createParams members:accids postscript:nil completion:^(V2NIMCreateTeamResult * _Nullable createResult, NSError * _Nullable error) {
      NSMutableDictionary *result = [NSMutableDictionary dictionary];
      if (error) {
        result[@"code"] = @(error.code);
        result[@"msg"] = NETeamUIKitErrorToast(error);
      } else {
        result[@"code"] = @0;
        result[@"msg"] = @"ok";
        if (createResult.team.teamId.length > 0) {
          result[@"teamId"] = createResult.team.teamId;
        }
      }
      [[Router shared] use:NETeamCreateDiscussResultRoute parameters:result closure:nil];
    }];
  }];

  [[Router shared] register:NETeamCreateSeniorRoute closure:^(NSDictionary<NSString *,id> *param) {
    NSArray<NSString *> *accids = [param[@"accids"] isKindOfClass:[NSArray class]] ? param[@"accids"] : nil;
    if (!accids.count) {
      return;
    }

    NSArray *users = [param[@"im_user"] isKindOfClass:[NSArray class]] ? param[@"im_user"] : nil;
    NSString *name = [self truncatedTeamName:param[@"names"] fallback:NETeamUIKitLocalizable(@"senior_team") users:users];

    NSString *iconUrl = [param[@"url"] isKindOfClass:[NSString class]] ? param[@"url"] : nil;
    if (iconUrl.length == 0) {
      NSUInteger index = arc4random_uniform((uint32_t)iconUrls.count);
      iconUrl = iconUrls[index];
    }

    V2NIMCreateTeamParams *createParams = [[V2NIMCreateTeamParams alloc] init];
    createParams.name = name;
    createParams.avatar = iconUrl;
    createParams.teamType = V2NIM_TEAM_TYPE_NORMAL;
    createParams.agreeMode = [TeamKitConfigCenter shared].teamAgreeMode;
    createParams.joinMode = [TeamKitConfigCenter shared].teamJoinMode;
    createParams.updateExtensionMode = V2NIM_TEAM_UPDATE_EXTENSION_MODE_ALL;

    [[TeamRepo shared] createTeam:createParams members:@[] postscript:nil completion:^(V2NIMCreateTeamResult * _Nullable createResult, NSError * _Nullable error) {
      NSMutableDictionary *result = [NSMutableDictionary dictionary];
      if (error) {
        result[@"code"] = @(error.code);
        result[@"msg"] = NETeamUIKitErrorToast(error);
      } else {
        result[@"code"] = @0;
        result[@"msg"] = @"ok";
        NSString *teamId = createResult.team.teamId ?: @"";
        if (teamId.length > 0) {
          result[@"teamId"] = teamId;
          NSString *conversationId = [V2NIMConversationIdUtil teamConversationId:teamId];
          if (conversationId.length > 0) {
            [[TeamRepo shared] getTeamInfo:teamId teamType:V2NIM_TEAM_TYPE_NORMAL completion:^(V2NIMTeam * _Nullable team, NSError * _Nullable teamError) {
              NSTimeInterval createTime = team ? team.createTime : [[NSDate date] timeIntervalSince1970];
              V2NIMMessage *message = [V2NIMMessageCreator createTipsMessage:NETeamUIKitLocalizable(@"create_senior_team_noti")];
              [[ChatRepo shared] insertMessageToLocal:message
                                       conversationId:conversationId
                                             senderId:[IMKitClient instance].account ?: @""
                                           createTime:@(createTime)
                                           completion:^(__unused V2NIMMessage * _Nullable insertedMessage, __unused NSError * _Nullable insertError) {
                [[TeamRepo shared] inviteTeamMembers:teamId teamType:V2NIM_TEAM_TYPE_NORMAL members:accids completion:^(__unused NSError * _Nullable inviteError, __unused NSArray<V2NIMTeamMember *> * _Nullable members) {
                }];
              }];
              if (teamError) {
                [NEALog infoLog:[self className] desc:[NSString stringWithFormat:@"registerCommonWithIconUrls getTeamInfo error:%@", teamError.localizedDescription ?: @""]];
              }
            }];
          }
        }
      }

      [[Router shared] use:NETeamCreateSeniorResultRoute parameters:result closure:nil];
    }];
  }];

  if ([IMKitConfigCenter shared].enableOnlineStatus) {
    [NESubscribeManager shared];
  }

  (void)iconUrls;
}

+ (void)registerRoutesWithJoinClass:(NSString *)joinClass
                        detailClass:(NSString *)detailClass
                       settingClass:(NSString *)settingClass
                  memberSelectClass:(NSString *)memberSelectClass {
  [[Router shared] register:NETeamJoinTeamRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
    UIViewController *controller = [self instantiateControllerWithClassName:joinClass team:nil];
    if (nav && controller) {
      [nav pushViewController:controller animated:animated];
    }
  }];

  [[Router shared] register:NETeamDetailInfoPageRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
    V2NIMTeam *team = [param[@"team"] isKindOfClass:[V2NIMTeam class]] ? param[@"team"] : nil;
    UIViewController *controller = [self instantiateControllerWithClassName:detailClass team:team];
    if (nav && controller) {
      [nav pushViewController:controller animated:animated];
    }
  }];

  [[Router shared] register:NETeamSettingViewRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
    UIViewController *controller = [self instantiateControllerWithClassName:settingClass team:nil];
    if ([controller respondsToSelector:NSSelectorFromString(@"setTeamId:")] && [param[@"teamid"] isKindOfClass:[NSString class]]) {
      [controller setValue:param[@"teamid"] forKey:@"teamId"];
    }
    if (nav && controller) {
      [nav pushViewController:controller animated:animated];
    }
  }];

  [[Router shared] register:NETeamMemberSelectViewRouter closure:^(NSDictionary<NSString *,id> *param) {
    UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
    BOOL animated = param[@"animated"] ? [param[@"animated"] boolValue] : YES;
    UIViewController *controller = [self instantiateControllerWithClassName:memberSelectClass team:nil];
    if ([controller respondsToSelector:NSSelectorFromString(@"setTeamId:")] && [param[@"teamId"] isKindOfClass:[NSString class]]) {
      [controller setValue:param[@"teamId"] forKey:@"teamId"];
    }
    if ([controller respondsToSelector:NSSelectorFromString(@"setTitle:")] && [param[@"navTitle"] isKindOfClass:[NSString class]]) {
      [controller setValue:param[@"navTitle"] forKey:@"title"];
    }
    if ([controller respondsToSelector:NSSelectorFromString(@"setSelectCountLimit:")]) {
      NSInteger memberLimit = [param[@"memberLimit"] respondsToSelector:@selector(integerValue)] ? [param[@"memberLimit"] integerValue] : 1;
      [controller setValue:@(memberLimit) forKey:@"selectCountLimit"];
    }
    if ([controller respondsToSelector:NSSelectorFromString(@"setSelectMemberBlock:")] && param[@"selectMemberBlock"]) {
      [controller setValue:param[@"selectMemberBlock"] forKey:@"selectMemberBlock"];
    }
    if ([controller respondsToSelector:NSSelectorFromString(@"setShowAllMembers:")]) {
      BOOL showAllMembers = param[@"showAllMembers"] ? [param[@"showAllMembers"] boolValue] : NO;
      [controller setValue:@(showAllMembers) forKey:@"showAllMembers"];
    }
    if (nav && controller) {
      [nav pushViewController:controller animated:animated];
    }
  }];
}

+ (UIViewController *)instantiateControllerWithClassName:(NSString *)className team:(V2NIMTeam * _Nullable)team {
  Class cls = NSClassFromString(className);
  if (!cls || ![cls isSubclassOfClass:[UIViewController class]]) {
    return nil;
  }

  UIViewController *controller = nil;
  SEL nimTeamSelector = NSSelectorFromString(@"initWithNimTeam:");
  SEL teamSelector = NSSelectorFromString(@"initWithTeam:");
  if (team && [cls instancesRespondToSelector:nimTeamSelector]) {
    controller = ((UIViewController *(*)(id, SEL, V2NIMTeam *))objc_msgSend)([cls alloc], nimTeamSelector, team);
  } else if (team && [cls instancesRespondToSelector:teamSelector]) {
    controller = ((UIViewController *(*)(id, SEL, V2NIMTeam *))objc_msgSend)([cls alloc], teamSelector, team);
  } else {
    controller = [[cls alloc] init];
  }
  return controller;
}

@end
