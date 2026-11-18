// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTextViewController.h"
#import "FunChatUIColor.h"

@implementation FunTextViewController

- (instancetype)initWithTitle:(nullable NSString *)title body:(nullable NSAttributedString *)body {
    self = [super initWithTitle:title body:body];
    return self;
}

- (void)setupUI {
    [super setupUI];
    self.view.backgroundColor = [UIColor funChatBackgroundColor];
}

- (void)didTapTel:(NSURL *)url {
    [self showCustomBottomTelAction:url];
}

- (void)didTapMailto:(NSURL *)url {
    [self showCustomBottomMailAction:url];
}

@end
