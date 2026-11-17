// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CreateAIRobotViewModel.h"
#import "ContactConst.h"
#import <NEChatKit/AIRepo.h>
#import <NEChatKit/ResourceRepo.h>

@implementation CreateAIRobotViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _name = @"";
    _accid = [self generateDefaultAccid];
  }
  return self;
}

- (NSString *)generateDefaultAccid {
  NSString *uuid = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
  return [@"Bot_" stringByAppendingString:[uuid substringToIndex:MIN((NSUInteger)28, uuid.length)]];
}

- (void)fetchUpdatedBot:(NSString *)accid
             completion:(void (^)(V2NIMUserAIBot *_Nullable bot))completion {
  V2NIMGetUserAIBotParams *params = [[V2NIMGetUserAIBotParams alloc] init];
  params.accid = accid;
  [[AIRepo shared] getUserAIBot:params completion:^(V2NIMUserAIBot *_Nullable bot, NSError *_Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (completion) {
        completion(bot);
      }
    });
  }];
}

- (void)fetchUpdatedBotWithAccid:(NSString *)accid
                                 :(void (^)(V2NIMUserAIBot *_Nullable bot))completion {
  [self fetchUpdatedBot:accid completion:completion];
}

- (void)createRobot:(void (^)(NSError *_Nullable error))completion {
  NSString *trimmedName = [self.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  if (trimmedName.length == 0) {
    NSError *error = [NSError errorWithDomain:@"NEContactUIKit"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey:
                                                  [contactLocalizable(@"ai_robot_name") stringByAppendingString:@"不能为空"]}];
    if (completion) {
      completion(error);
    }
    return;
  }

  if (self.avatarLocalPath.length > 0) {
    __weak typeof(self) weakSelf = self;
    V2NIMUploadFileTask *fileTask = [[ResourceRepo shared] createUploadFileTask:self.avatarLocalPath sceneName:nil];
    [[ResourceRepo shared] uploadFile:fileTask progress:nil completion:^(NSString *_Nullable url, NSError *_Nullable error) {
      if (error) {
        if (completion) {
          completion(error);
        }
        return;
      }
      [weakSelf doCreateWithName:trimmedName icon:url completion:completion];
    }];
  } else {
    [self doCreateWithName:trimmedName icon:nil completion:completion];
  }
}

- (void)doCreateWithName:(NSString *)name
                    icon:(nullable NSString *)icon
              completion:(void (^)(NSError *_Nullable error))completion {
  V2NIMCreateUserAIBotParams *params = [[V2NIMCreateUserAIBotParams alloc] init];
  params.accid = self.accid;
  params.name = name;
  if (icon.length > 0) {
    params.icon = icon;
  }

  NSString *accid = params.accid;
  __weak typeof(self) weakSelf = self;
  [[AIRepo shared] createUserAIBot:params completion:^(V2NIMCreateUserAIBotResult *_Nullable result, NSError *_Nullable error) {
    if (error) {
      if (completion) {
        completion(error);
      }
      return;
    }

    V2NIMGetUserAIBotParams *queryParams = [[V2NIMGetUserAIBotParams alloc] init];
    queryParams.accid = accid;
    [[AIRepo shared] getUserAIBot:queryParams completion:^(V2NIMUserAIBot *_Nullable bot, NSError *_Nullable queryError) {
      if (queryError) {
        if (completion) {
          completion(queryError);
        }
        return;
      }
      weakSelf.createdBot = bot;
      if (completion) {
        completion(nil);
      }
    }];
  }];
}

- (void)updateRobot:(NSString *)accid
         completion:(void (^)(NSError *_Nullable error))completion {
  NSString *trimmedName = [self.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  if (trimmedName.length == 0) {
    NSError *error = [NSError errorWithDomain:@"NEContactUIKit"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey:
                                                  [contactLocalizable(@"ai_robot_name") stringByAppendingString:@"不能为空"]}];
    if (completion) {
      completion(error);
    }
    return;
  }

  if (self.avatarLocalPath.length > 0) {
    __weak typeof(self) weakSelf = self;
    V2NIMUploadFileTask *fileTask = [[ResourceRepo shared] createUploadFileTask:self.avatarLocalPath sceneName:nil];
    [[ResourceRepo shared] uploadFile:fileTask progress:nil completion:^(NSString *_Nullable url, NSError *_Nullable error) {
      if (error) {
        if (completion) {
          completion(error);
        }
        return;
      }
      [weakSelf doUpdateWithAccid:accid name:trimmedName icon:url completion:completion];
    }];
  } else {
    [self doUpdateWithAccid:accid name:trimmedName icon:nil completion:completion];
  }
}

- (void)updateRobotWithAccid:(NSString *)accid
                            :(void (^)(NSError *_Nullable error))completion {
  [self updateRobot:accid completion:completion];
}

- (void)doUpdateWithAccid:(NSString *)accid
                     name:(NSString *)name
                     icon:(nullable NSString *)icon
               completion:(void (^)(NSError *_Nullable error))completion {
  V2NIMUpdateUserAIBotParams *params = [[V2NIMUpdateUserAIBotParams alloc] init];
  params.accid = accid;
  params.name = name;
  params.icon = icon;
  [[AIRepo shared] updateUserAIBot:params completion:^(NSError *_Nullable error) {
    if (completion) {
      completion(error);
    }
  }];
}

@end
