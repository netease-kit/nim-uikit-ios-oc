// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "NEBaseSelectCell.h"
#import "ContactConst.h"
#import "ContactUIConfig.h"
#import "NormalContactUIColor.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEChatKit/NECommonLoader.h>

#import <NEChatKit/NEFriendUserCache.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NEChatKit.h>

@interface NEBaseSelectCell ()
/// 是否展示人数（决定右侧预留宽度）
@property (nonatomic, assign) BOOL showsMemberCount;
@end

@implementation NEBaseSelectCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    _titleLabelMaxWidth = [UIScreen mainScreen].bounds.size.width - 170;
    _memberLabelMaxWidth = 52;
    _searchTextColor = [UIColor ne_defaultPrimaryColor];
    [self commonUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)commonUI {
  [self setupCommonCircleHeader];

  [self.contentView addSubview:self.multiSelectImageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.multiSelectImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.multiSelectImageView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20],
  ]];

  [self.contentView addSubview:self.titleLabel];
  self.titleLabelWidthAnchor = [self.titleLabel.widthAnchor constraintLessThanOrEqualToConstant:self.titleLabelMaxWidth];
  self.titleLabelWidthAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:12],
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];

  [self.contentView addSubview:self.optionLabel];
  self.memberLabelWidthAnchor = [self.optionLabel.widthAnchor constraintEqualToConstant:self.memberLabelMaxWidth];
  self.memberLabelWidthAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.optionLabel.leftAnchor constraintEqualToAnchor:self.titleLabel.rightAnchor constant:0],
    [self.optionLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [self.optionLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];
}

- (void)setConfig {
  self.titleLabel.textColor = [ContactUIConfig shared].contactProperties.itemTitleColor;
  self.optionLabel.textColor = self.titleLabel.textColor ?: [UIColor colorWithRed:51 / 255.0
                                                                             green:51 / 255.0
                                                                              blue:51 / 255.0
                                                                             alpha:1.0];
}

- (void)showSelect:(BOOL)isShow {
  self.multiSelectImageView.hidden = !isShow;
  self.leftConstraint.constant = isShow ? 50 : 20;
  // 名称宽度改由 `recalculateTitleLabelMaxWidth` 按 cell 实际宽度计算：
  // 折叠屏折叠/展开时列宽会变，继续用 `[UIScreen mainScreen]` 的宽度会算出超过列宽的上限。
  [self setNeedsLayout];
}

- (void)recalculateTitleLabelMaxWidth {
  CGFloat width = CGRectGetWidth(self.contentView.bounds);
  if (width <= 0) {
    return;
  }
  CGFloat left = CGRectGetMinX(self.titleLabel.frame);
  if (left <= 0) {
    return;
  }
  CGFloat reserved = (self.showsMemberCount ? self.memberLabelMaxWidth : 0) + 20.0;
  CGFloat candidate = MAX(0, width - left - reserved);
  if (fabs(candidate - self.titleLabelMaxWidth) <= 0.5) {
    return;
  }
  self.titleLabelMaxWidth = candidate;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self recalculateTitleLabelMaxWidth];
}

- (void)setModel:(MultiSelectModel *)model {
  [self setConfig];

  self.multiSelectImageView.highlighted = model.isSelected;
  self.titleLabel.text = model.name;
  self.showsMemberCount = model.memberCount > 0;
  self.optionLabel.text = self.showsMemberCount ? [NSString stringWithFormat:@" (%ld)", (long)model.memberCount] : nil;
  self.memberLabelWidthAnchor.constant = self.memberLabelMaxWidth;
  [self setNeedsLayout];

  NSString *url = model.avatar;
  NSString *accountId = [V2NIMConversationIdUtil conversationTargetId:model.conversationId ?: @""] ?: @"";
  NSString *name = model.avatarName ?: [[NEFriendUserCache shared] getFriendInfo:accountId].user.name ?: accountId;
  [self.userHeaderView configHeadData:url name:name uid:accountId];
}

- (void)setSearchText:(NSString *)searchText {
  _searchText = [searchText copy];
  if (searchText && self.titleLabel.text) {
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:self.titleLabel.text];
    NSRange range = [attributedStr.mutableString rangeOfString:searchText];
    [attributedStr addAttribute:NSForegroundColorAttributeName value:self.searchTextColor range:range];
    self.titleLabel.attributedText = attributedStr;
  }
}

- (void)setTitleLabelMaxWidth:(CGFloat)titleLabelMaxWidth {
  _titleLabelMaxWidth = titleLabelMaxWidth;
  self.titleLabelWidthAnchor.constant = titleLabelMaxWidth;
}

- (void)setMemberLabelMaxWidth:(CGFloat)memberLabelMaxWidth {
  _memberLabelMaxWidth = memberLabelMaxWidth;
  self.memberLabelWidthAnchor.constant = memberLabelMaxWidth;
}

#pragma mark - Lazy Init

- (UIImageView *)multiSelectImageView {
  if (!_multiSelectImageView) {
    _multiSelectImageView = [[UIImageView alloc] init];
    _multiSelectImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _multiSelectImageView.image = [coreLoader() loadImage:@"unselect"];
    _multiSelectImageView.accessibilityIdentifier = @"id.selector";
  }
  return _multiSelectImageView;
}

@end
