// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamJoinActionViewController.h"
#import "FunSystemNotificationCell.h"

@implementation FunTeamJoinActionViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)setupUI {
  [super setupUI];

  [self.tableView registerClass:[FunSystemNotificationCell class]
         forCellReuseIdentifier:NSStringFromClass([FunSystemNotificationCell class])];
  [self.emptyView setEmptyImageName:@"fun_user_empty"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  id noti = self.viewModel.teamJoinActions[indexPath.row];
  NSString *reuseIdentifier = NSStringFromClass([FunSystemNotificationCell class]);
  FunSystemNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier
                                                                    forIndexPath:indexPath];
  cell.delegate = self;
  [cell configeWithTeamJoinAction:noti];
  return cell;
}

@end
