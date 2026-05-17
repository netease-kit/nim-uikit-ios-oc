// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunFusionContactSelectedController.h"
#import "FunFusionContactSelectedCell.h"

@implementation FunFusionContactSelectedController

- (void)viewDidLoad {
  self.fusionRegisterCellDic = @{@0: [FunFusionContactSelectedCell class]};
  [super viewDidLoad];
  [self.fusionEmptyView setEmptyImageName:@"fun_user_empty"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 64;
}

@end
