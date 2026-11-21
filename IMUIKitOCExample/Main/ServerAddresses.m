// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ServerAddresses.h"
#import "IMPocConfigManager.h"
#import <NIMSDK/NIMSDK.h>

@implementation ServerAddresses

+ (NSDictionary *)parsedCustomConfig:(IMPocConfigModel *)model {
  if (model.customJson.length <= 0) {
    return @{};
  }
  NSData *data = [model.customJson dataUsingEncoding:NSUTF8StringEncoding];
  if (!data) {
    return @{};
  }
  id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
  return [object isKindOfClass:[NSDictionary class]] ? object : @{};
}

+ (nullable NSString *)stringValueForKeys:(NSArray<NSString *> *)keys
                               dictionary:(NSDictionary *)dictionary
                                  config:(NSDictionary *)configMap {
  for (NSString *key in keys) {
    id value = dictionary[key];
    if ([value isKindOfClass:[NSString class]] && ((NSString *)value).length > 0) {
      return value;
    }
    value = configMap[key];
    if ([value isKindOfClass:[NSString class]] && ((NSString *)value).length > 0) {
      return value;
    }
  }
  return nil;
}

+ (void)configServer {
  NIMServerSetting *serverAddresses = [[NIMServerSetting alloc] init];
  serverAddresses.lbsAddress = @"https://lbs.netease.im/lbs/conf.jsp";
  serverAddresses.nosUploadAddress = @"https://nosup-hz1.127.net";
  serverAddresses.nosDownloadAddress = @"{bucket}-nosdn.netease.im/{object}";
  serverAddresses.nosUploadHost = @"nosup-hz1.127.net";
  serverAddresses.httpsEnabled = YES;
  [NIMSDK sharedSDK].serverSetting = serverAddresses;
}

+ (void)configCustomServer:(IMPocConfigModel *)model {
  NSDictionary *configMap = model.configMap ?: @{};
  NIMServerSetting *serverAddresses = [[NIMServerSetting alloc] init];
  NSData *customData = [model.customJson dataUsingEncoding:NSUTF8StringEncoding];
  if (customData) {
    [serverAddresses updateSettingFromConfigData:customData];
  } else {
    serverAddresses.linkAddress = [self stringValueForKeys:@[ @"linkAddress" ]
                                                dictionary:@{}
                                                   config:configMap];
    serverAddresses.lbsAddress = [self stringValueForKeys:@[ @"lbsAddress", @"lbs_address" ]
                                               dictionary:@{}
                                                  config:configMap];
    serverAddresses.nosLbsAddress = [self stringValueForKeys:@[ @"nosLbsAddress", @"nos_lbs_address" ]
                                                  dictionary:@{}
                                                     config:configMap];
    serverAddresses.nosUploadAddress = [self stringValueForKeys:@[ @"nosUploadAddress", @"nos_upload_address" ]
                                                     dictionary:@{}
                                                        config:configMap];
    serverAddresses.nosDownloadAddress = [self stringValueForKeys:@[ @"nosDownloadAddress", @"nos_download_address" ]
                                                       dictionary:@{}
                                                          config:configMap];
    serverAddresses.nosUploadHost = [self stringValueForKeys:@[ @"nosUploadHost", @"nos_upload_host" ]
                                                  dictionary:@{}
                                                     config:configMap];
    serverAddresses.module = [self stringValueForKeys:@[ @"module" ]
                                           dictionary:@{}
                                              config:configMap];
  }
  [NIMSDK sharedSDK].serverSetting = serverAddresses;
}

+ (nullable NSString *)customAppkeyFromConfig:(IMPocConfigModel *)model {
  NSDictionary *customDictionary = [self parsedCustomConfig:model];
  NSDictionary *configMap = model.configMap ?: @{};
  return [self stringValueForKeys:@[ @"appkey", @"appKey" ]
                       dictionary:customDictionary
                          config:configMap];
}

@end
