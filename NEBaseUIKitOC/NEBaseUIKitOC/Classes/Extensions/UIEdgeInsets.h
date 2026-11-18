// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_INLINE CGFloat NEUIEdgeInsetsHorizontal(UIEdgeInsets insets) {
  return insets.left + insets.right;
}

NS_INLINE CGFloat NEUIEdgeInsetsVertical(UIEdgeInsets insets) {
  return insets.top + insets.bottom;
}

