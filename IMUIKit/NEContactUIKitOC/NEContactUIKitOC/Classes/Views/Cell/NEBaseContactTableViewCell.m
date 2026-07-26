// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseContactTableViewCell.h"
#import <NEChatKit/NEChatKitOC.h>
#import <NEChatKit/NECommonLoader.h>
#import "ContactConst.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/NEFriendUserCache.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "ContactInfo.h"
#import "ContactUIConfig.h"
#import "ContactConst.h"

@implementation NEBaseContactTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    _contactCellType = ContactCellTypeContactPerson;
    [self commonUI];
    [self initSubviewsLayout];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)commonUI {
  [self setupCommonCircleHeader];
  self.backgroundColor = [UIColor clearColor];

  [self.contentView addSubview:self.titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:12],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-35],
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];

  [self.contentView addSubview:self.arrowImageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.arrowImageView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
    [self.arrowImageView.widthAnchor constraintEqualToConstant:15],
    [self.arrowImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [self.arrowImageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];

  [self.contentView addSubview:self.onlineView];
  [NSLayoutConstraint activateConstraints:@[
    [self.onlineView.rightAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor],
    [self.onlineView.bottomAnchor constraintEqualToAnchor:self.userHeaderView.bottomAnchor],
    [self.onlineView.widthAnchor constraintEqualToConstant:8],
    [self.onlineView.heightAnchor constraintEqualToConstant:8],
  ]];

  [self.contentView addSubview:self.bottomLine];
  [NSLayoutConstraint activateConstraints:@[
    [self.bottomLine.leftAnchor constraintEqualToAnchor:self.userHeaderView.leftAnchor],
    [self.bottomLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.bottomLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.bottomLine.heightAnchor constraintEqualToConstant:1],
  ]];

  [self.contentView addSubview:self.redAngleView];
  [NSLayoutConstraint activateConstraints:@[
    [self.redAngleView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.redAngleView.rightAnchor constraintEqualToAnchor:self.arrowImageView.leftAnchor constant:-10],
    [self.redAngleView.heightAnchor constraintEqualToConstant:18],
  ]];
}

- (void)initSubviewsLayout {
  if ([ContactUIConfig shared].contactProperties.avatarType == NEContactAvatarTypeCycle) {
    self.userHeaderView.layer.cornerRadius = 18.0;
  } else if ([ContactUIConfig shared].contactProperties.avatarCornerRadius > 0) {
    self.userHeaderView.layer.cornerRadius = [ContactUIConfig shared].contactProperties.avatarCornerRadius;
  } else {
    self.userHeaderView.layer.cornerRadius = 18.0; // Normal UI
  }
}

- (void)setConfig {
  self.titleLabel.textColor = [ContactUIConfig shared].contactProperties.itemTitleColor;
}

- (void)setOnline:(BOOL)online {
  self.onlineView.hidden = (self.contactCellType != ContactCellTypeContactPerson);
  self.onlineView.backgroundColor = online ? [UIColor ne_colorWithHexString:@"#84ED85"] : [UIColor ne_colorWithHexString:@"#D4D9DA"];
}

- (void)setModel:(ContactInfo *)model {
  NEUserWithFriend *user = model.user;
  if (!user) {
    return;
  }
  [self setConfig];

  // 更新用户信息
  NSString *userId = user.user.accountId;
  if (userId) {
    NEUserWithFriend *u = [[NEFriendUserCache shared] getFriendInfo:userId];
    if (u) {
      user = u;
    }
  }

  self.contactCellType = model.contactCellType;
  if (model.contactCellType == ContactCellTypeContactOthers) {
    self.titleLabel.text = user.friend.alias;
    self.arrowImageView.hidden = NO;

    NSString *imageName = user.user.avatar;
    [self.userHeaderView sd_cancelCurrentImageLoad];
    [self.userHeaderView sd_setImageWithURL:nil completed:nil];
    [self.userHeaderView setTitle:@""];
    self.userHeaderView.image = ne_contactImageNamed(imageName);
    self.userHeaderView.backgroundColor = [UIColor clearColor];
    return;
  }

  // person、custom
  self.titleLabel.text = [user showName];
  self.arrowImageView.hidden = YES;

  NSString *url = user.user.avatar;
  NSString *name = [user shortName:YES count:2] ?: @"";
  NSString *accountId = user.user.accountId ?: @"";
  [self.userHeaderView configHeadData:url name:name uid:accountId];
}

#pragma mark - Lazy Init

- (UIImageView *)arrowImageView {
  if (!_arrowImageView) {
    _arrowImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
    _arrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _arrowImageView.contentMode = UIViewContentModeCenter;
    _arrowImageView.accessibilityIdentifier = @"id.arrow";
  }
  return _arrowImageView;
}

- (UIView *)onlineView {
  if (!_onlineView) {
    _onlineView = [[UIView alloc] init];
    _onlineView.translatesAutoresizingMaskIntoConstraints = NO;
    _onlineView.layer.cornerRadius = 4;
    _onlineView.backgroundColor = [UIColor ne_colorWithHexString:@"#D4D9DA"];
    _onlineView.hidden = YES;
  }
  return _onlineView;
}

- (UIView *)bottomLine {
  if (!_bottomLine) {
    _bottomLine = [[UIView alloc] init];
    _bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _bottomLine;
}

@end
