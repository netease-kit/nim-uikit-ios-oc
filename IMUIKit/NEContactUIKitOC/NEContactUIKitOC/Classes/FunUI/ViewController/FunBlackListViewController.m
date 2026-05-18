// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunBlackListViewController.h"
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import "FunBlackListCell.h"
#import "FunContactSelectedViewController.h"
#import "ContactConst.h"

@implementation FunBlackListViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)commonUI {
  [super commonUI];
  [self.tableView registerClass:[FunBlackListCell class]
         forCellReuseIdentifier:NSStringFromClass([FunBlackListCell class])];
  self.tableView.rowHeight = 64;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  FunBlackListCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([FunBlackListCell class])
                                                          forIndexPath:indexPath];
  cell.delegate = self;
  cell.index = indexPath.row;
  [cell setModel:self.viewModel.blockList[indexPath.row]];
  return cell;
}

/// 黑名单选择页面
- (NEBaseContactSelectedViewController *)getContactSelectVC {
  NSMutableSet<NSString *> *filterUsers = [NSMutableSet set];
  [filterUsers addObject:[IMKitClient.instance account]];
  return [[FunContactSelectedViewController alloc] initWithFilterUsers:filterUsers];
}

@end
