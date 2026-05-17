// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunHistoryMessageMemberController.h"

@implementation FunHistoryMessageMemberController

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super initWithConversationId:conversationId];
    if (self) {
        self.tag = @"FunHistoryMessageMemberController";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationView.hidden = NO;
}

- (void)setupSubviews {
    [super setupSubviews];
    self.searchTextField.hidden = YES;
    self.cancelButton.hidden = YES;
    self.tableViewTopAnchor.constant = 0;
    self.tableView.hidden = NO;
}

- (void)initialConfig {
    self.title = chatLocalizable(@"search_message_by_member");
}

@end
