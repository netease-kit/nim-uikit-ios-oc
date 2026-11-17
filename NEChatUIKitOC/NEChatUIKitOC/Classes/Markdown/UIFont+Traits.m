// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UIFont+Traits.h"

@implementation UIFont (Traits)

- (nullable UIFont *)ne_fontWithTraits:(UIFontDescriptorSymbolicTraits)traits {
    UIFontDescriptor *descriptor = [self.fontDescriptor fontDescriptorWithSymbolicTraits:traits];
    if (!descriptor) return nil;
    return [UIFont fontWithDescriptor:descriptor size:0];
}

- (nullable UIFont *)ne_bold {
    return [self ne_fontWithTraits:UIFontDescriptorTraitBold];
}

- (nullable UIFont *)ne_italic {
    return [self ne_fontWithTraits:UIFontDescriptorTraitItalic];
}

@end
