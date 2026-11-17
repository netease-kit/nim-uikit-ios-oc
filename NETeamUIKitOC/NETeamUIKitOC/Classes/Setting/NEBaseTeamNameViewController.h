// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamBaseViewController.h"
#import "NEBaseTeamSettingCell.h"

NS_ASSUME_NONNULL_BEGIN

@class TeamNameViewModel;
@class TeamRepo;
@class V2NIMTeam;
@class V2NIMTeamMember;

@interface NEBaseTeamNameViewController : NETeamBaseViewController <UITextViewDelegate>

@property (nonatomic, strong, nullable) V2NIMTeam *team;
@property (nonatomic, assign) ChangeType type;
@property (nonatomic, strong, nullable) V2NIMTeamMember *teamMember;
@property (nonatomic, strong) TeamRepo *repo;
@property (nonatomic, assign) NSInteger textLimit;
@property (nonatomic, strong, readonly) UIView *backView;
@property (nonatomic, strong, readonly) TeamNameViewModel *viewModel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UITextView *textInputView;
@property (nonatomic, strong) UIButton *clearButton;

- (void)setupUI;
- (void)configData;
- (BOOL)getEditablePermission;
- (void)disableSubmit;
- (void)enableSubmit;
- (void)saveName;
- (void)clearText;
- (void)figureTextCount:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
