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
    <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSString *conversationId;
@property (nonatomic, strong) TeamMemberSelectVM *viewModel;
@property (nonatomic, strong, nullable) NETeamInfoModel *teamInfo;
@property (nonatomic, copy, nullable) DidSelectedAtRow selectedBlock;
@property (nonatomic, assign) BOOL isShowAtAll;

- (instancetype)initWithConversationId:(NSString *)conversationId showSelf:(BOOL)showSelf showTeamMembers:(BOOL)showTeamMembers;
- (void)commonUI;

@end

NS_ASSUME_NONNULL_END
