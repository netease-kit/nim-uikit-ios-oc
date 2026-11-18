// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamMemberSelectController.h"
#import "TeamMemberSelectCell.h"
#import "NormalTeamUIColor.h"

@implementation TeamMemberSelectController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.cellClassDic[@0] = TeamMemberSelectCell.class;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationView.backgroundColor = UIColor.whiteColor;
  [self.navigationView.moreButton setTitleColor:UIColor.normalTeamBlueColor forState:UIControlStateNormal];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  TeamMemberSelectCell *cell = [tableView dequeueReusableCellWithIdentifier:@"0" forIndexPath:indexPath];
  NESelectTeamMember *member = self.viewModel.showDatas[indexPath.row];
  [cell configureMember:member searchResult:[self.viewModel currentSearchResultForSelectModel:member]];
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  (void)indexPath;
  return 52.0;
}

@end
