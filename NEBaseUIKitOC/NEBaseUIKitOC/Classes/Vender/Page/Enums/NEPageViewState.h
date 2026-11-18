// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NEPageViewState) {
  NEPageViewStateEmpty = 0,
  NEPageViewStateSingle = 1,
  NEPageViewStateFirst = 2,
  NEPageViewStateCenter = 3,
  NEPageViewStateLast = 4,
};

NS_INLINE NSInteger NEPageViewStateCount(NEPageViewState state) {
  switch (state) {
    case NEPageViewStateEmpty:
      return 0;
    case NEPageViewStateSingle:
      return 1;
    case NEPageViewStateFirst:
    case NEPageViewStateLast:
      return 2;
    case NEPageViewStateCenter:
      return 3;
  }
}

NS_ASSUME_NONNULL_END
