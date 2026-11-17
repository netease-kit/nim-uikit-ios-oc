// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunBotSubSessionListViewController.h"

#import "FunBotSubSessionChatViewController.h"
#import "FunUserSettingViewController.h"
#import "TopicChatViewModel.h"
#import <NEChatKit/NEChatDetectNetworkTool.h>

@implementation FunBotSubSessionListViewController

- (instancetype)initWithConversationId:(NSString *)conversationId
                              sessionId:(NSString *)sessionId
                            sessionName:(NSString *)sessionName {
  self = [super initWithConversationId:conversationId sessionId:sessionId sessionName:sessionName];
  if (self) {
    self.deleteButtonBackgroundColor = [UIColor ne_colorWithHexString:@"#E75E58"];
    self.renameButtonBackgroundColor = [UIColor ne_colorWithHexString:@"#337EFF"];
  }
  return self;
}

- (UIColor *)pageBackgroundColor { return UIColor.funChatBackgroundColor; }
- (UIColor *)listItemBackgroundColor { return UIColor.whiteColor; }
- (BOOL)showsListItemDivider { return YES; }
- (UIColor *)emptyActionTitleColor { return UIColor.funChatThemeColor; }
- (NSString *)defaultEmptyImageName { return @"fun_user_empty"; }
- (UIColor *)emptyActionBackgroundColor { return UIColor.whiteColor; }
- (UIColor *)searchHighlightColor { return UIColor.funChatThemeColor; }
- (NSString *)searchEmptyImageName { return @"fun_emptyView"; }

- (void)setupUI {
  [super setupUI];
  self.view.backgroundColor = self.pageBackgroundColor;
  [self applyFunBotSubSessionListBackground];
  self.tableView.backgroundColor = self.pageBackgroundColor;
  self.tableView.rowHeight = 64;
  self.tableViewTopAnchor.constant = self.listTopSpacing;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self applyFunBotSubSessionListBackground];
  self.tableViewTopAnchor.constant = self.listTopSpacing;
}

- (void)applyFunBotSubSessionListBackground {
  self.navigationView.backgroundColor = self.pageBackgroundColor;
  self.navigationView.titleBarBottomLine.backgroundColor = UIColor.funChatNavigationDivideBg;
  self.navigationController.navigationBar.backgroundColor = self.pageBackgroundColor;
  if (@available(iOS 13.0, *)) {
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = self.pageBackgroundColor;
    appearance.shadowColor = UIColor.funChatNavigationDivideBg;
    self.navigationController.navigationBar.standardAppearance = appearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
  }
}

- (void)enterTopic:(V2NIMTopic *)topic {
  FunBotSubSessionChatViewController *controller = [[FunBotSubSessionChatViewController alloc]
    initWithConversationId:self.conversationId sessionId:self.sessionId
    sessionName:self.sessionName topic:topic];
  controller.topicChatViewModel.delegate = controller;
  [self.navigationController pushViewController:controller animated:YES];
}

- (NSString *)displayNameForTopic:(V2NIMTopic *)topic {
  NSString *name = [topic.topicName ?: @"" stringByTrimmingCharactersInSet:
                    NSCharacterSet.whitespaceAndNewlineCharacterSet];
  return name.length > 0 ? name : chatLocalizable(@"bot_sub_session_new_conversation");
}

- (void)showRenameAlertWithTopic:(V2NIMTopic *)topic {
  BotSubSessionRenameDialogController *controller = [[BotSubSessionRenameDialogController alloc]
    initWithName:[self displayNameForTopic:topic]
    saveButtonBackgroundColor:[UIColor ne_colorWithHexString:@"#58BE6B"]];
  __weak typeof(self) weakSelf = self;
  __weak typeof(controller) weakController = controller;
  controller.onSave = ^(NSString *name) {
    if (name.length == 0) {
      [weakSelf.view ne_makeToast:chatLocalizable(@"bot_sub_session_input_name")];
      return;
    }
    if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
      [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
      return;
    }
    [weakSelf.viewModel updateTopicNameWithTopic:topic topicName:name
                                                :^(V2NIMTopic *updated, NSError *error) {
      if (error) [weakSelf.view ne_makeToast:chatLocalizable(@"bot_sub_session_rename_failed")];
      else [weakController dismissViewControllerAnimated:NO completion:nil];
    }];
  };
  [self presentViewController:controller animated:NO completion:nil];
}

- (void)showDeleteAlertWithTopic:(V2NIMTopic *)topic {
  NSString *message = [NSString stringWithFormat:chatLocalizable(@"bot_sub_session_delete_topic"),
                       [self displayNameForTopic:topic]];
  BotSubSessionDeleteDialogController *controller = [[BotSubSessionDeleteDialogController alloc]
    initWithTitle:chatLocalizable(@"bot_sub_session_delete_title") message:message
    confirmButtonBackgroundColor:[UIColor ne_colorWithHexString:@"#58BE6B"]];
  __weak typeof(self) weakSelf = self;
  __weak typeof(controller) weakController = controller;
  controller.onDelete = ^{
    [weakController dismissViewControllerAnimated:NO completion:nil];
    [weakSelf.viewModel removeTopicWithTopic:topic :^(NSError *error) {
      if (error) [weakSelf.view ne_makeToast:chatLocalizable(@"bot_sub_session_delete_failed")];
    }];
  };
  [self presentViewController:controller animated:NO completion:nil];
}

- (NEBaseUserSettingViewController *)getUserSettingViewController {
  return [[FunUserSettingViewController alloc] initWithUserId:self.sessionId];
}

@end
