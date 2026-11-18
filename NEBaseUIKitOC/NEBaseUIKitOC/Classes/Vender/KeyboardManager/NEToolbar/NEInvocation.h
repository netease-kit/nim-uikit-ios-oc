// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEInvocation : NSObject

@property (nonatomic, weak, nullable) id target;
@property (nonatomic, assign) SEL action;

- (instancetype)init:(id)target :(SEL)action NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTarget:(id)target action:(SEL)action;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (void)invokeFrom:(id)sender;

@end

NS_ASSUME_NONNULL_END
