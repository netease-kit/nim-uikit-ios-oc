// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import "TextWithRightArrowCell.h"
#import <NEChatKitOC/NECommonLoader.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation TextWithRightArrowCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.arrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.arrowImageView.contentMode = UIViewContentModeCenter;
    [self.contentView addSubview:self.arrowImageView];
    [NSLayoutConstraint activateConstraints:@[
      [self.arrowImageView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
      [self.arrowImageView.widthAnchor constraintEqualToConstant:20],
      [self.arrowImageView.heightAnchor constraintEqualToConstant:20],
      [self.arrowImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    ]];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)setModelWithModel:(UserItem *)model {
  [super setModelWithModel:model];
}

- (UIImageView *)arrowImageView {
  if (!_arrowImageView) {
    _arrowImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
  }
  return _arrowImageView;
}

@end
