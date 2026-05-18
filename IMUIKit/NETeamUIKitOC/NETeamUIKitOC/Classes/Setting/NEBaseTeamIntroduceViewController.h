// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class TeamIntroduceViewModel;
@class V2NIMTeam;

@interface NEBaseTeamIntroduceViewController : NETeamBaseViewController <UITextViewDelegate>

@property (nonatomic, strong, nullable) V2NIMTeam *team;
@property (nonatomic, assign, readonly) NSInteger textLimit;
@property (nonatomic, strong, readonly) UIView *backView;
@property (nonatomic, strong, readonly) TeamIntroduceViewModel *viewModel;
@property (nonatomic, strong, readonly) UITextView *textView;
@property (nonatomic, strong, readonly) UIButton *clearButton;
@property (nonatomic, strong, readonly) UILabel *countLabel;

- (void)setupUI;
- (BOOL)getPermission;
- (void)saveIntr;
- (void)figureTextCount:(NSString *)text;
- (void)clearText;

@end

NS_ASSUME_NONNULL_END
