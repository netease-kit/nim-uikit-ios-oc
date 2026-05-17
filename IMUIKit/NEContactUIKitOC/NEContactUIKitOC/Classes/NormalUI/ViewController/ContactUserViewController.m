// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactUserViewController.h"
#import "UserInfoHeaderView.h"
#import "ContactAliasViewController.h"

@implementation ContactUserViewController

- (void)initNormal {
  self.className = @"ContactUserViewController";
  self.headerView = [[UserInfoHeaderView alloc] init];
}

- (instancetype)initWithAccountId:(NSString *)accountId {
  self = [super initWithAccountId:accountId];
  if (self) {
    [self initNormal];
  }
  return self;
}

- (instancetype)initWithNimUser:(V2NIMUser *)nimUser {
  self = [super initWithNimUser:nimUser];
  if (self) {
    [self initNormal];
  }
  return self;
}

- (instancetype)initWithUser:(NEUserWithFriend *)user {
  self = [super initWithUser:user];
  if (self) {
    [self initNormal];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)commonUI {
  [super commonUI];
  self.tableView.rowHeight = 62;
}

- (NEBaseContactAliasViewController *)getContactAliasViewController {
  return [[ContactAliasViewController alloc] init];
}

@end
