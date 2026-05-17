// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UserItem.h"

@implementation UserItem

- (instancetype)init {
  self = [super init];
  if (self) {
    _title = @"";
    _detailTitle = nil;
    _value = NO;
    _textColor = [UIColor darkTextColor];
    _cellClass = [UITableViewCell class];
  }
  return self;
}

- (instancetype)initWithTitle:(NSString *)title
                  detailTitle:(nullable NSString *)detailTitle
                        value:(BOOL)value
                    textColor:(UIColor *)textColor
                    cellClass:(Class)cellClass {
  self = [super init];
  if (self) {
    _title = title;
    _detailTitle = detailTitle;
    _value = value;
    _textColor = textColor;
    _cellClass = cellClass;
  }
  return self;
}

@end
