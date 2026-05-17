// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UIAlertController.h"

@implementation UIAlertController (NECommonUIKit)

- (void)fixIpadAction {
  if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
    self.popoverPresentationController.sourceView = self.view;
    self.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds),
                                                               CGRectGetMidY(self.view.bounds),
                                                               0,
                                                               0);
    self.popoverPresentationController.permittedArrowDirections = 0;
  }
}

@end

