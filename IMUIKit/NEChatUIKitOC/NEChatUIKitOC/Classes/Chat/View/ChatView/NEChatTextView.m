// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatTextView.h"

@implementation NEChatTextView

- (void)layoutSubviews {
    [super layoutSubviews];
    [self removeScrollIndicators];
}

- (void)addSubview:(UIView *)view {
    NSString *className = NSStringFromClass([view class]);
    if (![className containsString:@"ScrollIndicator"]) {
        [super addSubview:view];
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return NO;
}

- (BOOL)shouldChangeTextInRange:(UITextRange *)range replacementText:(NSString *)text {
    return NO;
}

- (void)removeScrollIndicators {
    for (UIView *subview in self.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        if ([className containsString:@"ScrollIndicator"]) {
            [subview removeFromSuperview];
        }
    }
}

@end
