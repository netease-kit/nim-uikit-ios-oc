// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamMemberCell.h"
#import "TeamConstant.h"
#import <NEBaseUIKitOC/NEUserHeaderView.h>
#import <NEChatKit/NEChatKit.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NEAppLanguageUtil.h>
#import <NEChatKit/NEFriendUserCache.h>
#import <NEChatKit/TeamMemberInfoModel.h>
#import <NEChatKit/NEUserWithFriend.h>
#import <NEBaseUIKitOC/NETextSearchLayout.h>
#import <NIMSDK/V2NIMTeamServiceProtocol.h>
#import <NIMSDK/V2NIMUserServiceProtocol.h>

@interface NEBaseTeamMemberCell ()
@property (nonatomic, strong) NETeamMemberSearchResult *currentSearchResult;
@property (nonatomic, assign) BOOL isApplyingSearchLayout;
@end

@implementation NEBaseTeamMemberCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setupUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  self.backgroundColor = UIColor.clearColor;
  self.contentView.backgroundColor = UIColor.clearColor;

  [self.contentView addSubview:self.headerView];
  [NSLayoutConstraint activateConstraints:@[
    [self.headerView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:21.0],
    [self.headerView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.headerView.widthAnchor constraintEqualToConstant:42.0],
    [self.headerView.heightAnchor constraintEqualToConstant:42.0],
  ]];

  CGFloat rightMargin = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? -170.0 : -116.0;
  self.nameLabelRightMargin = [self.nameStackView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:rightMargin];
  [self.contentView addSubview:self.nameStackView];
  [NSLayoutConstraint activateConstraints:@[
    [self.nameStackView.leftAnchor constraintEqualToAnchor:self.headerView.rightAnchor constant:14.0],
    [self.nameStackView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    self.nameLabelRightMargin,
  ]];

  self.ownerWidth = [self.ownerLabel.widthAnchor constraintEqualToConstant:48.0];
  [self.contentView addSubview:self.ownerLabel];
  self.ownerRightVisibleConstant = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? -90.0 : -70.0;
  self.ownerRightHiddenConstant = -20.0;
  self.ownerRightMargin = [self.ownerLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:self.ownerRightVisibleConstant];
  [NSLayoutConstraint activateConstraints:@[
    self.ownerRightMargin,
    [self.ownerLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.ownerLabel.heightAnchor constraintEqualToConstant:22.0],
    self.ownerWidth,
  ]];
}

- (void)setRemoveControlsVisible:(BOOL)visible {
  self.removeButton.hidden = !visible;
  self.removeLabel.hidden = !visible;
  self.ownerRightMargin.constant = visible ? self.ownerRightVisibleConstant : self.ownerRightHiddenConstant;
}

- (void)configure:(NETeamMemberInfoModel *)model {
  [self configure:model searchResult:nil];
}

- (void)configure:(NETeamMemberInfoModel *)model searchResult:(NETeamMemberSearchResult *)searchResult {
  NSString *accountId = model.teamMember.accountId ?: model.nimUser.user.accountId ?: @"";
  NEUserWithFriend *aiUser = [[NEAIUserManager shared] getNEUserById:accountId];
  if (aiUser) {
    model.nimUser = aiUser;
  } else {
    NEUserWithFriend *cachedUser = [[NEFriendUserCache shared] getFriendInfo:accountId];
    if (cachedUser) {
      model.nimUser = cachedUser;
    }
  }
  self.currentModel = model;
  self.currentSearchResult = searchResult;

  NSString *url = model.nimUser.user.avatar;
  NSString *shortName = [model getShortName:[model showNickInTeam] ?: @"" length:2];
  [self.headerView configHeadData:url name:shortName uid:accountId];
  if (!searchResult) {
    [self configureName:[model atNameInTeam] ?: accountId];
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

- (void)setupRemoveButton {
  [self.contentView addSubview:self.removeButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.removeButton.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [self.removeButton.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.removeButton.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.removeButton.widthAnchor constraintEqualToConstant:100.0],
  ]];
  [self.removeButton addTarget:self action:@selector(didClickRemove) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didClickRemove {
  if ([self.delegate respondsToSelector:@selector(didClickRemoveButton:index:)]) {
    [self.delegate didClickRemoveButton:self.currentModel index:self.index];
  }
}

- (NEUserHeaderView *)headerView {
  if (!_headerView) {
    _headerView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _headerView.titleLabel.font = [NEConstant defaultTextFont:14.0];
    _headerView.titleLabel.textColor = UIColor.whiteColor;
    _headerView.layer.cornerRadius = 21.0;
    _headerView.clipsToBounds = YES;
    _headerView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _headerView;
}

- (UILabel *)ownerLabel {
  if (!_ownerLabel) {
    _ownerLabel = [[UILabel alloc] init];
    _ownerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _ownerLabel.font = [NEConstant defaultTextFont:12.0];
    _ownerLabel.textColor = [NEConstant hexRGB:0x337EFF];
    _ownerLabel.backgroundColor = [NEConstant hexRGB:0xE0ECFF];
    _ownerLabel.layer.borderColor = [NEConstant hexRGB:0xB9D3FF].CGColor;
    _ownerLabel.clipsToBounds = YES;
    _ownerLabel.layer.cornerRadius = 4.0;
    _ownerLabel.layer.borderWidth = 1.0;
    _ownerLabel.text = NETeamUIKitLocalizable(@"team_owner");
    _ownerLabel.textAlignment = NSTextAlignmentCenter;
    _ownerLabel.accessibilityIdentifier = @"id.identify";
  }
  return _ownerLabel;
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

- (UILabel *)removeLabel {
  if (!_removeLabel) {
    _removeLabel = [[UILabel alloc] init];
    _removeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _removeLabel.text = NETeamUIKitLocalizable(@"team_member_remove");
    _removeLabel.font = [UIFont systemFontOfSize:14.0];
    _removeLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _removeLabel;
}

- (UIButton *)removeButton {
  if (!_removeButton) {
    _removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _removeButton.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _removeButton;
}

@end
