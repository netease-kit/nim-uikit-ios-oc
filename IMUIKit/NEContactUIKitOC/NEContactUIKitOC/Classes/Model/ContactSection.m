// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactSection.h"

@implementation ContactSection

- (instancetype)initWithInitial:(NSString *)initial
                       contacts:(NSArray<ContactInfo *> *)contacts {
  self = [super init];
  if (self) {
    _initial = [initial copy];
    _contacts = [contacts mutableCopy];
  }
  return self;
}

- (NSComparisonResult)compare:(ContactSection *)other {
  return [self.initial compare:other.initial];
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[ContactSection class]]) {
    return NO;
  }
  ContactSection *other = (ContactSection *)object;
  return [self.initial isEqualToString:other.initial];
}

@end
