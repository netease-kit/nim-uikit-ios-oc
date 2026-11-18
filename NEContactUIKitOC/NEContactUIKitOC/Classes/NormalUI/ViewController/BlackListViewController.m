// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "BlackListViewController.h"

#import "BlackListCell.h"
#import "ContactSelectedViewController.h"
#import "ContactConst.h"
#import <NEChatKit/NEChatKit.h>

@implementation BlackListViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)commonUI {
  [super commonUI];
  self.navigationView.backgroundColor = [UIColor whiteColor];
  self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];

  [self.tableView registerClass:[BlackListCell class]
         forCellReuseIdentifier:NSStringFromClass([BlackListCell class])];
  self.tableView.rowHeight = 62;
}

/// 黑名单选择页面
- (NEBaseContactSelectedViewController *)getContactSelectVC {
  NSMutableSet<NSString *> *filterUsers = [NSMutableSet set];
  [filterUsers addObject:[IMKitClient.instance account]];
  return [[ContactSelectedViewController alloc] initWithFilterUsers:filterUsers];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  BlackListCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([BlackListCell class])
                                                        forIndexPath:indexPath];
  cell.delegate = self;
  cell.index = indexPath.row;
  [cell setModel:self.viewModel.blockList[indexPath.row]];
  return cell;
}

@end
