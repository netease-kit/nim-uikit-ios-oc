// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "NEBaseSelectUserViewController.h"
#import <NEBaseUIKitOC/SearchTextField.h>
#import "ChatNavigationView.h"
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NEChatKit.h>
#import <NEChatKit/ChatConstant.h>

#import "NEChatUIConstant.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/NEAIUserManager.h>

@interface NEBaseSelectUserViewController ()
@property (nonatomic, assign) BOOL showSelf;
@property (nonatomic, assign) BOOL showTeamMembers;
@property (nonatomic, assign, readwrite) BOOL isLoadingMembers;
@property (nonatomic, strong, nullable, readwrite) NSError *memberLoadError;
@property (nonatomic, strong) NSUUID *loadGeneration;
@property (nonatomic, copy) NSSet<NSString *> *searchableTeamMemberAccountIds;
@property (nonatomic, copy) NSArray<NSString *> *renderedAccountIds;
@property (nonatomic, copy, nullable) NSString *searchStartAccountId;
@property (nonatomic, assign) CGFloat searchStartRelativeY;
@property (nonatomic, assign) CGFloat searchStartContentOffsetX;
@end

@implementation NEBaseSelectUserViewController

- (instancetype)initWithConversationId:(NSString *)conversationId showSelf:(BOOL)showSelf showTeamMembers:(BOOL)showTeamMembers {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _conversationId = conversationId;
        _showSelf = showSelf;
        _showTeamMembers = showTeamMembers;
        _isShowAtAll = YES;
        _allMembers = @[];
        _visibleMembers = @[];
        _aiAccountIds = [NSSet set];
        _searchKeyword = @"";
        _loadGeneration = [NSUUID UUID];
        _searchableTeamMemberAccountIds = [NSSet set];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _conversationId = @"";
        _showSelf = YES;
        _showTeamMembers = NO;
        _allMembers = @[];
        _visibleMembers = @[];
        _aiAccountIds = [NSSet set];
        _searchKeyword = @"";
        _loadGeneration = [NSUUID UUID];
        _searchableTeamMemberAccountIds = [NSSet set];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"NEAdaptivePresentationDidChange" object:self];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"NEAdaptivePresentationDidChange" object:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.navigationView.hidden = YES;
    [self commonUI];
    [self loadData];
}

- (void)commonUI {
    self.view.backgroundColor = UIColor.whiteColor;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.accessibilityIdentifier = @"id.arrowDown";
    [button setImage:[UIImage ne_imageNamed:@"arrowDown"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(btnEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    [NSLayoutConstraint activateConstraints:@[
        [button.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [button.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [button.widthAnchor constraintEqualToConstant:50],
        [button.heightAnchor constraintEqualToConstant:50],
    ]];

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = chatLocalizable(@"user_select");
    label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.ne_darkText;
    [self.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:0],
        [label.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [label.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:0],
        [label.heightAnchor constraintEqualToConstant:50],
    ]];

    UIView *listTopView = label;
    CGFloat listTopSpacing = 0;

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.sectionHeaderHeight = 0;
    self.tableView.sectionFooterHeight = 0;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.estimatedRowHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0.0;
    }

    [self.view addSubview:self.tableView];
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.topAnchor constraintEqualToAnchor:listTopView.bottomAnchor constant:listTopSpacing],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];

    [self.emptyView setEmptyImageName:self.searchEmptyImageName];
    [self.emptyView setText:chatLocalizable(@"user_search_empty")];
    [self.view addSubview:self.emptyView];
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyView.leadingAnchor constraintEqualToAnchor:self.tableView.leadingAnchor],
        [self.emptyView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor],
        [self.emptyView.trailingAnchor constraintEqualToAnchor:self.tableView.trailingAnchor],
        [self.emptyView.bottomAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
    ]];
}

- (void)loadData {
    NSMutableArray<NETeamMemberInfoModel *> *aiUserMembers = [NSMutableArray array];
    if ([IMKitConfigCenter shared].enableAIUser) {
        NSArray *aiUsers = [[NEAIUserManager shared] getAIChatUserList];
        for (id user in aiUsers) {
            NETeamMemberInfoModel *teamMember = [[NETeamMemberInfoModel alloc] init];
            teamMember.nimUser = [[NEUserWithFriend alloc] initWithUser:user friend:nil];
            [aiUserMembers addObject:teamMember];
        }
    }
    NSMutableSet<NSString *> *aiAccountIds = [NSMutableSet set];
    for (NETeamMemberInfoModel *member in aiUserMembers) {
        NSString *accountId = member.teamMember.accountId ?: member.nimUser.user.accountId;
        if (accountId.length > 0) {
            [aiAccountIds addObject:accountId];
        }
    }
    self.aiAccountIds = aiAccountIds;

    if (!self.showTeamMembers) {
        NETeamInfoModel *team = [[NETeamInfoModel alloc] init];
        team.users = aiUserMembers;
        self.teamInfo = team;
        self.allMembers = aiUserMembers;
        self.visibleMembers = aiUserMembers;
        self.isShowAtAll = NO;
        [self reloadSearchResults];
        return;
    }

    if ([V2NIMConversationIdUtil conversationType:self.conversationId] != V2NIM_CONVERSATION_TYPE_TEAM) return;
    NSString *teamId = [V2NIMConversationIdUtil conversationTargetId:self.conversationId];
    if (!teamId) return;

    NSUUID *generation = [NSUUID UUID];
    self.loadGeneration = generation;
    self.isLoadingMembers = YES;
    self.memberLoadError = nil;
    if (self.allMembers.count == 0) {
        self.allMembers = [aiUserMembers copy];
        self.visibleMembers = [aiUserMembers copy];
    }
    [self reloadSearchResults];

    __weak typeof(self) weakSelf = self;
    [self.viewModel getTeamMembers:teamId
                         progress:^(NETeamMemberLoadProgress *progress) {
        if (![weakSelf.loadGeneration isEqual:generation] || ![progress.teamId isEqualToString:teamId]) {
            return;
        }
        weakSelf.isLoadingMembers = progress.phase == NETeamMemberLoadPhaseLoading;
        weakSelf.memberLoadError = progress.error;
        if (progress.phase == NETeamMemberLoadPhaseLoading || progress.phase == NETeamMemberLoadPhaseFinished) {
            [weakSelf applyLoadedMembers:progress.members
                                   team:[[NETeamUserManager shared] getTeamInfo]
                              aiMembers:aiUserMembers];
        } else {
            [weakSelf reloadSearchResults];
            if (progress.error) {
                [weakSelf.view ne_makeToast:progress.error.localizedDescription];
            }
        }
    }
                       completion:^(NSError * _Nullable error, NETeamInfoModel * _Nullable team) {
        if (![weakSelf.loadGeneration isEqual:generation]) {
            return;
        }
        if (error) {
            [weakSelf.view ne_makeToast:error.localizedDescription];
            return;
        }
        weakSelf.isLoadingMembers = NO;
        if (team) {
            weakSelf.memberLoadError = nil;
            [weakSelf applyLoadedMembers:team.users team:team.team aiMembers:aiUserMembers];
        } else {
            [weakSelf reloadSearchResults];
        }
    }];
}

- (void)applyLoadedMembers:(NSArray<NETeamMemberInfoModel *> *)members
                      team:(V2NIMTeam *)team
                 aiMembers:(NSArray<NETeamMemberInfoModel *> *)aiMembers {
    NSMutableArray<NETeamMemberInfoModel *> *filteredMembers = [NSMutableArray array];
    NSMutableDictionary<NSString *, NETeamMemberInfoModel *> *memberByAccountId = [NSMutableDictionary dictionary];
    for (NETeamMemberInfoModel *member in members ?: @[]) {
        NSString *accountId = member.teamMember.accountId ?: member.nimUser.user.accountId;
        if (accountId.length == 0) {
            continue;
        }
        if (!self.showSelf && [accountId isEqualToString:[[IMKitClient instance] account]]) {
            if (member.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_NORMAL) {
                NSDictionary *json = getDictionaryFromJSONString(team.serverExtension ?: @"");
                NSString *atValue = json[keyAllowAtAll];
                if ([atValue isEqualToString:allowAtManagerValue]) {
                    self.isShowAtAll = NO;
                }
            }
            continue;
        }
        memberByAccountId[accountId] = member;
        if ([self.aiAccountIds containsObject:accountId]) {
            continue;
        }
        [filteredMembers addObject:member];
    }

    self.searchableTeamMemberAccountIds = [NSSet setWithArray:memberByAccountId.allKeys];
    NSMutableArray<NETeamMemberInfoModel *> *displayAIMembers = [NSMutableArray array];
    for (NETeamMemberInfoModel *aiMember in aiMembers ?: @[]) {
        NSString *accountId = aiMember.nimUser.user.accountId;
        aiMember.teamMember = nil;
        aiMember.nimUser.friend = nil;
        if (accountId.length > 0) {
            NETeamMemberInfoModel *teamMember = memberByAccountId[accountId];
            if (teamMember) {
                aiMember.teamMember = teamMember.teamMember;
                aiMember.nimUser.friend = teamMember.nimUser.friend;
            }
        }
        [displayAIMembers addObject:aiMember];
    }

    NETeamInfoModel *snapshot = [[NETeamInfoModel alloc] init];
    snapshot.team = team;
    NSMutableArray<NETeamMemberInfoModel *> *allUsers = [NSMutableArray arrayWithArray:displayAIMembers];
    [allUsers addObjectsFromArray:filteredMembers];
    snapshot.users = allUsers;
    self.teamInfo = snapshot;
    self.allMembers = [allUsers copy];
    [self applySearch];
}

- (void)searchTextChanged:(SearchTextField *)textField {
    NSString *nextKeyword = textField.text ?: @"";
    NSString *previousKeyword = [self.searchKeyword stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    BOOL wasSearching = [self isSearching];
    NSString *normalizedKeyword = [nextKeyword stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!wasSearching && normalizedKeyword.length > 0) {
        [self captureSearchStartPosition];
    }
    self.searchKeyword = nextKeyword;
    [self applySearch];
    if (normalizedKeyword.length > 0 && ![previousKeyword isEqualToString:normalizedKeyword]) {
        [self scrollSearchResultsToTop];
    }
}

- (void)applySearch {
    NSString *normalizedKeyword = [self.searchKeyword stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    self.searchTextField.clearButtonMode = normalizedKeyword.length == 0 ? UITextFieldViewModeNever : UITextFieldViewModeWhileEditing;
    if (normalizedKeyword.length == 0) {
        self.visibleMembers = self.allMembers;
        [self reloadSearchResults];
        [self restoreSearchStartPositionIfNeeded];
        return;
    }

    NSMutableArray<NETeamMemberInfoModel *> *matches = [NSMutableArray array];
    for (NETeamMemberInfoModel *member in self.allMembers) {
        NSString *accountId = member.teamMember.accountId ?: member.nimUser.user.accountId;
        if (accountId.length == 0 ||
            ([self.aiAccountIds containsObject:accountId] &&
             ![self.searchableTeamMemberAccountIds containsObject:accountId])) {
            continue;
        }
        if ([NETeamMemberSearchMatcher matchesKeyword:normalizedKeyword
                                              teamNick:member.teamMember.teamNick
                                           friendAlias:member.nimUser.friend.alias
                                          userNickname:member.nimUser.user.name
                                             accountId:accountId]) {
            [matches addObject:member];
        }
    }
    self.visibleMembers = matches;
    [self reloadSearchResults];
}

- (NETeamMemberSearchResult *)searchResultForMember:(NETeamMemberInfoModel *)member {
    if (!self.isSearching) {
        return nil;
    }
    NSString *accountId = member.nimUser.user.accountId ?: member.teamMember.accountId;
    return [NETeamMemberSearchMatcher resultWithKeyword:self.searchKeyword
                                               teamNick:member.teamMember.teamNick
                                            friendAlias:member.nimUser.friend.alias
                                           userNickname:member.nimUser.user.name
                                              accountId:accountId];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    self.searchKeyword = @"";
    [self applySearch];
    [textField resignFirstResponder];
    return YES;
}

- (void)reloadSearchResults {
    [self reloadPreservingTopMember];
    [self updateMemberLoadStatus];
    self.emptyView.hidden = !self.isSearching || self.visibleMembers.count > 0 || self.isLoadingMembers || self.memberLoadError != nil;
}

- (void)scrollSearchResultsToTop {
    [self.tableView layoutIfNeeded];
    CGPoint contentOffset = self.tableView.contentOffset;
    contentOffset.y = -self.tableView.adjustedContentInset.top;
    [self.tableView setContentOffset:contentOffset animated:NO];
}

- (void)reloadPreservingTopMember {
    NSArray<NSIndexPath *> *visible = [self.tableView.indexPathsForVisibleRows sortedArrayUsingSelector:@selector(compare:)];
    NSIndexPath *topIndexPath = nil;
    for (NSIndexPath *indexPath in visible) {
        if (indexPath.section == 1) {
            topIndexPath = indexPath;
            break;
        }
    }
    NSString *anchorAccountId = nil;
    CGFloat relativeY = 0;
    if (topIndexPath && topIndexPath.row < self.renderedAccountIds.count) {
        anchorAccountId = self.renderedAccountIds[topIndexPath.row];
        relativeY = [self.tableView rectForRowAtIndexPath:topIndexPath].origin.y - self.tableView.contentOffset.y;
    }
    NSMutableArray<NSString *> *nextRenderedAccountIds = [NSMutableArray array];
    for (NETeamMemberInfoModel *model in self.visibleMembers) {
        [nextRenderedAccountIds addObject:model.teamMember.accountId ?: model.nimUser.user.accountId ?: @""];
    }

    [UIView performWithoutAnimation:^{
        [self.tableView reloadData];
        [self.tableView layoutIfNeeded];
    }];
    self.renderedAccountIds = [nextRenderedAccountIds copy];
    if (anchorAccountId.length == 0) {
        return;
    }
    __block NSInteger row = NSNotFound;
    [self.visibleMembers enumerateObjectsUsingBlock:^(NETeamMemberInfoModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *accountId = model.teamMember.accountId ?: model.nimUser.user.accountId;
        if ([accountId isEqualToString:anchorAccountId]) {
            row = (NSInteger)idx;
            *stop = YES;
        }
    }];
    if (row == NSNotFound) {
        return;
    }
    CGRect rect = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:1]];
    CGFloat minimumY = -self.tableView.adjustedContentInset.top;
    CGFloat maximumY = MAX(minimumY,
                           self.tableView.contentSize.height - self.tableView.bounds.size.height + self.tableView.adjustedContentInset.bottom);
    CGFloat targetY = MIN(MAX(CGRectGetMinY(rect) - relativeY, minimumY), maximumY);
    [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, targetY) animated:NO];
}

- (void)captureSearchStartPosition {
    NSArray<NSIndexPath *> *visible = [self.tableView.indexPathsForVisibleRows sortedArrayUsingSelector:@selector(compare:)];
    NSIndexPath *topIndexPath = nil;
    for (NSIndexPath *indexPath in visible) {
        if (indexPath.section == 1) {
            topIndexPath = indexPath;
            break;
        }
    }
    if (!topIndexPath || topIndexPath.row >= self.renderedAccountIds.count) {
        return;
    }
    NSString *accountId = self.renderedAccountIds[topIndexPath.row];
    if (accountId.length == 0) {
        return;
    }
    self.searchStartAccountId = accountId;
    self.searchStartRelativeY = [self.tableView rectForRowAtIndexPath:topIndexPath].origin.y - self.tableView.contentOffset.y;
    self.searchStartContentOffsetX = self.tableView.contentOffset.x;
}

- (void)restoreSearchStartPositionIfNeeded {
    NSString *accountId = self.searchStartAccountId;
    self.searchStartAccountId = nil;
    if (accountId.length == 0) {
        return;
    }
    __block NSInteger row = NSNotFound;
    [self.visibleMembers enumerateObjectsUsingBlock:^(NETeamMemberInfoModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *modelAccountId = model.teamMember.accountId ?: model.nimUser.user.accountId;
        if ([modelAccountId isEqualToString:accountId]) {
            row = (NSInteger)idx;
            *stop = YES;
        }
    }];
    if (row == NSNotFound) {
        return;
    }
    CGRect rect = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:1]];
    CGFloat minimumY = -self.tableView.adjustedContentInset.top;
    CGFloat maximumY = MAX(minimumY,
                           self.tableView.contentSize.height - self.tableView.bounds.size.height + self.tableView.adjustedContentInset.bottom);
    CGFloat targetY = MIN(MAX(CGRectGetMinY(rect) - self.searchStartRelativeY, minimumY), maximumY);
    [self.tableView setContentOffset:CGPointMake(self.searchStartContentOffsetX, targetY) animated:NO];
}

- (void)updateMemberLoadStatus {
    if (!self.showTeamMembers) {
        self.tableView.tableFooterView = [[UIView alloc] init];
        return;
    }
    CGFloat width = self.tableView.bounds.size.width;
    if (self.isLoadingMembers) {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 44)];
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        indicator.color = [self memberLoadStatusTintColor];
        indicator.center = CGPointMake(CGRectGetMidX(footer.bounds), CGRectGetMidY(footer.bounds));
        indicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [indicator startAnimating];
        [footer addSubview:indicator];
        self.tableView.tableFooterView = footer;
    } else if (self.memberLoadError) {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 52)];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = footer.bounds;
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        button.tintColor = [self memberLoadStatusTintColor];
        [button setTitleColor:[self memberLoadStatusTintColor] forState:UIControlStateNormal];
        [button setImage:[UIImage systemImageNamed:@"arrow.clockwise"] forState:UIControlStateNormal];
        [button setTitle:self.memberLoadError.localizedDescription forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:14];
        button.titleLabel.numberOfLines = 2;
        [button addTarget:self action:@selector(retryMemberLoad) forControlEvents:UIControlEventTouchUpInside];
        [footer addSubview:button];
        self.tableView.tableFooterView = footer;
    } else {
        self.tableView.tableFooterView = [[UIView alloc] init];
    }
}

- (void)retryMemberLoad {
    [self loadData];
}

- (BOOL)isSearching {
    NSString *normalizedKeyword = [self.searchKeyword stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return normalizedKeyword.length > 0;
}

- (UIColor *)memberLoadStatusTintColor {
    return UIColor.ne_defaultPrimaryColor;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.isShowAtAll && !self.isSearching ? 1 : 0;
    }
    return self.visibleMembers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[UITableViewCell alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (self.selectedBlock) {
            self.selectedBlock(indexPath.row, nil);
        }
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    if (indexPath.row >= self.visibleMembers.count) {
        return;
    }
    if (self.selectedBlock) {
        self.selectedBlock(indexPath.row, self.visibleMembers[indexPath.row]);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)btnEvent:(UIButton *)button {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Lazy Properties

- (NSString *)searchIconName {
    return @"textField_search_icon";
}

- (UIColor *)searchFieldBackgroundColor {
    return [UIColor ne_colorWithHexString:@"#F2F4F5"];
}

- (UIColor *)searchFieldTextColor {
    return UIColor.ne_darkText;
}

- (UIFont *)searchFieldFont {
    return [UIFont systemFontOfSize:14];
}

- (CGFloat)searchFieldCornerRadius {
    return 4;
}

- (CGFloat)searchFieldHorizontalInset {
    return 20;
}

- (CGFloat)searchFieldHeight {
    return 32;
}

- (NSString *)searchEmptyImageName {
    return @"user_empty";
}

- (SearchTextField *)searchTextField {
    if (!_searchTextField) {
        _searchTextField = [[NESingleLineSearchTextField alloc] init];
        _searchTextField.translatesAutoresizingMaskIntoConstraints = NO;
        _searchTextField.leftView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:self.searchIconName]];
        _searchTextField.leftViewMode = UITextFieldViewModeAlways;
        _searchTextField.placeholder = chatLocalizable(@"user_search_placeholder");
        _searchTextField.font = self.searchFieldFont;
        _searchTextField.textColor = self.searchFieldTextColor;
        _searchTextField.backgroundColor = self.searchFieldBackgroundColor;
        _searchTextField.layer.cornerRadius = self.searchFieldCornerRadius;
        _searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _searchTextField.returnKeyType = UIReturnKeySearch;
        _searchTextField.delegate = self;
        _searchTextField.accessibilityIdentifier = @"id.search";
        [_searchTextField addTarget:self action:@selector(searchTextChanged:) forControlEvents:UIControlEventEditingChanged];
        UIButton *clearButton = [_searchTextField valueForKey:@"_clearButton"];
        if ([clearButton isKindOfClass:[UIButton class]]) {
            clearButton.accessibilityIdentifier = @"id.clear";
        }
    }
    return _searchTextField;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    }
    return _tableView;
}

- (TeamMemberSelectVM *)viewModel {
    if (!_viewModel) {
        _viewModel = [[TeamMemberSelectVM alloc] init];
    }
    return _viewModel;
}

@end
