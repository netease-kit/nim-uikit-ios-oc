// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEUIView+NEKeyboardToolbar.h"
#import "NEToolbar.h"
#import "NETextView.h"
#import <objc/runtime.h>

@implementation NEBarButtonItemConfiguration

- (instancetype)initWithBarButtonSystemItem:(UIBarButtonSystemItem)barButtonSystemItem
                                     action:(SEL)action {
  self = [super init];
  if (self) {
    _barButtonSystemItem = barButtonSystemItem;
    _hasSystemItem = YES;
    _action = action;
  }
  return self;
}

- (instancetype)initWithImage:(UIImage *)image action:(SEL)action {
  self = [super init];
  if (self) {
    _image = image;
    _action = action;
  }
  return self;
}

- (instancetype)initWithTitle:(NSString *)title action:(SEL)action {
  self = [super init];
  if (self) {
    _title = [title copy];
    _action = action;
  }
  return self;
}

@end

static UIImage *NEKeyboardToolbarArrowImage(CGFloat width, CGFloat height, CGFloat lineWidth, CGPoint start, CGPoint mid, CGPoint end) {
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 0);
  CGContextRef context = UIGraphicsGetCurrentContext();
  if (!context) {
    UIGraphicsEndImageContext();
    return nil;
  }
  CGContextSetStrokeColorWithColor(context, UIColor.blackColor.CGColor);
  CGContextSetLineWidth(context, lineWidth);
  CGContextSetLineCap(context, kCGLineCapRound);
  CGContextMoveToPoint(context, start.x, start.y);
  CGContextAddLineToPoint(context, mid.x, mid.y);
  CGContextAddLineToPoint(context, end.x, end.y);
  CGContextStrokePath(context);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

@implementation UIImage (NEKeyboardToolbarImage)

+ (UIImage *)neKeyboardLeftImage {
  UIImage *image = NEKeyboardToolbarArrowImage(20, 20, 2.5, CGPointMake(12, 4), CGPointMake(6, 10), CGPointMake(12, 16));
  return [image imageFlippedForRightToLeftLayoutDirection];
}

+ (UIImage *)neKeyboardRightImage {
  UIImage *image = NEKeyboardToolbarArrowImage(20, 20, 2.5, CGPointMake(8, 4), CGPointMake(14, 10), CGPointMake(8, 16));
  return [image imageFlippedForRightToLeftLayoutDirection];
}

+ (UIImage *)neKeyboardUpImage {
  return NEKeyboardToolbarArrowImage(20, 20, 2.5, CGPointMake(4, 12), CGPointMake(10, 6), CGPointMake(16, 12));
}

+ (UIImage *)neKeyboardDownImage {
  return NEKeyboardToolbarArrowImage(20, 20, 2.5, CGPointMake(4, 8), CGPointMake(10, 14), CGPointMake(16, 8));
}

+ (UIImage *)neKeyboardPreviousImage {
  if (@available(iOS 10.0, *)) {
    return [self neKeyboardUpImage];
  }
  return [self neKeyboardLeftImage];
}

+ (UIImage *)neKeyboardNextImage {
  if (@available(iOS 10.0, *)) {
    return [self neKeyboardDownImage];
  }
  return [self neKeyboardRightImage];
}

@end

static void *NEKeyboardToolbarKey = &NEKeyboardToolbarKey;
static void *NEShouldHideToolbarPlaceholderKey = &NEShouldHideToolbarPlaceholderKey;
static void *NEToolbarPlaceholderKey = &NEToolbarPlaceholderKey;

static NEBarButtonItem *NEFlexibleBarButtonItem(void) {
  static NEBarButtonItem *item;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    item = [[NEBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    item.isSystemItem = YES;
  });
  return item;
}

static NEBarButtonItem *NEKeyboardToolbarBarButton(NEBarButtonItemConfiguration *configuration,
                                                   UIBarButtonItemStyle defaultStyle,
                                                   id target) {
  if (!configuration) {
    return nil;
  }

  NEBarButtonItem *item = nil;
  if (configuration.hasSystemItem) {
    item = [[NEBarButtonItem alloc] initWithBarButtonSystemItem:configuration.barButtonSystemItem
                                                         target:target
                                                         action:configuration.action];
    item.isSystemItem = YES;
  } else if (configuration.image) {
    item = [[NEBarButtonItem alloc] initWithImage:configuration.image
                                            style:defaultStyle
                                           target:target
                                           action:configuration.action];
  } else {
    item = [[NEBarButtonItem alloc] initWithTitle:configuration.title
                                            style:defaultStyle
                                           target:target
                                           action:configuration.action];
  }
  item.accessibilityLabel = configuration.accessibilityLabel;
  item.accessibilityIdentifier = configuration.accessibilityLabel;
  return item;
}

@implementation UIView (NEKeyboardToolbar)

- (NEToolbar *)neKeyboardToolbar {
  NEToolbar *toolbar = nil;
  if ([self respondsToSelector:@selector(inputAccessoryView)]) {
    toolbar = (NEToolbar *)[self valueForKey:@"inputAccessoryView"];
    if ([toolbar isKindOfClass:NEToolbar.class]) {
      return toolbar;
    }
  }

  toolbar = objc_getAssociatedObject(self, NEKeyboardToolbarKey);
  if (!toolbar) {
    toolbar = [[NEToolbar alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 44.0)];
    objc_setAssociatedObject(self, NEKeyboardToolbarKey, toolbar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return toolbar;
}

- (void)setNeKeyboardToolbar:(NEToolbar *)neKeyboardToolbar {
  objc_setAssociatedObject(self, NEKeyboardToolbarKey, neKeyboardToolbar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)neShouldHideToolbarPlaceholder {
  return [objc_getAssociatedObject(self, NEShouldHideToolbarPlaceholderKey) boolValue];
}

- (void)setNeShouldHideToolbarPlaceholder:(BOOL)neShouldHideToolbarPlaceholder {
  objc_setAssociatedObject(self, NEShouldHideToolbarPlaceholderKey, @(neShouldHideToolbarPlaceholder), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  self.neKeyboardToolbar.titleBarButton.title = self.neDrawingToolbarPlaceholder;
}

- (NSString *)neToolbarPlaceholder {
  return objc_getAssociatedObject(self, NEToolbarPlaceholderKey);
}

- (void)setNeToolbarPlaceholder:(NSString *)neToolbarPlaceholder {
  objc_setAssociatedObject(self, NEToolbarPlaceholderKey, neToolbarPlaceholder, OBJC_ASSOCIATION_COPY_NONATOMIC);
  self.neKeyboardToolbar.titleBarButton.title = self.neDrawingToolbarPlaceholder;
}

- (NSString *)neDrawingToolbarPlaceholder {
  if (self.neShouldHideToolbarPlaceholder) {
    return nil;
  }
  if (self.neToolbarPlaceholder.length > 0) {
    return self.neToolbarPlaceholder;
  }
  if ([self isKindOfClass:UITextField.class]) {
    return ((UITextField *)self).placeholder;
  }
  if ([self isKindOfClass:NETextView.class]) {
    return ((NETextView *)self).placeholder;
  }
  return nil;
}

- (void)neAddKeyboardToolbarWithTarget:(id)target
                             titleText:(NSString *)titleText
           rightBarButtonConfiguration:(NEBarButtonItemConfiguration *)rightBarButtonConfiguration
        previousBarButtonConfiguration:(NEBarButtonItemConfiguration *)previousBarButtonConfiguration
            nextBarButtonConfiguration:(NEBarButtonItemConfiguration *)nextBarButtonConfiguration {
  if (![self respondsToSelector:@selector(setInputAccessoryView:)]) {
    return;
  }

  NEToolbar *toolbar = self.neKeyboardToolbar;
  NSMutableArray<UIBarButtonItem *> *items = [NSMutableArray array];

  NEBarButtonItem *previous = NEKeyboardToolbarBarButton(previousBarButtonConfiguration, UIBarButtonItemStylePlain, target);
  if (previous) {
    toolbar.previousBarButton = previous;
    [items addObject:previous];
  }

  if (previous && nextBarButtonConfiguration) {
    [items addObject:toolbar.fixedSpaceBarButton];
  }

  NEBarButtonItem *next = NEKeyboardToolbarBarButton(nextBarButtonConfiguration, UIBarButtonItemStylePlain, target);
  if (next) {
    toolbar.nextBarButton = next;
    [items addObject:next];
  }

  [items addObject:NEFlexibleBarButtonItem()];
  toolbar.titleBarButton.title = titleText;
  [items addObject:toolbar.titleBarButton];
  [items addObject:NEFlexibleBarButtonItem()];

  NEBarButtonItem *right = NEKeyboardToolbarBarButton(rightBarButtonConfiguration, UIBarButtonItemStyleDone, target);
  if (right) {
    toolbar.doneBarButton = right;
    [items addObject:right];
  }

  toolbar.items = items;

  if ([self conformsToProtocol:@protocol(UITextInput)]) {
    UIKeyboardAppearance appearance = UIKeyboardAppearanceDefault;
    if ([self respondsToSelector:@selector(keyboardAppearance)]) {
      NSMethodSignature *signature = [(NSObject *)self methodSignatureForSelector:@selector(keyboardAppearance)];
      if (signature) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.selector = @selector(keyboardAppearance);
        [invocation invokeWithTarget:self];
        [invocation getReturnValue:&appearance];
      }
    }
    toolbar.barStyle = appearance == UIKeyboardAppearanceDark ? UIBarStyleBlack : UIBarStyleDefault;
  }

  if ([self isKindOfClass:UITextField.class]) {
    ((UITextField *)self).inputAccessoryView = toolbar;
  } else if ([self isKindOfClass:UITextView.class]) {
    ((UITextView *)self).inputAccessoryView = toolbar;
  }
}

- (void)neAddDoneOnKeyboardWithTarget:(id)target action:(SEL)action {
  [self neAddDoneOnKeyboardWithTarget:target action:action shouldShowPlaceholder:NO];
}

- (void)neAddDoneOnKeyboardWithTarget:(id)target
                               action:(SEL)action
               shouldShowPlaceholder:(BOOL)shouldShowPlaceholder {
  NEBarButtonItemConfiguration *right = [[NEBarButtonItemConfiguration alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone action:action];
  [self neAddKeyboardToolbarWithTarget:target
                             titleText:shouldShowPlaceholder ? self.neDrawingToolbarPlaceholder : nil
           rightBarButtonConfiguration:right
        previousBarButtonConfiguration:nil
            nextBarButtonConfiguration:nil];
}

- (void)neAddRightButtonOnKeyboardWithImage:(UIImage *)image
                                     target:(id)target
                                     action:(SEL)action {
  NEBarButtonItemConfiguration *right = [[NEBarButtonItemConfiguration alloc] initWithImage:image action:action];
  [self neAddKeyboardToolbarWithTarget:target
                             titleText:nil
           rightBarButtonConfiguration:right
        previousBarButtonConfiguration:nil
            nextBarButtonConfiguration:nil];
}

- (void)neAddRightButtonOnKeyboardWithText:(NSString *)text
                                    target:(id)target
                                    action:(SEL)action {
  NEBarButtonItemConfiguration *right = [[NEBarButtonItemConfiguration alloc] initWithTitle:text action:action];
  [self neAddKeyboardToolbarWithTarget:target
                             titleText:nil
           rightBarButtonConfiguration:right
        previousBarButtonConfiguration:nil
            nextBarButtonConfiguration:nil];
}

- (void)neAddCancelDoneOnKeyboardWithTarget:(id)target
                               cancelAction:(SEL)cancelAction
                                 doneAction:(SEL)doneAction {
  NEBarButtonItemConfiguration *left = [[NEBarButtonItemConfiguration alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel action:cancelAction];
  NEBarButtonItemConfiguration *right = [[NEBarButtonItemConfiguration alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone action:doneAction];
  [self neAddKeyboardToolbarWithTarget:target
                             titleText:nil
           rightBarButtonConfiguration:right
        previousBarButtonConfiguration:left
            nextBarButtonConfiguration:nil];
}

- (void)neAddPreviousNextDoneOnKeyboardWithTarget:(id)target
                                   previousAction:(SEL)previousAction
                                       nextAction:(SEL)nextAction
                                       doneAction:(SEL)doneAction {
  NEBarButtonItemConfiguration *right = [[NEBarButtonItemConfiguration alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone action:doneAction];
  NEBarButtonItemConfiguration *next = [[NEBarButtonItemConfiguration alloc] initWithImage:[UIImage neKeyboardNextImage] ?: UIImage.new action:nextAction];
  NEBarButtonItemConfiguration *previous = [[NEBarButtonItemConfiguration alloc] initWithImage:[UIImage neKeyboardPreviousImage] ?: UIImage.new action:previousAction];
  [self neAddKeyboardToolbarWithTarget:target
                             titleText:nil
           rightBarButtonConfiguration:right
        previousBarButtonConfiguration:previous
            nextBarButtonConfiguration:next];
}

@end
