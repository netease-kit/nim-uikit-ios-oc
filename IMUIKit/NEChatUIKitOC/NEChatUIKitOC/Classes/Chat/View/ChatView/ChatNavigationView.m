// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatNavigationView.h"
#import "UIImage+Chat.h"

@implementation ChatNavigationView

- (UIImageView *)earImageView {
    if (!_earImageView) {
        _earImageView = [[UIImageView alloc] init];
        _earImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _earImageView.image = [UIImage ne_imageNamed:@"op_earpiece"];
        _earImageView.hidden = YES;
    }
    return _earImageView;
}

- (void)setupUI {
    [super setupUI];
    [self.titleBarView addSubview:self.earImageView];
    [NSLayoutConstraint activateConstraints:@[
        [self.earImageView.leftAnchor constraintEqualToAnchor:self.navTitle.rightAnchor],
        [self.earImageView.centerYAnchor constraintEqualToAnchor:self.navTitle.centerYAnchor],
    ]];
}

- (void)setHandsetMode:(BOOL)ear {
    self.earImageView.hidden = ear;
}

@end
