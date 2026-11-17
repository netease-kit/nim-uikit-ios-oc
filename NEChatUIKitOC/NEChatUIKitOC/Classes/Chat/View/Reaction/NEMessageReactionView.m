// Copyright (c) 2026 NetEase, Inc. All rights reserved.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "NEMessageReactionView.h"
#import "UIImage+Chat.h"
#import "NEChatUIConstant.h"
#import <NEChatKit/UIColor+NECommon.h>

#if __has_include(<NEChatKit/NEChatKit-Swift.h>)
#import <NEChatKit/NEChatKit-Swift.h>
#endif

static const CGFloat kReactionItemHeight = 26.0;
static const CGFloat kReactionItemSpacing = 4.0;
static const CGFloat kReactionAddWidth = 26.0;
static const CGFloat kReactionHorizontalInset = 10.0;

@interface NEMessageReactionCapsuleButton : UIButton
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *countLabel;
@end

@implementation NEMessageReactionCapsuleButton

- (instancetype)initWithGroup:(NEMessageReactionGroup *)group {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _iconView = [[UIImageView alloc] initWithImage:chatLoadImage(group.emoji.resourceName)];
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    _iconView.userInteractionEnabled = NO;
    _countLabel = [[UILabel alloc] init];
    _countLabel.font = [UIFont systemFontOfSize:12 weight:group.isMine ? UIFontWeightSemibold : UIFontWeightMedium];
    _countLabel.textColor = group.isMine ? UIColor.ne_defaultPrimaryColor : UIColor.ne_greyText;
    _countLabel.textAlignment = NSTextAlignmentRight;
    _countLabel.adjustsFontSizeToFitWidth = YES;
    _countLabel.minimumScaleFactor = 0.8;
    _countLabel.userInteractionEnabled = NO;
    _countLabel.text = [self countText:group.count];
    [self addSubview:_iconView];
    [self addSubview:_countLabel];
  }
  return self;
}

- (NSString *)countText:(NSInteger)count {
  if (count > 999999) return [NSString stringWithFormat:@"%ldm", (long)(count / 1000000)];
  if (count > 999) return [NSString stringWithFormat:@"%ldk", (long)(count / 1000)];
  return [NSString stringWithFormat:@"%ld", (long)count];
}

- (CGSize)sizeThatFits:(CGSize)size {
  CGFloat countWidth = ceil([self.countLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, 15)].width);
  return CGSizeMake(kReactionHorizontalInset * 2.0 + 20.0 + 6.0 + countWidth,
                    kReactionItemHeight);
}

- (void)layoutSubviews {
  [super layoutSubviews];
  CGFloat countWidth = ceil([self.countLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, 15)].width);
  CGFloat iconWidth = self.iconView.image ? 20.0 : 0.0;
  CGFloat spacing = iconWidth > 0 ? 6.0 : 0.0;
  CGFloat iconX = iconWidth > 0 ? kReactionHorizontalInset : 0.0;
  self.iconView.hidden = iconWidth == 0;
  self.iconView.frame = CGRectMake(iconX, (CGRectGetHeight(self.bounds) - 20.0) / 2.0, iconWidth, 20.0);
  CGFloat labelX = iconX + iconWidth + spacing;
  self.countLabel.frame = CGRectMake(labelX, CGRectGetHeight(self.bounds) - 17.0,
                                     MAX(8.0, MIN(countWidth, CGRectGetWidth(self.bounds) - labelX - kReactionHorizontalInset)), 15.0);
}

@end

@interface NEMessageReactionView ()
@property (nonatomic, strong) NSArray<NEMessageReactionGroup *> *groups;
@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, assign) BOOL outgoing;
@property (nonatomic, assign, readwrite) BOOL enabledForDisplay;
@end

@implementation NEMessageReactionView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) [self setupAddButton];
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) [self setupAddButton];
  return self;
}

- (void)setupAddButton {
  _groups = @[];
  _buttons = [NSMutableArray array];
  self.backgroundColor = UIColor.clearColor;
  _addButton = [UIButton buttonWithType:UIButtonTypeSystem];
  _addButton.contentEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5);
  [_addButton setImage:chatLoadImage(@"reaction_add_emoji") forState:UIControlStateNormal];
  _addButton.layer.cornerRadius = kReactionItemHeight / 2.0;
  _addButton.layer.borderWidth = 0.5;
  _addButton.accessibilityLabel = @"Add reaction";
  _addButton.accessibilityIdentifier = @"id.messageReaction.add";
  [_addButton addTarget:self action:@selector(addTapped) forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:_addButton];
}

- (void)configureWithGroups:(NSArray<NEMessageReactionGroup *> *)groups
                    enabled:(BOOL)enabled
                 isOutgoing:(BOOL)isOutgoing {
  _groups = [groups copy] ?: @[];
  _outgoing = isOutgoing;
  for (UIButton *button in self.buttons) [button removeFromSuperview];
  [self.buttons removeAllObjects];
  UIColor *backgroundColor = [self reactionBackgroundColor];
  for (NEMessageReactionGroup *group in _groups) {
    NEMessageReactionCapsuleButton *button = [[NEMessageReactionCapsuleButton alloc] initWithGroup:group];
    button.tag = group.index;
    button.layer.cornerRadius = kReactionItemHeight / 2.0;
    button.layer.borderWidth = 0.5;
    button.layer.borderColor = UIColor.ne_chatReactionBorder.CGColor;
    button.backgroundColor = backgroundColor;
    button.accessibilityLabel = [NSString stringWithFormat:@"%@, %ld", group.emoji.accessibilityDescription, (long)group.count];
    button.accessibilityIdentifier = [NSString stringWithFormat:@"id.messageReaction.%ld", (long)group.index];
    [button addTarget:self action:@selector(groupTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    [self.buttons addObject:button];
  }
  self.hidden = !enabled || _groups.count == 0;
  self.enabledForDisplay = enabled && _groups.count > 0;
  self.addButton.hidden = !self.enabledForDisplay;
  self.addButton.layer.borderColor = UIColor.ne_chatReactionBorder.CGColor;
  self.addButton.backgroundColor = backgroundColor;
  [self invalidateIntrinsicContentSize];
  [self setNeedsLayout];
}

- (CGSize)intrinsicContentSize {
  if (self.hidden) return CGSizeMake(UIViewNoIntrinsicMetric, 0);
  CGFloat width = CGRectGetWidth(self.bounds) > 1 ? CGRectGetWidth(self.bounds) : self.naturalWidth;
  return CGSizeMake(self.naturalWidth, [self heightForWidth:width]);
}

- (CGFloat)naturalWidth {
  CGFloat width = 0;
  for (UIButton *button in [self visibleButtons]) width += [self buttonWidth:button maxWidth:CGFLOAT_MAX] + kReactionItemSpacing;
  return MAX(0, width - (width > 0 ? kReactionItemSpacing : 0));
}

- (CGFloat)layoutWidthForMaxWidth:(CGFloat)maxWidth {
  if (self.hidden || maxWidth <= 0) return 0;
  CGFloat available = MAX(maxWidth, 1);
  CGFloat x = 0;
  CGFloat widest = 0;
  for (UIButton *button in [self visibleButtons]) {
    CGFloat width = MIN([self buttonWidth:button maxWidth:available], available);
    if (x > 0 && x + width > available) {
      widest = MAX(widest, x - kReactionItemSpacing);
      x = 0;
    }
    x += width + kReactionItemSpacing;
  }
  return MIN(MAX(widest, MAX(0, x - kReactionItemSpacing)), available);
}

- (CGFloat)heightForWidth:(CGFloat)width {
  NSArray<UIButton *> *buttons = [self visibleButtons];
  if (buttons.count == 0) return 0;
  CGFloat available = MAX(width, 1);
  CGFloat x = 0;
  NSInteger rows = 1;
  for (UIButton *button in buttons) {
    CGFloat itemWidth = MIN([self buttonWidth:button maxWidth:available], available);
    if (x > 0 && x + itemWidth > available) {
      rows += 1;
      x = 0;
    }
    x += itemWidth + kReactionItemSpacing;
  }
  return rows * kReactionItemHeight + MAX(0, rows - 1) * kReactionItemSpacing;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  CGFloat available = MAX(CGRectGetWidth(self.bounds), 1);
  CGFloat x = 0;
  CGFloat y = 0;
  for (UIButton *button in [self visibleButtons]) {
    CGFloat width = MIN([self buttonWidth:button maxWidth:available], available);
    if (x > 0 && x + width > available) {
      x = 0;
      y += kReactionItemHeight + kReactionItemSpacing;
    }
    button.frame = CGRectMake(x, y, width, kReactionItemHeight);
    x += width + kReactionItemSpacing;
  }
}

- (NSArray<UIButton *> *)visibleButtons {
  NSMutableArray<UIButton *> *result = [NSMutableArray array];
  if (!self.addButton.hidden) [result addObject:self.addButton];
  for (UIButton *button in self.buttons) if (!button.hidden) [result addObject:button];
  return result;
}

- (CGFloat)buttonWidth:(UIButton *)button maxWidth:(CGFloat)maxWidth {
  if (button == self.addButton) return kReactionAddWidth;
  return [button sizeThatFits:CGSizeMake(maxWidth, kReactionItemHeight)].width;
}

- (UIColor *)reactionBackgroundColor {
  return self.outgoing ? UIColor.ne_chatReactionSendBackground : UIColor.ne_chatReactionReceiveBackground;
}

- (void)groupTapped:(UIButton *)sender {
  [self.delegate reactionView:self didSelectIndex:sender.tag];
}

- (void)addTapped {
  [self.delegate reactionView:self didSelectIndex:0];
}

@end
