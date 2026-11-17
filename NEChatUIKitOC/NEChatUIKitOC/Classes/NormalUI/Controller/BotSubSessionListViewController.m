// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "BotSubSessionListViewController.h"

#import "BotSubSessionChatViewController.h"
#import "TopicChatViewModel.h"
#import "UserSettingViewController.h"

@implementation BotSubSessionListViewController

- (instancetype)initWithConversationId:(NSString *)conversationId
                              sessionId:(NSString *)sessionId
                            sessionName:(NSString *)sessionName {
  self = [super initWithConversationId:conversationId sessionId:sessionId sessionName:sessionName];
  if (self) {
    self.deleteButtonBackgroundColor = [UIColor ne_colorWithHexString:@"#A8ABB6"];
    self.renameButtonBackgroundColor = [UIColor ne_colorWithHexString:@"#337EFF"];
  }
  return self;
}

- (void)setupUI {
  [super setupUI];
  self.navigationView.backgroundColor = UIColor.whiteColor;
  self.navigationController.navigationBar.backgroundColor = UIColor.whiteColor;
  self.tableView.backgroundColor = UIColor.whiteColor;
}

- (NSString *)defaultEmptyImageName { return @"user_empty"; }

- (void)enterTopic:(V2NIMTopic *)topic {
  BotSubSessionChatViewController *controller = [[BotSubSessionChatViewController alloc]
    initWithConversationId:self.conversationId sessionId:self.sessionId
    sessionName:self.sessionName topic:topic];
  controller.topicChatViewModel.delegate = controller;
  [self.navigationController pushViewController:controller animated:YES];
}

- (NEBaseUserSettingViewController *)getUserSettingViewController {
  return [[UserSettingViewController alloc] initWithUserId:self.sessionId];
}

@end
