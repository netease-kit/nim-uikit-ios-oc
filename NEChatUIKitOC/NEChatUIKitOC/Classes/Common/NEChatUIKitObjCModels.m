// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatUIKitObjCModels.h"

#import <NEChatKit/NECommonLoader.h>

#import "NEChatBaseViewController.h"

@interface LastReadPositionState ()
@property (nonatomic, assign, readwrite) LastReadPositionStateKind kind;
@property (nonatomic, strong, nullable, readwrite) NELastReadPositionSnapshot *snapshot;
@end

@implementation LastReadPositionState

- (instancetype)initWithKind:(LastReadPositionStateKind)kind
                     snapshot:(NELastReadPositionSnapshot *)snapshot {
  self = [super init];
  if (self) {
    _kind = kind;
    _snapshot = snapshot;
  }
  return self;
}

@end

@interface NEChatTextMentionSplitResult ()
@property (nonatomic, copy, readwrite) NSArray<NSString *> *parts;
@property (nonatomic, copy, readwrite) NSArray<NSNumber *> *atFlags;
@end

@implementation NEChatTextMentionSplitResult

- (instancetype)initWithParts:(NSArray<NSString *> *)parts
                       atFlags:(NSArray<NSNumber *> *)atFlags {
  self = [super init];
  if (self) {
    _parts = [parts copy];
    _atFlags = [atFlags copy];
  }
  return self;
}

@end

@interface NENotificationTeamStateResult ()
@property (nonatomic, assign, readwrite) BOOL isLeave;
@property (nonatomic, assign, readwrite) BOOL isDismiss;
@end

@implementation NENotificationTeamStateResult

- (instancetype)initWithIsLeave:(BOOL)isLeave isDismiss:(BOOL)isDismiss {
  self = [super init];
  if (self) {
    _isLeave = isLeave;
    _isDismiss = isDismiss;
  }
  return self;
}

@end

@interface NEChatUIKitImageResource ()
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSBundle *bundle;
@end

@implementation NEChatUIKitImageResource

- (instancetype)initWithName:(NSString *)name bundle:(NSBundle *)bundle {
  self = [super init];
  if (self) {
    _name = [name copy];
    _bundle = bundle;
  }
  return self;
}

- (UIImage *)image {
  NECommonLoader *loader = [[NECommonLoader alloc] initWithClass:[NEChatBaseViewController class]];
  return [loader loadImage:self.name];
}

@end

@implementation NEMarkdownEnabledElements

- (instancetype)initWithRawValue:(NSUInteger)rawValue {
  self = [super init];
  if (self) {
    _rawValue = rawValue;
  }
  return self;
}

+ (instancetype)elementsWithRawValue:(NSUInteger)rawValue {
  return [[self alloc] initWithRawValue:rawValue];
}

+ (instancetype)automaticLink { return [self elementsWithRawValue:1UL << 0]; }
+ (instancetype)header { return [self elementsWithRawValue:1UL << 1]; }
+ (instancetype)list { return [self elementsWithRawValue:1UL << 2]; }
+ (instancetype)quote { return [self elementsWithRawValue:1UL << 3]; }
+ (instancetype)link { return [self elementsWithRawValue:1UL << 4]; }
+ (instancetype)bold { return [self elementsWithRawValue:1UL << 5]; }
+ (instancetype)italic { return [self elementsWithRawValue:1UL << 6]; }
+ (instancetype)code { return [self elementsWithRawValue:1UL << 7]; }
+ (instancetype)strikethrough { return [self elementsWithRawValue:1UL << 8]; }
+ (instancetype)table { return [self elementsWithRawValue:1UL << 9]; }
+ (instancetype)orderedList { return [self elementsWithRawValue:1UL << 10]; }
+ (instancetype)horizontalRule { return [self elementsWithRawValue:1UL << 11]; }
+ (instancetype)image { return [self elementsWithRawValue:1UL << 12]; }

+ (instancetype)disabledAutomaticLink {
  return [self elementsWithRawValue:(1UL << 13) - 2];
}

+ (instancetype)all {
  return [self elementsWithRawValue:(1UL << 13) - 1];
}

- (BOOL)contains:(NEMarkdownEnabledElements *)other {
  return (self.rawValue & other.rawValue) == other.rawValue;
}

- (NEMarkdownEnabledElements *)adding:(NEMarkdownEnabledElements *)other {
  return [[[self class] alloc] initWithRawValue:self.rawValue | other.rawValue];
}

- (NEMarkdownEnabledElements *)removing:(NEMarkdownEnabledElements *)other {
  return [[[self class] alloc] initWithRawValue:self.rawValue & ~other.rawValue];
}

@end
