// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AIChatCellModel.h"

@implementation AIChatCellModel

- (instancetype)initWithTagTitle:(nullable NSString *)tagTitle
                   tagTitleColor:(nullable UIColor *)tagTitleColor
         tagTitleBackgroundColor:(nullable UIColor *)tagTitleBackgroundColor
                    contentTitle:(nullable NSString *)contentTitle {
    self = [super init];
    if (self) {
        _tagTitle = tagTitle;
        _tagTitleColor = tagTitleColor;
        _tagTitleBackgroundColor = tagTitleBackgroundColor;
        _contentTitle = contentTitle;
    }
    return self;
}

@end
