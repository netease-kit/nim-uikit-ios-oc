// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationPopListView.h"
#import <NEChatKitOC/NEAppLanguageUtil.h>
#import <NEChatKitOC/NEConstant.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NEButtonExtension.h>
#import <NECommonUIKitOC/NEConfigManager.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>

@interface NEConversationBasePopListView ()

@property (nonatomic, strong) UIView *shadowView;
@property (nonatomic, strong) UIView *popView;
@property (nonatomic, strong, nullable) UIView *triangleView;

- (void)setupUI;
- (void)itemClick:(UIButton *)sender;

@end

@implementation NEConversationPopListItem

- (instancetype)init {
  self = [super init];
  if (self) {
    _showNameColor = [NEConstant hexRGB:0x333333];
  }
  return self;
}

@end

@implementation NEConversationBasePopListView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _buttonHeight = 32.0;
    _popViewWidth = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? 180.0 : 122.0;
    _popViewRadius = 8.0;
    NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
    _topConstant = (useSystemNavValue && useSystemNavValue.boolValue) ? 10.0 : NEConstant.navigationAndStatusHeight;
    _shadowView = [[UIView alloc] initWithFrame:CGRectZero];
    _shadowView.translatesAutoresizingMaskIntoConstraints = NO;
    _shadowView.backgroundColor = UIColor.clearColor;
    _shadowView.clipsToBounds = NO;
    _shadowView.layer.shadowOffset = CGSizeMake(0, 4);
    _shadowView.layer.shadowColor = UIColor.ne_operationBorderColor.CGColor;
    _shadowView.layer.shadowOpacity = 0.25;
    _shadowView.layer.shadowRadius = 7.0;

    _popView = [[UIView alloc] initWithFrame:CGRectZero];
    _popView.translatesAutoresizingMaskIntoConstraints = NO;
    _popView.clipsToBounds = YES;
    _popView.layer.cornerRadius = _popViewRadius;
  }
  return self;
}

- (void)setItemDatas:(NSArray<NEConversationPopListItem *> *)itemDatas {
  _itemDatas = [itemDatas copy];
  self.popViewHeight = self.itemDatas.count * self.buttonHeight + 16.0;
  [self setupUI];
}

- (void)setupUI {
  self.backgroundColor = UIColor.clearColor;
  [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  self.triangleView = nil;

  [self addSubview:self.shadowView];
  [NSLayoutConstraint activateConstraints:@[
    [self.shadowView.widthAnchor constraintEqualToConstant:self.popViewWidth],
    [self.shadowView.heightAnchor constraintEqualToConstant:self.popViewHeight],
  ]];

  [self.shadowView addSubview:self.popView];
  [NSLayoutConstraint activateConstraints:@[
    [self.popView.topAnchor constraintEqualToAnchor:self.shadowView.topAnchor],
    [self.popView.leftAnchor constraintEqualToAnchor:self.shadowView.leftAnchor],
    [self.popView.rightAnchor constraintEqualToAnchor:self.shadowView.rightAnchor],
    [self.popView.bottomAnchor constraintEqualToAnchor:self.shadowView.bottomAnchor],
  ]];

  [self.popView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  CGFloat offset = 8.0;
  [self.itemDatas enumerateObjectsUsingBlock:^(NEConversationPopListItem * _Nonnull item, NSUInteger idx, __unused BOOL * _Nonnull stop) {
    UIButton *itemButton = [UIButton buttonWithType:UIButtonTypeCustom];
    itemButton.translatesAutoresizingMaskIntoConstraints = NO;
    itemButton.tag = idx;
    [itemButton setTitle:item.showName forState:UIControlStateNormal];
    [itemButton setTitleColor:item.showNameColor forState:UIControlStateNormal];
    itemButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
    itemButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    if (item.image) {
      [itemButton setImage:item.image forState:UIControlStateNormal];
      [itemButton layoutButtonImageWithStyle:NEButtonStyleLeft space:6.0];
    }
    [itemButton addTarget:self action:@selector(itemClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.popView addSubview:itemButton];
    [NSLayoutConstraint activateConstraints:@[
      [itemButton.topAnchor constraintEqualToAnchor:self.popView.topAnchor constant:offset + idx * self.buttonHeight],
      [itemButton.leftAnchor constraintEqualToAnchor:self.popView.leftAnchor constant:15.0],
      [itemButton.rightAnchor constraintEqualToAnchor:self.popView.rightAnchor constant:-4.0],
      [itemButton.heightAnchor constraintEqualToConstant:self.buttonHeight],
    ]];
  }];
}

- (void)itemClick:(UIButton *)sender {
  NSInteger index = sender.tag;
  if (index >= 0 && index < (NSInteger)self.itemDatas.count) {
    dispatch_block_t completion = self.itemDatas[index].completion;
    if (completion) {
      completion();
    }
  }
  [self removeSelf];
}

- (void)removeSelf {
  [self removeFromSuperview];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [super touchesBegan:touches withEvent:event];
  [self removeSelf];
}

@end

@implementation NEConversationNormalPopListView

- (void)setupUI {
  [super setupUI];
  [NSLayoutConstraint activateConstraints:@[
    [self.shadowView.topAnchor constraintEqualToAnchor:self.topAnchor constant:self.topConstant - 10.0],
    [self.shadowView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-20.0],
  ]];
  self.popView.backgroundColor = UIColor.whiteColor;
}

@end

@implementation NEConversationFunPopListView

- (void)setupUI {
  [super setupUI];
  [NSLayoutConstraint activateConstraints:@[
    [self.shadowView.topAnchor constraintEqualToAnchor:self.topAnchor constant:self.topConstant],
    [self.shadowView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-8.0],
  ]];
  UIColor *bgColor = [NEConstant hexRGB:0x4C4C4C];
  self.popView.backgroundColor = bgColor;

  UIView *triangleView = [[UIView alloc] initWithFrame:CGRectZero];
  triangleView.translatesAutoresizingMaskIntoConstraints = NO;
  triangleView.backgroundColor = bgColor;
  triangleView.transform = CGAffineTransformMakeRotation((CGFloat)M_PI_4);
  self.triangleView = triangleView;
  [self insertSubview:triangleView aboveSubview:self.shadowView];
  [NSLayoutConstraint activateConstraints:@[
    [triangleView.widthAnchor constraintEqualToConstant:11.0],
    [triangleView.heightAnchor constraintEqualToConstant:11.0],
    [triangleView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-25.0],
    [triangleView.topAnchor constraintEqualToAnchor:self.popView.topAnchor constant:-5.0],
  ]];
}

@end
