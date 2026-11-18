// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NECompatibleAnimationView.h"
#import <Lottie/Lottie.h>
#import <float.h>
#import <objc/message.h>

@interface NECompatibleAnimationKeypath (NEInternal)
@property (nonatomic, strong, readonly) LOTKeypath *lotKeypath;
@end

@interface NECompatibleAnimation ()
@property (nonatomic, strong, readonly, nullable) LOTComposition *composition;
@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *, id> *animationJSON;
@end

@implementation NECompatibleAnimation {
  LOTComposition *_composition;
  NSDictionary<NSString *, id> *_animationJSON;
}

- (instancetype)initWithName:(NSString *)name
                 subdirectory:(NSString *)subdirectory
                       bundle:(NSBundle *)bundle {
  self = [super init];
  if (self) {
    NSString *path = [bundle pathForResource:name ofType:@"json" inDirectory:subdirectory];
    NSData *data = path.length > 0 ? [NSData dataWithContentsOfFile:path] : nil;
    id json = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
      _animationJSON = [json copy];
      _composition = [LOTComposition animationFromJSON:_animationJSON inBundle:bundle];
    } else {
      NSString *resourceName = subdirectory.length > 0
          ? [subdirectory stringByAppendingPathComponent:name]
          : name;
      _composition = [LOTComposition animationNamed:resourceName inBundle:bundle];
    }
  }
  return self;
}

@end

@interface NECompatibleDictionaryTextProvider ()
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *values;
@end

@implementation NECompatibleDictionaryTextProvider {
  NSDictionary<NSString *, NSString *> *_values;
}

- (instancetype)initWithValues:(NSDictionary<NSString *,NSString *> *)values {
  self = [super init];
  if (self) {
    _values = [values copy];
  }
  return self;
}

@end

@interface NECompatibleAnimationView ()

@property (nonatomic, strong) LOTAnimationView *animationView;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *animationJSON;
@property (nonatomic, strong) NSMutableDictionary<NSString *, LOTColorValueCallback *> *colorCallbacks;
@property (nonatomic, assign) BOOL restoreAnimationWhenForegrounded;
@property (nonatomic, assign) NSUInteger playbackGeneration;

@end

@implementation NECompatibleAnimationView

- (instancetype)initWithCompatibleAnimation:(NECompatibleAnimation *)compatibleAnimation {
  return [self initWithCompatibleAnimation:compatibleAnimation
         compatibleRenderingEngineOption:NECompatibleRenderingEngineOptionShared];
}

- (instancetype)initWithCompatibleAnimation:(NECompatibleAnimation *)compatibleAnimation
           compatibleRenderingEngineOption:(NECompatibleRenderingEngineOption)compatibleRenderingEngineOption {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _compatibleAnimation = compatibleAnimation;
    _animationJSON = compatibleAnimation.animationJSON;
    LOTAnimationView *view = [[LOTAnimationView alloc] initWithModel:compatibleAnimation.composition
                                                           inBundle:nil];
    [self ne_commonInitWithAnimationView:view];
  }
  return self;
}

- (instancetype)initWithUrl:(NSURL *)url {
  return [self initWithUrl:url compatibleRenderingEngineOption:NECompatibleRenderingEngineOptionShared];
}

- (instancetype)initWithUrl:(NSURL *)url
  compatibleRenderingEngineOption:(NECompatibleRenderingEngineOption)compatibleRenderingEngineOption {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    [self ne_commonInitWithAnimationView:[[LOTAnimationView alloc] initWithContentsOfURL:url]];
    __weak typeof(self) weakSelf = self;
    [[[NSURLSession sharedSession] dataTaskWithURL:url
                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
      if (data.length == 0) {
        return;
      }
      id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
      if ([json isKindOfClass:[NSDictionary class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          weakSelf.animationJSON = json;
        });
      }
    }] resume];
  }
  return self;
}

- (instancetype)initWithData:(NSData *)data {
  return [self initWithData:data compatibleRenderingEngineOption:NECompatibleRenderingEngineOptionShared];
}

- (instancetype)initWithData:(NSData *)data
   compatibleRenderingEngineOption:(NECompatibleRenderingEngineOption)compatibleRenderingEngineOption {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSDictionary *dictionary = [json isKindOfClass:[NSDictionary class]] ? json : nil;
    _animationJSON = [dictionary copy];
    LOTAnimationView *view = dictionary
        ? [LOTAnimationView animationFromJSON:dictionary]
        : [[LOTAnimationView alloc] init];
    [self ne_commonInitWithAnimationView:view];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self ne_commonInitWithAnimationView:[[LOTAnimationView alloc] init]];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return nil;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)ne_commonInitWithAnimationView:(LOTAnimationView *)animationView {
  _loopAnimationCount = 0;
  _backgroundMode = NECompatibleBackgroundBehaviorPauseAndRestore;
  _colorCallbacks = [NSMutableDictionary dictionary];
  self.animationView = animationView;
  self.animationView.translatesAutoresizingMaskIntoConstraints = NO;
  [self addSubview:self.animationView];
  [NSLayoutConstraint activateConstraints:@[
    [self.animationView.topAnchor constraintEqualToAnchor:self.topAnchor],
    [self.animationView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    [self.animationView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
    [self.animationView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
  ]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(ne_didEnterBackground)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(ne_willEnterForeground)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
}

- (void)setCompatibleAnimation:(NECompatibleAnimation *)compatibleAnimation {
  _compatibleAnimation = compatibleAnimation;
  self.animationJSON = compatibleAnimation.animationJSON;
  self.animationView.sceneModel = compatibleAnimation.composition;
}

- (void)setLoopAnimationCount:(CGFloat)loopAnimationCount {
  _loopAnimationCount = loopAnimationCount;
  self.animationView.loopAnimation = loopAnimationCount == -1;
}

- (void)setContentMode:(UIViewContentMode)contentMode {
  self.animationView.contentMode = contentMode;
}

- (UIViewContentMode)contentMode {
  return self.animationView ? self.animationView.contentMode : [super contentMode];
}

- (void)setShouldRasterizeWhenIdle:(BOOL)shouldRasterizeWhenIdle {
  self.animationView.shouldRasterizeWhenIdle = shouldRasterizeWhenIdle;
}

- (BOOL)shouldRasterizeWhenIdle {
  return self.animationView.shouldRasterizeWhenIdle;
}

- (void)setCurrentProgress:(CGFloat)currentProgress {
  self.animationView.animationProgress = currentProgress;
}

- (CGFloat)currentProgress {
  return self.animationView.animationProgress;
}

- (CGFloat)duration {
  return self.animationView.animationDuration;
}

- (void)setCurrentTime:(NSTimeInterval)currentTime {
  self.currentProgress = self.duration > 0 ? currentTime / self.duration : 0;
}

- (NSTimeInterval)currentTime {
  return self.duration * self.currentProgress;
}

- (void)setCurrentFrame:(CGFloat)currentFrame {
  [self.animationView setProgressWithFrame:@(currentFrame)];
}

- (CGFloat)currentFrame {
  LOTComposition *composition = self.animationView.sceneModel;
  CGFloat start = composition.startFrame.doubleValue;
  CGFloat end = composition.endFrame.doubleValue;
  return start + (end - start) * self.currentProgress;
}

- (CGFloat)realtimeAnimationFrame {
  return self.currentFrame;
}

- (CGFloat)realtimeAnimationProgress {
  return self.currentProgress;
}

- (void)setAnimationSpeed:(CGFloat)animationSpeed {
  self.animationView.animationSpeed = animationSpeed;
}

- (CGFloat)animationSpeed {
  return self.animationView.animationSpeed;
}

- (BOOL)isAnimationPlaying {
  return self.animationView.isAnimationPlaying;
}

- (void)play {
  [self playWithCompletion:nil];
}

- (void)playWithCompletion:(void (^)(BOOL))completion {
  [self ne_playFromProgress:0 toProgress:1 completion:completion];
}

- (void)playFromProgress:(CGFloat)fromProgress
              toProgress:(CGFloat)toProgress
              completion:(void (^)(BOOL))completion {
  [self ne_playFromProgress:fromProgress toProgress:toProgress completion:completion];
}

- (void)playFromFrame:(CGFloat)fromFrame
              toFrame:(CGFloat)toFrame
           completion:(void (^)(BOOL))completion {
  LOTComposition *composition = self.animationView.sceneModel;
  CGFloat start = composition.startFrame.doubleValue;
  CGFloat end = composition.endFrame.doubleValue;
  CGFloat frameCount = end - start;
  if (frameCount == 0) {
    !completion ?: completion(NO);
    return;
  }
  [self ne_playFromProgress:(fromFrame - start) / frameCount
                 toProgress:(toFrame - start) / frameCount
                 completion:completion];
}

- (void)playFromMarker:(NSString *)fromMarker
               toMarker:(NSString *)toMarker
              completion:(void (^)(BOOL))completion {
  CGFloat fromFrame = [self frameTimeForMarker:fromMarker];
  CGFloat toFrame = [self frameTimeForMarker:toMarker];
  if ([self ne_markerNamed:fromMarker] == nil || [self ne_markerNamed:toMarker] == nil) {
    return;
  }
  [self playFromFrame:fromFrame toFrame:toFrame completion:completion];
}

- (void)playWithMarker:(NSString *)marker completion:(void (^)(BOOL))completion {
  NSDictionary *value = [self ne_markerNamed:marker];
  if (value == nil) {
    return;
  }
  CGFloat frame = [value[@"tm"] doubleValue];
  CGFloat duration = [value[@"dr"] doubleValue];
  [self playFromFrame:frame toFrame:frame + duration completion:completion];
}

- (void)stop {
  self.playbackGeneration += 1;
  [self.animationView stop];
}

- (void)pause {
  self.playbackGeneration += 1;
  [self.animationView pause];
}

- (void)reloadImages {
  CGFloat progress = self.currentProgress;
  LOTComposition *composition = self.animationView.sceneModel;
  self.animationView.sceneModel = composition;
  self.currentProgress = progress;
}

- (void)forceDisplayUpdate {
  [self.animationView forceDrawingUpdate];
}

- (id)getValueFor:(NECompatibleAnimationKeypath *)keypath atFrame:(CGFloat)atFrame {
  NSString *absoluteKeypath = keypath.lotKeypath.absoluteKeypath;
  if (absoluteKeypath.length == 0) {
    return nil;
  }

  [self.animationView keysForKeyPath:keypath.lotKeypath];
  id node = keypath.lotKeypath.searchResults[absoluteKeypath];
  NSDictionary *interpolators = nil;
  @try {
    interpolators = [node valueForKey:@"valueInterpolators"];
  } @catch (__unused NSException *exception) {
    LOTColorValueCallback *callback = self.colorCallbacks[absoluteKeypath];
    return callback ? [UIColor colorWithCGColor:callback.colorValue] : nil;
  }

  NSString *propertyName = absoluteKeypath.pathComponents.lastObject;
  if ([absoluteKeypath containsString:@"."]) {
    propertyName = [absoluteKeypath componentsSeparatedByString:@"."].lastObject;
  }
  id interpolator = interpolators[propertyName];
  NSNumber *frame = @(atFrame);
  if ([interpolator respondsToSelector:NSSelectorFromString(@"colorForFrame:")]) {
    CGColorRef (*sendColor)(id, SEL, NSNumber *) = (CGColorRef (*)(id, SEL, NSNumber *))objc_msgSend;
    CGColorRef color = sendColor(interpolator, NSSelectorFromString(@"colorForFrame:"), frame);
    return color ? [UIColor colorWithCGColor:color] : nil;
  }
  if ([interpolator respondsToSelector:NSSelectorFromString(@"floatValueForFrame:")]) {
    CGFloat (*sendFloat)(id, SEL, NSNumber *) = (CGFloat (*)(id, SEL, NSNumber *))objc_msgSend;
    return @(sendFloat(interpolator, NSSelectorFromString(@"floatValueForFrame:"), frame));
  }
  if ([interpolator respondsToSelector:NSSelectorFromString(@"pointValueForFrame:")]) {
    CGPoint (*sendPoint)(id, SEL, NSNumber *) = (CGPoint (*)(id, SEL, NSNumber *))objc_msgSend;
    return [NSValue valueWithCGPoint:sendPoint(interpolator, NSSelectorFromString(@"pointValueForFrame:"), frame)];
  }
  if ([interpolator respondsToSelector:NSSelectorFromString(@"sizeValueForFrame:")]) {
    CGSize (*sendSize)(id, SEL, NSNumber *) = (CGSize (*)(id, SEL, NSNumber *))objc_msgSend;
    return [NSValue valueWithCGSize:sendSize(interpolator, NSSelectorFromString(@"sizeValueForFrame:"), frame)];
  }
  if ([interpolator respondsToSelector:NSSelectorFromString(@"numberArrayForFrame:")]) {
    id (*sendObject)(id, SEL, NSNumber *) = (id (*)(id, SEL, NSNumber *))objc_msgSend;
    return sendObject(interpolator, NSSelectorFromString(@"numberArrayForFrame:"), frame);
  }
  LOTColorValueCallback *callback = self.colorCallbacks[absoluteKeypath];
  return callback ? [UIColor colorWithCGColor:callback.colorValue] : nil;
}

- (void)logHierarchyKeypaths {
  [self.animationView logHierarchyKeypaths];
}

- (void)setColorValue:(UIColor *)color forKeypath:(NECompatibleAnimationKeypath *)keypath {
  LOTColorValueCallback *callback = [LOTColorValueCallback withCGColor:color.CGColor];
  NSString *key = keypath.lotKeypath.absoluteKeypath ?: @"";
  self.colorCallbacks[key] = callback;
  [self.animationView setValueDelegate:callback forKeypath:keypath.lotKeypath];
}

- (UIColor *)getColorValueFor:(NECompatibleAnimationKeypath *)keypath atFrame:(CGFloat)atFrame {
  NSString *key = keypath.lotKeypath.absoluteKeypath ?: @"";
  LOTColorValueCallback *callback = self.colorCallbacks[key];
  if (callback) {
    return [UIColor colorWithCGColor:callback.colorValue];
  }
  id value = [self getValueFor:keypath atFrame:atFrame];
  return [value isKindOfClass:[UIColor class]] ? value : nil;
}

- (void)addSubview:(NEAnimationSubview *)subview forLayerAt:(NECompatibleAnimationKeypath *)keypath {
  [self.animationView addSubview:subview toKeypathLayer:keypath.lotKeypath];
}

- (CGRect)convertWithRect:(CGRect)rect toLayerAt:(NECompatibleAnimationKeypath *)keypath {
  return keypath ? [self.animationView convertRect:rect toKeypathLayer:keypath.lotKeypath] : rect;
}

- (CGPoint)convertWithPoint:(CGPoint)point toLayerAt:(NECompatibleAnimationKeypath *)keypath {
  return keypath ? [self.animationView convertPoint:point toKeypathLayer:keypath.lotKeypath] : point;
}

- (CGFloat)progressTimeForMarker:(NSString *)named {
  NSDictionary *marker = [self ne_markerNamed:named];
  if (marker == nil) {
    return 0;
  }
  LOTComposition *composition = self.animationView.sceneModel;
  CGFloat start = composition.startFrame.doubleValue;
  CGFloat end = composition.endFrame.doubleValue;
  return end == start ? 0 : ([marker[@"tm"] doubleValue] - start) / (end - start);
}

- (CGFloat)frameTimeForMarker:(NSString *)named {
  return [[self ne_markerNamed:named][@"tm"] ?: @0 doubleValue];
}

- (CGFloat)durationFrameTimeForMarker:(NSString *)named {
  return [[self ne_markerNamed:named][@"dr"] ?: @0 doubleValue];
}

- (NSDictionary<NSString *, id> *)ne_markerNamed:(NSString *)name {
  NSArray *markers = self.animationJSON[@"markers"];
  if (![markers isKindOfClass:[NSArray class]]) {
    return nil;
  }
  for (id value in markers) {
    if ([value isKindOfClass:[NSDictionary class]] && [value[@"cm"] isEqualToString:name]) {
      return value;
    }
  }
  return nil;
}

- (void)ne_playFromProgress:(CGFloat)fromProgress
                 toProgress:(CGFloat)toProgress
                 completion:(void (^)(BOOL))completion {
  NSUInteger generation = ++self.playbackGeneration;
  if (self.loopAnimationCount == -1) {
    self.animationView.loopAnimation = YES;
    [self.animationView playFromProgress:fromProgress
                              toProgress:toProgress
                          withCompletion:completion];
    return;
  }

  self.animationView.loopAnimation = NO;
  CGFloat requestedIterations = self.loopAnimationCount > 0 ? self.loopAnimationCount : 1;
  NSUInteger fullIterations = (NSUInteger)floor(requestedIterations);
  CGFloat partialIteration = requestedIterations - fullIterations;
  NSMutableArray<NSNumber *> *fractions = [NSMutableArray array];
  for (NSUInteger index = 0; index < fullIterations; index++) {
    [fractions addObject:@1];
  }
  if (partialIteration > DBL_EPSILON) {
    [fractions addObject:@(partialIteration)];
  }
  if (fractions.count == 0) {
    [fractions addObject:@1];
  }

  __weak typeof(self) weakSelf = self;
  __block NSUInteger iteration = 0;
  __block void (^playNext)(void) = nil;
  playNext = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf || strongSelf.playbackGeneration != generation) {
      playNext = nil;
      return;
    }
    CGFloat fraction = fractions[iteration].doubleValue;
    CGFloat iterationEnd = fromProgress + (toProgress - fromProgress) * fraction;
    [strongSelf.animationView playFromProgress:fromProgress
                                    toProgress:iterationEnd
                                withCompletion:^(BOOL finished) {
      __strong typeof(weakSelf) innerSelf = weakSelf;
      if (!innerSelf || innerSelf.playbackGeneration != generation) {
        playNext = nil;
        return;
      }
      if (!finished) {
        !completion ?: completion(NO);
        playNext = nil;
        return;
      }
      iteration += 1;
      if (iteration >= fractions.count) {
        !completion ?: completion(YES);
        playNext = nil;
      } else {
        playNext();
      }
    }];
  };
  playNext();
}

- (void)ne_didEnterBackground {
  self.restoreAnimationWhenForegrounded = NO;
  switch (self.backgroundMode) {
    case NECompatibleBackgroundBehaviorStop:
      [self stop];
      break;
    case NECompatibleBackgroundBehaviorPause:
      [self pause];
      break;
    case NECompatibleBackgroundBehaviorPauseAndRestore:
      self.restoreAnimationWhenForegrounded = self.isAnimationPlaying;
      [self pause];
      break;
    case NECompatibleBackgroundBehaviorForceFinish:
      [self pause];
      self.currentProgress = 1;
      break;
    case NECompatibleBackgroundBehaviorContinuePlaying:
      break;
  }
}

- (void)ne_willEnterForeground {
  if (self.restoreAnimationWhenForegrounded) {
    [self play];
    self.restoreAnimationWhenForegrounded = NO;
  }
}

@end
