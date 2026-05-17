// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunHistoryMediaResultController.h"
#import "FunForwardAlertViewController.h"
#import <NEChatKitOC/NEChatDetectNetworkTool.h>

@implementation FunHistoryMediaResultController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.emptyView.backgroundColor = [UIColor clearColor];
    [self.emptyView setEmptyImageWithName:@"fun_emptyView"];
}

- (void)showAction:(V2NIMMessage *)message {
    NSMutableArray<NECustomAlertAction *> *actions = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;

    NECustomAlertAction *findAction = [NECustomAlertAction actionWithTitle:chatLocalizable(@"search_result_find_in_chat") handler:^{
        [weakSelf routerToMessage:message];
    }];
    [actions addObject:findAction];

    NECustomAlertAction *forwardAction = [NECustomAlertAction actionWithTitle:chatLocalizable(@"operation_forward") handler:^{
        if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
            [weakSelf showToast:commonLocalizable(@"network_error")];
            return;
        }
        [weakSelf forwardMessage:message];
    }];
    [actions addObject:forwardAction];

    [self showCustomActionSheet:actions];
}

- (NEBaseForwardAlertViewController *)getForwardAlertController {
    return [[FunForwardAlertViewController alloc] init];
}

- (void)didClickMoreAction:(NEHistorySearchFileCell *)cell model:(MessageFileModel *)model {
    if (!model || !model.message) return;

    NSMutableArray<NECustomAlertAction *> *actions = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;

    NECustomAlertAction *forwardAction = [NECustomAlertAction actionWithTitle:chatLocalizable(@"operation_forward") handler:^{
        if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
            [weakSelf showToast:commonLocalizable(@"network_error")];
            return;
        }
        [weakSelf forwardMessage:model.message];
    }];
    [actions addObject:forwardAction];

    NECustomAlertAction *collectAction = [NECustomAlertAction actionWithTitle:chatLocalizable(@"operation_collection") handler:^{
        [weakSelf toCollectMessage:model];
    }];
    [actions addObject:collectAction];

    [self showCustomActionSheet:actions];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NEHistorySearchFileCell *cell = (NEHistorySearchFileCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.avatarImageView.layer.cornerRadius = 4;
    return cell;
}

- (void)setupUI {
    [super setupUI];
}

@end
