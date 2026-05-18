// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatNewMessageView.h"
#import "UIImage+Chat.h"
#import <NEChatKitOC/UIColor+NECommon.h>

@implementation FunChatNewMessageView

- (void)setupUI {
    [super setupUI];
    self.jumpDownImageView.image = [UIImage ne_imageNamed:@"fun_chat_jump_to_new"];
    self.messageCountLabel.textColor = [UIColor ne_funTheme];
}

@end
