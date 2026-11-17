// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationListCell.h"
#import "NEConversationListModel.h"
#import "NEAtMessageManager.h"
#import "NEMessageUtil.h"
#import "ConversationUIConfig.h"
@import NEBaseUIKitOC;
#import <NEChatKit/NEAIUserManager.h>
#import <NEChatKit/NEAIRobotManager.h>
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/NEFriendUserCache.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/V2NIMConversationExtension.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/StringExtension.h>
#import <NIMSDK/NIMSDK.h>
#import <objc/message.h>

/// 屏幕间距
static CGFloat const kScreenInterval = 20.0;

static NECommonLoader *NEConversationCellLoader(void) {
  static NECommonLoader *loader = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    loader = [[NECommonLoader alloc] initWithClass:[NEBaseConversationListCell class]];
  });
  return loader;
}

static NSString *NEConversationCellLocalizable(NSString *key) {
  return [NEConversationCellLoader() localizable:key];
}

static NSString *NEConversationAvatarName(NSString *accountId, NSString *conversationName) {
  V2NIMUserAIBot *robot = [[NEAIRobotManager shared] getBot:accountId];
  if (robot.name.length > 0) {
    return robot.name;
  }
  V2NIMAIUser *aiUser = [[NEAIUserManager shared] getAIUserById:accountId];
  if (aiUser.name.length > 0) {
    return aiUser.name;
  }
  NEUserWithFriend *friend = [[NEFriendUserCache shared] getFriendInfo:accountId];
  if (friend.user.name.length > 0) {
    return friend.user.name;
  }
  if (conversationName.length > 0) {
    return conversationName;
  }
  return accountId;
}

static BOOL NEConversationCellIsNormalStyle(void) {
  Class styleManagerClass = NSClassFromString(@"NEStyleManager");
  SEL instanceSelector = NSSelectorFromString(@"instance");
  SEL isNormalStyleSelector = NSSelectorFromString(@"isNormalStyle");
  if (styleManagerClass &&
      [styleManagerClass respondsToSelector:instanceSelector]) {
    id manager = ((id (*)(id, SEL))objc_msgSend)(styleManagerClass, instanceSelector);
    if (manager && [manager respondsToSelector:isNormalStyleSelector]) {
      return ((BOOL (*)(id, SEL))objc_msgSend)(manager, isNormalStyleSelector);
    }
  }
  return YES;
}

@interface NEBaseConversationListCell ()
@property (nonatomic, assign) NSInteger conversationType;
@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, assign) BOOL robotConversation;
@property (nonatomic, assign) BOOL requestedOnline;
@end

@implementation NEBaseConversationListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor clearColor];
    [self setupSubviews];
  }
  return self;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  self.sessionId = @"";
  self.robotConversation = NO;
  self.requestedOnline = NO;
  self.robotIconView.hidden = YES;
  self.onlineView.hidden = YES;
  self.redAngleView.hidden = YES;
  self.redAngleView.text = nil;
  self.mutedUnreadDotView.hidden = YES;
  self.notifyMsgView.hidden = YES;
}

- (void)setupSubviews {
  [self.contentView addSubview:self.headImageView];
  [self.contentView addSubview:self.onlineView];
  [self.contentView addSubview:self.redAngleView];
  [self.contentView addSubview:self.mutedUnreadDotView];
  [self.contentView addSubview:self.titleContentView];
  [self.contentView addSubview:self.subTitleLabel];
  [self.contentView addSubview:self.timeLabel];
  [self.contentView addSubview:self.notifyMsgView];

  BOOL isNormalStyle = NEConversationCellIsNormalStyle();
  CGFloat headSize = isNormalStyle ? 42.0 : 48.0;
  CGFloat titleTop = isNormalStyle ? 13.0 : 19.0;
  CGFloat notifyTopSpace = isNormalStyle ? 5.0 : 10.0;
  CGFloat notifySize = isNormalStyle ? 13.0 : 14.0;

  // headImageView: 左 16, 垂直居中, 42x42
  [NSLayoutConstraint activateConstraints:@[
    [self.headImageView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16],
    [self.headImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.headImageView.widthAnchor constraintEqualToConstant:headSize],
    [self.headImageView.heightAnchor constraintEqualToConstant:headSize],
  ]];

  // redAngleView
  [NSLayoutConstraint activateConstraints:@[
    [self.redAngleView.centerXAnchor constraintEqualToAnchor:self.headImageView.rightAnchor constant:-8],
    [self.redAngleView.centerYAnchor constraintEqualToAnchor:self.headImageView.topAnchor constant:8],
    [self.redAngleView.heightAnchor constraintEqualToConstant:18],
  ]];

  // 与 Swift 版本一致：免打扰会话有未读时显示 8x8 红点。
  [NSLayoutConstraint activateConstraints:@[
    [self.mutedUnreadDotView.centerXAnchor constraintEqualToAnchor:self.redAngleView.centerXAnchor constant:3],
    [self.mutedUnreadDotView.centerYAnchor constraintEqualToAnchor:self.redAngleView.centerYAnchor constant:-3],
    [self.mutedUnreadDotView.widthAnchor constraintEqualToConstant:8],
    [self.mutedUnreadDotView.heightAnchor constraintEqualToConstant:8],
  ]];

  // onlineView
  [NSLayoutConstraint activateConstraints:@[
    [self.onlineView.rightAnchor constraintEqualToAnchor:self.headImageView.rightAnchor],
    [self.onlineView.bottomAnchor constraintEqualToAnchor:self.headImageView.bottomAnchor],
    [self.onlineView.widthAnchor constraintEqualToConstant:12],
    [self.onlineView.heightAnchor constraintEqualToConstant:12],
  ]];

  // timeLabel
  self.timeWidthConstraint = [self.timeLabel.widthAnchor constraintEqualToConstant:0];
  self.timeWidthConstraint.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.timeLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-kScreenInterval],
    [self.timeLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:17],
  ]];

  // titleContentView
  [NSLayoutConstraint activateConstraints:@[
    [self.titleContentView.leftAnchor constraintEqualToAnchor:self.headImageView.rightAnchor constant:12],
    [self.titleContentView.rightAnchor constraintLessThanOrEqualToAnchor:self.timeLabel.leftAnchor constant:-5],
    [self.titleContentView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:titleTop],
  ]];

  // subTitleLabel
  [NSLayoutConstraint activateConstraints:@[
    [self.subTitleLabel.leftAnchor constraintEqualToAnchor:self.headImageView.rightAnchor constant:12],
    [self.subTitleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-50],
    [self.subTitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:6],
  ]];

  // notifyMsgView
  [NSLayoutConstraint activateConstraints:@[
    [self.notifyMsgView.rightAnchor constraintEqualToAnchor:self.timeLabel.rightAnchor constant:(isNormalStyle ? 0.0 : -2.0)],
    [self.notifyMsgView.topAnchor constraintEqualToAnchor:self.timeLabel.bottomAnchor constant:notifyTopSpace],
    [self.notifyMsgView.widthAnchor constraintEqualToConstant:notifySize],
    [self.notifyMsgView.heightAnchor constraintEqualToConstant:notifySize],
  ]];

  if (!isNormalStyle) {
    [self.contentView addSubview:self.bottomLine];
    [NSLayoutConstraint activateConstraints:@[
      [self.bottomLine.leftAnchor constraintEqualToAnchor:self.titleLabel.leftAnchor],
      [self.bottomLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
      [self.bottomLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
      [self.bottomLine.heightAnchor constraintEqualToConstant:0.5],
    ]];
  }
}

#pragma mark - Data Binding

- (void)configureData:(NEConversationListModel *)model {
  if (!model) return;

  self.conversationType = model.type;
  NSString *conversationId = model.conversationId;
  NSString *targetId = [V2NIMConversationIdUtil conversationTargetId:conversationId];
  self.sessionId = targetId ?: @"";

  NSString *displayName = model.name.length > 0 ? model.name : (targetId ?: @"");
  self.titleLabel.attributedText = nil;
  self.titleLabel.text = displayName;

  // P2P 头像占位名优先使用机器人、AI 或好友资料；群头像使用会话短名。
  NSString *avatarName = displayName;
  if (model.type == V2NIM_CONVERSATION_TYPE_P2P) {
    avatarName = NEConversationAvatarName(targetId ?: @"", model.name);
  } else if (model.type == V2NIM_CONVERSATION_TYPE_TEAM) {
    avatarName = model.cloudConversation ? [model.cloudConversation shortName:2]
                                         : [model.localConversation shortName:2];
  }
  [self.headImageView configHeadData:model.avatar name:avatarName ?: @"" uid:targetId];

  // 免打扰
  self.notifyMsgView.hidden = !model.mute;

  // 最后一条消息预览
  NSMutableAttributedString *preview = nil;
  if (model.lastMessageContent.length > 0) {
    preview = [[NSMutableAttributedString alloc] initWithAttributedString:model.lastMessageContent];
  } else if (model.lastMessage) {
    NSString *text = [NEMessageUtil messageContentFromLastMessage:model.lastMessage] ?: @"";
    preview = [[NSMutableAttributedString alloc] initWithString:text];
  }

  BOOL hasLastMessage = model.lastMessageContent.length > 0 || model.lastMessage != nil;
  if (hasLastMessage &&
      [NEAtMessageManager.instance isAtCurrentUserConversationId:model.conversationId]) {
    if (!preview) {
      preview = [[NSMutableAttributedString alloc] init];
    }
    NSString *atString = NEConversationCellLocalizable(@"you_were_mentioned");
    NSAttributedString *prefix = [[NSAttributedString alloc] initWithString:atString];
    [preview insertAttributedString:prefix atIndex:0];
    [preview addAttribute:NSForegroundColorAttributeName
                    value:[UIColor colorWithRed:0.90 green:0.38 blue:0.36 alpha:1.0]
                    range:NSMakeRange(0, atString.length)];
    [preview addAttribute:NSFontAttributeName
                    value:self.subTitleLabel.font
                    range:NSMakeRange(0, preview.length)];
  }

  if (preview.length > 0) {
    self.subTitleLabel.attributedText = preview;
  } else {
    self.subTitleLabel.attributedText = nil;
    self.subTitleLabel.text = @"";
  }

  BOOL cachedRobot = model.type == V2NIM_CONVERSATION_TYPE_P2P &&
                     [[NEAIRobotManager shared] isRobot:self.sessionId];
  [self applyRobotConversation:cachedRobot];
  if (model.type == V2NIM_CONVERSATION_TYPE_P2P && self.sessionId.length > 0) {
    NSString *expectedSessionId = self.sessionId;
    __weak typeof(self) weakSelf = self;
    [[NEAIRobotManager shared] checkIfRobot:expectedSessionId completion:^(BOOL isRobot) {
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || ![self.sessionId isEqualToString:expectedSessionId]) return;
        [self applyRobotConversation:isRobot];
      });
    }];
  }

  // 未读数
  if (model.unreadCount <= 0) {
    self.redAngleView.hidden = YES;
    self.mutedUnreadDotView.hidden = YES;
    self.redAngleView.text = nil;
  } else {
    self.redAngleView.hidden = model.mute ? YES : NO;
    self.mutedUnreadDotView.hidden = model.mute ? NO : YES;
    if (model.unreadCount <= 99) {
      self.redAngleView.text = [NSString stringWithFormat:@"%ld", (long)model.unreadCount];
    } else {
      self.redAngleView.text = @"99+";
    }
  }

  NSTimeInterval ts = 0;
  if (model.lastMessage.messageRefer) {
    ts = model.lastMessage.messageRefer.createTime;
  }
  if (ts <= 0) {
    ts = model.updateTime;
  }

  if (ts > 0) {
    self.timeLabel.text = [NSString stringFromTimeInterval:ts];
    CGFloat measureWidth = CGRectGetWidth(self.bounds) > 0 ? CGRectGetWidth(self.bounds) : NEConstant.screenWidth;
    CGSize labelSize = [self.timeLabel.text boundingRectWithSize:CGSizeMake(measureWidth, CGFLOAT_MAX)
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:@{NSFontAttributeName: self.timeLabel.font}
                                                        context:nil].size;
    self.timeWidthConstraint.constant = labelSize.width + 2;
  } else {
    self.timeLabel.text = @"";
    self.timeWidthConstraint.constant = 0;
  }

  // 置顶背景
  ConversationProperties *props = ConversationUIConfig.shared.conversationProperties;
  if (model.stickTop) {
    if (props.itemStickTopBackground) {
      self.contentView.backgroundColor = props.itemStickTopBackground;
    } else {
      self.contentView.backgroundColor = NEConversationCellIsNormalStyle() ? [NEConstant hexRGB:0xF3F5F7] : [NEConstant hexRGB:0xEDEDED];
    }
  } else if (props.itemBackground) {
    self.contentView.backgroundColor = props.itemBackground;
  } else {
    self.contentView.backgroundColor = NEConversationCellIsNormalStyle() ? UIColor.whiteColor : UIColor.whiteColor;
  }
}

- (void)setOnline:(BOOL)online {
  self.requestedOnline = online;
  // 仅非 AI/机器人的 P2P 会话显示在线状态
  self.onlineView.hidden = ![IMKitConfigCenter shared].enableOnlineStatus ||
                           (self.conversationType != V2NIM_CONVERSATION_TYPE_P2P) ||
                           [[NEAIUserManager shared] isAIUser:self.sessionId] ||
                           self.robotConversation;
  self.onlineView.backgroundColor = online
    ? [UIColor colorWithRed:0.52 green:0.93 blue:0.52 alpha:1.0]  // #84ED85
    : [UIColor colorWithRed:0.83 green:0.85 blue:0.85 alpha:1.0]; // #D4D9DA
}

- (void)initSubviewsLayout {
  ConversationProperties *properties = ConversationUIConfig.shared.conversationProperties;
  if (properties.avatarType == NEConversationAvatarTypeCycle) {
    self.headImageView.layer.cornerRadius = NEConversationCellIsNormalStyle() ? 21.0 : 24.0;
  } else if (properties.avatarCornerRadius > 0) {
    self.headImageView.layer.cornerRadius = properties.avatarCornerRadius;
  } else {
    self.headImageView.layer.cornerRadius = NEConversationCellIsNormalStyle() ? 21.0 : 4.0;
  }
}

- (NSTimeInterval)timestampDescriptionForRecentSessionWithRecentSession:(NIMRecentSession *)recentSession {
  return recentSession.lastMessage ? recentSession.lastMessage.timestamp : 0;
}

- (NSString *)contentForConversationWithLastMessage:(V2NIMLastMessage *)lastMessage {
  return [NEMessageUtil messageContentFromLastMessage:lastMessage] ?: @"";
}

- (void)applyRobotConversation:(BOOL)isRobot {
  self.robotConversation = isRobot;
  self.robotIconView.hidden = !isRobot;
  [self setOnline:self.requestedOnline];
}

#pragma mark - Lazy Init

- (NEUserHeaderView *)headImageView {
  if (!_headImageView) {
    _headImageView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _headImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _headImageView.titleLabel.font = [UIFont systemFontOfSize:14];
    ConversationProperties *props = ConversationUIConfig.shared.conversationProperties;
    if (props.avatarType == NEConversationAvatarTypeCycle) {
      _headImageView.layer.cornerRadius = NEConversationCellIsNormalStyle() ? 21.0 : 24.0;
    } else if (props.avatarCornerRadius > 0) {
      _headImageView.layer.cornerRadius = props.avatarCornerRadius;
    } else {
      _headImageView.layer.cornerRadius = NEConversationCellIsNormalStyle() ? 21.0 : 4.0;
    }
    _headImageView.clipsToBounds = YES;
  }
  return _headImageView;
}

- (UIView *)onlineView {
  if (!_onlineView) {
    _onlineView = [[UIView alloc] init];
    _onlineView.translatesAutoresizingMaskIntoConstraints = NO;
    _onlineView.layer.cornerRadius = 6;
    _onlineView.backgroundColor = [UIColor colorWithRed:0.83 green:0.85 blue:0.85 alpha:1.0];
    _onlineView.hidden = YES;
  }
  return _onlineView;
}

- (RedAngleLabel *)redAngleView {
  if (!_redAngleView) {
    _redAngleView = [[RedAngleLabel alloc] init];
    _redAngleView.translatesAutoresizingMaskIntoConstraints = NO;
    _redAngleView.font = [UIFont systemFontOfSize:12];
    _redAngleView.textColor = [UIColor whiteColor];
    _redAngleView.text = @"99+";
    _redAngleView.backgroundColor = [UIColor colorWithRed:0.95 green:0.29 blue:0.34 alpha:1.0]; // #F24957
    _redAngleView.textInsets = UIEdgeInsetsMake(3, 7, 3, 7);
    _redAngleView.textAlignment = NSTextAlignmentCenter;
    _redAngleView.layer.cornerRadius = 9;
    _redAngleView.clipsToBounds = YES;
    _redAngleView.hidden = YES;
  }
  return _redAngleView;
}

- (UIView *)mutedUnreadDotView {
  if (!_mutedUnreadDotView) {
    _mutedUnreadDotView = [[UIView alloc] init];
    _mutedUnreadDotView.translatesAutoresizingMaskIntoConstraints = NO;
    _mutedUnreadDotView.backgroundColor = [UIColor colorWithRed:0.95 green:0.29 blue:0.34 alpha:1.0]; // #F24957
    _mutedUnreadDotView.layer.cornerRadius = 4;
    _mutedUnreadDotView.clipsToBounds = YES;
    _mutedUnreadDotView.hidden = YES;
    _mutedUnreadDotView.accessibilityIdentifier = @"id.mutedUnreadDot";
  }
  return _mutedUnreadDotView;
}

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    ConversationProperties *props = ConversationUIConfig.shared.conversationProperties;
    _titleLabel.textColor = props.itemTitleColor;
    CGFloat fontSize = props.itemTitleSize > 0 ? props.itemTitleSize : (NEConversationCellIsNormalStyle() ? 16.0 : 17.0);
    _titleLabel.font = [UIFont systemFontOfSize:fontSize];
    _titleLabel.numberOfLines = 1;
    _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [_titleLabel setContentHuggingPriority:UILayoutPriorityRequired
                                  forAxis:UILayoutConstraintAxisHorizontal];
    [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                 forAxis:UILayoutConstraintAxisHorizontal];
    _titleLabel.accessibilityIdentifier = @"id.name";
  }
  return _titleLabel;
}

- (UIStackView *)titleContentView {
  if (!_titleContentView) {
    _titleContentView = [[UIStackView alloc] initWithArrangedSubviews:@[self.titleLabel, self.robotIconView]];
    _titleContentView.translatesAutoresizingMaskIntoConstraints = NO;
    _titleContentView.axis = UILayoutConstraintAxisHorizontal;
    _titleContentView.alignment = UIStackViewAlignmentCenter;
    _titleContentView.spacing = 2;
    [_titleContentView setContentHuggingPriority:UILayoutPriorityRequired
                                         forAxis:UILayoutConstraintAxisHorizontal];
    [_titleContentView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                       forAxis:UILayoutConstraintAxisHorizontal];
  }
  return _titleContentView;
}

- (UIImageView *)robotIconView {
  if (!_robotIconView) {
    _robotIconView = [[UIImageView alloc] initWithImage:[NEConversationCellLoader() loadImage:@"robot_icon"]];
    _robotIconView.translatesAutoresizingMaskIntoConstraints = NO;
    _robotIconView.contentMode = UIViewContentModeScaleAspectFit;
    _robotIconView.hidden = YES;
    _robotIconView.accessibilityLabel = @"AI";
    [_robotIconView.widthAnchor constraintEqualToConstant:22].active = YES;
    [_robotIconView.heightAnchor constraintEqualToConstant:18].active = YES;
    [_robotIconView setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                    forAxis:UILayoutConstraintAxisHorizontal];
  }
  return _robotIconView;
}

- (UILabel *)subTitleLabel {
  if (!_subTitleLabel) {
    _subTitleLabel = [[UILabel alloc] init];
    _subTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    ConversationProperties *props = ConversationUIConfig.shared.conversationProperties;
    _subTitleLabel.textColor = props.itemContentColor;
    CGFloat fontSize = props.itemContentSize > 0 ? props.itemContentSize : 13;
    _subTitleLabel.font = [UIFont systemFontOfSize:fontSize];
    _subTitleLabel.accessibilityIdentifier = @"id.message";
  }
  return _subTitleLabel;
}

- (UILabel *)timeLabel {
  if (!_timeLabel) {
    _timeLabel = [[UILabel alloc] init];
    _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    ConversationProperties *props = ConversationUIConfig.shared.conversationProperties;
    _timeLabel.textColor = props.itemDateColor;
    CGFloat fontSize = props.itemDateSize > 0 ? props.itemDateSize : 12;
    _timeLabel.font = [UIFont systemFontOfSize:fontSize];
    _timeLabel.textAlignment = NSTextAlignmentRight;
    _timeLabel.accessibilityIdentifier = @"id.time";
  }
  return _timeLabel;
}

- (UIImageView *)notifyMsgView {
  if (!_notifyMsgView) {
    _notifyMsgView = [[UIImageView alloc] init];
    _notifyMsgView.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *muteImg = [NEConversationCellLoader() loadImage:@"noNeed_notify"];
    if (!muteImg) {
      // 兜底：灰色圆点
      _notifyMsgView.backgroundColor = [UIColor lightGrayColor];
      _notifyMsgView.layer.cornerRadius = 8;
      _notifyMsgView.clipsToBounds = YES;
    } else {
      _notifyMsgView.image = muteImg;
    }
    _notifyMsgView.hidden = YES;
    _notifyMsgView.accessibilityIdentifier = @"id.mute";
  }
  return _notifyMsgView;
}

- (UIView *)bottomLine {
  if (!_bottomLine) {
    _bottomLine = [[UIView alloc] init];
    _bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomLine.backgroundColor = [UIColor colorWithRed:0xD8/255.0 green:0xD8/255.0 blue:0xD8/255.0 alpha:1.0];
  }
  return _bottomLine;
}

@end

@implementation NEConversationListCell

- (void)setupSubviews {
  [super setupSubviews];
}

- (void)initSubviewsLayout {
  [super initSubviewsLayout];
}

- (void)configureData:(NEConversationListModel *)model {
  [super configureData:model];
}

@end

@implementation ConversationListCell

- (void)setupSubviews {
  [super setupSubviews];
}

- (void)initSubviewsLayout {
  [super initSubviewsLayout];
}

- (void)configureData:(NEConversationListModel *)model {
  [super configureData:model];
}

@end

@implementation FunConversationListCell

- (void)setupSubviews {
  [super setupSubviews];
}

- (void)initSubviewsLayout {
  [super initSubviewsLayout];
}

- (void)configureData:(NEConversationListModel *)model {
  [super configureData:model];
}

@end

@interface NEBaseStickTopCell ()
@property (nonatomic, strong) NEUserHeaderView *stickTopHeadImageView;
@property (nonatomic, strong) UILabel *stickTopNameLabel;
@end

@implementation NEBaseStickTopCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupStickTopCellUI];
  }
  return self;
}

- (void)setupStickTopCellUI {
  [self.contentView addSubview:self.stickTopHeadImageView];
  [self.contentView addSubview:self.stickTopNameLabel];
}

- (void)configAIUserCellData:(NEAIUserModel *)model {
  V2NIMAIUser *user = model.aiUser;
  if (user == nil) {
    return;
  }

  NSString *name = user.name.length > 0 ? user.name : (user.accountId ?: @"");
  NSString *shortName = name.length > 2 ? [name substringFromIndex:name.length - 2] : name;
  [self.stickTopHeadImageView configHeadData:user.avatar
                                       name:shortName
                                        uid:user.accountId ?: @""];
  self.stickTopNameLabel.text = name;
}

- (NEUserHeaderView *)stickTopHeadImageView {
  if (!_stickTopHeadImageView) {
    _stickTopHeadImageView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _stickTopHeadImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _stickTopHeadImageView.titleLabel.textColor = UIColor.whiteColor;
    _stickTopHeadImageView.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    _stickTopHeadImageView.layer.cornerRadius = 21.0;
    _stickTopHeadImageView.clipsToBounds = YES;
  }
  return _stickTopHeadImageView;
}

- (UILabel *)stickTopNameLabel {
  if (!_stickTopNameLabel) {
    _stickTopNameLabel = [[UILabel alloc] init];
    _stickTopNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _stickTopNameLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    _stickTopNameLabel.textColor = [UIColor ne_greyText];
    _stickTopNameLabel.accessibilityIdentifier = @"id.name";
    _stickTopNameLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _stickTopNameLabel;
}

@end

@implementation StickTopCell

- (void)setupStickTopCellUI {
  [super setupStickTopCellUI];
  [NSLayoutConstraint activateConstraints:@[
    [self.stickTopHeadImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [self.stickTopHeadImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:15.0],
    [self.stickTopHeadImageView.widthAnchor constraintEqualToConstant:42.0],
    [self.stickTopHeadImageView.heightAnchor constraintEqualToConstant:42.0],
    [self.stickTopNameLabel.topAnchor constraintEqualToAnchor:self.stickTopHeadImageView.bottomAnchor constant:6.0],
    [self.stickTopNameLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [self.stickTopNameLabel.widthAnchor constraintEqualToConstant:66.0],
  ]];
}

@end

@implementation FunStickTopCell

- (void)setupStickTopCellUI {
  [super setupStickTopCellUI];
  self.stickTopHeadImageView.layer.cornerRadius = 4.0;
  [NSLayoutConstraint activateConstraints:@[
    [self.stickTopHeadImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [self.stickTopHeadImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:15.0],
    [self.stickTopHeadImageView.widthAnchor constraintEqualToConstant:48.0],
    [self.stickTopHeadImageView.heightAnchor constraintEqualToConstant:48.0],
    [self.stickTopNameLabel.topAnchor constraintEqualToAnchor:self.stickTopHeadImageView.bottomAnchor constant:6.0],
    [self.stickTopNameLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [self.stickTopNameLabel.widthAnchor constraintEqualToConstant:66.0],
  ]];
}

@end
