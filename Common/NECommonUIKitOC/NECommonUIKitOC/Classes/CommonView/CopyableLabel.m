// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CopyableLabel.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "NECommonUIConstant.h"
#import "UIView+YXToast.h"

@implementation CopyableLabel

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self sharedInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self sharedInit];
  }
  return self;
}

- (void)sharedInit {
  self.userInteractionEnabled = YES;
  UILongPressGestureRecognizer *longPress =
      [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showMenu:)];
  [self addGestureRecognizer:longPress];
}

- (BOOL)canBecomeFirstResponder {
  return YES;
}

- (void)copyText:(id)sender {
  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  pasteboard.string = self.copyString ?: self.text;

  [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];

  UIView *toastHost = self.window;
  if (toastHost) {
    [toastHost neMakeToast:commonLocalizable(@"copy_success") position:NEToastPositionCenter];
  }
}

- (void)copy:(id)sender {
  if (self.attributedText.length > 0) {
    NSDictionary *documentAttributes = @{
      NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType,
    };
    NSError *error = nil;
    NSData *data = [self.attributedText dataFromRange:NSMakeRange(0, self.attributedText.length)
                                   documentAttributes:documentAttributes
                                                error:&error];
    if (data.length > 0 && !error) {
      [[UIPasteboard generalPasteboard] setData:data
                               forPasteboardType:(NSString *)kUTTypeRTF];
    }
  }

  [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
}

- (void)showMenu:(UILongPressGestureRecognizer *)gesture {
  if (gesture.state != UIGestureRecognizerStateBegan) {
    return;
  }

  [self becomeFirstResponder];
  UIMenuController *menu = [UIMenuController sharedMenuController];
  if (!menu.isMenuVisible) {
    UIMenuItem *copyMenu =
        [[UIMenuItem alloc] initWithTitle:commonLocalizable(@"copy")
                                   action:@selector(copyText:)];
    menu.menuItems = @[ copyMenu ];
    [menu setTargetRect:self.bounds inView:self];
    [menu setMenuVisible:YES animated:YES];
  }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
  if (action == @selector(copyText:)) {
    return YES;
  }
  return NO;
}

@end
