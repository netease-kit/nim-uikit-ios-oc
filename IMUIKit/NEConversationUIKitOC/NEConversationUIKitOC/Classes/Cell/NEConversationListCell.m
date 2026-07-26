// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationListCell.h"
#import "NEConversationListModel.h"
#import "NEAtMessageManager.h"
#import "NEMessageUtil.h"
#import "ConversationUIConfig.h"
@import NECommonUIKitOC;
#import <NEChatKit/NEAIUserManager.h>
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NIMSDK/NIMSDK.h>
#import <objc/message.h>

/// 屏幕间距
static CGFloat const kScreenInterval = 20.0;

static NECommonLoader *NEConversationCellLoader(void) {
  static NECommonLoader *loader = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    loader = [[NECommonLoader alloc] initWithClass:[NEConversationListCell class]];
  });
  return loader;
}

static NSString *NEConversationCellLocalizable(NSString *key) {
  return [NEConversationCellLoader() localizable:key];
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

@interface NEConversationListCell ()
@property (nonatomic, assign) NSInteger conversationType;
@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, strong) UIView *bottomLine;
@end

@implementation NEConversationListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor clearColor];
    [self setupSubviews];
  }
  return self;
}

- (void)setupSubviews {
  [self.contentView addSubview:self.headImageView];
  [self.contentView addSubview:self.onlineView];
  [self.contentView addSubview:self.redAngleView];
  [self.contentView addSubview:self.titleLabel];
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

  // titleLabel
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.headImageView.rightAnchor constant:12],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.timeLabel.leftAnchor constant:-5],
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:titleTop],
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

  // 头像 & 名称
  NSString *name = model.name.length > 0 ? model.name : (targetId ?: @"");
  self.titleLabel.text = name;

  // 头像：URL 加载 + 文字占位 + uid 哈希背景色
  [self.headImageView configHeadData:model.avatar name:name uid:targetId];

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

  if (preview.length > 0 &&
      [[NEAtMessageManager sharedManager] isAtCurrentUserConversationId:model.conversationId]) {
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

  // 未读数
  if (model.unreadCount <= 0) {
    self.redAngleView.hidden = YES;
  } else {
    self.redAngleView.hidden = model.mute ? YES : NO;
    if (model.unreadCount <= 99) {
      self.redAngleView.text = [NSString stringWithFormat:@"%ld", (long)model.unreadCount];
    } else {
      self.redAngleView.text = @"99+";
    }
  }

  // 时间：V2NIMLastMessage 用 messageRefer.createTime
  NSTimeInterval ts = 0;
  if (model.lastMessage) {
    id messageRefer = [model.lastMessage valueForKey:@"messageRefer"];
    if (messageRefer) {
      ts = [[messageRefer valueForKey:@"createTime"] doubleValue];
    }
    if (ts <= 0) {
      // 兜底：直接取 createTime（部分 SDK 版本 LastMessage 直接有此字段）
      ts = [[model.lastMessage valueForKey:@"createTime"] doubleValue];
    }
  }
  if (ts <= 0) {
    // 最终兜底：使用 updateTime（秒级）
    ts = (NSTimeInterval)model.sortOrder / 1000.0;
  }

  if (ts > 0) {
    self.timeLabel.text = [self _timeStringFromInterval:ts];
    CGSize labelSize = [self.timeLabel.text boundingRectWithSize:CGSizeMake(UIScreen.mainScreen.bounds.size.width, CGFLOAT_MAX)
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
      self.contentView.backgroundColor = NEConversationCellIsNormalStyle() ? [NEConstant hexRGB:0xF6F8FC] : UIColor.whiteColor;
    }
  } else if (props.itemBackground) {
    self.contentView.backgroundColor = props.itemBackground;
  } else {
    self.contentView.backgroundColor = NEConversationCellIsNormalStyle() ? UIColor.whiteColor : UIColor.whiteColor;
  }
}

- (void)setOnline:(BOOL)online {
  // 仅非 AI 的 P2P 会话显示在线状态
  self.onlineView.hidden = ![IMKitConfigCenter shared].enableOnlineStatus ||
                           (self.conversationType != V2NIM_CONVERSATION_TYPE_P2P) ||
                           [[NEAIUserManager shared] isAIUser:self.sessionId];
  self.onlineView.backgroundColor = online
    ? [UIColor colorWithRed:0.52 green:0.93 blue:0.52 alpha:1.0]  // #84ED85
    : [UIColor colorWithRed:0.83 green:0.85 blue:0.85 alpha:1.0]; // #D4D9DA
}

#pragma mark - Private: 时间格式化

- (NSString *)_timeStringFromInterval:(NSTimeInterval)interval {
  // interval 可能是秒或毫秒
  NSDate *date;
  if (interval > 1e12) {
    date = [NSDate dateWithTimeIntervalSince1970:interval / 1000.0];
  } else {
    date = [NSDate dateWithTimeIntervalSince1970:interval];
  }

  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *todayComps = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[NSDate date]];
  NSDateComponents *dateComps = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];

  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  if (todayComps.year == dateComps.year &&
      todayComps.month == dateComps.month &&
      todayComps.day == dateComps.day) {
    formatter.dateFormat = @"HH:mm";
  } else if (todayComps.year == dateComps.year) {
    formatter.dateFormat = @"MM/dd";
  } else {
    formatter.dateFormat = @"yyyy/MM/dd";
  }
  return [formatter stringFromDate:date];
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

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    ConversationProperties *props = ConversationUIConfig.shared.conversationProperties;
    _titleLabel.textColor = props.itemTitleColor;
    CGFloat fontSize = props.itemTitleSize > 0 ? props.itemTitleSize : (NEConversationCellIsNormalStyle() ? 16.0 : 17.0);
    _titleLabel.font = [UIFont systemFontOfSize:fontSize];
    _titleLabel.accessibilityIdentifier = @"id.name";
  }
  return _titleLabel;
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
    _bottomLine.backgroundColor = [UIColor colorWithRed:0xF2/255.0 green:0xF5/255.0 blue:0xFA/255.0 alpha:1.0];
  }
  return _bottomLine;
}

@end
