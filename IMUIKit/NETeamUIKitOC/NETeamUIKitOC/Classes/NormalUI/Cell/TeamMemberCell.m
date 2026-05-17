// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamMemberCell.h"
#import "NormalTeamUIColor.h"
#import <NEChatKitOC/NEAppLanguageUtil.h>
#import <NEChatKitOC/NEConstant.h>
#import <NEChatKitOC/UIColor+NECommon.h>

@implementation TeamMemberCell

- (void)setupUI {
  [super setupUI];

  [self.contentView addSubview:self.removeLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.removeLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.removeLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20.0],
    [self.removeLabel.heightAnchor constraintEqualToConstant:22.0],
    [self.removeLabel.widthAnchor constraintEqualToConstant:([NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? 60.0 : 40.0)],
  ]];
  self.removeLabel.textColor = UIColor.ne_redText;
  self.removeLabel.clipsToBounds = YES;
  self.removeLabel.layer.cornerRadius = 4.0;
  self.removeLabel.layer.borderColor = UIColor.ne_redColor.CGColor;
  self.removeLabel.layer.borderWidth = 1.0;
  self.removeLabel.font = [UIFont systemFontOfSize:12.0];

  self.ownerLabel.backgroundColor = UIColor.normalTeamOwnerBgColor;
  self.ownerLabel.textColor = UIColor.normalTeamOwnerColor;
  self.ownerLabel.layer.borderColor = UIColor.normalTeamOwnerBorderColor.CGColor;
  self.ownerLabel.layer.cornerRadius = 11.0;

  [self setupRemoveButton];
}

@end
