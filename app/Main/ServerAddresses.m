// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ServerAddresses.h"
#import "IMPocConfigManager.h"
#import <NIMSDK/NIMSDK.h>
#import <NEChatKitOC/SettingRepo.h>

static NSString *const kDomesticAppKey = @"3e215d27b6a6a9e27dad7ef36dd5b65c";
static NSString *const kOverseasAppKey = @"accb0a77b32cfcec25a3e03570eff618";

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
  if ([[SettingRepo shared] getNodeValue]) {
    [NIMSDK sharedSDK].serverSetting = nil;
    return;
  }

  NIMServerSetting *serverAddresses = [[NIMServerSetting alloc] init];
  serverAddresses.lbsAddress = @"https://lbs.netease.im/lbs/conf.jsp";
  serverAddresses.nosUploadAddress = @"https://nosup-hz1.127.net";
  serverAddresses.nosDownloadAddress = @"{bucket}-nosdn.netease.im/{object}";
  serverAddresses.nosUploadHost = @"nosup-hz1.127.net";
  serverAddresses.httpsEnabled = YES;
  [NIMSDK sharedSDK].serverSetting = serverAddresses;
}

+ (void)configCustomServer:(IMPocConfigModel *)model {
  NSDictionary *customDictionary = [self parsedCustomConfig:model];
  NSDictionary *configMap = model.configMap ?: @{};

  NIMServerSetting *serverAddresses = [[NIMServerSetting alloc] init];
  serverAddresses.linkAddress = [self stringValueForKeys:@[ @"linkAddress" ]
                                              dictionary:customDictionary
                                                 config:configMap];
  serverAddresses.lbsAddress = [self stringValueForKeys:@[ @"lbsAddress", @"lbs_address" ]
                                             dictionary:customDictionary
                                                config:configMap];
  serverAddresses.nosLbsAddress = [self stringValueForKeys:@[ @"nosLbsAddress", @"nos_lbs_address" ]
                                                dictionary:customDictionary
                                                   config:configMap];
  serverAddresses.nosUploadAddress = [self stringValueForKeys:@[ @"nosUploadAddress", @"nos_upload_address" ]
                                                   dictionary:customDictionary
                                                      config:configMap];
  serverAddresses.nosDownloadAddress = [self stringValueForKeys:@[ @"nosDownloadAddress", @"nos_download_address" ]
                                                     dictionary:customDictionary
                                                        config:configMap];
  serverAddresses.nosUploadHost = [self stringValueForKeys:@[ @"nosUploadHost", @"nos_upload_host" ]
                                                dictionary:customDictionary
                                                   config:configMap];
  serverAddresses.module = [self stringValueForKeys:@[ @"module" ]
                                         dictionary:customDictionary
                                            config:configMap];
  [NIMSDK sharedSDK].serverSetting = serverAddresses;
}

+ (void)configTestServer {
  NIMServerSetting *serverAddresses = [[NIMServerSetting alloc] init];
  serverAddresses.lbsAddress = @"https://imtest-jd.netease.im/lbs/conf.jsp?k=fe416640c8e8a72734219e1847ad2547&sv=100300&pv=0&tp=4&networkType=0&lv=1";
  serverAddresses.linkAddress = @"59.111.241.213:8081";
  serverAddresses.module = @"00e3afe7487e6ac9ba69654672672ceddc05d5b6d45850859f11004d30c63e3691afd55722bdd2c75232b2a3561776201f84def8e38c508870ca7692b4228b0478e104460d7800dee3b6c3d8f89746ed48ee94f268f42b9c911437083d3815624e50de3fec3c0ec8ab3e71d5bdce3f4291d20538893cacdc00da9d1390ee39440d";
  [NIMSDK sharedSDK].serverSetting = serverAddresses;
}

+ (NSString *)getAppkey {
  return [[SettingRepo shared] getNodeValue] ? kDomesticAppKey : kOverseasAppKey;
}

+ (NSString *)apnsCername {
#if DEBUG
  return @"dev_im_uikit";
#else
  return @"dis_im_uikit";
#endif
}

+ (NSString *)pkCerName {
#if DEBUG
  return @"dev_im_voip";
#else
  return @"dis_im_voip";
#endif
}

+ (nullable NSString *)customAppkeyFromConfig:(IMPocConfigModel *)model {
  NSDictionary *customDictionary = [self parsedCustomConfig:model];
  NSDictionary *configMap = model.configMap ?: @{};
  return [self stringValueForKeys:@[ @"appkey", @"appKey" ]
                       dictionary:customDictionary
                          config:configMap];
}

@end
