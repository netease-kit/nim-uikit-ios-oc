// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEKeyboardReturnKeyHandler.h"
#import "NEKeyboardManager.h"

@interface NETextFieldViewInfoModal : NSObject

@property (nonatomic, weak, nullable) UIView *textFieldView;
@property (nonatomic, weak, nullable) id<UITextFieldDelegate> textFieldDelegate;
@property (nonatomic, weak, nullable) id<UITextViewDelegate> textViewDelegate;
@property (nonatomic, assign) UIReturnKeyType originalReturnKeyType;

@end

@implementation NETextFieldViewInfoModal
@end

static NSArray<UIView *> *NEDeepResponderViews(UIView *view) {
  NSMutableArray<UIView *> *responders = [NSMutableArray array];
  for (UIView *subview in view.subviews) {
    if ([subview isKindOfClass:UITextField.class] || [subview isKindOfClass:UITextView.class]) {
      [responders addObject:subview];
    }
    NSArray<UIView *> *nested = NEDeepResponderViews(subview);
    if (nested.count) {
      [responders addObjectsFromArray:nested];
    }
  }
  return responders;
}

static UIView * _Nullable NESuperviewOfClassType(UIView *view, Class classType) {
  UIView *current = view.superview;
  while (current) {
    if ([current isKindOfClass:classType]) {
      return current;
    }
    current = current.superview;
  }
  return nil;
}

static NSArray<UIView *> *NEResponderSiblings(UIView *view) {
  UIView *container = view.superview ?: view;
  return NEDeepResponderViews(container);
}

static NSArray<UIView *> *NESortedArrayByTag(NSArray<UIView *> *views) {
  return [views sortedArrayUsingComparator:^NSComparisonResult(UIView *obj1, UIView *obj2) {
    if (obj1.tag == obj2.tag) {
      return NSOrderedSame;
    }
    return obj1.tag < obj2.tag ? NSOrderedAscending : NSOrderedDescending;
  }];
}

static NSArray<UIView *> *NESortedArrayByPosition(NSArray<UIView *> *views) {
  return [views sortedArrayUsingComparator:^NSComparisonResult(UIView *obj1, UIView *obj2) {
    CGPoint p1 = [obj1.superview convertPoint:obj1.frame.origin toView:nil];
    CGPoint p2 = [obj2.superview convertPoint:obj2.frame.origin toView:nil];
    if (fabs(p1.y - p2.y) > 1.0) {
      return p1.y < p2.y ? NSOrderedAscending : NSOrderedDescending;
    }
    if (fabs(p1.x - p2.x) > 1.0) {
      return p1.x < p2.x ? NSOrderedAscending : NSOrderedDescending;
    }
    return NSOrderedSame;
  }];
}

@interface NEKeyboardReturnKeyHandler ()

@property (nonatomic, strong) NSMutableArray<NETextFieldViewInfoModal *> *textFieldInfoCache;

@end

@implementation NEKeyboardReturnKeyHandler

- (instancetype)init {
  self = [super init];
  if (self) {
    _lastTextFieldReturnKeyType = UIReturnKeyDefault;
    _textFieldInfoCache = [NSMutableArray array];
  }
  return self;
}

- (instancetype)initWithController:(UIViewController *)controller {
  self = [self init];
  if (self) {
    [self addResponderFromView:controller.view];
  }
  return self;
}

- (void)dealloc {
  NSArray<NETextFieldViewInfoModal *> *cache = [self.textFieldInfoCache copy];
  for (NETextFieldViewInfoModal *modal in cache) {
    UIView *view = modal.textFieldView;
    if ([view isKindOfClass:UITextField.class]) {
      UITextField *textField = (UITextField *)view;
      textField.returnKeyType = modal.originalReturnKeyType;
      textField.delegate = modal.textFieldDelegate;
    } else if ([view isKindOfClass:UITextView.class]) {
      UITextView *textView = (UITextView *)view;
      textView.returnKeyType = modal.originalReturnKeyType;
      textView.delegate = modal.textViewDelegate;
    }
  }
}

- (void)setLastTextFieldReturnKeyType:(UIReturnKeyType)lastTextFieldReturnKeyType {
  _lastTextFieldReturnKeyType = lastTextFieldReturnKeyType;
  for (NETextFieldViewInfoModal *modal in self.textFieldInfoCache) {
    if (modal.textFieldView) {
      [self updateReturnKeyTypeOnTextField:modal.textFieldView];
    }
  }
}

- (void)addTextFieldView:(UIView *)view {
  if (![view isKindOfClass:UITextField.class] && ![view isKindOfClass:UITextView.class]) {
    return;
  }
  if ([self textFieldViewCachedInfo:view]) {
    [self updateReturnKeyTypeOnTextField:view];
    return;
  }

  NETextFieldViewInfoModal *modal = [[NETextFieldViewInfoModal alloc] init];
  modal.textFieldView = view;

  if ([view isKindOfClass:UITextField.class]) {
    UITextField *textField = (UITextField *)view;
    modal.originalReturnKeyType = textField.returnKeyType;
    modal.textFieldDelegate = textField.delegate;
    textField.delegate = self;
  } else {
    UITextView *textView = (UITextView *)view;
    modal.originalReturnKeyType = textView.returnKeyType;
    modal.textViewDelegate = textView.delegate;
    textView.delegate = self;
  }

  [self.textFieldInfoCache addObject:modal];
  [self updateReturnKeyTypeOnTextField:view];
}

- (void)removeTextFieldView:(UIView *)view {
  NETextFieldViewInfoModal *modal = [self textFieldViewCachedInfo:view];
  if (!modal) {
    return;
  }

  if ([view isKindOfClass:UITextField.class]) {
    UITextField *textField = (UITextField *)view;
    textField.returnKeyType = modal.originalReturnKeyType;
    textField.delegate = modal.textFieldDelegate;
  } else if ([view isKindOfClass:UITextView.class]) {
    UITextView *textView = (UITextView *)view;
    textView.returnKeyType = modal.originalReturnKeyType;
    textView.delegate = modal.textViewDelegate;
  }

  [self.textFieldInfoCache removeObject:modal];
}

- (void)addResponderFromView:(UIView *)view {
  for (UIView *responder in NEDeepResponderViews(view)) {
    [self addTextFieldView:responder];
  }
}

- (void)removeResponderFromView:(UIView *)view {
  for (UIView *responder in NEDeepResponderViews(view)) {
    [self removeTextFieldView:responder];
  }
}

- (NETextFieldViewInfoModal *)textFieldViewCachedInfo:(UIView *)textField {
  for (NETextFieldViewInfoModal *modal in self.textFieldInfoCache) {
    if (modal.textFieldView == textField) {
      return modal;
    }
  }
  return nil;
}

- (NSArray<UIView *> *)sortedRespondersForView:(UIView *)view {
  UIView *superConsideredView = nil;
  for (Class allowedClass in NEKeyboardManager.shared.toolbarPreviousNextAllowedClasses) {
    superConsideredView = NESuperviewOfClassType(view, allowedClass);
    if (superConsideredView) {
      break;
    }
  }

  NSArray<UIView *> *textFields = superConsideredView ? NEDeepResponderViews(superConsideredView) : NEResponderSiblings(view);

  switch (NEKeyboardManager.shared.toolbarManageBehaviour) {
    case NEAutoToolbarManageBehaviourByTag:
      return NESortedArrayByTag(textFields);
    case NEAutoToolbarManageBehaviourByPosition:
      return NESortedArrayByPosition(textFields);
    case NEAutoToolbarManageBehaviourBySubviews:
    default:
      return textFields;
  }
}

- (void)updateReturnKeyTypeOnTextField:(UIView *)view {
  NSArray<UIView *> *textFields = [self sortedRespondersForView:view];
  UIView *lastView = textFields.lastObject;
  UIReturnKeyType keyType = (view == lastView) ? self.lastTextFieldReturnKeyType : UIReturnKeyNext;
  if ([view isKindOfClass:UITextField.class]) {
    ((UITextField *)view).returnKeyType = keyType;
  } else if ([view isKindOfClass:UITextView.class]) {
    ((UITextView *)view).returnKeyType = keyType;
  }
}

- (BOOL)goToNextResponderOrResign:(UIView *)view {
  NSArray<UIView *> *textFields = [self sortedRespondersForView:view];
  NSUInteger index = [textFields indexOfObject:view];
  if (index == NSNotFound) {
    return YES;
  }

  if (index < textFields.count - 1) {
    [textFields[index + 1] becomeFirstResponder];
    return NO;
  }

  [view resignFirstResponder];
  return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  id<UITextFieldDelegate> delegate = self.delegate ?: [self textFieldViewCachedInfo:textField].textFieldDelegate;
  if ([delegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
    return [delegate textFieldShouldBeginEditing:textField];
  }
  return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
  id<UITextFieldDelegate> delegate = self.delegate ?: [self textFieldViewCachedInfo:textField].textFieldDelegate;
  if ([delegate respondsToSelector:@selector(textFieldShouldEndEditing:)]) {
    return [delegate textFieldShouldEndEditing:textField];
  }
  return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
  [self updateReturnKeyTypeOnTextField:textField];
  id<UITextFieldDelegate> delegate = self.delegate ?: [self textFieldViewCachedInfo:textField].textFieldDelegate;
  if ([delegate respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
    [delegate textFieldDidBeginEditing:textField];
  }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  id<UITextFieldDelegate> delegate = self.delegate ?: [self textFieldViewCachedInfo:textField].textFieldDelegate;
  if ([delegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
    [delegate textFieldDidEndEditing:textField];
  }
}

- (void)textFieldDidEndEditing:(UITextField *)textField reason:(UITextFieldDidEndEditingReason)reason API_AVAILABLE(ios(10.0)) {
  id<UITextFieldDelegate> delegate = self.delegate ?: [self textFieldViewCachedInfo:textField].textFieldDelegate;
  if ([delegate respondsToSelector:@selector(textFieldDidEndEditing:reason:)]) {
    [delegate textFieldDidEndEditing:textField reason:reason];
  } else if ([delegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
    [delegate textFieldDidEndEditing:textField];
  }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
  id<UITextFieldDelegate> delegate = self.delegate ?: [self textFieldViewCachedInfo:textField].textFieldDelegate;
  if ([delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
    return [delegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
  }
  return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
  id<UITextFieldDelegate> delegate = self.delegate ?: [self textFieldViewCachedInfo:textField].textFieldDelegate;
  if ([delegate respondsToSelector:@selector(textFieldShouldClear:)]) {
    return [delegate textFieldShouldClear:textField];
  }
  return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  BOOL shouldReturn = YES;
  id<UITextFieldDelegate> delegate = self.delegate ?: [self textFieldViewCachedInfo:textField].textFieldDelegate;
  if ([delegate respondsToSelector:@selector(textFieldShouldReturn:)]) {
    shouldReturn = [delegate textFieldShouldReturn:textField];
  }
  if (shouldReturn) {
    [self goToNextResponderOrResign:textField];
    return YES;
  }
  return [self goToNextResponderOrResign:textField];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
  id<UITextViewDelegate> delegate = self.delegate ?: [self textFieldViewCachedInfo:textView].textViewDelegate;
  if ([delegate respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
    return [delegate textViewShouldBeginEditing:textView];
  }
  return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
  id<UITextViewDelegate> delegate = self.delegate ?: [self textFieldViewCachedInfo:textView].textViewDelegate;
  if ([delegate respondsToSelector:@selector(textViewShouldEndEditing:)]) {
    return [delegate textViewShouldEndEditing:textView];
  }
  return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
  [self updateReturnKeyTypeOnTextField:textView];
  id<UITextViewDelegate> delegate = self.delegate ?: [self textFieldViewCachedInfo:textView].textViewDelegate;
  if ([delegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
    [delegate textViewDidBeginEditing:textView];
  }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
  id<UITextViewDelegate> delegate = self.delegate ?: [self textFieldViewCachedInfo:textView].textViewDelegate;
  if ([delegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
    [delegate textViewDidEndEditing:textView];
  }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  BOOL shouldReturn = YES;
  id<UITextViewDelegate> delegate = self.delegate ?: [self textFieldViewCachedInfo:textView].textViewDelegate;
  if ([delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
    shouldReturn = [delegate textView:textView shouldChangeTextInRange:range replacementText:text];
  }
  if (shouldReturn && [text isEqualToString:@"\n"]) {
    return [self goToNextResponderOrResign:textView];
  }
  return shouldReturn;
}

- (void)textViewDidChange:(UITextView *)textView {
  id<UITextViewDelegate> delegate = self.delegate ?: [self textFieldViewCachedInfo:textView].textViewDelegate;
  if ([delegate respondsToSelector:@selector(textViewDidChange:)]) {
    [delegate textViewDidChange:textView];
  }
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
  id<UITextViewDelegate> delegate = self.delegate ?: [self textFieldViewCachedInfo:textView].textViewDelegate;
  if ([delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
    [delegate textViewDidChangeSelection:textView];
  }
}

- (BOOL)textView:(UITextView *)textView
    shouldInteractWithURL:(NSURL *)URL
                  inRange:(NSRange)characterRange
              interaction:(UITextItemInteraction)interaction {
  if (!self.delegate) {
    id<UITextViewDelegate> delegate = [self textFieldViewCachedInfo:textView].textViewDelegate;
    if ([delegate respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:interaction:)]) {
      return [delegate textView:textView
          shouldInteractWithURL:URL
                        inRange:characterRange
                    interaction:interaction];
    }
  }
  return YES;
}

- (BOOL)textView:(UITextView *)textView
    shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment
                              inRange:(NSRange)characterRange
                          interaction:(UITextItemInteraction)interaction {
  if (!self.delegate) {
    id<UITextViewDelegate> delegate = [self textFieldViewCachedInfo:textView].textViewDelegate;
    if ([delegate respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:interaction:)]) {
      return [delegate textView:textView
          shouldInteractWithTextAttachment:textAttachment
                                    inRange:characterRange
                                interaction:interaction];
    }
  }
  return YES;
}

- (BOOL)textView:(UITextView *)textView
    shouldInteractWithURL:(NSURL *)URL
                  inRange:(NSRange)characterRange {
  if (!self.delegate) {
    id<UITextViewDelegate> delegate = [self textFieldViewCachedInfo:textView].textViewDelegate;
    if ([delegate respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)]) {
      return [delegate textView:textView shouldInteractWithURL:URL inRange:characterRange];
    }
  }
  return YES;
}

- (BOOL)textView:(UITextView *)textView
    shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment
                              inRange:(NSRange)characterRange {
  if (!self.delegate) {
    id<UITextViewDelegate> delegate = [self textFieldViewCachedInfo:textView].textViewDelegate;
    if ([delegate respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:)]) {
      return [delegate textView:textView
          shouldInteractWithTextAttachment:textAttachment
                                    inRange:characterRange];
    }
  }
  return YES;
}

@end
