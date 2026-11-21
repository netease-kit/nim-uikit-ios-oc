// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAdaptiveWindowContext.h"

#import <string.h>

#pragma mark - Snapshot helpers

static BOOL NEAdaptiveFramesEqual(CGRect lhs, CGRect rhs) {
  return lhs.origin.x == rhs.origin.x && lhs.origin.y == rhs.origin.y &&
         lhs.size.width == rhs.size.width && lhs.size.height == rhs.size.height;
}

static uint64_t NEAdaptiveMixHash(uint64_t hash, uint64_t value) {
  return (hash ^ value) * 0x100000001b3ULL;
}

static uint64_t NEAdaptiveBitsOfDouble(double value) {
  uint64_t bits = 0;
  memcpy(&bits, &value, sizeof(bits));
  return bits;
}

static NEWindowSizeClass NEAdaptiveSizeClassFromUIUserInterfaceSizeClass(UIUserInterfaceSizeClass value) {
  switch (value) {
    case UIUserInterfaceSizeClassCompact:
      return NEWindowSizeClassCompact;
    case UIUserInterfaceSizeClassRegular:
      return NEWindowSizeClassRegular;
    default:
      return NEWindowSizeClassUnspecified;
  }
}

/// 读取视图（窗口或外壳视图）当前激活的 division / occlusion 占位区。
static NSArray<NEReservedRegionSnapshot *> *NEAdaptiveActiveReservedRegions(UIView *view) {
  if (@available(iOS 27.1, *)) {
    NSMutableArray<NEReservedRegionSnapshot *> *regions = [NSMutableArray array];
    NSArray<UIViewReservedRegion *> *occlusions =
        [view reservedRegionsOfKind:[UIViewReservedRegionKind occlusionRegionKind]];
    for (UIViewReservedRegion *region in occlusions) {
      if (!region.isActive) {
        continue;
      }
      [regions addObject:[[NEReservedRegionSnapshot alloc] initWithKind:NEReservedRegionKindOcclusion
                                                                  frame:region.frame]];
    }
    NSArray<UIViewReservedRegion *> *divisions =
        [view reservedRegionsOfKind:[UIViewReservedRegionKind divisionRegionKind]];
    for (UIViewReservedRegion *region in divisions) {
      if (!region.isActive) {
        continue;
      }
      [regions addObject:[[NEReservedRegionSnapshot alloc] initWithKind:NEReservedRegionKindDivision
                                                                  frame:region.frame]];
    }
    [regions sortUsingComparator:^NSComparisonResult(NEReservedRegionSnapshot *lhs,
                                                     NEReservedRegionSnapshot *rhs) {
      if (lhs.kind != rhs.kind) {
        return lhs.kind == NEReservedRegionKindOcclusion ? NSOrderedAscending : NSOrderedDescending;
      }
      if (lhs.frame.origin.x != rhs.frame.origin.x) {
        return lhs.frame.origin.x < rhs.frame.origin.x ? NSOrderedAscending : NSOrderedDescending;
      }
      if (lhs.frame.origin.y != rhs.frame.origin.y) {
        return lhs.frame.origin.y < rhs.frame.origin.y ? NSOrderedAscending : NSOrderedDescending;
      }
      if (lhs.frame.size.width != rhs.frame.size.width) {
        return lhs.frame.size.width < rhs.frame.size.width ? NSOrderedAscending : NSOrderedDescending;
      }
      if (lhs.frame.size.height != rhs.frame.size.height) {
        return lhs.frame.size.height < rhs.frame.size.height ? NSOrderedAscending : NSOrderedDescending;
      }
      return NSOrderedSame;
    }];
    return [regions copy];
  }
  return @[];
}

#pragma mark - NEReservedRegionSnapshot

@implementation NEReservedRegionSnapshot

- (instancetype)initWithKind:(NEReservedRegionKind)kind frame:(CGRect)frame {
  self = [super init];
  if (self) {
    _kind = kind;
    _frame = frame;
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  return self;
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[NEReservedRegionSnapshot class]]) {
    return NO;
  }
  NEReservedRegionSnapshot *other = (NEReservedRegionSnapshot *)object;
  return _kind == other.kind && NEAdaptiveFramesEqual(_frame, other.frame);
}

- (NSUInteger)hash {
  return (NSUInteger)(_kind * 31 + (NSInteger)_frame.origin.x + (NSInteger)_frame.origin.y);
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<NEReservedRegionSnapshot: kind=%ld frame=%@>",
                                    (long)_kind, NSStringFromCGRect(_frame)];
}

@end

#pragma mark - NEWindowSnapshot

@interface NEWindowSnapshot ()
@property (nonatomic, assign, readwrite) uint64_t reservedRegionFingerprint;
@end

@implementation NEWindowSnapshot

- (instancetype)initWithSize:(CGSize)size
                 safeAreaTop:(CGFloat)safeAreaTop
                safeAreaLeft:(CGFloat)safeAreaLeft
              safeAreaBottom:(CGFloat)safeAreaBottom
               safeAreaRight:(CGFloat)safeAreaRight
          horizontalSizeClass:(NEWindowSizeClass)horizontalSizeClass
            verticalSizeClass:(NEWindowSizeClass)verticalSizeClass
                 displayScale:(CGFloat)displayScale
             reservedRegions:(NSArray<NEReservedRegionSnapshot *> *)reservedRegions {
  self = [super init];
  if (self) {
    _size = size;
    _safeAreaTop = safeAreaTop;
    _safeAreaLeft = safeAreaLeft;
    _safeAreaBottom = safeAreaBottom;
    _safeAreaRight = safeAreaRight;
    _horizontalSizeClass = horizontalSizeClass;
    _verticalSizeClass = verticalSizeClass;
    _displayScale = displayScale;
    _reservedRegions = [reservedRegions copy];

    uint64_t hash = 0xcbf29ce484222325ULL;
    for (NEReservedRegionSnapshot *region in _reservedRegions) {
      hash = NEAdaptiveMixHash(hash, region.kind == NEReservedRegionKindOcclusion ? 1 : 2);
      hash = NEAdaptiveMixHash(hash, NEAdaptiveBitsOfDouble(region.frame.origin.x));
      hash = NEAdaptiveMixHash(hash, NEAdaptiveBitsOfDouble(region.frame.origin.y));
      hash = NEAdaptiveMixHash(hash, NEAdaptiveBitsOfDouble(region.frame.size.width));
      hash = NEAdaptiveMixHash(hash, NEAdaptiveBitsOfDouble(region.frame.size.height));
    }
    _reservedRegionFingerprint = hash;
  }
  return self;
}

+ (instancetype)snapshotWithWindow:(UIWindow *)window {
  return [self snapshotWithView:window];
}

+ (instancetype)snapshotWithView:(UIView *)view {
  if (!view) {
    return nil;
  }
  UIEdgeInsets insets = view.safeAreaInsets;
  return [[self alloc] initWithSize:view.bounds.size
                        safeAreaTop:insets.top
                       safeAreaLeft:insets.left
                     safeAreaBottom:insets.bottom
                      safeAreaRight:insets.right
                 horizontalSizeClass:NEAdaptiveSizeClassFromUIUserInterfaceSizeClass(
                                          view.traitCollection.horizontalSizeClass)
                   verticalSizeClass:NEAdaptiveSizeClassFromUIUserInterfaceSizeClass(
                                          view.traitCollection.verticalSizeClass)
                        displayScale:view.traitCollection.displayScale
                    reservedRegions:NEAdaptiveActiveReservedRegions(view)];
}

- (id)copyWithZone:(NSZone *)zone {
  return self;
}

- (BOOL)isEqualToSnapshot:(NEWindowSnapshot *)other {
  if (self == other) {
    return YES;
  }
  if (!other) {
    return NO;
  }
  if (_size.width != other.size.width || _size.height != other.size.height ||
      _safeAreaTop != other.safeAreaTop || _safeAreaLeft != other.safeAreaLeft ||
      _safeAreaBottom != other.safeAreaBottom || _safeAreaRight != other.safeAreaRight ||
      _horizontalSizeClass != other.horizontalSizeClass ||
      _verticalSizeClass != other.verticalSizeClass || _displayScale != other.displayScale) {
    return NO;
  }
  if (_reservedRegions.count != other.reservedRegions.count) {
    return NO;
  }
  for (NSUInteger index = 0; index < _reservedRegions.count; index++) {
    if (![_reservedRegions[index] isEqual:other.reservedRegions[index]]) {
      return NO;
    }
  }
  return YES;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[NEWindowSnapshot class]]) {
    return NO;
  }
  return [self isEqualToSnapshot:(NEWindowSnapshot *)object];
}

- (NSUInteger)hash {
  return (NSUInteger)(_reservedRegionFingerprint ^
                      NEAdaptiveBitsOfDouble(_size.width) ^
                      NEAdaptiveBitsOfDouble(_size.height));
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<NEWindowSnapshot: size=%@ insets=(%g,%g,%g,%g) scale=%g regions=%lu>",
                                    NSStringFromCGSize(_size), _safeAreaTop, _safeAreaLeft,
                                    _safeAreaBottom, _safeAreaRight, _displayScale,
                                    (unsigned long)_reservedRegions.count];
}

@end

#pragma mark - NEAdaptiveWindowContext

@implementation NEAdaptiveWindowContext {
  NEAdaptiveWindowSnapshotProvider _sample;
  void (^_onChange)(NEWindowSnapshot *snapshot);
  BOOL _isPublishing;
  BOOL _needsRefresh;
  NEWindowSnapshot *_snapshot;
}

- (instancetype)initWithSample:(NEAdaptiveWindowSnapshotProvider)sample
                      onChange:(void (^)(NEWindowSnapshot *snapshot))onChange {
  self = [super init];
  if (self) {
    NSAssert([NSThread isMainThread], @"NEAdaptiveWindowContext must be created on the main thread.");
    _sample = [sample copy];
    _onChange = [onChange copy];
  }
  return self;
}

- (instancetype)initWithWindow:(UIWindow *)window
                      onChange:(void (^)(NEWindowSnapshot *snapshot))onChange {
  return [self initWithWindow:window samplingView:nil onChange:onChange];
}

- (instancetype)initWithWindow:(UIWindow *)window
                  samplingView:(UIView *)samplingView
                      onChange:(void (^)(NEWindowSnapshot *snapshot))onChange {
  __weak UIWindow *weakWindow = window;
  __weak UIView *weakSamplingView = samplingView;
  return [self initWithSample:^NEWindowSnapshot *_Nullable {
    UIWindow *strongWindow = weakWindow;
    if (!strongWindow) {
      return nil;
    }
    UIView *strongSamplingView = weakSamplingView;
    UIView *sampler = (strongSamplingView && strongSamplingView.window == strongWindow)
                          ? strongSamplingView
                          : strongWindow;
    return [NEWindowSnapshot snapshotWithView:sampler];
  } onChange:onChange];
}

- (NEWindowSnapshot *)snapshot {
  return _snapshot;
}

- (void)refresh {
  NSAssert([NSThread isMainThread], @"NEAdaptiveWindowContext refresh must run on the main thread.");
  if (!_sample) {
    return;
  }
  if (_isPublishing) {
    _needsRefresh = YES;
    return;
  }
  _isPublishing = YES;
  do {
    _needsRefresh = NO;
    NEAdaptiveWindowSnapshotProvider sample = _sample;
    if (!sample) {
      break;
    }
    NEWindowSnapshot *next = sample();
    if (!_sample) {
      break;
    }
    if ([next isEqualToSnapshot:_snapshot] || next == _snapshot) {
      continue;
    }
    _snapshot = next;
    if (next && _onChange) {
      _onChange(next);
    }
  } while (_needsRefresh);
  _isPublishing = NO;
}

- (void)invalidate {
  NSAssert([NSThread isMainThread], @"NEAdaptiveWindowContext invalidate must run on the main thread.");
  _sample = nil;
  _onChange = nil;
  _snapshot = nil;
  _needsRefresh = NO;
}

@end
