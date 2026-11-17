// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEChatBaseViewController.h"
#import "TeamMemberSelectVM.h"
#import <NEChatKit/TeamInfoModel.h>
#import <NEChatKit/TeamMemberInfoModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^DidSelectedAtRow)(NSInteger index, NETeamMemberInfoModel *_Nullable model);

@interface NEBaseSelectUserViewController : NEChatBaseViewController
    <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSString *conversationId;
@property (nonatomic, strong) TeamMemberSelectVM *viewModel;
@property (nonatomic, strong, nullable) NETeamInfoModel *teamInfo;
@property (nonatomic, copy, nullable) DidSelectedAtRow selectedBlock;
@property (nonatomic, assign) BOOL isShowAtAll;
@property (nonatomic, strong) SearchTextField *searchTextField;
@property (nonatomic, copy) NSArray<NETeamMemberInfoModel *> *allMembers;
@property (nonatomic, copy) NSArray<NETeamMemberInfoModel *> *visibleMembers;
@property (nonatomic, copy) NSSet<NSString *> *aiAccountIds;
@property (nonatomic, copy) NSString *searchKeyword;
@property (nonatomic, assign, readonly) BOOL isSearching;
@property (nonatomic, assign, readonly) BOOL isLoadingMembers;
@property (nonatomic, strong, nullable, readonly) NSError *memberLoadError;

- (instancetype)initWithConversationId:(NSString *)conversationId showSelf:(BOOL)showSelf showTeamMembers:(BOOL)showTeamMembers;
- (void)commonUI;
- (void)applySearch;
- (nullable NETeamMemberSearchResult *)searchResultForMember:(NETeamMemberInfoModel *)member;
- (UIColor *)memberLoadStatusTintColor;

- (NSString *)searchIconName;
- (UIColor *)searchFieldBackgroundColor;
- (UIColor *)searchFieldTextColor;
- (UIFont *)searchFieldFont;
- (CGFloat)searchFieldCornerRadius;
- (CGFloat)searchFieldHorizontalInset;
- (CGFloat)searchFieldHeight;
- (NSString *)searchEmptyImageName;

@end

NS_ASSUME_NONNULL_END
