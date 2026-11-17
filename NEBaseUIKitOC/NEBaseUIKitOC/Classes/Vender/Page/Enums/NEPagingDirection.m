// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingDirection.h"

@interface PagingDirection ()

@property (nonatomic, assign, readwrite) PagingDirectionKind kind;
@property (nonatomic, assign, readwrite, getter=isSibling) BOOL sibling;

@end

@implementation PagingDirection

+ (instancetype)reverseWithSibling:(BOOL)sibling {
  PagingDirection *direction = [[self alloc] init];
  direction.kind = PagingDirectionKindReverse;
  direction.sibling = sibling;
  return direction;
}

+ (instancetype)forwardWithSibling:(BOOL)sibling {
  PagingDirection *direction = [[self alloc] init];
  direction.kind = PagingDirectionKindForward;
  direction.sibling = sibling;
  return direction;
}

+ (instancetype)noneDirection {
  PagingDirection *direction = [[self alloc] init];
  direction.kind = PagingDirectionKindNone;
  direction.sibling = NO;
  return direction;
}

- (id)copyWithZone:(NSZone *)zone {
  PagingDirection *copy = [[[self class] allocWithZone:zone] init];
  copy.kind = self.kind;
  copy.sibling = self.sibling;
  return copy;
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[PagingDirection class]]) {
    return NO;
  }
  PagingDirection *other = (PagingDirection *)object;
  return self.kind == other.kind && self.sibling == other.sibling;
}

- (NSUInteger)hash {
  return (NSUInteger)(self.kind + 2) ^ (self.sibling ? 0x100 : 0);
}

@end
