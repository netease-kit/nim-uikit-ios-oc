// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class NELastReadPositionSnapshot;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LastReadPositionStateKind) {
  LastReadPositionStateKindDisabled = 0,
  LastReadPositionStateKindReady = 1,
  LastReadPositionStateKindVisible = 2,
  LastReadPositionStateKindLocating = 3,
  LastReadPositionStateKindConsumed = 4,
};

@interface LastReadPositionState : NSObject

@property (nonatomic, assign, readonly) LastReadPositionStateKind kind;
@property (nonatomic, strong, nullable, readonly) NELastReadPositionSnapshot *snapshot;

- (instancetype)initWithKind:(LastReadPositionStateKind)kind
                     snapshot:(nullable NELastReadPositionSnapshot *)snapshot NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

@interface NEChatTextMentionSplitResult : NSObject

@property (nonatomic, copy, readonly) NSArray<NSString *> *parts;
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *atFlags;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

@interface NENotificationTeamStateResult : NSObject

@property (nonatomic, assign, readonly) BOOL isLeave;
@property (nonatomic, assign, readonly) BOOL isDismiss;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

@interface NEChatUIKitImageResource : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSBundle *bundle;
@property (nonatomic, strong, nullable, readonly) UIImage *image;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

@interface NEMarkdownEnabledElements : NSObject

@property (nonatomic, assign, readonly) NSUInteger rawValue;

- (instancetype)initWithRawValue:(NSUInteger)rawValue NS_DESIGNATED_INITIALIZER;

@property (class, nonatomic, strong, readonly) NEMarkdownEnabledElements *automaticLink;
@property (class, nonatomic, strong, readonly) NEMarkdownEnabledElements *header;
@property (class, nonatomic, strong, readonly) NEMarkdownEnabledElements *list;
@property (class, nonatomic, strong, readonly) NEMarkdownEnabledElements *quote;
@property (class, nonatomic, strong, readonly) NEMarkdownEnabledElements *link;
@property (class, nonatomic, strong, readonly) NEMarkdownEnabledElements *bold;
@property (class, nonatomic, strong, readonly) NEMarkdownEnabledElements *italic;
@property (class, nonatomic, strong, readonly) NEMarkdownEnabledElements *code;
@property (class, nonatomic, strong, readonly) NEMarkdownEnabledElements *strikethrough;
@property (class, nonatomic, strong, readonly) NEMarkdownEnabledElements *table;
@property (class, nonatomic, strong, readonly) NEMarkdownEnabledElements *orderedList;
@property (class, nonatomic, strong, readonly) NEMarkdownEnabledElements *horizontalRule;
@property (class, nonatomic, strong, readonly) NEMarkdownEnabledElements *image;
@property (class, nonatomic, strong, readonly) NEMarkdownEnabledElements *disabledAutomaticLink;
@property (class, nonatomic, strong, readonly) NEMarkdownEnabledElements *all;

- (BOOL)contains:(NEMarkdownEnabledElements *)other;
- (NEMarkdownEnabledElements *)adding:(NEMarkdownEnabledElements *)other;
- (NEMarkdownEnabledElements *)removing:(NEMarkdownEnabledElements *)other;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
