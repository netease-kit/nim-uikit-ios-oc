// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FusionContactSelectedController.h"
#import "FusionContactSelectedCell.h"

@implementation FusionContactSelectedController

- (void)viewDidLoad {
  self.fusionRegisterCellDic = @{@0: [FusionContactSelectedCell class]};
  [super viewDidLoad];
}

@end
