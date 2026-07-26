// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "HistoryMediaResultController.h"
#import "ForwardAlertViewController.h"
#import <NEChatKit/NEChatDetectNetworkTool.h>

@implementation HistoryMediaResultController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.emptyView.backgroundColor = UIColor.clearColor;
    [self.emptyView setEmptyImageName:@"emptyView"];
}

- (void)setupUI {
    [super setupUI];
}

- (void)showAction:(V2NIMMessage *)message {
    NSMutableArray<UIAlertAction *> *actions = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;

    UIAlertAction *findAction = [UIAlertAction actionWithTitle:chatLocalizable(@"search_result_find_in_chat") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf routerToMessage:message];
    }];
    [actions addObject:findAction];

    UIAlertAction *forwardAction = [UIAlertAction actionWithTitle:chatLocalizable(@"operation_forward") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
            [weakSelf showToast:commonLocalizable(@"network_error")];
            return;
        }
        [weakSelf forwardMessage:message];
    }];
    [actions addObject:forwardAction];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel") style:UIAlertActionStyleCancel handler:nil];
    [actions addObject:cancelAction];

    [self showActionSheet:actions];
}

- (NEBaseForwardAlertViewController *)getForwardAlertController {
    return [[ForwardAlertViewController alloc] init];
}

- (void)didClickMoreAction:(NEHistorySearchFileCell *)cell model:(MessageFileModel *)model {
    if (!model || !model.message) return;

    NSMutableArray<UIAlertAction *> *actions = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;

    UIAlertAction *forwardAction = [UIAlertAction actionWithTitle:chatLocalizable(@"operation_forward") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
            [weakSelf showToast:commonLocalizable(@"network_error")];
            return;
        }
        [weakSelf forwardMessage:model.message];
    }];
    [actions addObject:forwardAction];

    UIAlertAction *collectAction = [UIAlertAction actionWithTitle:chatLocalizable(@"operation_collection") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf toCollectMessage:model];
    }];
    [actions addObject:collectAction];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel") style:UIAlertActionStyleCancel handler:nil];
    [actions addObject:cancelAction];

    [self showActionSheet:actions];
}

@end
