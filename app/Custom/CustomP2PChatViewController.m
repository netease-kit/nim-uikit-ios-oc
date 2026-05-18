// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomP2PChatViewController.h"
#import "CustomChatCell.h"
#import "CustomView.h"
#import <NEChatKitOC/NECommonUtil.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NEChatUIKitOC/MessageCustomModel.h>
#import <NEChatUIKitOC/MessageUtils.h>
#import <NEChatUIKitOC/NEChatUIKitClient.h>
#import <NEChatUIKitOC/NEMoreItemModel.h>
#import <NEChatKitOC/OperationItem.h>

static NSInteger const kCustomMessageType = 20;

@interface CustomP2PChatViewController ()
@property (nonatomic, strong) CustomView *customTopViewInner;
@property (nonatomic, strong) CustomView *customBottomViewInner;
@end

@implementation CustomP2PChatViewController

- (void)viewDidLoad {
  [[NEChatUIKitClient instance] regsiterCustomCell:@{@"20" : [CustomChatCell class]}];
  [self customByOverride];
  [super viewDidLoad];
  [self customMessage];
}

- (void)customByOverride {
  [self.customTopViewInner.button setTitle:@"通过重写方式添加" forState:UIControlStateNormal];
  [self.bodyTopView addSubview:self.customTopViewInner];
  self.bodyTopView.backgroundColor = UIColor.yellowColor;
  self.bodyTopViewHeight = 80;

  [self.customBottomViewInner.button setTitle:@"通过重写方式添加" forState:UIControlStateNormal];
  [self.bodyBottomView addSubview:self.customBottomViewInner];
  self.bodyBottomView.backgroundColor = UIColor.yellowColor;
  self.bodyBottomViewHeight = 60;

  self.chatInputView.textviewLeftConstraint.constant = 100;
  self.chatInputView.textviewRightConstraint.constant = -100;
  self.operationCellFilter = @[ @(OperationTypeDelete), @(OperationTypeCopy) ];
  [self customBottomBar];

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NEMoreItemModel *itemNew = [[NEMoreItemModel alloc] init];
    itemNew.customImage = [UIImage imageNamed:@"mine_collection"];
    itemNew.title = @"新增";
    itemNew.action = ^(UIViewController *viewController, __unused NEMoreItemModel *model) {
      [viewController.view ne_makeToast:@"【更多】区域功能自定义点击事件"];
    };
    [[[NEChatUIKitClient instance] moreAction] addObject:itemNew];

    NSMutableArray<NEMoreItemModel *> *items = [NEChatUIKitClient instance].moreAction;
    NSIndexSet *indexes = [items indexesOfObjectsPassingTest:^BOOL(NEMoreItemModel *obj,
                                                                   NSUInteger idx,
                                                                   BOOL *stop) {
      (void)idx;
      (void)stop;
      if (obj.type == NEMoreActionTypeRtc) {
        obj.customImage = [UIImage imageNamed:@"mine_setting"];
        obj.title = @"覆盖";
        obj.action = ^(UIViewController *viewController, __unused NEMoreItemModel *model) {
          [viewController.view ne_makeToast:@"【更多】区域功能自定义点击事件"];
        };
      }
      return obj.type == NEMoreActionTypeFile;
    }];
    if (indexes.count > 0) {
      [items removeObjectsAtIndexes:indexes];
    }
  });
}

- (void)customMessage {
  UIButton *testButton = [UIButton buttonWithType:UIButtonTypeCustom];
  testButton.translatesAutoresizingMaskIntoConstraints = NO;
  [testButton setTitle:@"发送自定义消息" forState:UIControlStateNormal];
  testButton.titleLabel.font = [UIFont systemFontOfSize:12];
  testButton.backgroundColor = UIColor.redColor;
  [testButton addTarget:self action:@selector(sendCustomButton) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:testButton];
  [NSLayoutConstraint activateConstraints:@[
    [testButton.widthAnchor constraintEqualToConstant:120],
    [testButton.heightAnchor constraintEqualToConstant:40],
    [testButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [testButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
  ]];
}

- (void)getSessionInfo:(NSString *)sessionId completion:(void (^)(void))completion {
  [super getSessionInfo:sessionId completion:^{
    self.title = @"小易助手";
    if (completion) {
      completion();
    }
  }];
}

- (void)getMessageModel:(id<MessageModel>)model {
  [super getMessageModel:model];
  if (model.type == MessageTypeCustom && model.customType == kCustomMessageType) {
    model.contentSize = CGSizeMake(20, 20);
    model.height = 50;
  }
}

- (void)customBottomBar {
  NSArray<UIView *> *subviews = [self.chatInputView.stackView.arrangedSubviews copy];
  for (UIView *view in subviews) {
    [self.chatInputView.stackView removeArrangedSubview:view];
    [view removeFromSuperview];
  }

  NSArray<NSString *> *titles = @[ @"表情", @"语音", @"照片", @"更多" ];
  for (NSInteger index = 0; index < titles.count; index++) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.tag = index;
    [button setTitle:titles[index] forState:UIControlStateNormal];
    [button setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.chatInputView.stackView addArrangedSubview:button];
  }
}

- (void)buttonEvent:(UIButton *)button {
  if (button.tag == 0) {
    [self layoutInputView:self.bottomExanpndHeight scrollToBottom:YES];
    [self.chatInputView addEmojiView];
  } else if (button.tag == 1) {
    [self layoutInputView:self.bottomExanpndHeight scrollToBottom:YES];
    [self.chatInputView addRecordView];
  } else if (button.tag == 2) {
    [self openPhoto];
  } else if (button.tag == 3) {
    [self layoutInputView:self.bottomExanpndHeight scrollToBottom:YES];
    [self.chatInputView addMoreActionView];
  }
}

- (void)sendCustomButton {
  NSDictionary *data = @{@"type" : @(kCustomMessageType), @"customHeight" : @(100)};
  NSString *rawAttachment = [NECommonUtil getJSONStringFromDictionary:data];
  NSString *text = [NSString stringWithFormat:@"this is a custom message, create time:%f",
                                              NSDate.timeIntervalSinceReferenceDate];
  [self.viewModel sendCustomMessage:text
                      rawAttachment:rawAttachment
                     conversationId:nil
                         completion:^(NSError *error) {
                           if (error) {
                             [self.view ne_makeToast:error.localizedDescription ?: @""];
                           }
                         }];
}

- (CustomView *)customTopViewInner {
  if (!_customTopViewInner) {
    _customTopViewInner =
        [[CustomView alloc] initWithFrame:CGRectMake(0, 10, NEConstant.screenWidth, 40)];
    _customTopViewInner.backgroundColor = UIColor.blueColor;
  }
  return _customTopViewInner;
}

- (CustomView *)customBottomViewInner {
  if (!_customBottomViewInner) {
    _customBottomViewInner =
        [[CustomView alloc] initWithFrame:CGRectMake(0, 10, NEConstant.screenWidth, 40)];
    _customBottomViewInner.backgroundColor = UIColor.greenColor;
  }
  return _customBottomViewInner;
}

@end
