// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "SelectUserViewController.h"
#import "UIImage+Chat.h"
#import "NEChatUIConstant.h"
#import "ChatTeamMemberCell.h"
#import <NEChatKit/UIColor+NECommon.h>

@implementation SelectUserViewController

- (NSString *)searchIconName { return @"textField_search_icon"; }
- (UIColor *)searchFieldBackgroundColor { return [UIColor ne_colorWithHexString:@"#F2F4F5"]; }
- (UIColor *)searchFieldTextColor { return UIColor.ne_darkText; }
- (UIFont *)searchFieldFont { return [UIFont systemFontOfSize:14]; }
- (CGFloat)searchFieldCornerRadius { return 4; }
- (CGFloat)searchFieldHorizontalInset { return 20; }
- (CGFloat)searchFieldHeight { return 32; }
- (NSString *)searchEmptyImageName { return @"user_empty"; }

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
        [cell configureAllWithTitle:chatLocalizable(@"user_select_all")
                              image:[UIImage ne_imageNamed:@"chat_at_all"]];
    } else {
        if (indexPath.row < self.visibleMembers.count) {
            NETeamMemberInfoModel *member = self.visibleMembers[indexPath.row];
            [cell configure:member searchResult:[self searchResultForMember:member]];
        }
    }
    return cell;
}

@end
