// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamMemberSelectController.h"
#import "FunTeamMemberSelectCell.h"
#import "FunTeamUIColor.h"

@implementation FunTeamMemberSelectController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.cellClassDic[@0] = FunTeamMemberSelectCell.class;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.navigationView.moreButton setTitleColor:UIColor.funTeamThemeColor forState:UIControlStateNormal];
  [self.emptyView setEmptyImageName:@"fun_user_empty"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  FunTeamMemberSelectCell *cell = [tableView dequeueReusableCellWithIdentifier:@"0" forIndexPath:indexPath];
  [cell configureMember:self.viewModel.showDatas[indexPath.row]];
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  (void)indexPath;
  return 64.0;
}

@end
