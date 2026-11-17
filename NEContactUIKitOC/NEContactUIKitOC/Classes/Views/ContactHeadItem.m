// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactHeadItem.h"

@implementation ContactHeadItem

- (instancetype)initWithRouter:(NSString *)router
                          name:(nullable NSString *)name
                     imageName:(nullable NSString *)imageName
                         color:(nullable UIColor *)color {
  self = [super init];
  if (self) {
    _router = [router copy];
    _name = [name copy];
    _imageName = [imageName copy];
    _color = color;
  }
  return self;
}

@end
