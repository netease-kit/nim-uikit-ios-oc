// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "InputPersonInfoController.h"
#import <NEBaseUIKitOC/SearchTextField.h>
#import "AppKey.h"
#import "NEStyleManager.h"
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEChatKit/NEAppLanguageUtil.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatUIKitOC/FunChatUIColor.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEBaseUIKitOC/NENavigationView.h>
#import <NEBaseUIKitOC/UIView+YXToast.h>
#import <NETeamUIKitOC/TeamConstant.h>

@interface InputPersonInfoController () <UITextFieldDelegate, UITextViewDelegate>
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UITextView *signatureTextView;
@property (nonatomic, strong) UIButton *signatureClearButton;
@property (nonatomic, strong) UIView      *textfieldBgView;
@property (nonatomic, assign) NSInteger    limitCount;
@property (nonatomic, assign) NEEditType   editType;
@end

@implementation InputPersonInfoController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupSubviews];
  [self initialConfig];

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    if (self.editType == NEEditTypeSpecialSign) {
      [self.signatureTextView becomeFirstResponder];
    } else {
      [self.textField becomeFirstResponder];
    }
  });
}

- (void)setupSubviews {
  _textfieldBgView = [[UIView alloc] init];
  _textfieldBgView.translatesAutoresizingMaskIntoConstraints = NO;
  _textfieldBgView.backgroundColor = UIColor.whiteColor;
  _textfieldBgView.clipsToBounds = YES;
  _textfieldBgView.layer.cornerRadius = [NEStyleManager.instance isNormalStyle] ? 8 : 0;
  [self.view addSubview:_textfieldBgView];

  _textField = [[NESingleLineTextField alloc] init];
  _textField.translatesAutoresizingMaskIntoConstraints = NO;
  _textField.textColor = [UIColor colorWithRed:0x33/255.0 green:0x33/255.0 blue:0x33/255.0 alpha:1.0];
  _textField.font = [UIFont systemFontOfSize:14];
  _textField.delegate = self;
  _textField.clearButtonMode = UITextFieldViewModeAlways;
  _textField.accessibilityIdentifier = @"id.nickname";
  _textField.text = self.contentText;
  [_textField addTarget:self action:@selector(textFieldChange) forControlEvents:UIControlEventEditingChanged];
  UIButton *clearButton = [_textField valueForKey:@"_clearButton"];
  if ([clearButton isKindOfClass:UIButton.class]) {
    clearButton.accessibilityIdentifier = @"id.clear";
  }
  self.signatureTextView = [[UITextView alloc] init];
  self.signatureTextView.translatesAutoresizingMaskIntoConstraints = NO;
  self.signatureTextView.font = _textField.font;
  self.signatureTextView.textColor = _textField.textColor;
  self.signatureTextView.backgroundColor = UIColor.clearColor;
  self.signatureTextView.textContainer.lineFragmentPadding = 0;
  self.signatureTextView.delegate = self;
  self.signatureTextView.accessibilityIdentifier = @"id.signature";
  self.signatureTextView.text = self.contentText;
  BOOL isSignature = self.editType == NEEditTypeSpecialSign;
  UIView *inputView = isSignature ? self.signatureTextView : _textField;
  [_textfieldBgView addSubview:inputView];
  if (isSignature) {
    [_textfieldBgView addSubview:self.signatureClearButton];
  }

  CGFloat leftInset = [NEStyleManager.instance isNormalStyle] ? 20 : 0;

  [NSLayoutConstraint activateConstraints:@[
    [_textfieldBgView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:leftInset],
    [_textfieldBgView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-leftInset],
    [_textfieldBgView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:12 + self.topConstant],
    [_textfieldBgView.heightAnchor constraintEqualToConstant:isSignature ? 120 : 50],

    [inputView.leftAnchor constraintEqualToAnchor:_textfieldBgView.leftAnchor constant:16],
    [inputView.rightAnchor constraintEqualToAnchor:_textfieldBgView.rightAnchor constant:isSignature ? -44 : -12],
    [inputView.centerYAnchor constraintEqualToAnchor:_textfieldBgView.centerYAnchor],
  ]];
  if (isSignature) {
    [self.signatureTextView.heightAnchor constraintEqualToAnchor:_textfieldBgView.heightAnchor constant:-16].active = YES;
    [NSLayoutConstraint activateConstraints:@[
      [self.signatureClearButton.rightAnchor constraintEqualToAnchor:_textfieldBgView.rightAnchor constant:-12],
      [self.signatureClearButton.centerYAnchor constraintEqualToAnchor:_textfieldBgView.centerYAnchor],
      [self.signatureClearButton.widthAnchor constraintEqualToConstant:16],
      [self.signatureClearButton.heightAnchor constraintEqualToConstant:16],
    ]];
    [self updateSignatureClearButton];
  }

  [self applyKeyboardTypeForCurrentEditType];
}

- (void)initialConfig {
  BOOL isNormalStyle = [NEStyleManager.instance isNormalStyle];
  NSString *completeTitle = commonLocalizable(@"complete");

  self.view.backgroundColor = isNormalStyle ? [UIColor ne_backgroundColor] : [UIColor funChatBackgroundColor];
  [self.navigationView setMoreButtonTitle:completeTitle];
  [self.navigationView setMoreButtonWidth:[NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? 80 : 60];
  [self.navigationView addMoreButtonTarget:self selector:@selector(saveName)];

  if (isNormalStyle) {
    self.navigationView.backgroundColor = [UIColor ne_backgroundColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor ne_backgroundColor];
    [self.navigationView.moreButton setTitleColor:[UIColor ne_greyText] forState:UIControlStateNormal];
  } else {
    [self.navigationView.moreButton setTitleColor:[UIColor funChatThemeColor] forState:UIControlStateNormal];
    self.navigationView.moreButton.titleLabel.font = [UIFont systemFontOfSize:17];
  }
}

- (void)configTitle:(NEEditType)editType {
  self.editType = editType;
  switch (editType) {
    case NEEditTypeNickName:
      self.title = NELocalizable(@"nickname");
      self.limitCount = 15;
      break;
    case NEEditTypeCellphone:
      self.title = NELocalizable(@"phone");
      self.limitCount = 11;
      self.textField.keyboardType = UIKeyboardTypePhonePad;
      break;
    case NEEditTypeEmail:
      self.title = NELocalizable(@"email");
      self.limitCount = 30;
      self.textField.keyboardType = UIKeyboardTypeEmailAddress;
      break;
    case NEEditTypeSpecialSign:
      self.title = NELocalizable(@"individuality_sign");
      self.limitCount = 50;
      break;
  }
  [self applyKeyboardTypeForCurrentEditType];
}

- (void)setContentText:(NSString *)contentText {
  _contentText = contentText;
  self.textField.text = contentText;
  self.signatureTextView.text = contentText;
  [self updateSignatureClearButton];
}

- (void)saveName {
  [self.view endEditing:YES];

  if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }

  if (self.callBack) {
    self.callBack(self.editType == NEEditTypeSpecialSign ? (self.signatureTextView.text ?: @"") : (self.textField.text ?: @""));
  }
}

- (void)textFieldChange {
  if (self.textField.markedTextRange) {
    return;
  }
  NSString *text = self.textField.text ?: @"";
  if (self.limitCount <= 0 || text.length <= self.limitCount) {
    return;
  }
  self.textField.text = [text substringToIndex:self.limitCount];
  NEHandleInputLimitExceeded(self.view, self.limitCount);
}

- (void)applyKeyboardTypeForCurrentEditType {
  if (!self.textField) {
    return;
  }
  switch (self.editType) {
    case NEEditTypeCellphone:
      self.textField.keyboardType = UIKeyboardTypePhonePad;
      break;
    case NEEditTypeEmail:
      self.textField.keyboardType = UIKeyboardTypeEmailAddress;
      break;
    case NEEditTypeNickName:
    case NEEditTypeSpecialSign:
    default:
      self.textField.keyboardType = UIKeyboardTypeDefault;
      break;
  }
}

- (void)textViewDidChange:(UITextView *)textView {
  if (textView.markedTextRange) return;
  NSString *text = textView.text ?: @"";
  if (self.limitCount > 0 && text.length > self.limitCount) {
    while (text.length > self.limitCount) {
      NSRange lastCharacter = [text rangeOfComposedCharacterSequenceAtIndex:text.length - 1];
      text = [text substringToIndex:lastCharacter.location];
    }
    textView.text = text;
    NEHandleInputLimitExceeded(self.view, self.limitCount);
  }
  [self updateSignatureClearButton];
}

#pragma mark - Signature Clear

- (UIButton *)signatureClearButton {
  if (!_signatureClearButton) {
    _signatureClearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _signatureClearButton.translatesAutoresizingMaskIntoConstraints = NO;
    _signatureClearButton.backgroundColor = UIColor.clearColor;
    [_signatureClearButton setImage:[NETeamUIKitLoader() loadImage:@"clear_btn"] forState:UIControlStateNormal];
    _signatureClearButton.accessibilityIdentifier = @"id.clear";
    [_signatureClearButton addTarget:self action:@selector(clearSignature) forControlEvents:UIControlEventTouchUpInside];
  }
  return _signatureClearButton;
}

- (void)updateSignatureClearButton {
  if (!_signatureClearButton || self.editType != NEEditTypeSpecialSign) {
    return;
  }
  _signatureClearButton.hidden = self.signatureTextView.text.length == 0;
}

- (void)clearSignature {
  self.signatureTextView.text = @"";
  [self updateSignatureClearButton];
  [self textViewDidChange:self.signatureTextView];
}

@end
