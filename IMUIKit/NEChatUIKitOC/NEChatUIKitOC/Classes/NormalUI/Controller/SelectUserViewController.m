// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "SelectUserViewController.h"
#import "UIImage+Chat.h"
#import "NEChatUIConstant.h"
#import "ChatTeamMemberCell.h"

@implementation SelectUserViewController

- (instancetype)initWithConversationId:(NSString *)conversationId showSelf:(BOOL)showSelf showTeamMembers:(BOOL)showTeamMembers {
    self = [super initWithConversationId:conversationId showSelf:showSelf showTeamMembers:showTeamMembers];
    if (self) {
        // className not applicable in OC
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)commonUI {
    [super commonUI];
    [self.tableView registerClass:[ChatTeamMemberCell class] forCellReuseIdentifier:NSStringFromClass([ChatTeamMemberCell class])];
    self.tableView.rowHeight = 62;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatTeamMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ChatTeamMemberCell class]) forIndexPath:indexPath];
    if (indexPath.section == 0) {
        cell.headerView.image = [UIImage ne_imageNamed:@"chat_at_all"];
        cell.nameLabel.text = chatLocalizable(@"user_select_all");
    } else {
        if (indexPath.row < self.teamInfo.users.count) {
            [cell configure:self.teamInfo.users[indexPath.row]];
        }
    }
    return cell;
}

@end
