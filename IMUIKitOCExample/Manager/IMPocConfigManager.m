// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "IMPocConfigManager.h"

static NSString *const kPocConfigFilename = @"sdk_config";

// ─────────────────────────────────────────────
#pragma mark - IMPocConfigModel
// ─────────────────────────────────────────────

@implementation IMPocConfigModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _configMap = [[NSMutableDictionary alloc] init];
    _enableCustomConfig = @NO;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _configMap = [coder decodeObjectForKey:@"configMap"] ?: [[NSMutableDictionary alloc] init];
    _customJson = [coder decodeObjectForKey:@"customJson"];
    _enableCustomConfig = [coder decodeObjectForKey:@"enableCustomConfig"] ?: @NO;
    _accountId = [coder decodeObjectForKey:@"accountId"];
    _accountIdToken = [coder decodeObjectForKey:@"accountIdToken"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:_configMap forKey:@"configMap"];
  [coder encodeObject:_customJson forKey:@"customJson"];
  [coder encodeObject:_enableCustomConfig forKey:@"enableCustomConfig"];
  [coder encodeObject:_accountId forKey:@"accountId"];
  [coder encodeObject:_accountIdToken forKey:@"accountIdToken"];
}

@end

// ─────────────────────────────────────────────
#pragma mark - IMPocConfigManager
// ─────────────────────────────────────────────

@interface IMPocConfigManager ()
@property (nonatomic, strong, nullable) IMPocConfigModel *configModel;
@end

@implementation IMPocConfigManager

+ (instancetype)instance {
  static IMPocConfigManager *manager = nil;
  static dispatch_once_t token;
  dispatch_once(&token, ^{ manager = [[IMPocConfigManager alloc] initPrivate]; });
  return manager;
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _configModel = [self loadFromDisk:kPocConfigFilename];
  }
  return self;
}

- (IMPocConfigModel *)getConfig {
  return self.configModel ?: [[IMPocConfigModel alloc] init];
}

- (void)saveConfig:(IMPocConfigModel *)model {
  self.configModel = model;
  [self saveToDisk:model fileName:kPocConfigFilename];
}

- (void)clearConfig {
  NSURL *url = [self fileURL:kPocConfigFilename];
  if (url) {
    [NSFileManager.defaultManager removeItemAtURL:url error:nil];
    self.configModel = nil;
  }
}

- (void)saveToDisk:(IMPocConfigModel *)model fileName:(NSString *)name {
  NSURL *url = [self fileURL:name];
  if (!url) return;
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model requiringSecureCoding:NO error:nil];
  [data writeToURL:url atomically:YES];
}

- (nullable IMPocConfigModel *)loadFromDisk:(NSString *)name {
  NSURL *url = [self fileURL:name];
  if (!url || ![NSFileManager.defaultManager fileExistsAtPath:url.path]) return nil;
  NSData *data = [NSData dataWithContentsOfURL:url];
  if (!data) return nil;
  return [NSKeyedUnarchiver unarchivedObjectOfClass:[IMPocConfigModel class] fromData:data error:nil];
}

- (nullable NSURL *)fileURL:(NSString *)name {
  NSURL *docs = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
  return [docs URLByAppendingPathComponent:name];
}

@end
