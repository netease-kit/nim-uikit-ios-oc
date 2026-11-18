// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamDetailItem.h"

@implementation TeamDetailItem

- (instancetype)initWithTitle:(NSString *)title
                  detailTitle:(NSString *)detailTitle
                        value:(BOOL)value
                    textColor:(UIColor *)textColor
                    cellClass:(Class)cellClass {
  self = [super init];
  if (self) {
    _title = [title copy] ?: @"";
    _detailTitle = [detailTitle copy];
    _value = value;
    _textColor = textColor ?: [UIColor darkTextColor];
    _cellClass = cellClass ?: [UITableViewCell class];
  }
  return self;
}

@end
