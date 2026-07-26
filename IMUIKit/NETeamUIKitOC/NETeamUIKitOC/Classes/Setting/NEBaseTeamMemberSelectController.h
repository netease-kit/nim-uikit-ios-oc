// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamBaseViewController.h"
#import "TeamMemberSelectViewModel.h"
#import <NEChatKit/NETeamMemberInfoModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^NESelectTeamMemberBlock)(NSArray<NETeamMemberInfoModel *> *members);

@interface NEBaseTeamMemberSelectController : NETeamBaseViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, TeamMemberSelectViewModelDelegate>

@property (nonatomic, copy, nullable) NESelectTeamMemberBlock selectMemberBlock;
@property (nonatomic, assign) BOOL showAllMembers;
@property (nonatomic, strong, readonly) TeamMemberSelectViewModel *viewModel;
@property (nonatomic, copy, nullable) NSString *teamId;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, Class> *cellClassDic;
@property (nonatomic, strong, readonly) UITextField *searchInput;
@property (nonatomic, assign) NSInteger selectCountLimit;
@property (nonatomic, strong, readonly) UITableView *contentTableView;
@property (nonatomic, strong, readonly) UIView *searchBackView;
@property (nonatomic, strong, readonly) UIImageView *searchImageView;

- (void)didReloadTableData;
- (void)setupUI;
- (void)didChangeSelectMember;
- (void)didClickSure;

@end

NS_ASSUME_NONNULL_END
