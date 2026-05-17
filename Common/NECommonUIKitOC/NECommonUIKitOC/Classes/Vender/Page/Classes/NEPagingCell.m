// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingCell.h"

@implementation NEPagingCell

- (void)setPagingItem:(id<NEPagingItem>)pagingItem
             selected:(BOOL)selected
              options:(NEPagingOptions *)options {
  [NSException raise:NSInternalInconsistencyException format:@"setPagingItem:selected:options: not implemented"];
}

@end
