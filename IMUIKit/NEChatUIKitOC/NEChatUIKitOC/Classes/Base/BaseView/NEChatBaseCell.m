// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatBaseCell.h"

@implementation NEChatBaseCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  return self;
}

- (void)uploadProgress:(NSUInteger)progress {}
- (void)setModel:(MessageContentModel *)model {}
- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {}

@end