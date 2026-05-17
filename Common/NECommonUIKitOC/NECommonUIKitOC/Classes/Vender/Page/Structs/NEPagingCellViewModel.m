// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingCellViewModel.h"
#import "NEPagingOptions.h"

@implementation NEPagingTitleCellViewModel

- (instancetype)initWithTitle:(NSString *)title
                     selected:(BOOL)selected
                      options:(NEPagingOptions *)options {
  self = [super init];
  if (self) {
    _title = [title copy];
    _font = options.font;
    _selectedFont = options.selectedFont;
    _textColor = options.textColor;
    _selectedTextColor = options.selectedTextColor;
    _backgroundColor = options.backgroundColor;
    _selectedBackgroundColor = options.selectedBackgroundColor;
    _selected = selected;
    _labelSpacing = options.menuItemLabelSpacing;
  }
  return self;
}

@end
