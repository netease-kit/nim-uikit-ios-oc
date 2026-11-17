// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseChatTeamMemberCell.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NEChatKit.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEBaseUIKitOC/NETextSearchLayout.h>
#import <NEChatKit/NEConstant.h>
#import "ChatCellConstantValue.h"

@interface NEBaseChatTeamMemberCell ()
@property (nonatomic, strong) NETeamMemberSearchResult *currentSearchResult;
@property (nonatomic, assign) BOOL isApplyingSearchLayout;
@end

@implementation NEBaseChatTeamMemberCell

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
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (NEUserHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
        _headerView.titleLabel.font = [NEConstant defaultTextFont:14];
        _headerView.titleLabel.textColor = UIColor.whiteColor;
        _headerView.clipsToBounds = YES;
        _headerView.translatesAutoresizingMaskIntoConstraints = NO;
        _headerView.accessibilityIdentifier = @"id.atCellHeaderView";
    }
    return _headerView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.textColor = UIColor.ne_darkText;
        _nameLabel.font = [NEConstant defaultTextFont:16];
        _nameLabel.numberOfLines = 1;
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _nameLabel.accessibilityIdentifier = @"id.atCellName";
    }
    return _nameLabel;
}

- (UILabel *)subtitleLabel {
    if (!_subtitleLabel) {
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.textColor = UIColor.ne_greyText;
        _subtitleLabel.font = [NEConstant defaultTextFont:13];
        _subtitleLabel.numberOfLines = 1;
        _subtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _subtitleLabel.accessibilityIdentifier = @"id.atCellSubtitle";
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
        _nameStackView.spacing = 1;
    }
    return _nameStackView;
}

- (UIColor *)searchHighlightColor {
    return UIColor.ne_searchHighlight;
}

- (CGFloat)nameHorizontalSpacing {
    return 14;
}

- (CGFloat)nameTrailingInset {
    return 70;
}

- (void)setupUI {
    [self.contentView addSubview:self.headerView];
    [NSLayoutConstraint activateConstraints:@[
        [self.headerView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:21],
        [self.headerView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.headerView.widthAnchor constraintEqualToConstant:fun_chat_min_h],
        [self.headerView.heightAnchor constraintEqualToConstant:fun_chat_min_h],
    ]];

    [self.contentView addSubview:self.nameStackView];
    [NSLayoutConstraint activateConstraints:@[
        [self.nameStackView.leftAnchor constraintEqualToAnchor:self.headerView.rightAnchor constant:self.nameHorizontalSpacing],
        [self.nameStackView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.nameStackView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-self.nameTrailingInset],
    ]];
}

- (void)configure:(NETeamMemberInfoModel *)model {
    [self configure:model searchResult:nil];
}

- (void)configure:(NETeamMemberInfoModel *)model searchResult:(NETeamMemberSearchResult *)searchResult {
    NSString *url = model.nimUser.user.avatar;
    NSString *accountId = model.nimUser.user.accountId ?: model.teamMember.accountId ?: @"";
    NSString *name = [model getShortName:[model.nimUser showName:NO] ?: accountId length:2];
    [self.headerView configHeadData:url name:name uid:accountId];
    self.currentSearchResult = searchResult;
    if (!searchResult) {
        [self configureAllWithTitle:[model atNameInTeam] ?: accountId];
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
                                               matchRange:primary.matchRange
                                                baseColor:UIColor.ne_darkText
                                                 baseFont:self.nameLabel.font];
    if (searchResult.secondaryDisplayText.length > 0) {
        NETextSearchLayoutResult *secondary = [NETextSearchLayout resultWithText:searchResult.secondaryDisplayText
                                                                       matchRange:searchResult.secondaryDisplayMatchRange
                                                                            font:self.subtitleLabel.font
                                                                        maxWidth:self.subtitleLabel.bounds.size.width];
        self.subtitleLabel.attributedText = [self highlightedText:secondary.text
                                                         matchRange:secondary.matchRange
                                                          baseColor:UIColor.ne_greyText
                                                           baseFont:self.subtitleLabel.font];
        self.subtitleLabel.hidden = NO;
    } else {
        self.subtitleLabel.attributedText = nil;
        self.subtitleLabel.text = nil;
        self.subtitleLabel.hidden = YES;
    }
}

- (void)configureAllWithTitle:(NSString *)title {
    self.currentSearchResult = nil;
    self.nameLabel.attributedText = nil;
    self.nameLabel.text = title;
    self.subtitleLabel.attributedText = nil;
    self.subtitleLabel.text = nil;
    self.subtitleLabel.hidden = YES;
}

- (void)configureAllWithTitle:(NSString *)title image:(UIImage *)image {
    [self.headerView configStaticImage:image];
    [self configureAllWithTitle:title];
}

- (NSAttributedString *)highlightedText:(NSString *)text
                             matchRange:(NSRange)matchRange
                              baseColor:(UIColor *)baseColor
                               baseFont:(UIFont *)baseFont {
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text
                                                                                        attributes:@{
                                                                                          NSForegroundColorAttributeName: baseColor,
                                                                                          NSFontAttributeName: baseFont,
    }];
    if (matchRange.location != NSNotFound && NSMaxRange(matchRange) <= attributedText.length) {
        [attributedText addAttribute:NSForegroundColorAttributeName
                               value:self.searchHighlightColor
                               range:matchRange];
    }
    return attributedText;
}

@end
