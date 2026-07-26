// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomChatCell.h"
#import <NIMSDK/V2NIMMessage.h>
#import <NEChatUIKitOC/MessageContentModel.h>
#import <NEChatUIKitOC/MessageCustomModel.h>

@implementation CustomChatCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = UIColor.lightGrayColor;
    _testLabel = [[UILabel alloc] init];
    _testLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_testLabel];
    [NSLayoutConstraint activateConstraints:@[
      [_testLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
      [_testLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    ]];
    _testLabel.font = [UIFont systemFontOfSize:14];
    _testLabel.textColor = UIColor.blackColor;
  }
  return self;
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
  (void)isSend;
  if ([model isKindOfClass:[MessageCustomModel class]]) {
    self.testLabel.text = model.message.text;
  }
}

@end
