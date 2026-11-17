// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "InputEmoticonTabView.h"
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import "NEChatUIConstant.h"
#import "UIImage+Chat.h"

static CGFloat const NIMInputEmoticonTabWidth = 52.0;

@interface NIMInputEmoticonTabButton : UIButton

@property (nonatomic, strong) UIView *selectionBackgroundView;
@property (nonatomic, assign) BOOL showsSelectionBackground;

- (void)updateSelectionBackgroundWithAccentColor:(UIColor *)accentColor;

@end

@implementation NIMInputEmoticonTabButton

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _selectionBackgroundView = [[UIView alloc] init];
    _selectionBackgroundView.userInteractionEnabled = NO;
    _selectionBackgroundView.layer.cornerRadius = 7;
    _selectionBackgroundView.accessibilityIdentifier = @"id.emoticonTabSelectionBackground";
    [self insertSubview:_selectionBackgroundView atIndex:0];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self sendSubviewToBack:self.selectionBackgroundView];
  self.selectionBackgroundView.frame = CGRectMake((self.bounds.size.width - 34) / 2,
                                                   (self.bounds.size.height - 34) / 2,
                                                   34,
                                                   34);
}

- (void)updateSelectionBackgroundWithAccentColor:(UIColor *)accentColor {
  self.selectionBackgroundView.backgroundColor = self.selected && self.showsSelectionBackground
      ? [accentColor colorWithAlphaComponent:0.14]
      : UIColor.clearColor;
}

@end

@interface InputEmoticonTabView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray<NIMInputEmoticonTabButton *> *tabs;
@property (nonatomic, strong) NSMutableArray<UIView *> *separators;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) UIColor *accentColor;

@end

@implementation InputEmoticonTabView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setUpSubViews];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setUpSubViews];
  }
  return self;
}

- (void)setUpSubViews {
  _tabs = [NSMutableArray array];
  _separators = [NSMutableArray array];
  _selectedIndex = 0;
  _accentColor = UIColor.ne_defaultPrimaryColor;
  [self addSubview:self.scrollView];
  [self addSubview:self.sendButton];

  [NSLayoutConstraint activateConstraints:@[
    [self.scrollView.topAnchor constraintEqualToAnchor:self.topAnchor],
    [self.scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    [self.scrollView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.scrollView.rightAnchor constraintEqualToAnchor:self.sendButton.leftAnchor],
    [self.sendButton.topAnchor constraintEqualToAnchor:self.topAnchor],
    [self.sendButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    [self.sendButton.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    [self.sendButton.widthAnchor constraintEqualToConstant:60],
  ]];
}

- (UIScrollView *)scrollView {
  if (!_scrollView) {
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.scrollsToTop = NO;
  }
  return _scrollView;
}

- (UIButton *)sendButton {
  if (!_sendButton) {
    _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_sendButton setTitle:chatLocalizable(@"send") forState:UIControlStateNormal];
    [_sendButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _sendButton.backgroundColor = self.accentColor;
    _sendButton.titleLabel.font = [NEConstant defaultTextFont:14];
    _sendButton.accessibilityIdentifier = @"id.emojiSend";
  }
  return _sendButton;
}

- (void)setAccentColor:(UIColor *)accentColor {
  _accentColor = accentColor ?: UIColor.ne_defaultPrimaryColor;
  self.sendButton.backgroundColor = _accentColor;
  [self updateTabPresentations];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  for (NSInteger index = 0; index < (NSInteger)self.tabs.count; index++) {
    self.tabs[index].frame = CGRectMake((CGFloat)index * NIMInputEmoticonTabWidth,
                                        0,
                                        NIMInputEmoticonTabWidth,
                                        self.bounds.size.height);
    self.separators[index].frame = CGRectMake((CGFloat)(index + 1) * NIMInputEmoticonTabWidth - 0.5,
                                              0,
                                              0.5,
                                              self.bounds.size.height);
  }
  self.scrollView.contentSize = CGSizeMake((CGFloat)self.tabs.count * NIMInputEmoticonTabWidth,
                                           self.bounds.size.height);
  [self ensureSelectedTabVisible:NO];
}

- (void)selectTabIndex:(NSInteger)index {
  if (index < 0 || index >= (NSInteger)self.tabs.count) {
    return;
  }
  self.selectedIndex = index;
  for (NSInteger tabIndex = 0; tabIndex < (NSInteger)self.tabs.count; tabIndex++) {
    self.tabs[tabIndex].selected = tabIndex == index;
  }
  [self updateTabPresentations];
  [self ensureSelectedTabVisible:YES];
}

- (void)loadItemsWithNormalIcons:(NSArray<UIImage *> *)normalIcons
                   selectedIcons:(NSArray<UIImage *> *)selectedIcons
        selectionBackgroundFlags:(NSArray<NSNumber *> *)selectionBackgroundFlags
             accessibilityValues:(NSArray<NSString *> *)accessibilityValues {
  for (UIButton *button in self.tabs) {
    [button removeFromSuperview];
  }
  for (UIView *separator in self.separators) {
    [separator removeFromSuperview];
  }
  [self.tabs removeAllObjects];
  [self.separators removeAllObjects];

  NSUInteger count = MIN(normalIcons.count, selectedIcons.count);
  count = MIN(count, selectionBackgroundFlags.count);
  count = MIN(count, accessibilityValues.count);
  for (NSUInteger index = 0; index < count; index++) {
    NIMInputEmoticonTabButton *button = [[NIMInputEmoticonTabButton alloc] initWithFrame:CGRectZero];
    button.tag = (NSInteger)index;
    [button setImage:normalIcons[index] forState:UIControlStateNormal];
    [button setImage:selectedIcons[index] forState:UIControlStateSelected];
    button.showsSelectionBackground = selectionBackgroundFlags[index].boolValue;
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [button addTarget:self action:@selector(onTouchTab:) forControlEvents:UIControlEventTouchUpInside];
    button.accessibilityIdentifier = @"id.emoticonTab";
    button.accessibilityValue = accessibilityValues[index];
    [self.scrollView addSubview:button];
    [self.tabs addObject:button];

    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = UIColor.ne_borderColor;
    [self.scrollView addSubview:separator];
    [self.separators addObject:separator];
  }

  self.selectedIndex = MIN(self.selectedIndex, MAX((NSInteger)count - 1, 0));
  [self setNeedsLayout];
  [self layoutIfNeeded];
  if (count > 0) {
    [self selectTabIndex:self.selectedIndex];
  }
}

- (void)loadCatalogs:(nullable NSArray<NIMInputEmoticonCatalog *> *)emoticonCatalogs {
  NSMutableArray<UIImage *> *normalIcons = [NSMutableArray array];
  NSMutableArray<UIImage *> *selectedIcons = [NSMutableArray array];
  NSMutableArray<NSNumber *> *selectionBackgroundFlags = [NSMutableArray array];
  NSMutableArray<NSString *> *accessibilityValues = [NSMutableArray array];
  for (NIMInputEmoticonCatalog *catalog in emoticonCatalogs ?: @[]) {
    [normalIcons addObject:[UIImage ne_bundleImage:catalog.iconPressed ?: @""] ?: [[UIImage alloc] init]];
    [selectedIcons addObject:[UIImage ne_bundleImage:catalog.iconPressed ?: @""] ?: [[UIImage alloc] init]];
    [selectionBackgroundFlags addObject:@YES];
    [accessibilityValues addObject:catalog.catalogID ?: @""];
  }
  [self loadItemsWithNormalIcons:normalIcons
                   selectedIcons:selectedIcons
        selectionBackgroundFlags:selectionBackgroundFlags
              accessibilityValues:accessibilityValues];
}

- (void)setSendButtonVisible:(BOOL)visible {
  self.sendButton.hidden = !visible;
}

- (void)updateTabPresentations {
  for (NIMInputEmoticonTabButton *button in self.tabs) {
    [button updateSelectionBackgroundWithAccentColor:self.accentColor];
  }
}

- (void)ensureSelectedTabVisible:(BOOL)animated {
  if (self.selectedIndex < 0 || self.selectedIndex >= (NSInteger)self.tabs.count) {
    return;
  }
  [self.scrollView scrollRectToVisible:self.tabs[self.selectedIndex].frame animated:animated];
}

- (void)onTouchTab:(UIButton *)sender {
  NSInteger index = sender.tag;
  if (index < 0 || index >= (NSInteger)self.tabs.count) {
    return;
  }
  [self selectTabIndex:index];
  if ([self.delegate respondsToSelector:@selector(tabView:didSelectTabIndex:)]) {
    [self.delegate tabView:self didSelectTabIndex:index];
  }
}

@end
