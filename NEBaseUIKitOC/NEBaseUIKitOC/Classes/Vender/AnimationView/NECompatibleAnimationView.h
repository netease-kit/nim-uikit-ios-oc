// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEAnimationSubview.h"
#import "NECompatibleAnimationKeypath.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NECompatibleBackgroundBehavior) {
  NECompatibleBackgroundBehaviorStop = 0,
  NECompatibleBackgroundBehaviorPause = 1,
  NECompatibleBackgroundBehaviorPauseAndRestore = 2,
  NECompatibleBackgroundBehaviorForceFinish = 3,
  NECompatibleBackgroundBehaviorContinuePlaying = 4,
};

typedef NS_ENUM(NSInteger, NECompatibleRenderingEngineOption) {
  NECompatibleRenderingEngineOptionShared = 0,
  NECompatibleRenderingEngineOptionDefaultEngine = 1,
  NECompatibleRenderingEngineOptionAutomatic = 2,
  NECompatibleRenderingEngineOptionMainThread = 3,
  NECompatibleRenderingEngineOptionCoreAnimation = 4,
};

/// Objective-C compatible wrapper around a named Lottie animation.
@interface NECompatibleAnimation : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithName:(NSString *)name
                 subdirectory:(nullable NSString *)subdirectory
                       bundle:(NSBundle *)bundle NS_DESIGNATED_INITIALIZER;

@end

/// Objective-C compatible dictionary text provider.
@interface NECompatibleDictionaryTextProvider : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithValues:(NSDictionary<NSString *, NSString *> *)values NS_DESIGNATED_INITIALIZER;

@end


/// Objective-C compatible animation view API matching the Swift UIKit wrapper.
@interface NECompatibleAnimationView : UIView

- (instancetype)initWithCompatibleAnimation:(NECompatibleAnimation *)compatibleAnimation;
- (instancetype)initWithCompatibleAnimation:(NECompatibleAnimation *)compatibleAnimation
           compatibleRenderingEngineOption:(NECompatibleRenderingEngineOption)compatibleRenderingEngineOption NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithUrl:(NSURL *)url;
- (instancetype)initWithUrl:(NSURL *)url
  compatibleRenderingEngineOption:(NECompatibleRenderingEngineOption)compatibleRenderingEngineOption NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithData:(NSData *)data;
- (instancetype)initWithData:(NSData *)data
   compatibleRenderingEngineOption:(NECompatibleRenderingEngineOption)compatibleRenderingEngineOption NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@property (nonatomic, strong, nullable) NECompatibleAnimation *compatibleAnimation;
@property (nonatomic, assign) CGFloat loopAnimationCount;
@property (nonatomic, strong, nullable) NECompatibleDictionaryTextProvider *compatibleDictionaryTextProvider;
@property (nonatomic, assign) BOOL shouldRasterizeWhenIdle;
@property (nonatomic, assign) CGFloat currentProgress;
@property (nonatomic, assign, readonly) CGFloat duration;
@property (nonatomic, assign) NSTimeInterval currentTime;
@property (nonatomic, assign) CGFloat currentFrame;
@property (nonatomic, assign, readonly) CGFloat realtimeAnimationFrame;
@property (nonatomic, assign, readonly) CGFloat realtimeAnimationProgress;
@property (nonatomic, assign) CGFloat animationSpeed;
@property (nonatomic, assign) BOOL respectAnimationFrameRate;
@property (nonatomic, assign, readonly) BOOL isAnimationPlaying;
@property (nonatomic, assign, readonly, getter=isAnimationPlaying) BOOL animationPlaying
    __attribute__((deprecated("Use isAnimationPlaying")));
@property (nonatomic, assign) NECompatibleBackgroundBehavior backgroundMode;

- (void)play;
- (void)playWithCompletion:(nullable void (^)(BOOL finished))completion;
- (void)playFromProgress:(CGFloat)fromProgress
              toProgress:(CGFloat)toProgress
              completion:(nullable void (^)(BOOL finished))completion;
- (void)playFromFrame:(CGFloat)fromFrame
              toFrame:(CGFloat)toFrame
           completion:(nullable void (^)(BOOL finished))completion;
- (void)playFromMarker:(NSString *)fromMarker
               toMarker:(NSString *)toMarker
              completion:(nullable void (^)(BOOL finished))completion;
- (void)playWithMarker:(NSString *)marker completion:(nullable void (^)(BOOL finished))completion;
- (void)stop;
- (void)pause;
- (void)reloadImages;
- (void)forceDisplayUpdate;
- (nullable id)getValueFor:(NECompatibleAnimationKeypath *)keypath atFrame:(CGFloat)atFrame;
- (void)logHierarchyKeypaths;
- (void)setColorValue:(UIColor *)color forKeypath:(NECompatibleAnimationKeypath *)keypath;
- (nullable UIColor *)getColorValueFor:(NECompatibleAnimationKeypath *)keypath atFrame:(CGFloat)atFrame;
- (void)addSubview:(NEAnimationSubview *)subview forLayerAt:(NECompatibleAnimationKeypath *)keypath;
- (CGRect)convertWithRect:(CGRect)rect toLayerAt:(nullable NECompatibleAnimationKeypath *)keypath;
- (CGPoint)convertWithPoint:(CGPoint)point toLayerAt:(nullable NECompatibleAnimationKeypath *)keypath;
- (CGFloat)progressTimeForMarker:(NSString *)named;
- (CGFloat)frameTimeForMarker:(NSString *)named;
- (CGFloat)durationFrameTimeForMarker:(NSString *)named;

@end

NS_ASSUME_NONNULL_END
