// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "IMPushConfigManager.h"
#import <NEChatKitOC/SettingRepo.h>

static NSString *const kPushConfigFilename = @"im_sdk_push_config";

// ─────────────────────────────────────────────
#pragma mark - IMPushConfigModel
// ─────────────────────────────────────────────

@implementation IMPushConfigModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _configMap = [[NSMutableDictionary alloc] init];
    _config = [[V2NIMMessagePushConfig alloc] init];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _configMap = [coder decodeObjectForKey:@"configMap"] ?: [[NSMutableDictionary alloc] init];
    _customJson = [coder decodeObjectForKey:@"customJson"];
    _config = [coder decodeObjectForKey:@"config"] ?: [[V2NIMMessagePushConfig alloc] init];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:_configMap forKey:@"configMap"];
  [coder encodeObject:_customJson forKey:@"customJson"];
  [coder encodeObject:_config forKey:@"config"];
}

@end

// ─────────────────────────────────────────────
#pragma mark - IMPushConfigManager
// ─────────────────────────────────────────────

@interface IMPushConfigManager ()
@property (nonatomic, strong, nullable) IMPushConfigModel *configModel;
@end

@implementation IMPushConfigManager

+ (instancetype)instance {
  static IMPushConfigManager *manager = nil;
  static dispatch_once_t token;
  dispatch_once(&token, ^{ manager = [[IMPushConfigManager alloc] initPrivate]; });
  return manager;
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _configModel = [self loadFromDisk:kPushConfigFilename];
  }
  return self;
}

- (IMPushConfigModel *)getConfig {
  return self.configModel ?: [[IMPushConfigModel alloc] init];
}

- (void)saveConfig:(IMPushConfigModel *)model {
  self.configModel = model;
  [self saveToDisk:model fileName:kPushConfigFilename];
  [[SettingRepo shared] setMessagePushConfig:[self getPushConfig]];
}

- (V2NIMMessagePushConfig *)getPushConfig {
  NSMutableDictionary *map = self.configModel.configMap;
  if (self.configModel.customJson.length > 0) {
    NSData *data = [self.configModel.customJson dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if ([json isKindOfClass:[NSDictionary class]]) {
      map = [json mutableCopy];
    }
  }
  V2NIMMessagePushConfig *pushConfig = self.configModel.config ?: [[V2NIMMessagePushConfig alloc] init];
  if (map[@"pushEnabled"])     pushConfig.pushEnabled     = [map[@"pushEnabled"] boolValue];
  if (map[@"pushNickEnabled"]) pushConfig.pushNickEnabled = [map[@"pushNickEnabled"] boolValue];
  if (map[@"pushContent"])     pushConfig.pushContent     = map[@"pushContent"];
  if (map[@"pushPayload"])     pushConfig.pushPayload     = map[@"pushPayload"];
  if (map[@"forcePush"])       pushConfig.forcePush       = [map[@"forcePush"] boolValue];
  if (map[@"forcePushContent"]) pushConfig.forcePushContent = map[@"forcePushContent"];
  return pushConfig;
}

- (void)clearConfig {
  NSURL *url = [self fileURL:kPushConfigFilename];
  if (url) {
    [NSFileManager.defaultManager removeItemAtURL:url error:nil];
    self.configModel = nil;
  }
}

- (void)saveToDisk:(IMPushConfigModel *)model fileName:(NSString *)name {
  NSURL *url = [self fileURL:name];
  if (!url) return;
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model requiringSecureCoding:NO error:nil];
  [data writeToURL:url atomically:YES];
}

- (nullable IMPushConfigModel *)loadFromDisk:(NSString *)name {
  NSURL *url = [self fileURL:name];
  if (!url || ![NSFileManager.defaultManager fileExistsAtPath:url.path]) return nil;
  NSData *data = [NSData dataWithContentsOfURL:url];
  if (!data) return nil;
  return [NSKeyedUnarchiver unarchivedObjectOfClass:[IMPushConfigModel class] fromData:data error:nil];
}

- (nullable NSURL *)fileURL:(NSString *)name {
  NSURL *docs = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
  return [docs URLByAppendingPathComponent:name];
}

@end
