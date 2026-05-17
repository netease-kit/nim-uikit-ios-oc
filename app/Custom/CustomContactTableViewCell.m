// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomContactTableViewCell.h"
#import <NECommonUIKitOC/NEUserHeaderView.h>
#import <NEContactUIKitOC/ContactInfo.h>
#import <NEContactUIKitOC/NEBaseContactViewCell.h>

@interface CustomContactTableViewCell ()
@property (nonatomic, strong) UIImageView *redDotView;
@end

@implementation CustomContactTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    _redDotView = [[UIImageView alloc] init];
    _redDotView.translatesAutoresizingMaskIntoConstraints = NO;
    _redDotView.backgroundColor = UIColor.redColor;
    _redDotView.layer.cornerRadius = 6;
    _redDotView.hidden = YES;
    _redDotView.clipsToBounds = YES;
    [self.contentView addSubview:_redDotView];
    [NSLayoutConstraint activateConstraints:@[
      [_redDotView.rightAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor],
      [_redDotView.topAnchor constraintEqualToAnchor:self.userHeaderView.topAnchor],
      [_redDotView.widthAnchor constraintEqualToConstant:12],
      [_redDotView.heightAnchor constraintEqualToConstant:12],
    ]];
  }
  return self;
}

- (void)setModel:(ContactInfo *)model {
  [super setModel:model];
  self.redDotView.hidden = NO;
}

@end
