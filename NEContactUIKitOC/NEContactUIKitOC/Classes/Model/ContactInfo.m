// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactInfo.h"
#import <NEChatKit/NEChatKit.h>


@class Router;

FOUNDATION_EXPORT NSString *const ContactPersonRouter;

@implementation ContactInfo

- (instancetype)init {
  self = [super init];
  if (self) {
    _contactCellType = ContactCellTypeContactPerson;
    _router = ContactPersonRouter;
    _isSelected = NO;
    _isOnline = NO;
  }
  return self;
}

- (nullable NSNumber *)getRowHeight {
  return nil;
}

- (NSComparisonResult)compare:(ContactInfo *)other {
  NSString *lhsName = self.user.showName ?: @"";
  NSString *rhsName = other.user.showName ?: @"";
  return [lhsName compare:rhsName];
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[ContactInfo class]]) {
    return NO;
  }
  ContactInfo *other = (ContactInfo *)object;
  NSString *lhsName = self.user.showName ?: @"";
  NSString *rhsName = other.user.showName ?: @"";
  return [lhsName isEqualToString:rhsName];
}

@end
