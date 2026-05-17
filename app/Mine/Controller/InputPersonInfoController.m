// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "InputPersonInfoController.h"
#import "AppKey.h"
#import "NEStyleManager.h"
#import <NEChatKitOC/NEChatDetectNetworkTool.h>
#import <NEChatKitOC/NEAppLanguageUtil.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatUIKitOC/FunChatUIColor.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/NENavigationView.h>
#import <NECommonUIKitOC/UIView+YXToast.h>

@interface InputPersonInfoController () <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
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
    [self.textField becomeFirstResponder];
  });
}

- (void)setupSubviews {
  _textfieldBgView = [[UIView alloc] init];
  _textfieldBgView.translatesAutoresizingMaskIntoConstraints = NO;
  _textfieldBgView.backgroundColor = UIColor.whiteColor;
  _textfieldBgView.clipsToBounds = YES;
  _textfieldBgView.layer.cornerRadius = [NEStyleManager.instance isNormalStyle] ? 8 : 0;
  [self.view addSubview:_textfieldBgView];

  _textField = [[UITextField alloc] init];
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
  [_textfieldBgView addSubview:_textField];

  CGFloat leftInset = [NEStyleManager.instance isNormalStyle] ? 20 : 0;

  [NSLayoutConstraint activateConstraints:@[
    [_textfieldBgView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:leftInset],
    [_textfieldBgView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-leftInset],
    [_textfieldBgView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:12 + self.topConstant],
    [_textfieldBgView.heightAnchor constraintEqualToConstant:50],

    [_textField.leftAnchor constraintEqualToAnchor:_textfieldBgView.leftAnchor constant:16],
    [_textField.rightAnchor constraintEqualToAnchor:_textfieldBgView.rightAnchor constant:-12],
    [_textField.centerYAnchor constraintEqualToAnchor:_textfieldBgView.centerYAnchor],
  ]];

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
}

- (void)saveName {
  [self.view endEditing:YES];

  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }

  if (self.callBack) {
    self.callBack(self.textField.text ?: @"");
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
  [self.view ne_makeToast:[NSString stringWithFormat:NELocalizable(@"text_count_limit"), (int)self.limitCount]];
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

@end
