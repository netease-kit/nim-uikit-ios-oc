// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "HistoryMessageMemberController.h"

@implementation HistoryMessageMemberController

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super initWithConversationId:conversationId];
    if (self) {
        self.tag = @"HistoryMessageMemberController";
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)setupSubviews {
    [super setupSubviews];
    self.searchTextField.hidden = YES;
    self.tipLable.hidden = YES;
    self.collectionView.hidden = YES;
    self.tableViewTopAnchor.constant = 0;
    self.tableView.hidden = NO;
}

- (void)initialConfig {
    self.title = chatLocalizable(@"search_message_by_member");
}

@end
