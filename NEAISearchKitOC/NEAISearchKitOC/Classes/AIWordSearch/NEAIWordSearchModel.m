// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAIWordSearchModel.h"
#import "NEAISearchConstant.h"
#import <NEChatKit/NSString+NECommon.h>

@interface NEAIWordSearchModel ()

- (void)measure;

@end

@implementation NEAIWordSearchModel

- (instancetype)initWithContent:(NSAttributedString *)content {
  return [self initWithContent:content maxTextWidth:0];
}

- (instancetype)initWithContent:(NSAttributedString *)content
                   maxTextWidth:(CGFloat)maxTextWidth {
  self = [super init];
  if (self) {
    _content = content;
    // NEAISearchTextMaxSize 只作为首次布局前的整窗宽度回退，不再作为测量基准。
    _maxTextWidth = maxTextWidth > 0 ? maxTextWidth : NEAISearchTextMaxSize().width;
    [self measure];
  }
  return self;
}

- (void)updateMaxTextWidth:(CGFloat)width {
  if (width <= 0 || fabs(width - _maxTextWidth) <= 0.5) {
    return;
  }
  _maxTextWidth = width;
  [self measure];
}

/// 按当前宽度测量行高；宽度至少为 1，避免异常值导致无限换行。
- (void)measure {
  CGSize textSize =
      [NSAttributedString ne_getRealLabelSize:self.content
                                          font:NEAISearchTextFont()
                                          size:CGSizeMake(MAX(1.0, _maxTextWidth), CGFLOAT_MAX)
                                 numberOfLines:0];
  _height = ceil(textSize.height);
}

@end
