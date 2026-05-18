// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AddApplicationViewController.h"
#import "SystemNotificationCell.h"

@implementation AddApplicationViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)setupUI {
  [super setupUI];
  self.navigationView.backgroundColor = [UIColor whiteColor];
  self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];

  [self.tableView registerClass:[SystemNotificationCell class]
         forCellReuseIdentifier:NSStringFromClass([SystemNotificationCell class])];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  id noti = self.viewModel.friendAddApplications[indexPath.row];
  NSString *reuseIdentifier = NSStringFromClass([SystemNotificationCell class]);
  SystemNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier
                                                                 forIndexPath:indexPath];
  cell.delegate = self;
  [cell configeWithApplication:noti];
  return cell;
}

@end
