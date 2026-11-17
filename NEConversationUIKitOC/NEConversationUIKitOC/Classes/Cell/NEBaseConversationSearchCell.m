// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseConversationSearchCell.h"
#import <NEBaseUIKitOC/NEUserHeaderView.h>
#import <NEChatKit/ConversationSearchListModel.h>
#import <NEChatKit/NIMExtension.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/TeamMemberInfoModel.h>
#import <NEBaseUIKitOC/NETextSearchLayout.h>

@interface NEBaseConversationSearchCell ()

@property (nonatomic, copy) NSString *activePrimaryText;
@property (nonatomic, assign) NSRange activePrimaryMatchRange;
@property (nonatomic, copy, nullable) NSString *activeSecondaryText;
@property (nonatomic, assign) NSRange activeSecondaryMatchRange;
@property (nonatomic, assign) BOOL isApplyingSearchLayout;

- (void)resetTextAppearance;
- (void)updateFriendDisplay:(NEUserWithFriend *)user;
- (void)updateTeamDisplay:(V2NIMTeam *)team;
- (void)applySearchDisplay;

@end

@implementation NEBaseConversationSearchCell

- (void)setSearchModel:(ConversationSearchListModel *)searchModel {
  _searchModel = searchModel;
  self.activePrimaryText = nil;
  self.activeSecondaryText = nil;
  [self resetTextAppearance];
  self.subTitleLabel.attributedText = nil;
  self.subTitleLabel.text = nil;
  self.subTitleLabel.hidden = YES;
  if (searchModel.userInfo != nil) {
    NSString *url = searchModel.userInfo.user.avatar ?: @"";
    NSString *accountId = searchModel.userInfo.user.accountId ?: searchModel.userInfo.friend.accountId ?: @"";
    NSString *name = searchModel.userInfo.user.name.length > 0 ? searchModel.userInfo.user.name : accountId;
    [self.headImageView configHeadData:url name:name uid:accountId];
    [self updateFriendDisplay:searchModel.userInfo];
  } else if (searchModel.team != nil) {
    NSString *url = searchModel.team.avatar ?: @"";
    NSString *name = [searchModel.team ne_getShortName:2] ?: @"";
    NSString *teamId = searchModel.team.teamId ?: @"";
    [self.headImageView configHeadData:url name:name uid:teamId];
    [self updateTeamDisplay:searchModel.team];
  }
  [self updateSubtitleLayout];
}

- (void)setSearchText:(NSString *)searchText {
  _searchText = [searchText copy] ?: @"";
  [self resetTextAppearance];
  if (self.searchModel.userInfo != nil) {
    [self updateFriendDisplay:self.searchModel.userInfo];
  } else if (self.searchModel.team != nil) {
    [self updateTeamDisplay:self.searchModel.team];
  } else {
    self.activePrimaryText = nil;
    self.activeSecondaryText = nil;
  }
  [self updateSubtitleLayout];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  if (self.activePrimaryText.length > 0 && !self.isApplyingSearchLayout) {
    self.isApplyingSearchLayout = YES;
    [self applySearchDisplay];
    self.isApplyingSearchLayout = NO;
  }
}

- (void)updateFriendDisplay:(NEUserWithFriend *)user {
  self.activePrimaryText = nil;
  self.activeSecondaryText = nil;
  NSString *keyword = [self.searchText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  NETeamMemberSearchResult *result = nil;
  if (keyword.length > 0) {
    result = [NETeamMemberSearchMatcher resultWithKeyword:keyword
                                                 teamNick:nil
                                               friendAlias:user.friend.alias
                                            userNickname:user.user.name
                                               accountId:user.user.accountId ?: user.friend.accountId];
  }
  if (result != nil) {
    self.activePrimaryText = result.primaryDisplayText;
    self.activePrimaryMatchRange = result.primaryDisplayMatchRange;
    self.activeSecondaryText = result.secondaryDisplayText;
    self.activeSecondaryMatchRange = result.secondaryDisplayMatchRange;
    [self applySearchDisplay];
    return;
  }

  NSString *accountId = user.user.accountId ?: user.friend.accountId ?: @"";
  self.titleLabel.attributedText = nil;
  self.titleLabel.text = [user showName] ?: accountId;
  self.subTitleLabel.attributedText = nil;
  self.subTitleLabel.text = nil;
}

- (void)updateTeamDisplay:(V2NIMTeam *)team {
  NSString *titleText = team.name ?: @"";
  NSString *keyword = [self.searchText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  NETeamMemberSearchResult *result = [NETeamMemberSearchMatcher displayResultWithKeyword:keyword
                                                                                     text:titleText];
  self.activePrimaryText = nil;
  self.activeSecondaryText = nil;
  if (result != nil) {
    self.activePrimaryText = result.primaryDisplayText;
    self.activePrimaryMatchRange = result.primaryDisplayMatchRange;
    [self applySearchDisplay];
  } else {
    self.titleLabel.attributedText = nil;
    self.titleLabel.text = titleText;
  }
  self.subTitleLabel.text = nil;
  self.subTitleLabel.attributedText = nil;
}

- (void)applySearchDisplay {
  if (self.activePrimaryText.length == 0) {
    return;
  }
  NETextSearchLayoutResult *primary = [NETextSearchLayout resultWithText:self.activePrimaryText
                                                                matchRange:self.activePrimaryMatchRange
                                                                     font:self.titleLabel.font
                                                                 maxWidth:self.titleLabel.bounds.size.width];
  self.titleLabel.attributedText = [self highlightedText:primary.text
                                               matchRange:primary.matchRange
                                                baseColor:UIColor.ne_darkText];
  if (self.activeSecondaryText.length > 0) {
    NETextSearchLayoutResult *secondary = [NETextSearchLayout resultWithText:self.activeSecondaryText
                                                                     matchRange:self.activeSecondaryMatchRange
                                                                          font:self.subTitleLabel.font
                                                                      maxWidth:self.subTitleLabel.bounds.size.width];
    self.subTitleLabel.text = secondary.text;
    self.subTitleLabel.attributedText = [self highlightedText:secondary.text
                                                       matchRange:secondary.matchRange
                                                        baseColor:UIColor.ne_greyText];
    self.subTitleLabel.hidden = NO;
  } else {
    self.subTitleLabel.text = nil;
    self.subTitleLabel.attributedText = nil;
    self.subTitleLabel.hidden = YES;
  }
}

- (void)updateSubtitleLayout {
  BOOL hasSubtitle = self.subTitleLabel.text.length > 0;
  self.subTitleLabel.hidden = !hasSubtitle;
  self.titleLabelCenterYAnchor.active = !hasSubtitle;
  self.titleLabelTopAnchor.active = hasSubtitle;
}

- (void)resetTextAppearance {
  self.titleLabel.textColor = UIColor.ne_darkText;
  self.subTitleLabel.textColor = UIColor.ne_greyText;
}

- (NSAttributedString *)highlightedText:(NSString *)text
                            matchRange:(NSRange)matchRange
                             baseColor:(UIColor *)baseColor {
  NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:text
                                                                                   attributes:@{NSForegroundColorAttributeName: baseColor}];
  if (matchRange.location != NSNotFound && NSMaxRange(matchRange) <= attributed.length) {
    [attributed addAttribute:NSForegroundColorAttributeName value:[self getRangeTextColor] range:matchRange];
  }
  return attributed;
}

- (UIColor *)getRangeTextColor {
  return UIColor.ne_searchHighlight;
}

@end
