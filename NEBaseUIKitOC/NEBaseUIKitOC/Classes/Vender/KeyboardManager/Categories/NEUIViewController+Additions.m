// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEUIViewController+Additions.h"
#import <objc/runtime.h>

static void *NELayoutGuideConstraintKey = &NELayoutGuideConstraintKey;

@implementation UIViewController (NEAdditions)

- (UIViewController *)neParentNEContainerViewController {
  return self;
}

- (NSLayoutConstraint *)neLayoutGuideConstraint {
  return objc_getAssociatedObject(self, NELayoutGuideConstraintKey);
}

- (void)setNeLayoutGuideConstraint:(NSLayoutConstraint *)neLayoutGuideConstraint {
  objc_setAssociatedObject(self, NELayoutGuideConstraintKey, neLayoutGuideConstraint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
