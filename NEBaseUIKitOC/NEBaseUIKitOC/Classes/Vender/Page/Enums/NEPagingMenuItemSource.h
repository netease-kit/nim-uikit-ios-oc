// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NEPagingMenuItemSourceKind) {
  NEPagingMenuItemSourceKindClass = 0,
  NEPagingMenuItemSourceKindNib = 1,
};

@interface NEPagingMenuItemSource : NSObject

@property (nonatomic, assign, readonly) NEPagingMenuItemSourceKind kind;
@property (nonatomic, assign, readonly, nullable) Class cellClass;
@property (nonatomic, strong, readonly, nullable) UINib *nib;

+ (instancetype)sourceWithClass:(Class)cellClass;
+ (instancetype)sourceWithNib:(UINib *)nib;

@end

NS_ASSUME_NONNULL_END
