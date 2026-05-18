// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NEContentsAppearance) {
  NEContentsAppearanceViewDidAppear,
  NEContentsAppearanceViewWillAppear,
  NEContentsAppearanceViewDidDisappear,
  NEContentsAppearanceViewWillDisappear,
};

typedef NSArray * _Nullable (^NEContentsDequeueHandler)(void);

@protocol NEContentsAppearanceHandlerProtocol <NSObject>

@property (nonatomic, copy, nullable) NEContentsDequeueHandler contentsDequeueHandler;

- (void)beginDraggingAtIndex:(NSInteger)index;
- (void)stopScrollingAtIndex:(NSInteger)index;
- (void)callAppearance:(NEContentsAppearance)appearance
              animated:(BOOL)animated
               atIndex:(NSInteger)index;
- (void)preReloadAtIndex:(NSInteger)index;
- (void)postReloadAtIndex:(NSInteger)index;

@end

@interface NEContentsAppearanceHandler : NSObject <NEContentsAppearanceHandlerProtocol>

@property (nonatomic, copy, nullable) NEContentsDequeueHandler contentsDequeueHandler;

@end

NS_ASSUME_NONNULL_END
