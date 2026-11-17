// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomConversationController.h"
#import "CustomConversationListCell.h"
#import <NEConversationUIKitOC/ConversationViewModel.h>
#import <NEConversationUIKitOC/NEConversationListModel.h>
#import <NEBaseUIKitOC/UIView+YXToast.h>

static NSString *const kCustomConversationCellReuseId = @"CustomConversationListCell";

@implementation CustomConversationController

- (instancetype)initWithDataSourceType:(NEConversationDataSourceType)type {
  self = [super initWithDataSourceType:type];
  if (self) {
    self.delegate = self;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.tableView registerClass:[CustomConversationListCell class]
         forCellReuseIdentifier:kCustomConversationCellReuseId];
}

- (UITableViewCell *)cellForRowAtModel:(NEConversationListModel *)model
                             indexPath:(NSIndexPath *)indexPath
                             tableView:(UITableView *)tableView {
  if (model.customType == 1) {
    CustomConversationListCell *cell =
        [tableView dequeueReusableCellWithIdentifier:kCustomConversationCellReuseId
                                        forIndexPath:indexPath];
    [cell configureData:model];
    return cell;
  }
  return [super cellForRowAtModel:model indexPath:indexPath tableView:tableView];
}

- (void)didClickAddBtn {
  [self.view ne_makeToast:@"CustomConversationController didClickAddBtn"];
}

- (void)searchAction {
  [self.view ne_makeToast:@"CustomConversationController searchAction"];
}

- (void)onDataLoaded {
  for (NEConversationListModel *model in self.viewModel.conversationListData) {
    model.customType = 1;
  }
  [self.tableView reloadData];
}

@end
