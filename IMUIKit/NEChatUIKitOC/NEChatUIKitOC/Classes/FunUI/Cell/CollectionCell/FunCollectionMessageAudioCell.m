// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunCollectionMessageAudioCell.h"
#import "ChatUIConfig.h"
#import "UIImage+Chat.h"

@implementation FunCollectionMessageAudioCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  return self;
}

- (void)setupCommonUI {
  [super setupCommonUI];
  [self setFunStyle];
  UIImage *image = [ChatUIConfig shared].messageProperties.receiveMessageBgImage ?: [UIImage ne_imageNamed:@"fun_pin_message_audio_bg"];
  UIEdgeInsets capInsets = [ChatUIConfig shared].messageProperties.backgroundImageCapInsets;
  if (capInsets.top != 0 || capInsets.left != 0 || capInsets.bottom != 0 || capInsets.right != 0) {
    self.bubbleImage.image = [image resizableImageWithCapInsets:capInsets];
  } else {
    self.bubbleImage.image = image;
    self.bubbleImage.contentMode = UIViewContentModeScaleAspectFill;
  }
}

@end
