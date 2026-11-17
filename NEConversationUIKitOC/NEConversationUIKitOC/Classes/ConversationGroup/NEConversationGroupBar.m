// Copyright (c) 2026 NetEase, Inc. All rights reserved.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "NEConversationGroupBar.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <objc/message.h>

static NECommonLoader *NEGroupBarLoader(void) {
  static NECommonLoader *loader;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    loader = [[NECommonLoader alloc] initWithClass:[NEConversationGroupBar class]];
  });
  return loader;
}

static BOOL NEGroupBarIsNormalStyle(void) {
  Class styleManagerClass = NSClassFromString(@"NEStyleManager");
  SEL instanceSelector = NSSelectorFromString(@"instance");
  SEL isNormalStyleSelector = NSSelectorFromString(@"isNormalStyle");
  if (styleManagerClass && [styleManagerClass respondsToSelector:instanceSelector]) {
    id manager = ((id (*)(id, SEL))objc_msgSend)(styleManagerClass, instanceSelector);
    if (manager && [manager respondsToSelector:isNormalStyleSelector]) {
      return ((BOOL (*)(id, SEL))objc_msgSend)(manager, isNormalStyleSelector);
    }
  }
  return YES;
}
#import "NEConversationGroupManager.h"

@interface NEConversationGroupBar ()
@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) UIStackView *stackView;
@property(nonatomic, strong) UIButton *manageButton;
@property(nonatomic, copy) NSArray<NEConversationGroupItem *> *groups;
@property(nonatomic, weak, nullable) NEConversationGroupItem *selectedGroup;
@end

@implementation NEConversationGroupBar
- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _stackView = [[UIStackView alloc] init];
    _stackView.translatesAutoresizingMaskIntoConstraints = NO;
    _stackView.axis = UILayoutConstraintAxisHorizontal;
    _stackView.spacing = 6;
    _stackView.alignment = UIStackViewAlignmentCenter;
    [_scrollView addSubview:_stackView];
    _manageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _manageButton.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *manageImage = [NEGroupBarLoader() loadImage:@"conversation_group_manager"];
    if (!manageImage) {
      manageImage = [UIImage systemImageNamed:@"slider.horizontal.3"];
    }
    [_manageButton setImage:manageImage forState:UIControlStateNormal];
    [_manageButton addTarget:self action:@selector(manageAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_scrollView];
    [self addSubview:_manageButton];
    [NSLayoutConstraint activateConstraints:@[
      [_manageButton.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-16],
      [_manageButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
      [_manageButton.widthAnchor constraintEqualToConstant:32],
      [_manageButton.heightAnchor constraintEqualToConstant:32],
      [_scrollView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:12],
      [_scrollView.topAnchor constraintEqualToAnchor:self.topAnchor],
      [_scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
      [_scrollView.rightAnchor constraintEqualToAnchor:_manageButton.leftAnchor constant:-8],
      [_stackView.leftAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.leftAnchor],
      [_stackView.rightAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.rightAnchor],
      [_stackView.topAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.topAnchor],
      [_stackView.bottomAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.bottomAnchor],
      [_stackView.heightAnchor constraintEqualToAnchor:_scrollView.frameLayoutGuide.heightAnchor],
    ]];
    [self applyStyle];
  }
  return self;
}

- (void)reloadGroups:(NSArray<NEConversationGroupItem *> *)groups
       selectedGroup:(nullable NEConversationGroupItem *)selectedGroup {
  self.groups = [groups isKindOfClass:[NSArray class]] ? groups : @[];
  self.selectedGroup = selectedGroup;
  for (UIView *view in self.stackView.arrangedSubviews) {
    [self.stackView removeArrangedSubview:view];
    [view removeFromSuperview];
  }
  [self applyStyle];
  [self.groups enumerateObjectsUsingBlock:^(NEConversationGroupItem *item, NSUInteger idx, BOOL *stop) {
    if (![item isKindOfClass:[NEConversationGroupItem class]]) return;
    BOOL selected = item.groupId.length > 0 && [item.groupId isEqualToString:selectedGroup.groupId];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.tag = idx;
    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    button.titleLabel.lineBreakMode = NSLineBreakByClipping;
    [button setTitle:item.displayName forState:UIControlStateNormal];
    [button setTitleColor:selected ? [self primaryColor] : UIColor.ne_darkText forState:UIControlStateNormal];
    button.backgroundColor = selected ? [self selectedBackgroundColor] : UIColor.clearColor;
    button.layer.cornerRadius = 4;
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 8);
    [button addTarget:self action:@selector(groupAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.stackView addArrangedSubview:button];
    [NSLayoutConstraint activateConstraints:@[
      [button.heightAnchor constraintEqualToConstant:36],
      [button.widthAnchor constraintGreaterThanOrEqualToConstant:44],
    ]];
  }];
}

- (void)applyStyle {
  self.backgroundColor = NEGroupBarIsNormalStyle() ? UIColor.whiteColor : [UIColor colorWithRed:0xED / 255.0 green:0xED / 255.0 blue:0xED / 255.0 alpha:1];
  self.scrollView.backgroundColor = self.backgroundColor;
  UIImage *manageImage = [NEGroupBarLoader() loadImage:@"conversation_group_manager"];
  if (!manageImage) {
    manageImage = [UIImage systemImageNamed:@"slider.horizontal.3"];
  }
  [self.manageButton setImage:manageImage forState:UIControlStateNormal];
  self.manageButton.accessibilityLabel = [NEGroupBarLoader() localizable:@"conversation_group_setting_title"];
}

- (UIColor *)primaryColor {
  return NEGroupBarIsNormalStyle() ? UIColor.ne_defaultPrimaryColor : UIColor.ne_funTheme;
}

- (UIColor *)selectedBackgroundColor {
  NSUInteger value = NEGroupBarIsNormalStyle() ? 0xEAF2FF : 0xEAF8ED;
  return [UIColor colorWithRed:((value >> 16) & 0xFF) / 255.0
                         green:((value >> 8) & 0xFF) / 255.0
                          blue:(value & 0xFF) / 255.0
                         alpha:1];
}

- (void)groupAction:(UIButton *)sender {
  if (sender.tag < 0 || sender.tag >= self.groups.count) return;
  [self.delegate conversationGroupBarDidSelect:self.groups[sender.tag]];
}
- (void)manageAction { [self.delegate conversationGroupBarDidRequestManagement]; }
@end
