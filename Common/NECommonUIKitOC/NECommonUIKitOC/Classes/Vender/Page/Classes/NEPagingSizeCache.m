// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingSizeCache.h"
#import "NEPagingItem.h"
#import "NEPagingOptions.h"

@interface NEPagingSizeCache ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *sizeCache;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *selectedSizeCache;

@end

@implementation NEPagingSizeCache

- (instancetype)initWithOptions:(NEPagingOptions *)options {
  self = [super init];
  if (self) {
    _options = options;
    _sizeCache = [NSMutableDictionary dictionary];
    _selectedSizeCache = [NSMutableDictionary dictionary];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationDidEnterBackground:)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didReceiveMemoryWarning:)
                                               name:UIApplicationDidReceiveMemoryWarningNotification
                                             object:nil];
  }
  return self;
}

- (void)dealloc {
  [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)clear {
  [self.sizeCache removeAllObjects];
  [self.selectedSizeCache removeAllObjects];
}

- (CGFloat)itemSizeForPagingItem:(id<NEPagingItem>)pagingItem {
  NSNumber *key = @(pagingItem.identifier);
  NSNumber *cached = self.sizeCache[key];
  if (cached) {
    return cached.doubleValue;
  }
  CGFloat size = self.sizeForPagingItem ? self.sizeForPagingItem(pagingItem, NO) : self.options.estimatedItemWidth;
  self.sizeCache[key] = @(size);
  return size;
}

- (CGFloat)itemWidthSelectedForPagingItem:(id<NEPagingItem>)pagingItem {
  NSNumber *key = @(pagingItem.identifier);
  NSNumber *cached = self.selectedSizeCache[key];
  if (cached) {
    return cached.doubleValue;
  }
  CGFloat size = self.sizeForPagingItem ? self.sizeForPagingItem(pagingItem, YES) : self.options.estimatedItemWidth;
  self.selectedSizeCache[key] = @(size);
  return size;
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
  [self clear];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
  [self clear];
}

@end
