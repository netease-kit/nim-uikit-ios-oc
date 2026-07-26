// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamManagerMemberCell.h"
#import <NEChatKit/NEAppLanguageUtil.h>

@implementation TeamManagerMemberCell

- (void)setupUI {
  [super setupUI];
  self.ownerLabel.hidden = YES;
  self.nameLabelRightMargin.constant = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? -100.0 : -65.0;
}

@end
