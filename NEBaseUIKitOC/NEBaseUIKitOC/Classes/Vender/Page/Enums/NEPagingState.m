// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingState.h"

@interface NEPagingState ()

@property (nonatomic, assign, readwrite) NEPagingStateKind kind;
@property (nonatomic, strong, readwrite, nullable) id<NEPagingItem> currentPagingItem;
@property (nonatomic, strong, readwrite, nullable) id<NEPagingItem> upcomingPagingItem;
@property (nonatomic, assign, readwrite) CGFloat progress;
@property (nonatomic, assign, readwrite) CGPoint initialContentOffset;
@property (nonatomic, assign, readwrite) CGFloat distance;

@end

@implementation NEPagingState

+ (instancetype)emptyState {
  NEPagingState *state = [[self alloc] init];
  state.kind = NEPagingStateKindEmpty;
  return state;
}

+ (instancetype)selectedStateWithPagingItem:(id<NEPagingItem>)pagingItem {
  NEPagingState *state = [[self alloc] init];
  state.kind = NEPagingStateKindSelected;
  state.currentPagingItem = pagingItem;
  return state;
}

+ (instancetype)scrollingStateWithPagingItem:(id<NEPagingItem>)pagingItem
                           upcomingPagingItem:(id<NEPagingItem>)upcomingPagingItem
                                     progress:(CGFloat)progress
                         initialContentOffset:(CGPoint)initialContentOffset
                                     distance:(CGFloat)distance {
  NEPagingState *state = [[self alloc] init];
  state.kind = NEPagingStateKindScrolling;
  state.currentPagingItem = pagingItem;
  state.upcomingPagingItem = upcomingPagingItem;
  state.progress = progress;
  state.initialContentOffset = initialContentOffset;
  state.distance = distance;
  return state;
}

- (id<NEPagingItem>)visuallySelectedPagingItem {
  if (fabs(self.progress) > 0.5) {
    return self.upcomingPagingItem ?: self.currentPagingItem;
  }
  return self.currentPagingItem;
}

- (id)copyWithZone:(NSZone *)zone {
  switch (self.kind) {
    case NEPagingStateKindSelected:
      return [[[self class] allocWithZone:zone] selectedStateWithPagingItem:self.currentPagingItem];
    case NEPagingStateKindScrolling:
      return [[[self class] allocWithZone:zone] scrollingStateWithPagingItem:self.currentPagingItem
                                                           upcomingPagingItem:self.upcomingPagingItem
                                                                     progress:self.progress
                                                         initialContentOffset:self.initialContentOffset
                                                                     distance:self.distance];
    case NEPagingStateKindEmpty:
    default:
      return [[[self class] allocWithZone:zone] emptyState];
  }
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[NEPagingState class]]) {
    return NO;
  }
  NEPagingState *other = (NEPagingState *)object;
  if (self.kind != other.kind) {
    return NO;
  }
  BOOL currentEqual = (!self.currentPagingItem && !other.currentPagingItem) ||
                      [self.currentPagingItem isEqualToPagingItem:other.currentPagingItem];
  BOOL upcomingEqual = (!self.upcomingPagingItem && !other.upcomingPagingItem) ||
                       [self.upcomingPagingItem isEqualToPagingItem:other.upcomingPagingItem];
  return currentEqual &&
         upcomingEqual &&
         CGPointEqualToPoint(self.initialContentOffset, other.initialContentOffset) &&
         self.progress == other.progress &&
         self.distance == other.distance;
}

- (NSUInteger)hash {
  NSUInteger hash = (NSUInteger)self.kind;
  hash ^= (NSUInteger)self.currentPagingItem.identifier;
  hash ^= (NSUInteger)self.upcomingPagingItem.identifier;
  hash ^= (NSUInteger)lrint(self.progress * 1000);
  hash ^= (NSUInteger)lrint(self.distance * 1000);
  return hash;
}

@end
