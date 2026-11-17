// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "NEBaseChatLastReadPositionView.h"
#import "UIImage+Chat.h"
#if __has_include(<NEChatKit/NEChatKit-Swift.h>)
#import <NEChatKit/NEChatKit-Swift.h>
#endif
#import "NEChatUIConstant.h"

@interface NEBaseChatLastReadPositionView ()
@property (nonatomic, strong, readwrite) UIImageView *positionImageView;
@property (nonatomic, strong, readwrite) UILabel *messageCountLabel;
@property (nonatomic, strong, readwrite) UIActivityIndicatorView *activityIndicator;
@end

@implementation NEBaseChatLastReadPositionView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  _positionImageView = [[UIImageView alloc] initWithImage:[UIImage ne_imageNamed:@"chat_jump_to_new"]];
  _positionImageView.translatesAutoresizingMaskIntoConstraints = NO;
  _positionImageView.contentMode = UIViewContentModeScaleAspectFit;
  _positionImageView.transform = CGAffineTransformMakeRotation(M_PI);
  _messageCountLabel = [[UILabel alloc] init];
  _messageCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _messageCountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
  _messageCountLabel.adjustsFontForContentSizeCategory = YES;
  _messageCountLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  [_messageCountLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
  _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
  _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
  _activityIndicator.hidesWhenStopped = YES;
  self.accentColor = UIColor.ne_defaultPrimaryColor;

  self.backgroundColor = UIColor.whiteColor;
  self.layer.cornerRadius = 20;
  self.layer.borderWidth = 1;
  self.layer.borderColor = [UIColor.blackColor colorWithAlphaComponent:0.08].CGColor;
  self.clipsToBounds = YES;
  [self addSubview:_positionImageView];
  [self addSubview:_messageCountLabel];
  [self addSubview:_activityIndicator];
  [NSLayoutConstraint activateConstraints:@[
    [_positionImageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
    [_positionImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [_positionImageView.widthAnchor constraintEqualToConstant:16],
    [_positionImageView.heightAnchor constraintEqualToConstant:16],
    [_messageCountLabel.leadingAnchor constraintEqualToAnchor:_positionImageView.trailingAnchor constant:4],
    [_messageCountLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-30],
    [_messageCountLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [_activityIndicator.centerXAnchor constraintEqualToAnchor:_positionImageView.centerXAnchor],
    [_activityIndicator.centerYAnchor constraintEqualToAnchor:_positionImageView.centerYAnchor],
  ]];
  self.isAccessibilityElement = YES;
  self.accessibilityTraits = UIAccessibilityTraitButton;
  self.accessibilityIdentifier = @"id.chatLastReadPosition";
  self.accessibilityHint = chatLocalizable(@"last_read_position_accessibility_hint");
}

- (void)setAccentColor:(UIColor *)accentColor {
  _accentColor = accentColor ?: UIColor.ne_defaultPrimaryColor;
  self.positionImageView.tintColor = _accentColor;
  self.messageCountLabel.textColor = _accentColor;
  self.activityIndicator.color = _accentColor;
}

- (void)updateWithSnapshot:(NELastReadPositionSnapshot *)snapshot locating:(BOOL)locating {
  if (!snapshot) {
    self.messageCountLabel.text = nil;
    [self.activityIndicator stopAnimating];
    return;
  }
  NSString *text = snapshot.isOverflow
    ? chatLocalizable(@"last_read_position_overflow")
    : [NSString stringWithFormat:chatLocalizable(@"last_read_position_count"), snapshot.displayCount];
  self.messageCountLabel.text = text;
  self.accessibilityLabel = text;
  self.userInteractionEnabled = !locating;
  self.accessibilityTraits = locating ? (UIAccessibilityTraitButton | UIAccessibilityTraitNotEnabled) : UIAccessibilityTraitButton;
  self.positionImageView.hidden = locating;
  if (locating) {
    [self.activityIndicator startAnimating];
  } else {
    [self.activityIndicator stopAnimating];
  }
}

@end
