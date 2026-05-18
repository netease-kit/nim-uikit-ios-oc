// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunSelectUserViewController.h"
#import "UIImage+Chat.h"
#import "FunChatTeamMemberCell.h"
#import "NEChatUIConstant.h"
#import "FunChatUIColor.h"

@implementation FunSelectUserViewController

- (instancetype)initWithConversationId:(NSString *)conversationId showSelf:(BOOL)showSelf showTeamMembers:(BOOL)showTeamMembers {
    self = [super initWithConversationId:conversationId showSelf:showSelf showTeamMembers:showTeamMembers];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[FunChatTeamMemberCell class] forCellReuseIdentifier:[FunChatTeamMemberCell description]];
}

- (void)commonUI {
    [super commonUI];

    [self.tableView registerClass:[FunChatTeamMemberCell class]
           forCellReuseIdentifier:NSStringFromClass([FunChatTeamMemberCell class])];
    self.tableView.rowHeight = 64;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FunChatTeamMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([FunChatTeamMemberCell class])
                                                                 forIndexPath:indexPath];
    if (indexPath.section == 0) {
        cell.headerView.image = [UIImage ne_imageNamed:@"fun_at_all"];
        cell.nameLabel.text = chatLocalizable(@"user_select_all");
    } else {
        if (indexPath.row < self.teamInfo.users.count) {
            NETeamMemberInfoModel *model = self.teamInfo.users[indexPath.row];
            [cell configure:model];
        }
    }
    return cell;
}

@end
