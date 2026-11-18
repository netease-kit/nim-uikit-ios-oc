// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NIMInputEmoticonButton.h"
#import <NEChatKit/NEALog.h>
#import <NEChatKit/NEConstant.h>
#import "UIImage+Chat.h"

static NSString *const kClassTag = @"NIMInputEmoticonButton";

@implementation NIMInputEmoticonButton

+ (instancetype)iconButtonWithData:(NIMInputEmoticon *)data
                         catalogID:(NSString *)catalogID
                          delegate:(id<NIMInputEmoticonButtonDelegate>)delegate {
  NIMInputEmoticonButton *iconButton = [[NIMInputEmoticonButton alloc] init];
  [iconButton addTarget:iconButton action:@selector(onIconSelected:) forControlEvents:UIControlEventTouchUpInside];
  iconButton.emotionData = data;
  iconButton.catalogID = catalogID;
  iconButton.userInteractionEnabled = YES;
  iconButton.exclusiveTouch = YES;
  iconButton.contentMode = UIViewContentModeScaleToFill;
  iconButton.delegate = delegate;
  iconButton.accessibilityIdentifier = @"id.emoji";
  iconButton.accessibilityValue = data.tag;

  switch (data.type) {
    case NIMEmoticonTypeUnicode:
      [iconButton setTitle:data.unicode forState:UIControlStateNormal];
      [iconButton setTitle:data.unicode forState:UIControlStateHighlighted];
      iconButton.titleLabel.font = [NEConstant defaultTextFont:32];
      break;
    default: {
      UIImage *image = [UIImage ne_bundleImage:data.fileName ?: @""];
      [iconButton setImage:image forState:UIControlStateNormal];
      [iconButton setImage:image forState:UIControlStateHighlighted];
      break;
    }
  }
  return iconButton;
}

- (void)onIconSelected:(NIMInputEmoticonButton *)sender {
  if (!self.emotionData || !self.catalogID) {
    [NEALog errorLog:kClassTag desc:@"emotionData or catalogID maybe nil"];
    return;
  }
  [self.delegate selectedEmoticon:self.emotionData catalogID:self.catalogID];
}

@end
