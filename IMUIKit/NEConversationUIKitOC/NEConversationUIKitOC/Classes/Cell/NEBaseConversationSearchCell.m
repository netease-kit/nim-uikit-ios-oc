// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseConversationSearchCell.h"
#import <NECommonUIKitOC/NEUserHeaderView.h>
#import <NEChatKit/ConversationSearchListModel.h>
#import <NEChatKit/NIMExtension.h>
#import <NEChatKit/UIColor+NECommon.h>

@implementation NEBaseConversationSearchCell

- (void)setSearchModel:(ConversationSearchListModel *)searchModel {
  _searchModel = searchModel;
  if (searchModel.userInfo != nil) {
    NSString *url = searchModel.userInfo.user.avatar ?: @"";
    NSString *name = [searchModel.userInfo shortName:YES count:2] ?: @"";
    NSString *accountId = searchModel.userInfo.user.accountId ?: @"";
    [self.headImageView configHeadData:url name:name uid:accountId];
    self.titleLabel.text = [searchModel.userInfo showName];
    self.subTitleLabel.text = accountId;
  } else if (searchModel.team != nil) {
    NSString *url = searchModel.team.avatar ?: @"";
    NSString *name = [searchModel.team ne_getShortName:2] ?: @"";
    NSString *teamId = searchModel.team.teamId ?: @"";
    [self.headImageView configHeadData:url name:name uid:teamId];
    self.titleLabel.text = [searchModel.team ne_getShowName];
    self.subTitleLabel.text = nil;
  }
}

- (void)setSearchText:(NSString *)searchText {
  _searchText = [searchText copy] ?: @"";

  NSString *titleText = self.titleLabel.text ?: @"";
  NSMutableAttributedString *titleAttributed = [[NSMutableAttributedString alloc] initWithString:titleText];
  if (_searchText.length > 0) {
    NSRange titleRange = [titleText rangeOfString:_searchText];
    if (titleRange.location != NSNotFound) {
      [titleAttributed addAttribute:NSForegroundColorAttributeName value:[self getRangeTextColor] range:titleRange];
    }
  }
  self.titleLabel.attributedText = titleAttributed;
  self.titleLabelCenterYAnchor.active = YES;
  self.titleLabelTopAnchor.active = NO;
  self.subTitleLabel.hidden = YES;

  NSString *subTitleText = self.subTitleLabel.text ?: @"";
  if (subTitleText.length > 0) {
    NSMutableAttributedString *subTitleAttributed = [[NSMutableAttributedString alloc] initWithString:subTitleText];
    if (_searchText.length > 0) {
      NSRange subTitleRange = [subTitleText rangeOfString:_searchText];
      if (subTitleRange.location != NSNotFound) {
        [subTitleAttributed addAttribute:NSForegroundColorAttributeName value:[self getRangeTextColor] range:subTitleRange];
      }
    }
    self.subTitleLabel.attributedText = subTitleAttributed;
    self.subTitleLabel.hidden = NO;
    self.titleLabelTopAnchor.active = YES;
    self.titleLabelCenterYAnchor.active = NO;
  }
}

- (UIColor *)getRangeTextColor {
  return UIColor.ne_normalTheme;
}

@end
