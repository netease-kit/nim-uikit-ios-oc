// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "InputEmoticonTabView.h"
#import <NEChatKitOC/NEALog.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatKitOC/NEConstant.h>
#import "NEChatUIConstant.h"

static NSString *const kClassTag = @"InputEmoticonTabView";

@interface InputEmoticonTabView ()

@property (nonatomic, strong) NSMutableArray<UIButton *> *tabs;
@property (nonatomic, strong) NSMutableArray<UIView *> *seps;

@end

@implementation InputEmoticonTabView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _tabs = [NSMutableArray array];
    _seps = [NSMutableArray array];
    [self setUpSubViews];
  }
  return self;
}

- (UIButton *)sendButton {
  if (!_sendButton) {
    _sendButton = [[UIButton alloc] init];
    _sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_sendButton setTitle:chatLocalizable(@"send") forState:UIControlStateNormal];
    _sendButton.titleLabel.textColor = UIColor.whiteColor;
    _sendButton.backgroundColor = UIColor.ne_normalTheme;
    _sendButton.titleLabel.font = [NEConstant defaultTextFont:14];
    _sendButton.accessibilityIdentifier = @"id.emojiSend";
  }
  return _sendButton;
}

- (void)setUpSubViews {
  [self addSubview:self.sendButton];

  [NSLayoutConstraint activateConstraints:@[
    [self.sendButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-10],
    [self.sendButton.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    [self.sendButton.widthAnchor constraintEqualToConstant:60],
    [self.sendButton.heightAnchor constraintEqualToConstant:32],
  ]];
}

- (void)selectTabIndex:(NSInteger)index {
  for (NSInteger i = 0; i < (NSInteger)self.tabs.count; i++) {
    self.tabs[i].selected = (i == index);
  }
}

- (void)loadCatalogs:(nullable NSArray<NIMInputEmoticonCatalog *> *)emoticonCatalogs {
  for (UIButton *button in self.tabs) {
    [button removeFromSuperview];
  }
  for (UIView *view in self.seps) {
    [view removeFromSuperview];
  }
  [self.tabs removeAllObjects];
  [self.seps removeAllObjects];

  if (!emoticonCatalogs) {
    [NEALog errorLog:kClassTag desc:@"emoticonCatalogs is nil"];
    return;
  }

  for (NSUInteger i = 0; i < emoticonCatalogs.count; i++) {
    UIButton *button = [[UIButton alloc] init];
    [button addTarget:self action:@selector(onTouchTab:) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    [self addSubview:button];
    [self.tabs addObject:button];

    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.5, 35)];
    sep.backgroundColor = UIColor.ne_borderColor;
    [self.seps addObject:sep];
    [self addSubview:sep];
  }
}

- (void)onTouchTab:(UIButton *)sender {
  NSUInteger index = [self.tabs indexOfObject:sender];
  if (index != NSNotFound) {
    [self selectTabIndex:(NSInteger)index];
    if ([self.delegate respondsToSelector:@selector(tabView:didSelectTabIndex:)]) {
      [self.delegate tabView:self didSelectTabIndex:(NSInteger)index];
    }
  }
}

@end
