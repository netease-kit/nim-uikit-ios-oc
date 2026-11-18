// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseSystemNotificationCell.h"
#import "ContactConst.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "ContactConst.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/NEChatKit.h>

@interface NEBaseSystemNotificationCell ()
@property (nonatomic, strong, nullable) NEAddApplication *addApplication;
@property (nonatomic, strong, nullable) NETeamJoinAction *teamJoinAction;
@end

@implementation NEBaseSystemNotificationCell

static void NEContactUpdateConstraintConstant(UIView *containerView,
                                              id firstItem,
                                              NSLayoutAttribute firstAttribute,
                                              id _Nullable secondItem,
                                              CGFloat constant) {
  for (NSLayoutConstraint *constraint in containerView.constraints) {
    if (constraint.firstItem != firstItem || constraint.firstAttribute != firstAttribute) {
      continue;
    }
    if (constraint.secondItem != secondItem) {
      continue;
    }
    constraint.constant = constant;
    return;
  }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)setupUI {
  [super setupUI];
  [self.contentView addSubview:self.agreeButton];
  [self.contentView addSubview:self.rejectButton];
  [self.contentView addSubview:self.resultImage];
  [self.contentView addSubview:self.resultLabel];
  self.resultLabel.text = @"";
  [NSLayoutConstraint activateConstraints:@[
    [self.agreeButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.agreeButton.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
    [self.agreeButton.widthAnchor constraintEqualToConstant:60],
    [self.agreeButton.heightAnchor constraintEqualToConstant:32],
  ]];
  [self.agreeButton addTarget:self action:@selector(agreeClick:) forControlEvents:UIControlEventTouchUpInside];

  [NSLayoutConstraint activateConstraints:@[
    [self.rejectButton.centerYAnchor constraintEqualToAnchor:self.agreeButton.centerYAnchor],
    [self.rejectButton.rightAnchor constraintEqualToAnchor:self.agreeButton.leftAnchor constant:-16],
    [self.rejectButton.widthAnchor constraintEqualToConstant:60],
    [self.rejectButton.heightAnchor constraintEqualToConstant:32],
  ]];
  [self.rejectButton addTarget:self action:@selector(rejectClick:) forControlEvents:UIControlEventTouchUpInside];

  [NSLayoutConstraint activateConstraints:@[
    [self.resultLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
    [self.resultLabel.centerYAnchor constraintEqualToAnchor:self.agreeButton.centerYAnchor],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.resultImage.rightAnchor constraintEqualToAnchor:self.resultLabel.leftAnchor constant:-6],
    [self.resultImage.centerYAnchor constraintEqualToAnchor:self.resultLabel.centerYAnchor],
    [self.resultImage.widthAnchor constraintEqualToConstant:16],
    [self.resultImage.heightAnchor constraintEqualToConstant:16],
  ]];
  [self refreshLocalizedTexts];
}

- (void)configeWithApplication:(NEAddApplication *)application {
  [super configeWithApplication:application];
  self.addApplication = application;
  self.teamJoinAction = nil;

  if (application.handleStatus != V2NIM_FRIEND_ADD_APPLICATION_STATUS_INIT) {
    self.agreeButton.hidden = YES;
    self.rejectButton.hidden = YES;
    self.titleLabelRightMargin.constant = -90;

    if ([application.v2Notification.applicantAccountId isEqualToString:[[IMKitClient instance] account]]) {
      // 自己申请的，不展示结果
      self.resultLabel.hidden = YES;
      self.resultImage.hidden = YES;
    } else {
      self.resultLabel.hidden = NO;
      self.resultImage.hidden = NO;

      switch (application.handleStatus) {
        case V2NIM_FRIEND_ADD_APPLICATION_STATUS_AGREED:
        case V2NIM_FRIEND_ADD_APPLICATION_STATUS_DIRECT_ADD:
          self.resultLabel.text = contactLocalizable(@"valid_agreed");
          self.resultImage.image = ne_contactImageNamed(@"valid_processed");
          break;
        case V2NIM_FRIEND_ADD_APPLICATION_STATUS_REJECED:
          self.resultLabel.text = contactLocalizable(@"valid_refused");
          self.resultImage.image = ne_contactImageNamed(@"valid_refused");
          break;
        case V2NIM_FRIEND_ADD_APPLICATION_STATUS_EXPIRED:
          self.resultLabel.text = contactLocalizable(@"expired");
          self.resultImage.image = ne_contactImageNamed(@"valid_refused");
          break;
        default:
          self.resultLabel.text = @"";
          break;
      }
    }
  } else {
    self.agreeButton.hidden = NO;
    self.rejectButton.hidden = NO;
    self.resultLabel.hidden = YES;
    self.resultImage.hidden = YES;
    self.titleLabelRightMargin.constant = -180;
  }
  [self refreshLocalizedTexts];
}

- (void)configeWithTeamJoinAction:(NETeamJoinAction *)teamJoinAction {
  [super configeWithTeamJoinAction:teamJoinAction];
  self.teamJoinAction = teamJoinAction;
  self.addApplication = nil;
  NEContactUpdateConstraintConstant(self.contentView, self.optionLabel, NSLayoutAttributeTop, self.titleLabel, 12);
  NEContactUpdateConstraintConstant(self.contentView, self.optionLabel, NSLayoutAttributeRight, self.contentView, -16);
  NEContactUpdateConstraintConstant(self.contentView, self.agreeButton, NSLayoutAttributeCenterY, self.contentView, -10);
  [self.contentView layoutIfNeeded];

  if (teamJoinAction.handleStatus != V2NIM_TEAM_JOIN_ACTION_STATUS_INIT) {
    self.agreeButton.hidden = YES;
    self.rejectButton.hidden = YES;
    self.titleLabelRightMargin.constant = -90;

    self.resultLabel.hidden = NO;
    self.resultImage.hidden = NO;

    switch (teamJoinAction.handleStatus) {
      case V2NIM_TEAM_JOIN_ACTION_STATUS_AGREED:
        self.resultLabel.text = contactLocalizable(@"valid_agreed");
        self.resultImage.image = ne_contactImageNamed(@"valid_processed");
        break;
      case V2NIM_TEAM_JOIN_ACTION_STATUS_REJECTED:
        self.resultLabel.text = contactLocalizable(@"valid_refused");
        self.resultImage.image = ne_contactImageNamed(@"valid_refused");
        break;
      case V2NIM_TEAM_JOIN_ACTION_STATUS_EXPIRED:
        self.resultLabel.text = contactLocalizable(@"expired");
        self.resultImage.image = ne_contactImageNamed(@"valid_refused");
        break;
      default:
        self.resultLabel.text = @"";
        break;
    }
  } else {
    if (teamJoinAction.nimTeamJoinAction.actionType == V2NIM_TEAM_JOIN_ACTION_TYPE_REJECT_APPLICATION ||
        teamJoinAction.nimTeamJoinAction.actionType == V2NIM_TEAM_JOIN_ACTION_TYPE_REJECT_INVITATION) {
      // 申请被拒绝，不展示结果
      self.resultLabel.hidden = YES;
      self.resultImage.hidden = YES;
      self.agreeButton.hidden = YES;
      self.rejectButton.hidden = YES;
      self.titleLabelRightMargin.constant = -16;
    } else {
      self.agreeButton.hidden = NO;
      self.rejectButton.hidden = NO;
      self.resultLabel.hidden = YES;
      self.resultImage.hidden = YES;
      self.titleLabelRightMargin.constant = -180;
    }
  }
  [self refreshLocalizedTexts];
}

- (void)rejectClick:(UIButton *)sender {
  if (self.addApplication) {
    if ([self.delegate respondsToSelector:@selector(onRefuseWithApplication:)]) {
      [self.delegate onRefuseWithApplication:self.addApplication];
    }
  }

  if (self.teamJoinAction) {
    if ([self.delegate respondsToSelector:@selector(onRefuseWithAction:)]) {
      [self.delegate onRefuseWithAction:self.teamJoinAction];
    }
  }
}

- (void)agreeClick:(UIButton *)sender {
  if (self.addApplication) {
    if ([self.delegate respondsToSelector:@selector(onAcceptWithApplication:)]) {
      [self.delegate onAcceptWithApplication:self.addApplication];
    }
  }

  if (self.teamJoinAction) {
    if ([self.delegate respondsToSelector:@selector(onAcceptWithAction:)]) {
      [self.delegate onAcceptWithAction:self.teamJoinAction];
    }
  }
}

#pragma mark - Lazy Init

- (ExpandButton *)rejectButton {
  if (!_rejectButton) {
    _rejectButton = [[ExpandButton alloc] init];
    _rejectButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_rejectButton setTitle:contactLocalizable(@"refuse") forState:UIControlStateNormal];
    [_rejectButton setTitleColor:[UIColor ne_colorWithHexString:@"333333"] forState:UIControlStateNormal];
    _rejectButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
    _rejectButton.clipsToBounds = NO;
    _rejectButton.layer.cornerRadius = 4;
    _rejectButton.layer.borderColor = [UIColor ne_colorWithHexString:@"D9D9D9"].CGColor;
    _rejectButton.layer.borderWidth = 1;
    _rejectButton.accessibilityIdentifier = @"id.reject";
  }
  return _rejectButton;
}

- (ExpandButton *)agreeButton {
  if (!_agreeButton) {
    _agreeButton = [[ExpandButton alloc] init];
    _agreeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_agreeButton setTitle:contactLocalizable(@"agree") forState:UIControlStateNormal];
    UIColor *blue = [UIColor ne_colorWithHexString:@"337EFF"];
    [_agreeButton setTitleColor:blue forState:UIControlStateNormal];
    _agreeButton.titleLabel.font = [UIFont systemFontOfSize:14];
    _agreeButton.clipsToBounds = YES;
    _agreeButton.layer.cornerRadius = 4;
    _agreeButton.layer.borderWidth = 1;
    _agreeButton.layer.borderColor = blue.CGColor;
    _agreeButton.accessibilityIdentifier = @"id.accept";
  }
  return _agreeButton;
}

- (UIImageView *)resultImage {
  if (!_resultImage) {
    _resultImage = [[UIImageView alloc] init];
    _resultImage.translatesAutoresizingMaskIntoConstraints = NO;
    _resultImage.image = ne_contactImageNamed(@"valid_processed");
  }
  return _resultImage;
}

- (UILabel *)resultLabel {
  if (!_resultLabel) {
    _resultLabel = [[UILabel alloc] init];
    _resultLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _resultLabel.textColor = [UIColor ne_emptyTitleColor];
    _resultLabel.font = [UIFont systemFontOfSize:14.0];
    _resultLabel.textAlignment = NSTextAlignmentRight;
    _resultLabel.accessibilityIdentifier = @"id.verifyResult";
  }
  return _resultLabel;
}

- (void)refreshLocalizedTexts {
  [self.rejectButton setTitle:contactLocalizable(@"refuse") forState:UIControlStateNormal];
  [self.agreeButton setTitle:contactLocalizable(@"agree") forState:UIControlStateNormal];

  if (self.addApplication) {
    if (self.addApplication.handleStatus != V2NIM_FRIEND_ADD_APPLICATION_STATUS_INIT &&
        ![self.addApplication.v2Notification.applicantAccountId isEqualToString:[[IMKitClient instance] account]]) {
      switch (self.addApplication.handleStatus) {
        case V2NIM_FRIEND_ADD_APPLICATION_STATUS_AGREED:
        case V2NIM_FRIEND_ADD_APPLICATION_STATUS_DIRECT_ADD:
          self.resultLabel.text = contactLocalizable(@"valid_agreed");
          break;
        case V2NIM_FRIEND_ADD_APPLICATION_STATUS_REJECED:
          self.resultLabel.text = contactLocalizable(@"valid_refused");
          break;
        case V2NIM_FRIEND_ADD_APPLICATION_STATUS_EXPIRED:
          self.resultLabel.text = contactLocalizable(@"expired");
          break;
        default:
          break;
      }
    }
  }

  if (self.teamJoinAction) {
    if (self.teamJoinAction.handleStatus != V2NIM_TEAM_JOIN_ACTION_STATUS_INIT) {
      switch (self.teamJoinAction.handleStatus) {
        case V2NIM_TEAM_JOIN_ACTION_STATUS_AGREED:
          self.resultLabel.text = contactLocalizable(@"valid_agreed");
          break;
        case V2NIM_TEAM_JOIN_ACTION_STATUS_REJECTED:
          self.resultLabel.text = contactLocalizable(@"valid_refused");
          break;
        case V2NIM_TEAM_JOIN_ACTION_STATUS_EXPIRED:
          self.resultLabel.text = contactLocalizable(@"expired");
          break;
        default:
          break;
      }
    }
  }
}

@end
