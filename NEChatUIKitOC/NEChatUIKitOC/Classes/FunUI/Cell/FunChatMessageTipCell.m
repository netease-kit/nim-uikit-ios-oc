// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageTipCell.h"
#import "FunChatUIColor.h"

@implementation FunChatMessageTipCell

- (void)commonUI {
    [super commonUI];
    self.contentLabel.font = [UIFont systemFontOfSize:14];
    self.contentLabel.textColor = [UIColor funRecordAudioTextColor];
}

@end
