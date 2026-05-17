// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingMenuItemSource.h"

@interface NEPagingMenuItemSource ()

@property (nonatomic, assign, readwrite) NEPagingMenuItemSourceKind kind;
@property (nonatomic, assign, readwrite, nullable) Class cellClass;
@property (nonatomic, strong, readwrite, nullable) UINib *nib;

@end

@implementation NEPagingMenuItemSource

+ (instancetype)sourceWithClass:(Class)cellClass {
  NEPagingMenuItemSource *source = [[self alloc] init];
  source.kind = NEPagingMenuItemSourceKindClass;
  source.cellClass = cellClass;
  return source;
}

+ (instancetype)sourceWithNib:(UINib *)nib {
  NEPagingMenuItemSource *source = [[self alloc] init];
  source.kind = NEPagingMenuItemSourceKindNib;
  source.nib = nib;
  return source;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[NEPagingMenuItemSource class]]) {
    return NO;
  }
  NEPagingMenuItemSource *other = (NEPagingMenuItemSource *)object;
  if (self.kind != other.kind) {
    return NO;
  }
  switch (self.kind) {
    case NEPagingMenuItemSourceKindClass:
      return self.cellClass == other.cellClass;
    case NEPagingMenuItemSourceKindNib:
      return self.nib == other.nib;
  }
}

- (NSUInteger)hash {
  switch (self.kind) {
    case NEPagingMenuItemSourceKindClass:
      return (NSUInteger)(__bridge void *)self.cellClass;
    case NEPagingMenuItemSourceKindNib:
      return (NSUInteger)(__bridge void *)self.nib;
  }
}

@end
