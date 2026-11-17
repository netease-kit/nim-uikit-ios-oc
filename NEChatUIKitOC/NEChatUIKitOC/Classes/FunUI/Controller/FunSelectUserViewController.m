// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunSelectUserViewController.h"
#import "UIImage+Chat.h"
#import "FunChatTeamMemberCell.h"
#import "NEChatUIConstant.h"
#import "FunChatUIColor.h"

@implementation FunSelectUserViewController

- (NSString *)searchIconName { return @"textField_search_icon"; }
- (UIColor *)searchFieldBackgroundColor { return [UIColor ne_colorWithHexString:@"#F2F4F5"]; }
- (UIColor *)searchFieldTextColor { return UIColor.ne_darkText; }
- (UIFont *)searchFieldFont { return [UIFont systemFontOfSize:14]; }
- (CGFloat)searchFieldCornerRadius { return 4; }
- (CGFloat)searchFieldHorizontalInset { return 20; }
- (CGFloat)searchFieldHeight { return 32; }
- (NSString *)searchEmptyImageName { return @"fun_user_empty"; }
- (UIColor *)memberLoadStatusTintColor { return UIColor.ne_funTheme; }

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
        [cell configureAllWithTitle:chatLocalizable(@"user_select_all")
                              image:[UIImage ne_imageNamed:@"fun_at_all"]];
    } else {
        if (indexPath.row < self.visibleMembers.count) {
            NETeamMemberInfoModel *model = self.visibleMembers[indexPath.row];
            [cell configure:model searchResult:[self searchResultForMember:model]];
        }
    }
    return cell;
}

@end
