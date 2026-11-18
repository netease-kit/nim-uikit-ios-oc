// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamMemberSelectCell.h"
#import "NESelectTeamMember.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NEConstant.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEBaseUIKitOC/NEUserHeaderView.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/TeamMemberInfoModel.h>
#import <NEChatKit/NEUserWithFriend.h>
#import <NEBaseUIKitOC/NETextSearchLayout.h>
#import <NIMSDK/V2NIMTeamServiceProtocol.h>
#import <NIMSDK/V2NIMUserServiceProtocol.h>

@interface NEBaseTeamMemberSelectCell ()
@property (nonatomic, strong) NETeamMemberSearchResult *currentSearchResult;
@property (nonatomic, assign) BOOL isApplyingSearchLayout;
@end

@implementation NEBaseTeamMemberSelectCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  [self.contentView addSubview:self.headerView];
  [self.contentView addSubview:self.nameStackView];
  [self.contentView addSubview:self.checkImageView];
}

- (void)configureMember:(NESelectTeamMember *)model {
  [self configureMember:model searchResult:nil];
}

- (void)configureMember:(NESelectTeamMember *)model
            searchResult:(NETeamMemberSearchResult *)searchResult {
  self.currentModel = model;
  self.currentSearchResult = searchResult;
  self.checkImageView.highlighted = model.isSelected;

  NSString *url = model.member.nimUser.user.avatar;
  NSString *name = [model.member getShortName:[model.member showNickInTeam] ?: @"" length:2] ?: @"";
  NSString *accountId = model.member.teamMember.accountId ?: model.member.nimUser.user.accountId ?: @"";
  [self.headerView configHeadData:url name:name uid:accountId];
  if (!searchResult) {
    [self configureName:[model.member atNameInTeam] ?: accountId];
    return;
  }

  [self applySearchResult:searchResult];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  if (self.currentSearchResult != nil && !self.isApplyingSearchLayout) {
    self.isApplyingSearchLayout = YES;
    [self applySearchResult:self.currentSearchResult];
    self.isApplyingSearchLayout = NO;
  }
}

- (void)applySearchResult:(NETeamMemberSearchResult *)searchResult {
  NETextSearchLayoutResult *primary = [NETextSearchLayout resultWithText:searchResult.primaryDisplayText ?: @""
                                                                matchRange:searchResult.primaryDisplayMatchRange
                                                                     font:self.nameLabel.font
                                                                 maxWidth:self.nameLabel.bounds.size.width];
  self.nameLabel.attributedText = [self highlightedText:primary.text
                                                 range:primary.matchRange
                                             baseColor:UIColor.ne_darkText
                                              baseFont:self.nameLabel.font];
  if (searchResult.secondaryDisplayText.length > 0) {
    NETextSearchLayoutResult *secondary = [NETextSearchLayout resultWithText:searchResult.secondaryDisplayText
                                                                     matchRange:searchResult.secondaryDisplayMatchRange
                                                                          font:self.subtitleLabel.font
                                                                      maxWidth:self.subtitleLabel.bounds.size.width];
    self.subtitleLabel.attributedText = [self highlightedText:secondary.text
                                                       range:secondary.matchRange
                                                   baseColor:UIColor.ne_greyText
                                                    baseFont:self.subtitleLabel.font];
    self.subtitleLabel.hidden = NO;
  } else {
    self.subtitleLabel.attributedText = nil;
    self.subtitleLabel.text = nil;
    self.subtitleLabel.hidden = YES;
  }
}

- (void)configureName:(NSString *)name {
  self.currentSearchResult = nil;
  self.nameLabel.attributedText = nil;
  self.nameLabel.text = name;
  self.subtitleLabel.attributedText = nil;
  self.subtitleLabel.text = nil;
  self.subtitleLabel.hidden = YES;
}

- (NSAttributedString *)highlightedText:(NSString *)value
                                  range:(NSRange)range
                              baseColor:(UIColor *)baseColor
                               baseFont:(UIFont *)baseFont {
  NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:value
                                                                            attributes:@{
                                                                              NSForegroundColorAttributeName: baseColor,
                                                                              NSFontAttributeName: baseFont,
                                                                            }];
  if (range.location != NSNotFound && NSMaxRange(range) <= text.length) {
    [text addAttribute:NSForegroundColorAttributeName value:UIColor.ne_searchHighlight range:range];
  }
  return text;
}

- (UIImageView *)checkImageView {
  if (!_checkImageView) {
    _checkImageView = [[UIImageView alloc] init];
    _checkImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _checkImageView.contentMode = UIViewContentModeScaleAspectFit;
    _checkImageView.image = [coreLoader() loadImage:@"unselect"];
  }
  return _checkImageView;
}

- (NEUserHeaderView *)headerView {
  if (!_headerView) {
    _headerView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    _headerView.titleLabel.font = [NEConstant defaultTextFont:14.0];
    _headerView.titleLabel.textColor = UIColor.whiteColor;
    _headerView.clipsToBounds = YES;
    _headerView.accessibilityIdentifier = @"id.avatar";
  }
  return _headerView;
}

- (UILabel *)nameLabel {
  if (!_nameLabel) {
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nameLabel.font = [NEConstant defaultTextFont:16.0];
    _nameLabel.textColor = UIColor.ne_darkText;
    _nameLabel.numberOfLines = 1;
    _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _nameLabel.accessibilityIdentifier = @"id.userName";
  }
  return _nameLabel;
}

- (UILabel *)subtitleLabel {
  if (!_subtitleLabel) {
    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.font = [NEConstant defaultTextFont:13.0];
    _subtitleLabel.textColor = UIColor.ne_greyText;
    _subtitleLabel.numberOfLines = 1;
    _subtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _subtitleLabel.accessibilityIdentifier = @"id.userSubtitle";
    _subtitleLabel.hidden = YES;
  }
  return _subtitleLabel;
}

- (UIStackView *)nameStackView {
  if (!_nameStackView) {
    _nameStackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.nameLabel, self.subtitleLabel]];
    _nameStackView.translatesAutoresizingMaskIntoConstraints = NO;
    _nameStackView.axis = UILayoutConstraintAxisVertical;
    _nameStackView.alignment = UIStackViewAlignmentFill;
    _nameStackView.spacing = 1.0;
  }
  return _nameStackView;
}

@end
