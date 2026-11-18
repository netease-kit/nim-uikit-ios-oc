// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationBaseViewController.h"
#import "ConversationUIConfig.h"
#import <NEBaseUIKitOC/CommonUIConfig.h>

@implementation NEConversationBaseViewController

- (BOOL)shouldShowTitleBar {
  return ConversationUIConfig.shared.showTitleBar;
}

- (BOOL)shouldBindMoreButtonAction { return NO; }

- (void)setupBackUI {
  UIImage *image = [CommonUIConfig.shared.backArrowImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:image
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(backEvent)];
  backItem.accessibilityIdentifier = @"id.backArrow";
  self.navigationItem.leftBarButtonItem = backItem;
}

@end
