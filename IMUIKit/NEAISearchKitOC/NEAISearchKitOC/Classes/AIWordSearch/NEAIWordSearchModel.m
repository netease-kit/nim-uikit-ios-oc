// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAIWordSearchModel.h"
#import "NEAISearchConstant.h"
#import <NEChatKitOC/NSString+NECommon.h>

@implementation NEAIWordSearchModel

- (instancetype)initWithContent:(NSAttributedString *)content {
  self = [super init];
  if (self) {
    _content = content;
    CGSize textSize = [NSAttributedString ne_getRealLabelSize:content
                                                         font:NEAISearchTextFont()
                                                         size:NEAISearchTextMaxSize()
                                                numberOfLines:0];
    _height = ceil(textSize.height);
  }
  return self;
}

@end
