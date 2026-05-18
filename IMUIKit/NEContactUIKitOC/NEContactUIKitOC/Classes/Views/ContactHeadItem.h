// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ContactHeadItem : NSObject

@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy, nullable) NSString *imageName;
@property (nonatomic, strong, nullable) UIColor *color;
@property (nonatomic, copy) NSString *router;

- (instancetype)initWithRouter:(NSString *)router
                          name:(nullable NSString *)name
                     imageName:(nullable NSString *)imageName
                         color:(nullable UIColor *)color;

@end

NS_ASSUME_NONNULL_END
