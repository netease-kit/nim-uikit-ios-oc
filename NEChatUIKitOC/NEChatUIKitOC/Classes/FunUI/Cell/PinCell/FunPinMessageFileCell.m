// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunPinMessageFileCell.h"

@implementation FunPinMessageFileCell

- (void)setupUI {
    [super setupUI];
    self.backLeftConstraint.constant = 0;
    self.backRightConstraint.constant = 0;
    self.backView.layer.cornerRadius = 0;
    self.headerView.layer.cornerRadius = 4.0;
}

@end
