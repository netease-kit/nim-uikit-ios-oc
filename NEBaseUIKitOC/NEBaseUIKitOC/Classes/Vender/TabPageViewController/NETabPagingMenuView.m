// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETabPagingMenuView.h"

#import "UIEdgeInsets.h"

@interface NEPagingMenuViewCell ()

@property (nonatomic, copy, readwrite, nullable) NSString *identifier;
@property (nonatomic, strong, readwrite, nullable) NSNumber *index;

@end

@implementation NEPagingMenuViewCell

@end

@interface PagingMenuFocusViewAnimationCoordinator ()

@property (nonatomic, assign, readwrite) CGRect beginFrame;
@property (nonatomic, assign, readwrite) CGRect endFrame;
@property (nonatomic, copy, nullable) PagingMenuFocusViewAnimationBlock animationHandler;
@property (nonatomic, copy, nullable) NEPagingKitAnimationCompletion completionHandler;

@end

@implementation PagingMenuFocusViewAnimationCoordinator

- (instancetype)initWithBeginFrame:(CGRect)beginFrame endFrame:(CGRect)endFrame {
  self = [super init];
  if (self) {
    _beginFrame = beginFrame;
    _endFrame = endFrame;
  }
  return self;
}

- (void)animateFocusViewAlongside:(PagingMenuFocusViewAnimationBlock)animation
                       completion:(NEPagingKitAnimationCompletion)completion {
  self.animationHandler = animation;
  self.completionHandler = completion;
}

@end

@implementation PagingMenuFocusView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = UIColor.clearColor;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    self.backgroundColor = UIColor.clearColor;
  }
  return self;
}

@end

@interface NEPagingMenuRegisteredCell : NSObject

@property (nonatomic, strong, nullable) UINib *nib;
@property (nonatomic, assign, nullable) Class cellClass;

@end

@implementation NEPagingMenuRegisteredCell

@end

@interface NETabPagingMenuView ()

@property (nonatomic, strong, readwrite) PagingMenuFocusView *focusView;
@property (nonatomic, strong) NSMutableArray<NEPagingMenuViewCell *> *mutableVisibleCells;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<NEPagingMenuViewCell *> *> *queue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NEPagingMenuRegisteredCell *> *registeredCells;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *widths;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong, nullable) NSNumber *touchingIndex;
@property (nonatomic, assign, readwrite) NSInteger numberOfItem;

@end

@implementation NETabPagingMenuView

static void *kNETabPagingMenuViewBoundsObserverContext = &kNETabPagingMenuViewBoundsObserverContext;

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (void)dealloc {
  [self removeObserver:self
            forKeyPath:NSStringFromSelector(@selector(bounds))
               context:kNETabPagingMenuViewBoundsObserverContext];
}

- (void)commonInit {
  _cellAlignment = NETabPagingMenuViewAlignmentLeft;
  _mutableVisibleCells = [NSMutableArray array];
  _queue = [NSMutableDictionary dictionary];
  _registeredCells = [NSMutableDictionary dictionary];
  _widths = [NSMutableArray array];
  self.backgroundColor = UIColor.clearColor;

  [self configureContainerView];
  [self configureFocusView];

  [self addObserver:self
         forKeyPath:NSStringFromSelector(@selector(bounds))
            options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
            context:kNETabPagingMenuViewBoundsObserverContext];
}

- (NSArray<NEPagingMenuViewCell *> *)visibleCells {
  return self.mutableVisibleCells.copy;
}

- (CGFloat)totalSpacing {
  return self.cellSpacing * [self numberOfCellSpacing];
}

- (nullable NSNumber *)indexForItemAtPoint:(CGPoint)point {
  CGFloat currentOffsetX = 0;
  for (NSInteger idx = 0; idx < self.widths.count; idx++) {
    CGFloat width = self.widths[idx].doubleValue;
    CGFloat nextOffsetX = currentOffsetX + width;
    if (point.x >= currentOffsetX && point.x < nextOffsetX) {
      return @(idx);
    }
    currentOffsetX = nextOffsetX;
  }
  return nil;
}

- (nullable NEPagingMenuViewCell *)cellForItemAtIndex:(NSInteger)index {
  for (NEPagingMenuViewCell *cell in self.mutableVisibleCells) {
    if (cell.index.integerValue == index) {
      return cell;
    }
  }
  return nil;
}

- (void)reloadDataWithIndex:(NSInteger)index
                 completion:(NEPagingKitAnimationCompletion)completion {
  self.focusView.selectedIndex = @(index);
  self.contentOffset = CGPointZero;
  [self reloadDataInternal];
  __weak typeof(self) weakSelf = self;
  [NEPagingKitProxy catchLayoutCompletionWithLayout:^{
    [weakSelf scrollToIndex:index completion:^(BOOL finished) {
      if (completion) {
        completion(finished);
      }
    }];
  } completion:^(BOOL finished) {
    if (!finished && completion) {
      completion(NO);
    }
  }];
}

- (void)registerNib:(UINib *)nib withIdentifier:(NSString *)identifier {
  if (identifier.length == 0) {
    return;
  }
  NEPagingMenuRegisteredCell *cell = [[NEPagingMenuRegisteredCell alloc] init];
  cell.nib = nib;
  self.registeredCells[identifier] = cell;
}

- (void)registerClass:(Class)cellClass withIdentifier:(NSString *)identifier {
  if (identifier.length == 0 || !cellClass) {
    return;
  }
  NEPagingMenuRegisteredCell *cell = [[NEPagingMenuRegisteredCell alloc] init];
  cell.cellClass = cellClass;
  self.registeredCells[identifier] = cell;
}

- (void)registerFocusView:(UIView *)view isBehindCell:(BOOL)isBehindCell {
  if (!view) {
    return;
  }
  view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  view.translatesAutoresizingMaskIntoConstraints = YES;
  view.frame = (CGRect){CGPointZero, self.focusView.bounds.size};
  [self.focusView addSubview:view];
  self.focusView.layer.zPosition = isBehindCell ? -1 : 0;
}

- (void)registerFocusViewNib:(UINib *)nib isBehindCell:(BOOL)isBehindCell {
  UIView *view = [[nib instantiateWithOwner:self options:nil] firstObject];
  if ([view isKindOfClass:UIView.class]) {
    [self registerFocusView:view isBehindCell:isBehindCell];
  }
}

- (NEPagingMenuViewCell *)dequeueWithIdentifier:(NSString *)identifier {
  NSMutableArray<NEPagingMenuViewCell *> *cells = self.queue[identifier];
  if (cells.count > 0) {
    NEPagingMenuViewCell *cell = cells.firstObject;
    [cells removeObjectAtIndex:0];
    cell.identifier = identifier;
    return cell;
  }

  NEPagingMenuRegisteredCell *registeredCell = self.registeredCells[identifier];
  if (registeredCell.nib) {
    NEPagingMenuViewCell *cell = [[registeredCell.nib instantiateWithOwner:self options:nil] firstObject];
    cell.identifier = identifier;
    return cell;
  }
  if (registeredCell.cellClass) {
    NEPagingMenuViewCell *cell = [[registeredCell.cellClass alloc] initWithFrame:CGRectZero];
    cell.identifier = identifier;
    return cell;
  }

  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"No registered cell for identifier %@", identifier]
                               userInfo:nil];
}

- (CGRect)rectForItemAtIndex:(NSInteger)index {
  if (self.widths.count == 0) {
    return CGRectMake(0, 0, 0, CGRectGetHeight(self.bounds));
  }

  if (index >= self.widths.count) {
    CGFloat rightEdge = 0;
    for (NSNumber *width in self.widths) {
      rightEdge += width.doubleValue;
    }
    rightEdge += self.totalSpacing;
    CGFloat mostRightWidth = self.widths.lastObject.doubleValue;
    return CGRectMake(rightEdge, 0, mostRightWidth, CGRectGetHeight(self.bounds));
  }

  if (index < 0) {
    CGFloat mostLeftWidth = self.widths.firstObject.doubleValue;
    return CGRectMake(-mostLeftWidth, 0, mostLeftWidth, CGRectGetHeight(self.bounds));
  }

  CGFloat x = 0;
  for (NSInteger idx = 0; idx < index; idx++) {
    x += self.widths[idx].doubleValue;
  }
  x += self.cellSpacing * index;
  return CGRectMake(x, 0, self.widths[index].doubleValue, CGRectGetHeight(self.bounds));
}

- (void)invalidateLayout {
  id<PagingMenuViewDataSource> dataSource = self.dataSource;
  if (!dataSource) {
    return;
  }

  [self.widths removeAllObjects];
  CGFloat containerWidth = 0;
  for (NSInteger index = 0; index < self.numberOfItem; index++) {
    CGFloat width = [dataSource pagingMenuView:self widthForItemAt:index];
    [self.widths addObject:@(width)];
    containerWidth += width;
  }
  containerWidth += self.totalSpacing;

  self.contentSize = CGSizeMake(containerWidth, CGRectGetHeight(self.bounds));
  CGRect containerFrame = self.containerView.frame;
  containerFrame.size = self.contentSize;
  self.containerView.frame = containerFrame;

  [self alignEachVisibleCell];
}

- (void)scrollToIndex:(NSInteger)index percent:(CGFloat)percent {
  if (self.numberOfItem <= 0) {
    return;
  }

  NSInteger correctedIndex = index;
  CGFloat correctedPercent = percent;
  [self correctScrollIndex:&correctedIndex percent:&correctedPercent];

  NSInteger rightIndex = correctedIndex + 1;
  CGRect leftFrame = [self rectForItemAtIndex:correctedIndex];
  CGRect rightFrame = [self rectForItemAtIndex:rightIndex];

  CGFloat width = (CGRectGetWidth(rightFrame) - CGRectGetWidth(leftFrame)) * correctedPercent + CGRectGetWidth(leftFrame);
  CGRect focusFrame = self.focusView.frame;
  focusFrame.size = CGSizeMake(width, CGRectGetHeight(self.bounds));
  self.focusView.frame = focusFrame;

  CGFloat centerPointX = CGRectGetMidX(leftFrame) + (CGRectGetMidX(rightFrame) - CGRectGetMidX(leftFrame)) * correctedPercent;
  CGFloat offsetX = centerPointX - CGRectGetWidth(self.bounds) / 2.0;
  CGFloat normalizedOffsetX = MIN(MAX(self.minContentOffsetX, offsetX), self.maxContentOffsetX);
  self.focusView.center = CGPointMake(centerPointX, self.center.y);

  NSInteger expectedIndex = (CGRectGetMidX(self.focusView.frame) < CGRectGetMaxX(leftFrame)) ? correctedIndex : rightIndex;
  expectedIndex = MAX(0, MIN(expectedIndex, self.numberOfItem - 1));
  self.focusView.selectedIndex = @(expectedIndex);

  self.contentOffset = CGPointMake(normalizedOffsetX, 0);
  [self selectVisibleCellAtIndex:expectedIndex];
}

- (void)scrollToIndex:(NSInteger)index
           completion:(NEPagingKitAnimationCompletion)completion {
  if (self.numberOfItem <= 0 || index < 0 || index >= self.numberOfItem) {
    if (completion) {
      completion(NO);
    }
    return;
  }

  CGRect itemFrame = [self rectForItemAtIndex:index];
  CGFloat offsetX = CGRectGetMidX(itemFrame) - CGRectGetWidth(self.bounds) / 2.0;
  CGPoint offset = CGPointMake(MIN(MAX(self.minContentOffsetX, offsetX), self.maxContentOffsetX), 0);

  self.focusView.selectedIndex = @(index);
  [self selectVisibleCellAtIndex:index];

  PagingMenuFocusViewAnimationCoordinator *coordinator =
      [[PagingMenuFocusViewAnimationCoordinator alloc] initWithBeginFrame:self.focusView.frame
                                                                 endFrame:itemFrame];
  if ([self.menuDelegate respondsToSelector:@selector(pagingMenuView:willAnimateFocusViewTo:withCoordinator:)]) {
    [self.menuDelegate pagingMenuView:self willAnimateFocusViewTo:index withCoordinator:coordinator];
  }

  __weak typeof(self) weakSelf = self;
  [NEPagingKitProxy performSystemAnimation:^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    strongSelf.contentOffset = offset;
    strongSelf.focusView.frame = itemFrame;
    [strongSelf.focusView layoutIfNeeded];
    if (coordinator.animationHandler) {
      coordinator.animationHandler(coordinator);
    }
  } completion:^(BOOL finished) {
    if (coordinator.completionHandler) {
      coordinator.completionHandler(finished);
    }
    if (completion) {
      completion(finished);
    }
  }];
}

- (nullable NSNumber *)expectedAlignmentPositionXIfNeeded {
  if (self.hasScrollableArea) {
    return nil;
  }

  CGFloat maxOffsetX = self.maxSafedOffset;
  CGFloat originX = 0;
  switch (self.cellAlignment) {
    case NETabPagingMenuViewAlignmentCenter:
      originX = maxOffsetX / 2.0;
      break;
    case NETabPagingMenuViewAlignmentLeft:
      originX = 0;
      break;
    case NETabPagingMenuViewAlignmentRight:
      originX = maxOffsetX;
      break;
  }
  return @(originX);
}

- (void)layoutSubviews {
  [super layoutSubviews];

  if (self.numberOfItem != 0) {
    CGRect visibleBounds = [self convertRect:self.bounds toView:self.containerView];
    CGFloat extraOffset = CGRectGetWidth(visibleBounds) / 2.0;
    [self tileCellFrom:MAX(0, CGRectGetMinX(visibleBounds) - extraOffset)
                    to:MIN(self.contentSize.width,
                           CGRectGetMaxX(visibleBounds) + extraOffset)];
  }

  [self alignContainerViewIfNeeded];
}

- (void)safeAreaInsetsDidChange {
  [super safeAreaInsetsDidChange];
  [self alignEachVisibleCell];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [super touchesBegan:touches withEvent:event];
  CGPoint touchPoint = [[touches anyObject] locationInView:self.containerView];
  for (NEPagingMenuViewCell *cell in self.mutableVisibleCells) {
    if (CGRectContainsPoint(cell.frame, touchPoint)) {
      self.touchingIndex = cell.index;
      return;
    }
  }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [super touchesEnded:touches withEvent:event];

  NSNumber *touchingIndex = self.touchingIndex;
  self.touchingIndex = nil;
  if (!touchingIndex) {
    return;
  }

  CGPoint touchPoint = [[touches anyObject] locationInView:self.containerView];
  for (NEPagingMenuViewCell *cell in self.mutableVisibleCells) {
    if (CGRectContainsPoint(cell.frame, touchPoint) &&
        cell.index.integerValue == touchingIndex.integerValue) {
      if ([self.menuDelegate respondsToSelector:@selector(pagingMenuView:didSelectItemAt:)]) {
        [self.menuDelegate pagingMenuView:self didSelectItemAt:touchingIndex.integerValue];
      }
      break;
    }
  }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [super touchesCancelled:touches withEvent:event];
  self.touchingIndex = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
  if (context != kNETabPagingMenuViewBoundsObserverContext) {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
  }

  NSValue *newValue = change[NSKeyValueChangeNewKey];
  NSValue *oldValue = change[NSKeyValueChangeOldKey];
  if ([newValue isKindOfClass:NSValue.class] && [oldValue isKindOfClass:NSValue.class]) {
    CGRect newFrame = newValue.CGRectValue;
    CGRect oldFrame = oldValue.CGRectValue;
    if (CGRectGetHeight(newFrame) != CGRectGetHeight(oldFrame)) {
      [self adjustComponentHeightsFromNewHeight:CGRectGetHeight(newFrame)];
    }
  }
}

#pragma mark - Private

- (void)reloadDataInternal {
  id<PagingMenuViewDataSource> dataSource = self.dataSource;
  if (!dataSource) {
    return;
  }

  for (NEPagingMenuViewCell *cell in self.mutableVisibleCells) {
    [cell removeFromSuperview];
  }
  [self.mutableVisibleCells removeAllObjects];
  self.numberOfItem = [dataSource numberOfItemForPagingMenuView];

  [self invalidateLayout];
  [self setNeedsLayout];
  [self layoutIfNeeded];
}

- (void)configureContainerView {
  self.containerView = [[UIView alloc] initWithFrame:self.bounds];
  self.containerView.center = self.center;
  [self addSubview:self.containerView];
}

- (void)configureFocusView {
  self.focusView = [[PagingMenuFocusView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
  [self.containerView addSubview:self.focusView];
}

- (CGFloat)numberOfCellSpacing {
  return MAX((CGFloat)self.numberOfItem - 1.0, 0);
}

- (UIEdgeInsets)contentSafeAreaInsets {
  if (@available(iOS 11.0, *)) {
    return self.safeAreaInsets;
  }
  return UIEdgeInsetsZero;
}

- (CGFloat)safedViewWidth {
  return CGRectGetWidth(self.bounds) - NEUIEdgeInsetsHorizontal(self.contentSafeAreaInsets);
}

- (BOOL)hasScrollableArea {
  return self.safedViewWidth < self.contentSize.width;
}

- (CGFloat)maxContentOffsetX {
  return MAX(CGRectGetWidth(self.bounds),
             self.contentSize.width + self.contentSafeAreaInsets.right + self.contentInset.right) -
         CGRectGetWidth(self.bounds);
}

- (CGFloat)minContentOffsetX {
  return -(self.contentSafeAreaInsets.left + self.contentInset.left);
}

- (CGFloat)maxSafedOffset {
  return self.safedViewWidth - CGRectGetWidth(self.containerView.frame);
}

- (void)alignEachVisibleCell {
  for (NEPagingMenuViewCell *cell in self.mutableVisibleCells) {
    CGFloat leftEdge = 0;
    for (NSInteger idx = 0; idx < cell.index.integerValue; idx++) {
      leftEdge += self.widths[idx].doubleValue + self.cellSpacing;
    }
    CGRect frame = cell.frame;
    frame.origin = CGPointMake(leftEdge, 0);
    frame.size = CGSizeMake(self.widths[cell.index.integerValue].doubleValue,
                            CGRectGetHeight(self.containerView.bounds));
    cell.frame = frame;
  }
}

- (void)adjustComponentHeightsFromNewHeight:(CGFloat)newHeight {
  self.contentSize = CGSizeMake(self.contentSize.width, newHeight);
  CGRect containerFrame = self.containerView.frame;
  containerFrame.size.height = newHeight;
  self.containerView.frame = containerFrame;
  for (NEPagingMenuViewCell *cell in self.mutableVisibleCells) {
    CGRect frame = cell.frame;
    frame.size.height = newHeight;
    cell.frame = frame;
  }
  CGRect focusFrame = self.focusView.frame;
  focusFrame.size.height = newHeight;
  self.focusView.frame = focusFrame;
}

- (CGFloat)placeNewCellOnRightWithRightEdge:(CGFloat)rightEdge
                                      index:(NSInteger)index
                                 dataSource:(id<PagingMenuViewDataSource>)dataSource {
  NSInteger nextIndex = (index + 1) % self.numberOfItem;
  NEPagingMenuViewCell *cell = [dataSource pagingMenuView:self cellForItemAt:nextIndex];
  cell.selected = (self.focusView.selectedIndex.integerValue == nextIndex);
  cell.index = @(nextIndex);
  [self.containerView insertSubview:cell atIndex:0];

  [self.mutableVisibleCells addObject:cell];
  cell.frame = CGRectMake(rightEdge, 0, self.widths[nextIndex].doubleValue, CGRectGetHeight(self.containerView.bounds));

  if ([self.menuDelegate respondsToSelector:@selector(pagingMenuView:willDisplay:forItemAt:)]) {
    [self.menuDelegate pagingMenuView:self willDisplay:cell forItemAt:nextIndex];
  }

  return CGRectGetMaxX(cell.frame);
}

- (CGFloat)placeNewCellOnLeftWithLeftEdge:(CGFloat)leftEdge
                                    index:(NSInteger)index
                               dataSource:(id<PagingMenuViewDataSource>)dataSource {
  NSInteger nextIndex = (index == 0) ? self.numberOfItem - 1 : (index - 1) % self.numberOfItem;
  NEPagingMenuViewCell *cell = [dataSource pagingMenuView:self cellForItemAt:nextIndex];
  cell.selected = (self.focusView.selectedIndex.integerValue == nextIndex);
  cell.index = @(nextIndex);
  [self.containerView insertSubview:cell atIndex:0];

  [self.mutableVisibleCells insertObject:cell atIndex:0];
  cell.frame = CGRectMake(leftEdge - self.widths[nextIndex].doubleValue - self.cellSpacing,
                          0,
                          self.widths[nextIndex].doubleValue,
                          CGRectGetHeight(self.containerView.bounds));

  if ([self.menuDelegate respondsToSelector:@selector(pagingMenuView:willDisplay:forItemAt:)]) {
    [self.menuDelegate pagingMenuView:self willDisplay:cell forItemAt:nextIndex];
  }

  return CGRectGetMinX(cell.frame);
}

- (void)tileCellFrom:(CGFloat)minX to:(CGFloat)maxX {
  id<PagingMenuViewDataSource> dataSource = self.dataSource;
  if (!dataSource || self.numberOfItem <= 0) {
    return;
  }

  if (self.mutableVisibleCells.count == 0) {
    [self placeNewCellOnRightWithRightEdge:minX index:self.numberOfItem - 1 dataSource:dataSource];
  }

  NEPagingMenuViewCell *lastCell = self.mutableVisibleCells.lastObject;
  CGFloat rightEdge = lastCell ? CGRectGetMaxX(lastCell.frame) + self.cellSpacing : 0;
  while (lastCell &&
         rightEdge < maxX &&
         (lastCell.index.integerValue + 1) >= 0 &&
         (lastCell.index.integerValue + 1) < self.numberOfItem) {
    rightEdge = [self placeNewCellOnRightWithRightEdge:rightEdge
                                                 index:lastCell.index.integerValue
                                            dataSource:dataSource] + self.cellSpacing;
    lastCell = self.mutableVisibleCells.lastObject;
  }

  NEPagingMenuViewCell *firstCell = self.mutableVisibleCells.firstObject;
  CGFloat leftEdge = firstCell ? CGRectGetMinX(firstCell.frame) : 0;
  while (firstCell &&
         leftEdge > minX &&
         (firstCell.index.integerValue - 1) >= 0 &&
         (firstCell.index.integerValue - 1) < self.numberOfItem) {
    leftEdge = [self placeNewCellOnLeftWithLeftEdge:leftEdge
                                              index:firstCell.index.integerValue
                                         dataSource:dataSource];
    firstCell = self.mutableVisibleCells.firstObject;
  }

  while (self.mutableVisibleCells.lastObject &&
         CGRectGetMinX(self.mutableVisibleCells.lastObject.frame) > maxX) {
    [self recycleCell:self.mutableVisibleCells.lastObject];
    [self.mutableVisibleCells removeLastObject];
  }

  while (self.mutableVisibleCells.firstObject &&
         CGRectGetMaxX(self.mutableVisibleCells.firstObject.frame) < minX) {
    [self recycleCell:self.mutableVisibleCells.firstObject];
    [self.mutableVisibleCells removeObjectAtIndex:0];
  }
}

- (void)recycleCell:(NEPagingMenuViewCell *)cell {
  [cell removeFromSuperview];
  if (cell.identifier.length == 0) {
    return;
  }

  NSMutableArray<NEPagingMenuViewCell *> *cells = self.queue[cell.identifier];
  if (!cells) {
    cells = [NSMutableArray array];
    self.queue[cell.identifier] = cells;
  }
  [cells addObject:cell];
}

- (void)alignContainerViewIfNeeded {
  NSNumber *expectedOriginX = [self expectedAlignmentPositionXIfNeeded];
  if (!expectedOriginX) {
    return;
  }

  CGRect frame = self.containerView.frame;
  if (frame.origin.x != expectedOriginX.doubleValue) {
    frame.origin.x = expectedOriginX.doubleValue;
    self.containerView.frame = frame;
  }
}

- (void)correctScrollIndex:(NSInteger *)index percent:(CGFloat *)percent {
  if (*percent < 0) {
    if (*index == 0) {
      return;
    }
    *index = MAX(*index - 1, 0);
    *percent = *percent + 1.0;
  }
}

- (void)selectVisibleCellAtIndex:(NSInteger)index {
  for (NEPagingMenuViewCell *cell in self.mutableVisibleCells) {
    cell.selected = (cell.index.integerValue == index);
  }
}

@end
