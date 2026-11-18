// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAIWordSearchTextCell.h"
#import "NEAISearchConstant.h"
#import "NEAIWordSearchModel.h"
#import <NEChatKit/UIColor+NECommon.h>

@interface NEAIWordSearchTextCell ()

@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIView *bottomLineView;

@end

@implementation NEAIWordSearchTextCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self commonUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self commonUI];
  }
  return self;
}

- (void)commonUI {
  self.userInteractionEnabled = NO;
  [self.contentView addSubview:self.contentLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.contentLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16.0],
    [self.contentLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20.0],
    [self.contentLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20.0],
    [self.contentLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-16.0],
  ]];

  [self.contentView addSubview:self.bottomLineView];
  [NSLayoutConstraint activateConstraints:@[
    [self.bottomLineView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
    [self.bottomLineView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.bottomLineView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.bottomLineView.heightAnchor constraintEqualToConstant:4.0],
  ]];
}

- (void)showBottomLine:(BOOL)show {
  self.bottomLineView.hidden = !show;
}

- (void)setModel:(NEAIWordSearchModel *)model {
  self.contentLabel.attributedText = model.content;
}

- (UILabel *)contentLabel {
  if (!_contentLabel) {
    _contentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _contentLabel.font = NEAISearchTextFont();
    _contentLabel.textColor = UIColor.ne_darkText;
    _contentLabel.numberOfLines = 0;
    _contentLabel.textAlignment = NSTextAlignmentJustified;
    _contentLabel.accessibilityIdentifier = @"id.content";
  }
  return _contentLabel;
}

- (UIView *)bottomLineView {
  if (!_bottomLineView) {
    _bottomLineView = [[UIView alloc] initWithFrame:CGRectZero];
    _bottomLineView.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomLineView.backgroundColor = [UIColor ne_colorWithHexString:@"#EDEDED"];
  }
  return _bottomLineView;
}

@end
