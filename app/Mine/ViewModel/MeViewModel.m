// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MeViewModel.h"
#import "AppKey.h"
#import <NEChatKitOC/IMKitConfigCenter.h>

@interface MeViewModel ()
@property (nonatomic, strong, readwrite) NSArray<NSDictionary<NSString *, NSString *> *> *mineData;
@end

@implementation MeViewModel

- (void)getData {
  NSMutableArray<NSDictionary<NSString *, NSString *> *> *mineData = [@[
    @{ NELocalizable(@"setting") : @"mine_setting" },
    @{ NELocalizable(@"about_yunxin") : @"about_yunxin" },
  ] mutableCopy];

  if ([IMKitConfigCenter shared].enableCollectionMessage) {
    [mineData insertObject:@{ NELocalizable(@"mine_collection") : @"mine_collection" } atIndex:1];
  }

  self.mineData = [mineData copy];
}

@end
