// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunContactUserViewController.h"
#import "TextWithSwitchCell.h"
#import "CenterTextCell.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "FunUserInfoHeaderView.h"
#import "FunContactAliasViewController.h"
#import "FunContactUIColor.h"
#import "ContactConst.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation FunContactUserViewController

- (void)initFun {
  self.className = @"FunContactUserViewController";
  self.headerView = [[FunUserInfoHeaderView alloc] init];
}

- (instancetype)initWithAccountId:(NSString *)accountId {
  self = [super initWithAccountId:accountId];
  if (self) { [self initFun]; }
  return self;
}

- (instancetype)initWithNimUser:(V2NIMUser *)nimUser {
  self = [super initWithNimUser:nimUser];
  if (self) { [self initFun]; }
  return self;
}

- (instancetype)initWithUser:(NEUserWithFriend *)user {
  self = [super initWithUser:user];
  if (self) { [self initFun]; }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)commonUI {
  [super commonUI];
  self.tableView.rowHeight = 46;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UserItem *item = self.data[indexPath.section][indexPath.row];
  UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
  if ([cell isKindOfClass:[CenterTextCell class]] &&
      ([item.title isEqualToString:[self chatActionTitle]] || [item.title isEqualToString:contactLocalizable(@"add_friend")])) {
    CenterTextCell *c = (CenterTextCell *)cell;
    c.titleLabel.textColor = [UIColor funContactUserViewChatTitleTextColor];
    return c;
  }
  if ([cell isKindOfClass:[TextWithSwitchCell class]]) {
    TextWithSwitchCell *c = (TextWithSwitchCell *)cell;
    c.switchButton.onTintColor = [UIColor funContactThemeColor];
    return c;
  }
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  UserItem *item = self.data[indexPath.section][indexPath.row];
  if ([item.title isEqualToString:contactLocalizable(@"sign")]) {
    return 66;
  }
  return 46;
}

- (NEBaseContactAliasViewController *)getContactAliasViewController {
  return [[FunContactAliasViewController alloc] init];
}

- (void)deleteFriend:(NEUserWithFriend *)user {
  NECustomActionSheetController *sheet = [[NECustomActionSheetController alloc] init];
  sheet.cancelAction.contentText.text = commonLocalizable(@"cancel");
  sheet.cancelAction.contentText.accessibilityIdentifier = @"id.action3";

  NECustomAlertAction *deleteAction =
      [[NECustomAlertAction alloc] initWithTitle:contactLocalizable(@"delete_friend")
                                      completion:nil];
  deleteAction.contentText.textColor = [UIColor ne_redText];
  deleteAction.contentText.accessibilityIdentifier = @"id.action2";

  NSString *name = [user showName] ?: @"";
  NSString *deleteTitle =
      [NSString stringWithFormat:contactLocalizable(@"delete_title"), name];
  NECustomAlertAction *titleAction =
      [[NECustomAlertAction alloc] initWithTitle:deleteTitle completion:nil];
  titleAction.contentText.font = [UIFont systemFontOfSize:13];
  titleAction.contentText.textColor = [UIColor ne_colorWithHexString:@"#8F8F8F"];
  [self applyContactNameEmojiStyleToLabel:titleAction.contentText name:name];
  titleAction.contentText.accessibilityIdentifier = @"id.action1";

  __weak typeof(self) weakSelf = self;
  deleteAction.clickAction = ^{
    [weakSelf deleteFriendAction:user];
  };

  [sheet addAction:titleAction actionHeight:51];
  [sheet addAction:deleteAction actionHeight:51];
  [self presentViewController:sheet animated:YES completion:nil];
}

@end
