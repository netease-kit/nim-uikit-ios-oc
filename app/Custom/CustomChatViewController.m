// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomChatViewController.h"
#import <NEChatKitOC/ChatRepo.h>
#import <NEChatKitOC/NEChatDetectNetworkTool.h>
#import <NERtcCallKit/NECallEngineConsts.h>

static NSInteger NIMDemoCurrentCallStatus(void) {
  return [NECallEngine sharedInstance].callStatus;
}

static void NIMDemoSetupCallProvider(id<NERecordProvider> provider) {
  [[NECallEngine sharedInstance] setCallRecordProvider:provider];
}

static void NIMDemoSendCallRecord(NERecordConfig *config) {
  NSString *accId = config.accId;
  if (accId.length <= 0) {
    return;
  }

  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability] &&
      NIMDemoCurrentCallStatus() == 1) {
    return;
  }

  V2NIMMessage *message =
      [V2NIMMessageCreator createCallMessage:@""
                                       type:(int)config.callType
                                  channelId:@""
                                     status:(int)config.callState
                                  durations:@[]];
  NSString *conversationId = [V2NIMConversationIdUtil p2pConversationId:accId];
  if (conversationId.length <= 0) {
    return;
  }

  [[ChatRepo shared] sendMessage:message
                  conversationId:conversationId
                          params:nil
                      completion:^(__unused V2NIMSendMessageResult *result,
                                   NSError *error,
                                   __unused NSUInteger progress) {
                        if (error) {
                          NSLog(@"send call record error: %@", error.localizedDescription ?: @"");
                        }
                      }];
}

@implementation CustomNormalChatViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  NIMDemoSetupCallProvider(self);
}

- (void)onRecordSend:(NERecordConfig *)config {
  NIMDemoSendCallRecord(config);
}

@end

@implementation CustomFunChatViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  NIMDemoSetupCallProvider(self);
}

- (void)onRecordSend:(NERecordConfig *)config {
  NIMDemoSendCallRecord(config);
}

@end
