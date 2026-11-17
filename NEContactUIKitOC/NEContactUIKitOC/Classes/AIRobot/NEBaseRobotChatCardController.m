// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "NEBaseRobotChatCardController.h"
#import "ContactConst.h"
#import "NormalContactUIColor.h"
#import <NEChatKit/NEFriendUserCache.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <QuartzCore/QuartzCore.h>


@interface NEBaseRobotChatCardController ()

@property(nonatomic, strong, readwrite) V2NIMUserAIBot *bot;

@end

@implementation NEBaseRobotChatCardController

- (instancetype)initWithBot:(V2NIMUserAIBot *)bot {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _bot = bot;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = contactLocalizable(@"ai_robot_detail_title");
  self.navigationView.moreButton.hidden = YES;
  self.view.backgroundColor = [self cardPageBackgroundColor];
  [self setupCardUI];
  [self configCard];
}

- (void)setupCardUI {
  UIView *card = [[UIView alloc] init];
  card.translatesAutoresizingMaskIntoConstraints = NO;
  card.backgroundColor = [UIColor whiteColor];
  card.layer.cornerRadius = 8.0;
  card.clipsToBounds = YES;
  [self.view addSubview:card];
  [NSLayoutConstraint activateConstraints:@[
    [card.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant + 12.0],
    [card.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:[self cardHorizontalMargin]],
    [card.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-[self cardHorizontalMargin]],
  ]];

  [card addSubview:self.avatarView];
  [NSLayoutConstraint activateConstraints:@[
    [self.avatarView.topAnchor constraintEqualToAnchor:card.topAnchor constant:24.0],
    [self.avatarView.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
    [self.avatarView.widthAnchor constraintEqualToConstant:[self avatarSize]],
    [self.avatarView.heightAnchor constraintEqualToConstant:[self avatarSize]],
  ]];

  [card addSubview:self.nameLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.nameLabel.topAnchor constraintEqualToAnchor:self.avatarView.bottomAnchor constant:12.0],
    [self.nameLabel.leftAnchor constraintEqualToAnchor:card.leftAnchor constant:16.0],
    [self.nameLabel.rightAnchor constraintEqualToAnchor:card.rightAnchor constant:-16.0],
    [self.nameLabel.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-24.0],
  ]];

  [self.view addSubview:self.chatButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.chatButton.topAnchor constraintEqualToAnchor:card.bottomAnchor constant:12.0],
    [self.chatButton.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:[self cardHorizontalMargin]],
    [self.chatButton.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-[self cardHorizontalMargin]],
    [self.chatButton.heightAnchor constraintEqualToConstant:50.0],
  ]];
}

- (void)configCard {
  NSString *name = self.bot.name.length > 0 ? self.bot.name : (self.bot.accid ?: @"");
  self.nameLabel.text = name;
  NSString *shortName = [NEFriendUserCache getShortName:name length:2] ?: @"";
  [self.avatarView configHeadData:self.bot.icon name:shortName uid:self.bot.accid ?: @""];
}

- (UIColor *)cardPageBackgroundColor {
  return [UIColor ne_lightBackgroundColor];
}

- (CGFloat)cardHorizontalMargin {
  return 20.0;
}

- (CGFloat)avatarSize {
  return 60.0;
}

- (UIColor *)chatButtonColor {
  return [UIColor ne_defaultPrimaryColor];
}

- (void)didTapChatButton {
  if (!self.navigationController) {
    return;
  }
  NSString *conversationId = [V2NIMConversationIdUtil p2pConversationId:self.bot.accid ?: @""];
  if (conversationId.length == 0) {
    return;
  }

  [[Router shared] use:@"imkit://chat/p2pChat.page"
            parameters:@{
              @"nav": self.navigationController,
              @"conversationId": conversationId,
              @"animated": @YES,
            }
               closure:nil];
}

#pragma mark - Lazy Init

- (NEUserHeaderView *)avatarView {
  if (!_avatarView) {
    _avatarView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    _avatarView.layer.cornerRadius = [self avatarSize] / 2.0;
    _avatarView.clipsToBounds = YES;
    _avatarView.titleLabel.font = [UIFont systemFontOfSize:20.0];
    _avatarView.titleLabel.textColor = [UIColor whiteColor];
  }
  return _avatarView;
}

- (UILabel *)nameLabel {
  if (!_nameLabel) {
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nameLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    _nameLabel.textColor = [UIColor ne_darkText];
    _nameLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _nameLabel;
}

- (UIButton *)chatButton {
  if (!_chatButton) {
    _chatButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _chatButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_chatButton setTitle:contactLocalizable(@"ai_robot_chat") forState:UIControlStateNormal];
    [_chatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _chatButton.titleLabel.font = [UIFont systemFontOfSize:16.0];
    _chatButton.backgroundColor = [self chatButtonColor];
    _chatButton.layer.cornerRadius = 8.0;
    _chatButton.clipsToBounds = YES;
    [_chatButton addTarget:self action:@selector(didTapChatButton) forControlEvents:UIControlEventTouchUpInside];
  }
  return _chatButton;
}

@end
